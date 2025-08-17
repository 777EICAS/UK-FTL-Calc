//
//  ContentView.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI
import EventKit

// Import extracted components
// Note: These components are now in separate files for better organization
// All components are automatically available in the same module

struct ContentView: View {
    @StateObject private var viewModel = FTLViewModel()
    @State private var showingCalendarImport = false
    @State private var showingSettings = false

    @State private var showingFileUpload = false
    @State private var showingFTLFactors = false
    @State private var showingFlightSelection = false

    @State private var selectedTab = 0
    @State private var showingAugmentedCrewPopup = false
    @State private var showingAcclimatisedPopup = false
    @State private var showingStandbyPopup = false
    @State private var showingRestFacilitySelection = false
    @State private var scrollToResults = false
    @State private var scrollToCalculateButton = false
    @State private var scrollToStandbyInput = false
    @State private var scrollToTop = false
    @State private var resultsSectionID = UUID()
    @State private var calculateButtonID = UUID()
    @State private var standbyInputID = UUID()
    @State private var topSectionID = UUID()
    @FocusState private var isStandbyInputFocused: Bool
    @AppStorage("homeBase") private var homeBase: String = "LHR"
    @AppStorage("secondHomeBase") private var secondHomeBase: String = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Manual Calc Tab
            ManualCalcView()
                .tabItem {
                    Image(systemName: "pencil.and.outline")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("Manual Calc")
                }
                .tag(0)
            
            // Main FTL Calculator Tab
            mainCalculatorView
                .tabItem {
                    Image(systemName: "airplane")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    Text("FTL Calculator")
                }
                .tag(1)
            
            // Calendar Tab
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                        .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                    Text("Calendar")
                }
                .tag(2)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                    Text("Settings")
                }
                .tag(3)
            
            // Profile Tab
            UserSettings()
                .tabItem {
                    Image(systemName: "person.circle")
                        .environment(\.symbolVariants, selectedTab == 4 ? .fill : .none)
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            // Custom tab bar styling with background for better visibility
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Set the tab bar appearance
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Add subtle shadow for floating effect
            UITabBar.appearance().layer.shadowColor = UIColor.black.cgColor
            UITabBar.appearance().layer.shadowOffset = CGSize(width: 0, height: -2)
            UITabBar.appearance().layer.shadowRadius = 8
            UITabBar.appearance().layer.shadowOpacity = 0.1
            UITabBar.appearance().layer.masksToBounds = false
        }
    }
    
    // MARK: - Trip Context Detection
    // Treat London bases (LHR/LGW/STN) as a single home-base group for context
    private func isHomeBaseEquivalent(_ airport: String, homeBase: String) -> Bool {
        let londonBases: Set<String> = ["LHR", "LGW", "STN"]
        let ap = airport.uppercased()
        let hb = homeBase.uppercased()
        return ap == hb || (londonBases.contains(ap) && londonBases.contains(hb))
    }
    private func detectAndSetTripContext(selectedFlight: FlightRecord, allFlights: [FlightRecord]) {
        // Look for the outbound flight (first flight of the trip) that matches this inbound flight
        // For JFK-LHR, we're looking for LHR-JFK in the same trip
        
        let homeBase = viewModel.homeBase
        let selectedDeparture = selectedFlight.departure
        let selectedArrival = selectedFlight.arrival
        
        print("DEBUG: Trip context detection for \(selectedFlight.flightNumber) (\(selectedDeparture)-\(selectedArrival))")
        print("DEBUG: Home base: \(homeBase)")
        print("DEBUG: Selected flight trip number: \(selectedFlight.tripNumber)")
        
        // If this is an inbound flight (returning to home-base group), look for the corresponding outbound flight
        if isHomeBaseEquivalent(selectedArrival, homeBase: homeBase) && !isHomeBaseEquivalent(selectedDeparture, homeBase: homeBase) {
            print("DEBUG: Detected inbound flight - looking for corresponding outbound flight")
            
            // Find the outbound flight that matches this trip
            // Look for a flight that departs from home base and arrives at the current departure airport
            // AND is in the same trip
            let outboundFlight = allFlights.first { flight in
                isHomeBaseEquivalent(flight.departure, homeBase: homeBase) &&
                flight.arrival.uppercased() == selectedDeparture.uppercased() &&
                flight.tripNumber == selectedFlight.tripNumber &&
                flight.isOutbound // Ensure we're getting the outbound sector
            }
            
            if let outboundFlight = outboundFlight {
                print("DEBUG: Found corresponding outbound flight: \(outboundFlight.flightNumber) (\(outboundFlight.departure)-\(outboundFlight.arrival))")
                print("DEBUG: Outbound report time: \(outboundFlight.reportTime)")
                print("DEBUG: Outbound flight trip number: \(outboundFlight.tripNumber)")
                
                // Set the original home base report time for acclimatisation calculations
                viewModel.setOriginalHomeBaseReportTime(outboundFlight.reportTime)
                
                print("DEBUG: Set original home base report time to: \(outboundFlight.reportTime)")
                print("DEBUG: This will calculate elapsed time from \(outboundFlight.reportTime) to \(selectedFlight.reportTime)")
            } else {
                print("DEBUG: No corresponding outbound flight found in same trip - treating as standalone flight")
                print("DEBUG: Available flights in same trip:")
                let sameTripFlights = allFlights.filter { $0.tripNumber == selectedFlight.tripNumber }
                for flight in sameTripFlights {
                    print("DEBUG:   \(flight.flightNumber) \(flight.departure)-\(flight.arrival) (outbound: \(flight.isOutbound))")
                }
            }
        } else {
            print("DEBUG: Not an inbound to home-base group or departure from home base - no trip context needed")
        }
    }
    
    // MARK: - Helper Functions
    private func calculateTimeZoneDifference() {
        guard !viewModel.departure.isEmpty,
              !viewModel.arrival.isEmpty else {
            print("DEBUG: Empty departure or arrival")
            return
        }
        
        // Calculate time zone difference for acclimatisation purposes
        // For Table 1: Reference time is from trip start location (home base)
        // Local time is from current duty start location (current departure airport)
        let departure = viewModel.departure.uppercased()
        let homeBase = viewModel.homeBase.uppercased()
        
        // Determine first sector status BEFORE computing elapsed time (treat London bases as one)
        viewModel.ftlFactors.isFirstSector = isHomeBaseEquivalent(departure, homeBase: homeBase)
        
        // For acclimatisation: time zone difference is from reference location (home base) to current duty start location
        let timeZoneDiff = TimeUtilities.getTimeZoneDifference(from: homeBase, to: departure)
        print("DEBUG: Calculating TZ diff from reference location '\(homeBase)' to current duty start location '\(departure)' for acclimatisation")
        print("DEBUG: Time zone difference result: \(timeZoneDiff)")
        
        viewModel.ftlFactors.timeZoneDifference = timeZoneDiff
        
        // Calculate elapsed time since original home base reporting (for acclimatisation purposes)
        let elapsedTime: Double
        if viewModel.ftlFactors.isFirstSector {
            // First sector: elapsed time is 0 hours (trip hasn't started yet)
            elapsedTime = 0.0
            // Store the original home base report time for future sectors
            viewModel.ftlFactors.originalHomeBaseReportTime = viewModel.reportTime
            print("DEBUG: First sector - elapsed time set to 0 hours")
        } else {
            // Check if we have a pre-calculated elapsed time from imported XML data
            // For flights with multiple sectors (like shuttle trips), match by both flight number AND route
            if let currentFlight = viewModel.allImportedFlights.first(where: { flight in
                flight.flightNumber == viewModel.flightNumber &&
                flight.departure == viewModel.departure &&
                flight.arrival == viewModel.arrival
            }) {
                // For shuttle trips, use elapsedTimeFromTripStart for acclimatisation
                // For regular trips, use elapsedTimeHours
                if currentFlight.isShuttleTrip {
                    elapsedTime = currentFlight.elapsedTimeFromTripStart
                    print("DEBUG: Using shuttle trip elapsed time from trip start: \(elapsedTime) hours")
                } else {
                    elapsedTime = currentFlight.elapsedTimeHours
                    print("DEBUG: Using regular trip elapsed time: \(elapsedTime) hours")
                }
                print("DEBUG: Flight details - Trip: \(currentFlight.tripNumber), Outbound: \(currentFlight.isOutbound), Shuttle: \(currentFlight.isShuttleTrip)")
                
                // Validate the pre-calculated elapsed time
                if currentFlight.isOutbound && elapsedTime != 0.0 {
                    print("DEBUG: WARNING - Outbound flight has non-zero elapsed time: \(elapsedTime)h (should be 0)")
                }
            } else {
                // Manual flight entry: calculate elapsed time manually
                if !viewModel.ftlFactors.originalHomeBaseReportTime.isEmpty {
                    // Use date-aware calculation if we have the outbound flight information
                    if let outboundFlight = viewModel.allImportedFlights.first(where: { flight in
                        isHomeBaseEquivalent(flight.departure, homeBase: viewModel.homeBase) &&
                        flight.arrival.uppercased() == viewModel.departure.uppercased()
                    }) {
                        // Calculate elapsed time using date information
                        elapsedTime = TimeUtilities.calculateElapsedTimeWithDates(
                            startDate: outboundFlight.date,
                            startTime: viewModel.ftlFactors.originalHomeBaseReportTime,
                            endDate: viewModel.allImportedFlights.first(where: { flight in
                            flight.flightNumber == viewModel.flightNumber &&
                            flight.departure == viewModel.departure &&
                            flight.arrival == viewModel.arrival
                        })?.date ?? "",
                            endTime: viewModel.reportTime
                        )
                        print("DEBUG: Using date-aware elapsed time calculation: \(elapsedTime) hours")
                    } else {
                        // Fallback to time-only calculation
                        elapsedTime = TimeUtilities.calculateHoursBetween(viewModel.ftlFactors.originalHomeBaseReportTime, viewModel.reportTime)
                        print("DEBUG: Using fallback time-only elapsed time calculation: \(elapsedTime) hours")
                    }
                } else {
                    // Fallback: use current sector's elapsed time
                    elapsedTime = TimeUtilities.calculateHoursBetween(viewModel.reportTime, viewModel.dutyEndTime)
                }
            }
        }
        viewModel.ftlFactors.elapsedTimeHours = elapsedTime
        
        // Re-affirm first sector flag using home-base equivalence
        viewModel.ftlFactors.isFirstSector = isHomeBaseEquivalent(departure, homeBase: viewModel.homeBase)
        
        // Automatically determine acclimatisation status based on UK CAA Table 1 regulations
        let acclimatisationStatus = UKCAALimits.determineAcclimatisationStatus(
            timeZoneDifference: timeZoneDiff,
            elapsedTimeHours: viewModel.ftlFactors.elapsedTimeHours,
            isFirstSector: viewModel.ftlFactors.isFirstSector,
            homeBase: viewModel.homeBase,
            departure: departure
        )
        viewModel.ftlFactors.isAcclimatised = acclimatisationStatus.isAcclimatised
        viewModel.ftlFactors.shouldBeAcclimatised = acclimatisationStatus.shouldBeAcclimatised
        
        print("DEBUG: Auto-determined acclimatisation - Time zone diff: \(timeZoneDiff)h, Elapsed: \(viewModel.ftlFactors.elapsedTimeHours)h, First sector: \(viewModel.ftlFactors.isFirstSector), Reason: \(acclimatisationStatus.reason)")
    }
    
    private var mainCalculatorView: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        // Header Section
                        headerSection
                            .id(topSectionID)
                        
                        // Flight Data Input
                        flightDataSection
                        
                        // Results Section
                        if viewModel.hasCalculatedResults {
                            resultsSection
                                .id(resultsSectionID)
                        }
                        
                        // Reset Form Button
                        resetFormSection
                    }
                    .padding()
                }
                .onChange(of: scrollToResults) { _, shouldScroll in
                    if shouldScroll && viewModel.hasCalculatedResults {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo(resultsSectionID, anchor: .top)
                        }
                        scrollToResults = false
                    }
                }
                .onChange(of: scrollToCalculateButton) { _, shouldScroll in
                    if shouldScroll {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo(calculateButtonID, anchor: .center)
                        }
                        scrollToCalculateButton = false
                    }
                }
                .onChange(of: scrollToStandbyInput) { _, shouldScroll in
                    if shouldScroll {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo(standbyInputID, anchor: .center)
                        }
                        scrollToStandbyInput = false
                    }
                }
                .onChange(of: viewModel.ftlFactors.standbyTypeSelected) { _, isSelected in
                    if isSelected {
                        // Trigger scroll to standby input after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            scrollToStandbyInput = true
                            isStandbyInputFocused = true
                        }
                    }
                }
                .onChange(of: scrollToTop) { _, shouldScroll in
                    if shouldScroll {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo(topSectionID, anchor: .top)
                        }
                        scrollToTop = false
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)

            .sheet(isPresented: $showingAugmentedCrewPopup) {
                AugmentedCrewRestFacilityView(
                    restFacilityType: $viewModel.ftlFactors.restFacilityType,
                    hasAugmentedCrew: $viewModel.ftlFactors.hasAugmentedCrew,
                    hasInFlightRest: $viewModel.ftlFactors.hasInFlightRest,
                    isPresented: $showingAugmentedCrewPopup,
                    numberOfAdditionalPilots: $viewModel.ftlFactors.numberOfAdditionalPilots,
                    takeoffTime: viewModel.takeoffTime,
                    landingTime: viewModel.landingTime
                )
            }
            .sheet(isPresented: $showingAcclimatisedPopup) {
                AcclimatisedExplanationView(
                    isAcclimatised: $viewModel.ftlFactors.isAcclimatised,
                    isPresented: $showingAcclimatisedPopup,
                    timeZoneDifference: $viewModel.ftlFactors.timeZoneDifference
                )
            }
            .sheet(isPresented: $showingStandbyPopup) {
                StandbyTypeSelectionView(
                    standbyType: $viewModel.ftlFactors.standbyType,
                    hasStandbyDuty: $viewModel.ftlFactors.hasStandbyDuty,
                    standbyTypeSelected: $viewModel.ftlFactors.standbyTypeSelected,
                    isPresented: $showingStandbyPopup
                )
            }
            .sheet(isPresented: $showingRestFacilitySelection) {
                InFlightRestFacilitySelectionView(
                    restFacilityType: $viewModel.ftlFactors.restFacilityType,
                    hasInFlightRest: $viewModel.ftlFactors.hasInFlightRest,
                    isPresented: $showingRestFacilitySelection
                )
            }
            .sheet(isPresented: $showingFTLFactors) {
                FTLFactorsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFileUpload) {
                FileUploadView { selectedFlights, allFlights in
                    // Always import all flights from the PDF for trip context
                    print("DEBUG: PDF Upload - Received \(selectedFlights.count) selected flights from \(allFlights.count) total flights")
                    
                    // Store all flights in the view model for trip context detection
                    viewModel.allImportedFlights = allFlights
                    
                    if let firstFlight = selectedFlights.first {
                        print("DEBUG: PDF Upload - First flight data:")
                        print("  flightNumber: '\(firstFlight.flightNumber)'")
                        print("  departure: '\(firstFlight.departure)'")
                        print("  arrival: '\(firstFlight.arrival)'")
                        print("  reportTime: '\(firstFlight.reportTime)'")
                        print("  takeoffTime: '\(firstFlight.takeoffTime)'")
                        print("  landingTime: '\(firstFlight.landingTime)'")
                        print("  dutyEndTime: '\(firstFlight.dutyEndTime)'")
                        
                        // Reset calculation state when new data is imported
                        viewModel.resetCalculationState()
                        
                        viewModel.flightNumber = firstFlight.flightNumber
                        viewModel.departure = firstFlight.departure
                        viewModel.arrival = firstFlight.arrival
                        
                        // Adjust report time for LGW/LHR arrivals (75 minutes before takeoff)
                        if firstFlight.arrival == "LGW" || firstFlight.arrival == "LHR" {
                            let reportTime = TimeUtilities.addHours(firstFlight.takeoffTime, hours: -1.25) // 75 minutes = 1.25 hours
                            viewModel.reportTime = reportTime + "z" // Ensure z suffix is preserved
                            print("DEBUG: LGW/LHR arrival - Adjusted report time to 75 minutes before takeoff")
                            print("DEBUG: Takeoff time: \(firstFlight.takeoffTime) -> Report time: \(viewModel.reportTime)")
                        } else {
                            viewModel.reportTime = firstFlight.reportTime
                            print("DEBUG: Non-LGW/LHR arrival - Using original report time")
                        }
                        
                        viewModel.takeoffTime = firstFlight.takeoffTime
                        viewModel.landingTime = firstFlight.landingTime
                        viewModel.dutyEndTime = firstFlight.dutyEndTime
                        
                        // Auto-detect trip context and set original home base report time
                        detectAndSetTripContext(selectedFlight: firstFlight, allFlights: allFlights)
                        
                        // Calculate time zone difference and elapsed time AFTER report time adjustment
                        calculateTimeZoneDifference()
                        
                        // Auto-set augmented crew based on pilot count
                        print("DEBUG: Pilot count analysis for \(firstFlight.flightNumber):")
                        print("  Total pilots detected: \(firstFlight.pilotCount)")
                        print("  Standard crew: 2 pilots")
                        print("  Additional pilots needed: \(firstFlight.pilotCount > 2 ? firstFlight.pilotCount - 2 : 0)")
                        
                        if firstFlight.pilotCount > 2 {
                            // More than 2 pilots = augmented crew
                            let additionalPilots = firstFlight.pilotCount - 2
                            viewModel.ftlFactors.hasAugmentedCrew = true
                            viewModel.ftlFactors.numberOfAdditionalPilots = additionalPilots
                            // Auto-select in-flight rest when augmented crew is selected
                            viewModel.ftlFactors.hasInFlightRest = true
                            print("DEBUG: Auto-set augmented crew - \(additionalPilots) additional pilot(s) for \(firstFlight.pilotCount) total pilots")
                            print("DEBUG: Auto-set in-flight rest for augmented crew")
                            print("DEBUG: numberOfAdditionalPilots set to: \(viewModel.ftlFactors.numberOfAdditionalPilots)")
                            // Show rest facility selection popup (number of additional pilots already calculated)
                            showingAugmentedCrewPopup = true
                        } else {
                            // 1 or 2 pilots = standard crew (no augmented crew)
                            viewModel.ftlFactors.hasAugmentedCrew = false
                            viewModel.ftlFactors.numberOfAdditionalPilots = 0
                            // Don't auto-select in-flight rest for standard crew
                            viewModel.ftlFactors.hasInFlightRest = false
                            print("DEBUG: Standard crew - \(firstFlight.pilotCount) pilot(s) total (no augmented crew)")
                        }
                        
                        print("DEBUG: PDF Upload - After setting viewModel data:")
                        print("  viewModel.flightNumber: '\(viewModel.flightNumber)'")
                        print("  viewModel.departure: '\(viewModel.departure)'")
                        print("  viewModel.arrival: '\(viewModel.arrival)'")
                        print("  viewModel.reportTime: '\(viewModel.reportTime)'")
                        print("  viewModel.takeoffTime: '\(viewModel.takeoffTime)'")
                        print("  viewModel.landingTime: '\(viewModel.landingTime)'")
                        print("  viewModel.dutyEndTime: '\(viewModel.dutyEndTime)'")
                        print("  viewModel.canCalculate: \(viewModel.canCalculate)")
                        
                        // Trigger auto-scroll to calculate button after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            scrollToCalculateButton = true
                        }
                    } else {
                        print("DEBUG: PDF Upload - No flights found in parsed data")
                    }
                    // Automatically dismiss the sheet and return to home page
                    showingFileUpload = false
                }

            }
            .sheet(isPresented: $showingFlightSelection) {
                FlightSelectionView(
                    allFlights: viewModel.allImportedFlights,
                    onFlightSelected: { selectedFlight in
                        showingFlightSelection = false
                        viewModel.selectFlight(selectedFlight)
                        
                        // Auto-detect trip context and set original home base report time
                        detectAndSetTripContext(selectedFlight: selectedFlight, allFlights: viewModel.allImportedFlights)
                        
                        // Calculate time zone difference and elapsed time
                        calculateTimeZoneDifference()
                        
                        // Auto-set augmented crew based on pilot count
                        if selectedFlight.pilotCount > 2 {
                            let additionalPilots = selectedFlight.pilotCount - 2
                            viewModel.ftlFactors.hasAugmentedCrew = true
                            viewModel.ftlFactors.numberOfAdditionalPilots = additionalPilots
                            viewModel.ftlFactors.hasInFlightRest = true
                            showingAugmentedCrewPopup = true
                        } else {
                            viewModel.ftlFactors.hasAugmentedCrew = false
                            viewModel.ftlFactors.numberOfAdditionalPilots = 0
                            viewModel.ftlFactors.hasInFlightRest = false
                        }
                        
                        // Trigger auto-scroll to calculate button
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            scrollToCalculateButton = true
                        }
                    },
                    onCancel: {
                        showingFlightSelection = false
                    }
                )
            }
        }
    }
    
    // FlightSelectionView and FlightSelectionRow are now in FlightPicker.swift
    

    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Main Header Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("UK CAA FTL Calculator")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Flight Time Limitations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // Helpful message about flight selection
                    if viewModel.hasImportedFlights {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                            
                            Text("Use the Select Flight button to choose from all \(viewModel.availableFlightsCount) flights in your roster")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                    }
                    
                    // Action Buttons with Labels
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            // Flight Selection Button (when flights are available)
                            if viewModel.hasImportedFlights {
                                VStack(spacing: 4) {
                                    Button(action: {
                                        showingFlightSelection = true
                                    }) {
                                        Image(systemName: "airplane.circle")
                                            .font(.title)
                                            .foregroundColor(.green)
                                            .background(
                                                Circle()
                                                    .fill(Color.green.opacity(0.1))
                                                    .frame(width: 44, height: 44)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .overlay(
                                        Text("\(viewModel.availableFlightsCount)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .background(Color.green)
                                            .clipShape(Circle())
                                            .frame(width: 16, height: 16)
                                            .offset(x: 12, y: -12)
                                    )
                                    
                                    Text("Select Flight")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            
                            // File Upload Button
                            VStack(spacing: 4) {
                                Button(action: {
                                    showingFileUpload = true
                                }) {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                        .background(
                                            Circle()
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 44, height: 44)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text("Upload Roster")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            

                        }
                    }
                }
                
                // Status Badge
                HStack {
                    Spacer()
                    Text(getStatusBadgeText())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(viewModel.statusColor)
                        .cornerRadius(6)
                }
                
                // Progress Indicator (if applicable)
                if viewModel.hasCalculatedResults {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Duty Time")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(TimeUtilities.formatHoursAndMinutes(viewModel.dutyTimeValue)) / \(TimeUtilities.formatHoursAndMinutes(viewModel.dynamicDailyDutyLimit))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 6)
                                    .cornerRadius(3)
                                
                                Rectangle()
                                    .fill(getProgressColor())
                                    .frame(width: min(CGFloat(getProgressPercentage()) * geometry.size.width, geometry.size.width), height: 6)
                                    .cornerRadius(3)
                            }
                        }
                        .frame(height: 6)
                        
                        Text(getRemainingTimeText())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Header Helper Functions
    private func getStatusBadgeText() -> String {
        switch viewModel.currentStatus {
        case "Ready to Calculate":
            return "READY"
        case "Calculating...":
            return "PROCESSING"
        case "Compliant":
            return "COMPLIANT"
        case "Non-Compliant":
            return "NON-COMPLIANT"
        default:
            return "READY"
        }
    }
    
    private func getProgressColor() -> Color {
        let percentage = getProgressPercentage()
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getProgressPercentage() -> Double {
        guard viewModel.dynamicDailyDutyLimit > 0 else { return 0 }
        return min(viewModel.dutyTimeValue / viewModel.dynamicDailyDutyLimit, 1.0)
    }
    
    private func getRemainingTimeText() -> String {
        guard viewModel.dynamicDailyDutyLimit > 0 else { return "Daily limit not calculated" }
        
        let remainingTime = viewModel.dynamicDailyDutyLimit - viewModel.dutyTimeValue
        
        if remainingTime <= 0 {
            return "Daily limit exceeded by \(TimeUtilities.formatHoursAndMinutes(abs(remainingTime)))"
        } else {
            return "\(TimeUtilities.formatHoursAndMinutes(remainingTime)) remaining of daily limit"
        }
    }
    

    
    private var flightDataSection: some View {
        VStack(spacing: 16) {
            // Flight Details Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "airplane.departure")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    Text("Flight Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                // Flight Information Grid
                VStack(spacing: 16) {
                    // Flight Number Row
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Flight Number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter flight number", text: $viewModel.flightNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.subheadline)
                    }
                    
                    // Route Information
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Departure")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Airport code", text: $viewModel.departure)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.subheadline)
                        }
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Arrival")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Airport code", text: $viewModel.arrival)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.subheadline)
                        }
                    }
                    
                    // Time Information Grid
                    VStack(spacing: 12) {
                        // Report and OFF Block Times
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock.badge.checkmark")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("Report Time (Z)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                TextField("HH:MM", text: $viewModel.reportTime)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "airplane")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("OFF Block Time (Z)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                TextField("HH:MM", text: $viewModel.takeoffTime)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.subheadline)
                            }
                        }
                        
                        // Landing and Duty End Times
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "airplane.arrival")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("ON Block Time (Z)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                TextField("HH:MM", text: $viewModel.landingTime)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock.badge.xmark")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text("Duty End Time (Z)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                TextField("HH:MM", text: $viewModel.dutyEndTime)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    // Standby Start Time (only show when standby is enabled and type is selected)
                    if viewModel.ftlFactors.hasStandbyDuty && viewModel.ftlFactors.standbyTypeSelected {
                        // Notification banner for standby start time input
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("Next Step: Enter Standby Start Time")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                                                VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                                Text("Standby Start Time (Z)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            TextField("HH:MM", text: $viewModel.ftlFactors.standbyStartTime)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.subheadline)
                                .id(standbyInputID)
                                .focused($isStandbyInputFocused)
                                .placeholder(when: viewModel.ftlFactors.standbyStartTime.isEmpty) {
                                    Text("Enter standby start time (Z time)")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                }
                        }
                    }
                    
                    // Time Zone and Auto-Calculate
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
            Image(systemName: "globe")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text("Departure to Arrival TZ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                calculateTimeZoneDifference()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption)
                                    Text("Auto")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .disabled(viewModel.departure.isEmpty || viewModel.arrival.isEmpty)
                        }
                        
                        TextField("Hours", text: Binding(
                            get: { String(viewModel.ftlFactors.timeZoneDifference) },
                            set: { newValue in
                                if let intValue = Int(newValue) {
                                    viewModel.ftlFactors.timeZoneDifference = intValue
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.subheadline)
                    }
                    
                    // Flight Time Display
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Calculated Block Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack {
                            Text(viewModel.calculatedFlightTimeDisplay)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text("OFF Block to ON Block")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
        }
        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // FTL Factors Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("FTL Factors")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(action: { showingFTLFactors = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.blue)
                    }
                }
                
                // Quick FTL Factors Toggles
                VStack(spacing: 8) {
                    // Early Start Warning
                    if viewModel.ftlFactors.isEarlyStart {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Early start detected (before 06:00)")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    // Current Limits Preview
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Max FDP")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(TimeUtilities.formatHoursAndMinutes(viewModel.dynamicDailyDutyLimit))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Quick Toggle Controls
                    VStack(spacing: 6) {

                        
                        HStack {
                            Text("Quick Settings:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            // Augmented Crew Toggle
                            VStack(spacing: 2) {
                                Toggle("", isOn: Binding(
                                    get: { viewModel.ftlFactors.hasAugmentedCrew },
                                    set: { newValue in
                                        if newValue {
                                            // Set augmented crew to true immediately when toggled on
                                            viewModel.ftlFactors.hasAugmentedCrew = true
                                            showingAugmentedCrewPopup = true
                                        } else {
                                            viewModel.ftlFactors.hasAugmentedCrew = false
                                            // Reset related values when turning off
                                            viewModel.ftlFactors.numberOfAdditionalPilots = 0
                                            viewModel.ftlFactors.hasInFlightRest = false
                                        }
                                    }
                                ))
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                                
                                VStack(spacing: 1) {
                                    Text("Augmented Crew")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    // Add empty space to maintain alignment
                                    Text("")
                                        .font(.caption2)
                                        .opacity(0)
                                }
                            }
                            
                            // In-Flight Rest Toggle
                            VStack(spacing: 2) {
                                Toggle("", isOn: Binding(
                                    get: { viewModel.ftlFactors.hasInFlightRest },
                                    set: { newValue in
                                        if newValue {
                                            showingRestFacilitySelection = true
                                        } else {
                                            viewModel.ftlFactors.hasInFlightRest = false
                                            viewModel.ftlFactors.restFacilityType = .none
                                        }
                                    }
                                ))
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                                
                                VStack(spacing: 1) {
                                    Text("In-Flight Rest")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    // Add empty space to maintain alignment
                                    Text("")
                                        .font(.caption2)
                                        .opacity(0)
                                }
                            }
                            
                            // Standby Toggle
                            VStack(spacing: 2) {
                                Toggle("", isOn: Binding(
                                    get: { viewModel.ftlFactors.hasStandbyDuty },
                                    set: { newValue in
                                        if newValue {
                                            showingStandbyPopup = true
                                        } else {
                                            viewModel.ftlFactors.hasStandbyDuty = false
                                            viewModel.ftlFactors.standbyTypeSelected = false
                                            viewModel.ftlFactors.standbyStartTime = ""
                                        }
                                    }
                                ))
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                                
                                VStack(spacing: 1) {
                                    Text("Standby")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    // Add empty space to maintain alignment
                                    Text("")
                                        .font(.caption2)
                                        .opacity(0)
                                }
                            }
                            

                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    

                    
                    // Enhanced Active Factors Summary - Only show after calculation
                    if !viewModel.activeFactors.isEmpty && viewModel.hasCalculatedResults {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Active Factors")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(viewModel.activeFactors.count) factors")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Enhanced helpful instruction text with visual emphasis
                            HStack {
                                Image(systemName: "hand.tap")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("Tap any factor for detailed breakdown")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Factor combination summary
                            if viewModel.activeFactors.count > 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("How Factors Combine")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 8) {
                                        ForEach(Array(viewModel.activeFactors.enumerated()), id: \.offset) { index, factor in
                                            HStack(spacing: 4) {
                                                Image(systemName: factor.impactType.icon)
                                                    .font(.caption2)
                                                    .foregroundColor(factor.impactType.color)
                                                Text("\(factor.priority)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .frame(width: 16, height: 16)
                                                    .background(factor.impactType.color)
                                                    .clipShape(Circle())
                                            }
                                            
                                            if index < viewModel.activeFactors.count - 1 {
                                                Image(systemName: "arrow.right")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                                }
                            }
                            
                            LazyVStack(spacing: 8) {
                                ForEach(Array(viewModel.activeFactors.enumerated()), id: \.offset) { index, factor in
                                    ActiveFactorCard(factor: factor, hasAugmentedCrew: viewModel.ftlFactors.hasAugmentedCrew)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Calculate Button
            Button(action: { 
                print("DEBUG: Calculate FTL button pressed!")
                print("DEBUG: Current viewModel state:")
                print("  flightNumber: '\(viewModel.flightNumber)'")
                print("  departure: '\(viewModel.departure)'")
                print("  arrival: '\(viewModel.arrival)'")
                print("  reportTime: '\(viewModel.reportTime)'")
                print("  takeoffTime: '\(viewModel.takeoffTime)'")
                print("  landingTime: '\(viewModel.landingTime)'")
                print("  dutyEndTime: '\(viewModel.dutyEndTime)'")
                print("  canCalculate: \(viewModel.canCalculate)")
                viewModel.calculateFTL()
                
                // Trigger auto-scroll to results after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    scrollToResults = true
                }
            }) {
                HStack {
                    Image(systemName: "function")
                    Text("Calculate FTL")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .id(calculateButtonID)
            .disabled(!viewModel.canCalculate)
            .onAppear {
                print("DEBUG: Calculate button canCalculate = \(viewModel.canCalculate)")
            }
            
            // Error Message Display
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("UK CAA FTL Analysis")
                .font(.headline)
                .padding(.horizontal)
            
            // Current Duty Summary
            VStack(spacing: 16) {
                // Duty Time vs Limits
                DutyLimitCard(
                    currentDuty: viewModel.dutyTimeValue,
                    maxDuty: viewModel.dynamicDailyDutyLimit,
                    title: "Daily Duty Time",
                    subtitle: nil,
                    reportTime: viewModel.reportTime,
                    dutyEndTime: viewModel.dutyEndTime,
                    blockTime: TimeUtilities.calculateHoursBetween(viewModel.takeoffTime, viewModel.landingTime)
                )
                

                
                // Commanders Discretion Section
                CommandersDiscretionCard(
                    currentDuty: viewModel.dutyTimeValue,
                    maxDuty: viewModel.dynamicDailyDutyLimit,
                    hasStandbyDuty: viewModel.ftlFactors.hasStandbyDuty,
                    standbyType: viewModel.ftlFactors.standbyType,
                    isAugmentedCrew: viewModel.ftlFactors.hasAugmentedCrew,
                    hasInflightRest: viewModel.ftlFactors.hasInFlightRest,
                    reportTime: viewModel.reportTime,
                    dutyEndTime: viewModel.dutyEndTime,
                    blockTime: TimeUtilities.calculateHoursBetween(viewModel.takeoffTime, viewModel.landingTime)
                )
                
                // Rest Requirements
                RestRequirementCard(
                    dutyTime: viewModel.dutyTimeValue,
                    requiredRest: viewModel.requiredRest,
                    isOutbound: viewModel.isSelectedFlightOutbound
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // AI Analysis Button
            if viewModel.aiAnalysisResult != nil {
                NavigationLink(destination: AIAnalysisView(analysisResult: viewModel.aiAnalysisResult!)) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                        
                        Text("View AI Analysis")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBlue).opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var resetFormSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.resetData()
                // Trigger scroll to top after reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToTop = true
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.red)
                    Text("Reset Form")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}




// MARK: - New FTL Analysis Cards









// MARK: - Active Factor Card

#Preview {
    ContentView()
}

// MARK: - TextField Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Factor Detail Popup View

