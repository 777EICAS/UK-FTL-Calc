//
//  ContentView.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI
import EventKit

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
            // Main FTL Calculator Tab
            mainCalculatorView
                .tabItem {
                    Image(systemName: "airplane")
                        .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                    Text("FTL Calculator")
                }
                .tag(0)
            
            // Calendar Tab
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    Text("Calendar")
                }
                .tag(1)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                        .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                    Text("Settings")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                    Text("Profile")
                }
                .tag(3)
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
            if let currentFlight = viewModel.allImportedFlights.first(where: { $0.flightNumber == viewModel.flightNumber }) {
                // Use the pre-calculated elapsed time from the XML parser
                elapsedTime = currentFlight.elapsedTimeHours
                print("DEBUG: Using pre-calculated elapsed time from XML: \(elapsedTime) hours")
                print("DEBUG: Flight details - Trip: \(currentFlight.tripNumber), Outbound: \(currentFlight.isOutbound)")
                
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
                            endDate: viewModel.allImportedFlights.first(where: { $0.flightNumber == viewModel.flightNumber })?.date ?? "",
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
                .onChange(of: scrollToResults) { shouldScroll in
                    if shouldScroll && viewModel.hasCalculatedResults {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo(resultsSectionID, anchor: .top)
                        }
                        scrollToResults = false
                    }
                }
                .onChange(of: scrollToCalculateButton) { shouldScroll in
                    if shouldScroll {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo(calculateButtonID, anchor: .center)
                        }
                        scrollToCalculateButton = false
                    }
                }
                .onChange(of: scrollToStandbyInput) { shouldScroll in
                    if shouldScroll {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo(standbyInputID, anchor: .center)
                        }
                        scrollToStandbyInput = false
                    }
                }
                .onChange(of: viewModel.ftlFactors.standbyTypeSelected) { isSelected in
                    if isSelected {
                        // Trigger scroll to standby input after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            scrollToStandbyInput = true
                            isStandbyInputFocused = true
                        }
                    }
                }
                .onChange(of: scrollToTop) { shouldScroll in
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
    
    // MARK: - Flight Selection View
    private struct FlightSelectionView: View {
        let allFlights: [FlightRecord]
        let onFlightSelected: (FlightRecord) -> Void
        let onCancel: () -> Void
        @State private var searchText = ""
        
        var filteredFlights: [FlightRecord] {
            if searchText.isEmpty {
                return allFlights
            } else {
                return allFlights.filter { flight in
                    flight.flightNumber.localizedCaseInsensitiveContains(searchText) ||
                    flight.departure.localizedCaseInsensitiveContains(searchText) ||
                    flight.arrival.localizedCaseInsensitiveContains(searchText) ||
                    flight.date.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Select Flight from Roster")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Choose which flight you want to analyze for FTL calculations. All flights from your uploaded roster are available below.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Additional helpful message
                        Text("💡 You can access all flights from your roster anytime using the Select Flight button - no need to re-upload!")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Flight Count Badge
                    HStack {
                        Text("\(filteredFlights.count) of \(allFlights.count) flights")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(12)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search flights by number, route, or date...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Flight List
                    if filteredFlights.isEmpty {
                        VStack(spacing: 16) {
                            if searchText.isEmpty {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                
                                Text("No Flights Available")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("No flights were found in your uploaded roster. Please try uploading a different file.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                
                                Text("No Matching Flights")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("No flights match your search for '\(searchText)'. Try a different search term.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredFlights) { flight in
                                    FlightSelectionRow(flight: flight) {
                                        onFlightSelected(flight)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            onCancel()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Flight Selection Row
    private struct FlightSelectionRow: View {
        let flight: FlightRecord
        let onSelect: () -> Void
        
        var body: some View {
            Button(action: onSelect) {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Flight Icon and Route
                        VStack(spacing: 4) {
                            Image(systemName: "airplane")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            // Route indicator
                            HStack(spacing: 4) {
                                Text(flight.departure)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text(flight.arrival)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Flight Details
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(flight.flightNumber)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Date badge
                                Text(flight.date)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                            }
                            
                            // Times row
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Report")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(flight.reportTime)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Takeoff")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(flight.takeoffTime)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Landing")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(flight.landingTime)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Flight time and duty time
                            HStack {
                                Text("Flight: \(TimeUtilities.formatHoursAndMinutes(flight.flightTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Duty: \(TimeUtilities.formatHoursAndMinutes(flight.dutyTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Selection indicator
                        VStack {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("Select")
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    

    
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
                                Toggle("", isOn: $viewModel.ftlFactors.hasInFlightRest)
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
                                    ActiveFactorCard(factor: factor)
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
                    subtitle: nil
                )
                

                
                // Commanders Discretion Section
                CommandersDiscretionCard(
                    currentDuty: viewModel.dutyTimeValue,
                    maxDuty: viewModel.dynamicDailyDutyLimit,
                    hasStandbyDuty: viewModel.ftlFactors.hasStandbyDuty,
                    standbyType: viewModel.ftlFactors.standbyType
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

struct ResultCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}



// MARK: - New FTL Analysis Cards
struct DutyLimitCard: View {
    let currentDuty: Double
    let maxDuty: Double
    let title: String
    let subtitle: String?
    
    private var percentage: Double {
        guard maxDuty > 0 else { return 0 }
        return (currentDuty / maxDuty) * 100
    }
    
    private var statusColor: Color {
        if percentage >= 100 {
            return .red
        } else if percentage >= 80 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var statusText: String {
        if percentage >= 100 {
            return "EXCEEDED"
        } else if percentage >= 80 {
            return "APPROACHING LIMIT"
        } else {
            return "WITHIN LIMITS"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(6)
            }
            
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(TimeUtilities.formatHoursAndMinutes(currentDuty))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Maximum Allowed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(TimeUtilities.formatHoursAndMinutes(maxDuty))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor)
                    }
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(statusColor)
                            .frame(width: min(CGFloat(percentage / 100) * geometry.size.width, geometry.size.width), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
                
                Text("\(String(format: "%.0f", percentage))% of limit used")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Remaining Time
            if percentage < 100 {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("\(TimeUtilities.formatHoursAndMinutes(maxDuty - currentDuty)) remaining")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Spacer()
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("\(TimeUtilities.formatHoursAndMinutes(currentDuty - maxDuty)) over limit")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CommandersDiscretionCard: View {
    let currentDuty: Double
    let maxDuty: Double
    let hasStandbyDuty: Bool
    let standbyType: StandbyType?
    
    private var maxExtension: Double {
        return 2.0 // UK CAA Regulation 965/2012: Commander's discretion allows up to 2 hours extension
    }
    
    private var isHomeStandbyWith16HourLimit: Bool {
        return hasStandbyDuty && standbyType == .homeStandby && maxDuty >= 16.0
    }
    
    private var canExtend: Bool {
        // Commanders discretion is not available for home standby when 16-hour limit is the limiting factor
        if isHomeStandbyWith16HourLimit {
            return false
        }
        return currentDuty < maxDuty + maxExtension
    }
    
    private var remainingWithExtension: Double {
        return maxDuty + maxExtension - currentDuty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.badge.shield.checkmark")
                    .foregroundColor(.blue)
                Text("Commander's Discretion")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if canExtend {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Maximum Extension")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(TimeUtilities.formatHoursAndMinutes(maxExtension))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(TimeUtilities.formatHoursAndMinutes(maxDuty + maxExtension))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if currentDuty < maxDuty + maxExtension {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.green)
                            Text("\(TimeUtilities.formatHoursAndMinutes(remainingWithExtension)) available with discretion")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Spacer()
                        }
                    }
                    
                    // Conditions
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Conditions for Extension:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Commander approval required")
                                .font(.caption)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Safety assessment completed")
                                .font(.caption)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Fatigue risk evaluated")
                                .font(.caption)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text("Extension not available")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    
                    if isHomeStandbyWith16HourLimit {
                        Text("Home standby has a hard limit of 16 hours total duty. Commanders discretion cannot be applied to increase this limit.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Duty time exceeds maximum allowed even with commander's discretion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.1))
        .cornerRadius(12)
    }
}

struct RestRequirementCard: View {
    let dutyTime: Double
    let requiredRest: String
    let isOutbound: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double")
                    .foregroundColor(.purple)
                Text("Rest Requirements")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                // Sector type indicator
                HStack(spacing: 4) {
                    Image(systemName: isOutbound ? "airplane.departure" : "airplane.arrival")
                        .font(.caption)
                        .foregroundColor(isOutbound ? .orange : .green)
                    Text(isOutbound ? "Outbound" : "Inbound")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isOutbound ? .orange : .green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isOutbound ? Color.orange : Color.green).opacity(0.1))
                .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Required Rest")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        Text(requiredRest)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    Spacer()
                }
                
                // Rest period explanation
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rest Period Rules:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    if isOutbound {
                        Text("• Outbound sector: 10h minimum rest required")
                            .font(.caption)
                        Text("• Rest must be ≥ duty time or 10h, whichever is greater")
                            .font(.caption)
                    } else {
                        Text("• Inbound sector (home base): 12h minimum rest required")
                            .font(.caption)
                        Text("• Rest must be ≥ duty time or 12h, whichever is greater")
                            .font(.caption)
                    }
                    
                    if dutyTime > 14.0 {
                        Text("• Extended duty (>14h): 16h rest required")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemPurple).opacity(0.1))
        .cornerRadius(12)
    }
}

struct AcclimatisedExplanationView: View {
    @Binding var isAcclimatised: Bool
    @Binding var isPresented: Bool
    @Binding var timeZoneDifference: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Acclimatised Crew")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Understanding acclimatisation conditions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Current Time Zone Difference
                VStack(spacing: 8) {
                    Text("Current Time Zone Difference: \(timeZoneDifference) hours")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    if timeZoneDifference < 4 {
                        Text("You are automatically considered acclimatised")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("You must meet acclimatisation requirements")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Explanation
                VStack(alignment: .leading, spacing: 16) {
                    Text("Acclimatisation Rules:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Less than 4 hours time zone change")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("You are ALWAYS considered acclimatised")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.orange)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("4-6 hours time zone difference")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Non-acclimatised on arrival. Become acclimatised after 3 local nights")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.red)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("7+ hours time zone difference")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Non-acclimatised on arrival. Become acclimatised after 4 local nights")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Important Note")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Only select 'Acclimatised' if you meet the above conditions. Extended duty limits apply when acclimatised.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        isAcclimatised = true
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply Acclimatised Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Acclimatisation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}



struct ProfileView: View {
    @AppStorage("homeBase") private var homeBase: String = ""
    @AppStorage("secondHomeBase") private var secondHomeBase: String = ""
    @AppStorage("airline") private var airline: String = ""
    @State private var showingHomeBasePicker = false
    @State private var showingSecondHomeBasePicker = false
    @State private var showingAirlinePicker = false
    
    // Common airport codes with time zones
    let airports = [
        ("LHR", "London Heathrow", "Europe/London"),
        ("LGW", "London Gatwick", "Europe/London"),
        ("STN", "London Stansted", "Europe/London"),
        ("JFK", "New York JFK", "America/New_York"),
        ("LAX", "Los Angeles", "America/Los_Angeles"),
        ("ORD", "Chicago O'Hare", "America/Chicago"),
        ("DFW", "Dallas/Fort Worth", "America/Chicago"),
        ("ATL", "Atlanta", "America/New_York"),
        ("DEN", "Denver", "America/Denver"),
        ("SFO", "San Francisco", "America/Los_Angeles"),
        ("MIA", "Miami", "America/New_York"),
        ("BOS", "Boston", "America/New_York"),
        ("SEA", "Seattle", "America/Los_Angeles"),
        ("CDG", "Paris Charles de Gaulle", "Europe/Paris"),
        ("FRA", "Frankfurt", "Europe/Berlin"),
        ("AMS", "Amsterdam", "Europe/Amsterdam"),
        ("MAD", "Madrid", "Europe/Madrid"),
        ("BCN", "Barcelona", "Europe/Madrid"),
        ("FCO", "Rome", "Europe/Rome"),
        ("MXP", "Milan", "Europe/Rome"),
        ("ZRH", "Zurich", "Europe/Zurich"),
        ("VIE", "Vienna", "Europe/Vienna"),
        ("CPH", "Copenhagen", "Europe/Copenhagen"),
        ("ARN", "Stockholm", "Europe/Stockholm"),
        ("OSL", "Oslo", "Europe/Oslo"),
        ("HEL", "Helsinki", "Europe/Helsinki"),
        ("WAW", "Warsaw", "Europe/Warsaw"),
        ("PRG", "Prague", "Europe/Prague"),
        ("BUD", "Budapest", "Europe/Budapest"),
        ("ATH", "Athens", "Europe/Athens"),
        ("IST", "Istanbul", "Europe/Istanbul"),
        ("DXB", "Dubai", "Asia/Dubai"),
        ("DOH", "Doha", "Asia/Qatar"),
        ("AUH", "Abu Dhabi", "Asia/Dubai"),
        ("BKK", "Bangkok", "Asia/Bangkok"),
        ("SIN", "Singapore", "Asia/Singapore"),
        ("HKG", "Hong Kong", "Asia/Hong_Kong"),
        ("NRT", "Tokyo Narita", "Asia/Tokyo"),
        ("HND", "Tokyo Haneda", "Asia/Tokyo"),
        ("ICN", "Seoul Incheon", "Asia/Seoul"),
        ("SYD", "Sydney", "Australia/Sydney"),
        ("MEL", "Melbourne", "Australia/Melbourne"),
        ("BNE", "Brisbane", "Australia/Brisbane"),
        ("PER", "Perth", "Australia/Perth"),
        ("AKL", "Auckland", "Pacific/Auckland"),
        ("YVR", "Vancouver", "America/Vancouver"),
        ("YYZ", "Toronto", "America/Toronto"),
        ("YUL", "Montreal", "America/Toronto"),
        ("YYC", "Calgary", "America/Edmonton"),
        ("YEG", "Edmonton", "America/Edmonton"),
        ("YOW", "Ottawa", "America/Toronto"),
        ("YHZ", "Halifax", "America/Halifax"),
        ("YWG", "Winnipeg", "America/Winnipeg")
    ]
    
    // Common airlines
    let airlines = [
        ("BA", "British Airways"),
        ("VS", "Virgin Atlantic"),
        ("EI", "Aer Lingus"),
        ("AF", "Air France"),
        ("LH", "Lufthansa"),
        ("KL", "KLM Royal Dutch Airlines"),
        ("IB", "Iberia"),
        ("AZ", "Alitalia"),
        ("LX", "Swiss International Air Lines"),
        ("OS", "Austrian Airlines"),
        ("SK", "SAS Scandinavian Airlines"),
        ("AY", "Finnair"),
        ("LO", "LOT Polish Airlines"),
        ("OK", "Czech Airlines"),
        ("MA", "Malev Hungarian Airlines"),
        ("OA", "Olympic Air"),
        ("TK", "Turkish Airlines"),
        ("EK", "Emirates"),
        ("QR", "Qatar Airways"),
        ("EY", "Etihad Airways"),
        ("TG", "Thai Airways"),
        ("SQ", "Singapore Airlines"),
        ("CX", "Cathay Pacific"),
        ("NH", "All Nippon Airways"),
        ("JL", "Japan Airlines"),
        ("KE", "Korean Air"),
        ("QF", "Qantas"),
        ("AC", "Air Canada"),
        ("AA", "American Airlines"),
        ("UA", "United Airlines"),
        ("DL", "Delta Air Lines"),
        ("WN", "Southwest Airlines"),
        ("B6", "JetBlue Airways"),
        ("AS", "Alaska Airlines"),
        ("F9", "Frontier Airlines"),
        ("NK", "Spirit Airlines"),
        ("HA", "Hawaiian Airlines")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Pilot Profile")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Configure your home bases and time zones")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Home Base Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Home Bases")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Primary Home Base
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Home Base")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Button(action: { showingHomeBasePicker = true }) {
                                HStack {
                                    if !homeBase.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(homeBase)
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            if let airport = airports.first(where: { $0.0 == homeBase }) {
                                                Text(airport.1)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    } else {
                                        Text("Select Primary Home Base")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Second Home Base
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Second Home Base (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Button(action: { showingSecondHomeBasePicker = true }) {
                                HStack {
                                    if !secondHomeBase.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(secondHomeBase)
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            if let airport = airports.first(where: { $0.0 == secondHomeBase }) {
                                                Text(airport.1)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    } else {
                                        Text("Select Second Home Base")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Airline Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Airline")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Button(action: { showingAirlinePicker = true }) {
                            HStack {
                                if !airline.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(airline)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        if let airlineInfo = airlines.first(where: { $0.0 == airline }) {
                                            Text(airlineInfo.1)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                } else {
                                    Text("Select Airline")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Current Time Display
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Current Local Times")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            // Primary Home Base Time (only show if selected)
                            if !homeBase.isEmpty {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Primary Home Base")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(homeBase)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Local Time")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(getLocalTime(for: homeBase))
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                
                                // Second Home Base Time
                                if !secondHomeBase.isEmpty {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Second Home Base")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(secondHomeBase)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Local Time")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(getLocalTime(for: secondHomeBase))
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)

            .sheet(isPresented: $showingHomeBasePicker) {
                AirportPickerView(
                    selectedAirport: $homeBase,
                    title: "Select Primary Home Base",
                    airports: airports
                )
            }
            .sheet(isPresented: $showingSecondHomeBasePicker) {
                AirportPickerView(
                    selectedAirport: $secondHomeBase,
                    title: "Select Second Home Base",
                    airports: airports
                )
            }
            .sheet(isPresented: $showingAirlinePicker) {
                AirlinePickerView(
                    selectedAirline: $airline,
                    title: "Select Airline",
                    airlines: airlines
                )
            }

        }
    }
    
    private func getLocalTime(for airportCode: String) -> String {
        return TimeUtilities.getLocalTime(for: airportCode)
    }
    

}

struct AirlinePickerView: View {
    @Binding var selectedAirline: String
    let title: String
    let airlines: [(String, String)]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredAirlines: [(String, String)] {
        if searchText.isEmpty {
            return airlines
        } else {
            return airlines.filter { airline in
                airline.0.localizedCaseInsensitiveContains(searchText) ||
                airline.1.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search airlines...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Airline List
                List(filteredAirlines, id: \.0) { airline in
                    Button(action: {
                        selectedAirline = airline.0
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(airline.0)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(airline.1)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedAirline == airline.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AirportPickerView: View {
    @Binding var selectedAirport: String
    let title: String
    let airports: [(String, String, String)]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredAirports: [(String, String, String)] {
        if searchText.isEmpty {
            return airports
        } else {
            return airports.filter { airport in
                airport.0.localizedCaseInsensitiveContains(searchText) ||
                airport.1.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search airports...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Airport List
                List(filteredAirports, id: \.0) { airport in
                    Button(action: {
                        selectedAirport = airport.0
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(airport.0)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(airport.1)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedAirport == airport.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Active Factor Card
struct ActiveFactorCard: View {
    let factor: ActiveFactor
    @State private var showingDetailPopup = false
    
    var body: some View {
        Button(action: {
            showingDetailPopup = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: factor.impactType.icon)
                        .foregroundColor(factor.impactType.color)
                        .font(.caption)
                    
                    Text(factor.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Impact indicator
                    Text(factor.impactType.rawValue.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(factor.impactType.color.opacity(0.2))
                        .foregroundColor(factor.impactType.color)
                        .cornerRadius(4)
                    
                    // Add chevron to indicate it's tappable
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(factor.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Show factor value preview
                Text(factor.factorValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(factor.impactType.color)
                    .lineLimit(1)
                
                if !factor.details.isEmpty {
                    Text(factor.details)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(1)
                }
                
                Text(factor.impact)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(factor.impactType.color)
                
                // Show priority and dependencies preview
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.number")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(factor.priority)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if !factor.dependencies.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("\(factor.dependencies.count)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    // Tap hint
                    Text("Tap for details")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .italic()
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(factor.impactType.color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(showingDetailPopup ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: showingDetailPopup)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                .opacity(showingDetailPopup ? 1 : 0)
        )
        .sheet(isPresented: $showingDetailPopup) {
            FactorDetailPopupView(factor: factor)
        }
    }
}

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
struct FactorDetailPopupView: View {
    let factor: ActiveFactor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with icon and title
                    VStack(spacing: 16) {
                        Image(systemName: factor.impactType.icon)
                            .font(.system(size: 50))
                            .foregroundColor(factor.impactType.color)
                        
                        Text(factor.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // Impact type badge
                        Text(factor.impactType.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(factor.impactType.color.opacity(0.2))
                            .foregroundColor(factor.impactType.color)
                            .cornerRadius(8)
                        
                        // Priority indicator
                        HStack {
                            Image(systemName: "list.number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Calculation Priority: \(factor.priority)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Factor Value Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Factor Value")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(factor.factorValue)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(factor.impactType.color)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(factor.impactType.color.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Before/After Comparison (if available)
                    if let beforeAfter = factor.beforeAfter {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Limit Change")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .center, spacing: 8) {
                                    Text("Before")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(beforeAfter.before)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                Image(systemName: "arrow.right")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .center, spacing: 8) {
                                    Text("After")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(beforeAfter.after)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(factor.impactType.color)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(factor.impactType.color.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Calculation Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How This Factor Was Calculated")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(factor.calculationDetails)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Dependencies Section
                    if !factor.dependencies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dependencies")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(factor.dependencies, id: \.self) { dependency in
                                    HStack {
                                        Image(systemName: "link")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text(dependency)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Main description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(factor.description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Additional details
                    if !factor.details.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(factor.details)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Impact explanation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Impact on Duty Limits")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: factor.impactType.icon)
                                .foregroundColor(factor.impactType.color)
                                .font(.title2)
                            
                            Text(factor.impact)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(factor.impactType.color)
                            
                            Spacer()
                        }
                        .padding()
                        .background(factor.impactType.color.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Regulatory context based on factor type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Regulatory Context")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(getRegulatoryContext(for: factor))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Additional regulatory details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Regulatory Reference")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(factor.regulatoryBasis)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Factor interactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Factor Interactions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(getFactorInteractions(for: factor))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Factor Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getRegulatoryContext(for factor: ActiveFactor) -> String {
        switch factor.title {
        case "Acclimatisation":
            return "UK CAA Table 1 determines acclimatisation status based on time zone difference and elapsed time since departure from home base. Acclimatised crews can use extended duty limits from Table 2, while non-acclimatised crews must use reduced limits."
            
        case "Report Time":
            return "FDP limits are determined by local report time at the departure location. The base limit is found in UK CAA Table 2 (acclimatised) or Table 3 (unknown acclimatisation), then modified by other factors."
            
        case "Augmented Crew":
            return "Additional pilots allow extended duty times up to 17-18 hours depending on rest facility type. This is based on UK CAA regulations for augmented crew operations with proper rest facilities."
            
        case "In-Flight Rest":
            return "Rest facilities during flight allow extended duty times. Class 1 facilities provide the most rest time, followed by Class 2 and Class 3. The specific limits depend on the number of additional pilots and facility type."
            
        case "Split Duty":
            return "Split duty periods with rest breaks require reduced duty limits to ensure adequate recovery time. The rest period must meet minimum duration requirements and be properly documented."
            
        case "Consecutive Duty Days":
            return "After 5 or more consecutive duty days, reduced limits apply to prevent cumulative fatigue. This is a key safety measure in the UK CAA FTL regulations."
            
        case "Standby Duty":
            return "Standby duty affects when FDP begins and how total duty time is calculated. Home standby delays FDP start by 2 hours, while airport standby counts all time toward FDP limits."
            
        default:
            return "This factor affects duty limits according to UK CAA Flight Time Limitations regulations. The specific impact depends on the combination of factors present in your duty."
        }
    }
    
    private func getRegulatoryReference(for factor: ActiveFactor) -> String {
        switch factor.title {
        case "Acclimatisation":
            return "UK CAA Table 1: Acclimatisation Status"
        case "Report Time":
            return "UK CAA Table 2: Acclimatised Duty Limits"
        case "Augmented Crew":
            return "UK CAA Regulations: Augmented Crew Operations"
        case "In-Flight Rest":
            return "UK CAA Regulations: In-Flight Rest Facilities"
        case "Split Duty":
            return "UK CAA Regulations: Split Duty Periods"
        case "Consecutive Duty Days":
            return "UK CAA Regulations: Consecutive Duty Days"
        case "Standby Duty":
            return "UK CAA Regulations: Standby Duty"
        default:
            return "UK CAA Regulations: General Duty Limits"
        }
    }
    
    private func getFactorInteractions(for factor: ActiveFactor) -> String {
        switch factor.title {
        case "Acclimatisation":
            return "Acclimatisation status affects which regulatory table is used for base FDP limits. Acclimatised crews use Table 2, while non-acclimatised crews use Table 3. This factor interacts with Report Time to determine the starting point for all other modifications."
            
        case "Report Time":
            return "Report time establishes the base FDP limit from the appropriate regulatory table. This base limit is then modified by all other active factors. Early start times (before 06:00) can further reduce limits regardless of acclimatisation status."
            
        case "Augmented Crew":
            return "Augmented crew allows extended duty times but requires proper rest facilities. The number of additional pilots and rest facility type determine the maximum duty limit. This factor works with In-Flight Rest to provide the maximum possible extension."
            
        case "In-Flight Rest":
            return "In-flight rest facilities extend duty limits beyond standard limits. The extension depends on the rest facility class and whether augmented crew is present. This factor cannot exceed the maximum limits set by Augmented Crew regulations."
            
        case "Split Duty":
            return "Split duty reduces the maximum duty time to ensure adequate recovery during the duty period. This reduction applies regardless of other factors and cannot be overridden by extensions from augmented crew or rest facilities."
            
        case "Consecutive Duty Days":
            return "Consecutive duty day limits are cumulative and apply to the entire duty period. These limits work in combination with daily limits and cannot be extended by other factors. They represent a fundamental safety boundary."
            
        case "Standby Duty":
            return "Standby duty affects when FDP begins and how total duty time is calculated. Home standby delays FDP start, while airport standby counts all time. This factor modifies the duty start time, which then affects all subsequent calculations."
            
        default:
            return "This factor works in combination with other active factors to determine your final duty limits. The most restrictive limit always applies, ensuring compliance with UK CAA safety regulations."
        }
    }
    
    private func getCalculationPriority(for factor: ActiveFactor) -> String {
        switch factor.title {
        case "Acclimatisation":
            return "1st - Determines base regulatory table"
        case "Report Time":
            return "2nd - Establishes base FDP limit"
        case "Augmented Crew":
            return "3rd - Allows duty time extensions"
        case "In-Flight Rest":
            return "4th - Extends duty time based on facilities"
        case "Split Duty":
            return "5th - Applies reduction if applicable"
        case "Consecutive Duty Days":
            return "6th - Applies cumulative limits"
        case "Standby Duty":
            return "7th - Modifies duty start time"
        default:
            return "Variable - Applied as needed"
        }
    }
}

