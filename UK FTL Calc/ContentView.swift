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

    @State private var showingPDFUpload = false
    @State private var showingFTLFactors = false
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
    
    // MARK: - Helper Functions
    private func calculateTimeZoneDifference() {
        guard !viewModel.departure.isEmpty,
              !viewModel.arrival.isEmpty else {
            print("DEBUG: Empty departure or arrival")
            return
        }
        
        // Calculate time zone difference from departure airport to arrival airport
        // Convert to uppercase to match the airport codes in the function
        let departure = viewModel.departure.uppercased()
        let arrival = viewModel.arrival.uppercased()
        
        print("DEBUG: Calculating TZ diff from '\(departure)' to '\(arrival)'")
        
        let timeZoneDiff = TimeUtilities.getTimeZoneDifference(from: departure, to: arrival)
        print("DEBUG: Time zone difference result: \(timeZoneDiff)")
        
        viewModel.ftlFactors.timeZoneDifference = timeZoneDiff
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
                    numberOfAdditionalPilots: $viewModel.ftlFactors.numberOfAdditionalPilots
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
            .sheet(isPresented: $showingPDFUpload) {
                PDFUploadView { parsedFlights in
                    // Handle parsed flights for the main calculator
                    print("DEBUG: PDF Upload - Received \(parsedFlights.count) flights")
                    if let firstFlight = parsedFlights.first {
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
                            viewModel.reportTime = reportTime
                            print("DEBUG: LGW/LHR arrival - Adjusted report time to 75 minutes before takeoff")
                            print("DEBUG: Takeoff time: \(firstFlight.takeoffTime) -> Report time: \(viewModel.reportTime)")
                        } else {
                            viewModel.reportTime = firstFlight.reportTime
                            print("DEBUG: Non-LGW/LHR arrival - Using original report time")
                        }
                        
                        viewModel.takeoffTime = firstFlight.takeoffTime
                        viewModel.landingTime = firstFlight.landingTime
                        viewModel.dutyEndTime = firstFlight.dutyEndTime
                        
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
                    showingPDFUpload = false
                }
            }
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
                    

                    
                    // PDF Upload Button
                    Button(action: {
                        showingPDFUpload = true
                    }) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title)
                            .foregroundColor(.blue)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 44, height: 44)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
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
                                    Text("Report Time")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                TextField("HH:MM", text: $viewModel.reportTime)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "airplane.takeoff")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("OFF Block Time")
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
                                    Text("ON Block Time")
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
                                    Text("Duty End Time")
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
                            // Augmented Crew Toggle (moved to first position)
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
                            
                            // Night Duty Toggle
                            VStack(spacing: 2) {
                                Toggle("", isOn: $viewModel.ftlFactors.isNightDuty)
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                                
                                VStack(spacing: 1) {
                                    Text("Night Duty")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    // Show auto-detected indicator when night duty is detected
                                    if viewModel.ftlFactors.isNightDuty && viewModel.isNightDutyAutoDetected {
                                        Text("Auto")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                            .fontWeight(.medium)
                                    } else {
                                        // Add empty space to maintain alignment when no "Auto" text
                                        Text("")
                                            .font(.caption2)
                                            .opacity(0)
                                    }
                                }
                            }
                            
                            // Acclimatised Toggle
                            VStack(spacing: 2) {
                                Toggle("", isOn: Binding(
                                    get: { 
                                        return viewModel.ftlFactors.isAcclimatised
                                    },
                                    set: { newValue in
                                        if newValue {
                                            if viewModel.ftlFactors.timeZoneDifference >= 4 {
                                                showingAcclimatisedPopup = true
                                            } else {
                                                // Less than 4 hours: always acclimatised
                                                viewModel.ftlFactors.isAcclimatised = true
                                            }
                                        } else {
                                            // Allow deselection for all cases
                                            viewModel.ftlFactors.isAcclimatised = false
                                        }
                                    }
                                ))
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                                
                                VStack(spacing: 1) {
                                    Text("Acclimatised")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    // Show auto-selected indicator for home base departures
                                    let departureUpper = viewModel.departure.uppercased()
                                    let homeBaseUpper = homeBase.uppercased()
                                    let secondHomeBaseUpper = secondHomeBase.uppercased()
                                    
                                    if departureUpper == homeBaseUpper || departureUpper == secondHomeBaseUpper {
                                        Text("Auto")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                            .fontWeight(.medium)
                                    } else {
                                        // Add empty space to maintain alignment when no "Auto" text
                                        Text("")
                                            .font(.caption2)
                                            .opacity(0)
                                    }
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
                    
                    // Active Factors Summary
                    if !viewModel.limitExplanations.isEmpty && viewModel.canCalculate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Factors:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(viewModel.limitExplanations), id: \.self) { explanation in
                                HStack(alignment: .top, spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                    Text(explanation)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
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
                    Image(systemName: "calculator")
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
                    subtitle: "Current vs Maximum Allowed"
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
                    requiredRest: viewModel.requiredRest
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
    let subtitle: String
    
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
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                    Text("\(TimeUtilities.formatHoursAndMinutes(currentDuty))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                    
                    Spacer()
                    
                    Text("\(TimeUtilities.formatHoursAndMinutes(maxDuty))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
    
    private var restHours: Double {
        if dutyTime <= 10 {
            return 11
        } else if dutyTime <= 12 {
            return 12
        } else {
            return 14
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double")
                    .foregroundColor(.purple)
                Text("Rest Requirements")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Required Rest")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        Text("\(String(format: "%.0f", restHours))h")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Next Duty")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        Text(requiredRest)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                }
                
                // Rest period explanation
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rest Period Rules:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    if dutyTime <= 10 {
                        Text("• ≤10h duty: 11h rest required")
                            .font(.caption)
                    } else if dutyTime <= 12 {
                        Text("• 10-12h duty: 12h rest required")
                            .font(.caption)
                    } else {
                        Text("• >12h duty: 14h rest required")
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

