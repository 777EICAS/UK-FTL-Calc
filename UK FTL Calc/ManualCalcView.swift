//
//  ManualCalcView.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct ManualCalcView: View {
    @AppStorage("homeBase") private var homeBase: String = "LHR"
    @AppStorage("secondHomeBase") private var secondHomeBase: String = ""
    @State private var showingStandbyOptions = false
    @State private var selectedStandbyType: String = "Standby"
    @State private var isStandbyEnabled = false
    @State private var showingLocationPicker = false
    @State private var selectedStandbyLocation: String = ""
    @State private var showingDateTimePicker = false
    @State private var standbyStartDateTime = Date()
    @State private var showingReportingLocationPicker = false
    @State private var selectedReportingLocation: String = ""
    @State private var showingReportingDateTimePicker = false
    @State private var reportingDateTime: Date = Date()
    @State private var showingAcclimatisationPicker = false
    @State private var selectedAcclimatisation: String = ""
    @State private var timezoneDifference: Int = 0
    @State private var elapsedTime: Int = 0
    @State private var numberOfSectors: Int = 1
    @State private var hasInFlightRest: Bool = false
    @State private var restFacilityType: RestFacilityType = .none
    @State private var hasSplitDuty: Bool = false
    @State private var hasExtendedFDP: Bool = false
    @State private var showingInFlightRestPicker = false
    @State private var inFlightRestSectors: Int = 1 // 1 = 1-2 sectors, 3 = 3 sectors
    @State private var isLongFlight: Bool = false // Only applicable for 1-2 sectors
    @State private var additionalCrewMembers: Int = 1 // 1 or 2 additional crew
    @State private var estimatedBlockTime: Double = 0.0 // Estimated flight time in hours
    @State private var showingBlockTimePicker = false
    @State private var selectedHour: Int = 12 // Track selected hour for reporting time input
    @State private var selectedMinute: Int = 20 // Track selected minute for reporting time input
    @State private var selectedBlockTimeHour: Int = 0 // Track selected hour for block time input
    @State private var selectedBlockTimeMinute: Int = 0 // Track selected minute for block time input
    @State private var selectedStandbyHour: Int = 9 // Track selected hour for standby time input
    @State private var selectedStandbyMinute: Int = 0 // Track selected minute for standby time input
    @State private var showingWithDiscretionDetails = false
    @State private var showingWithoutDiscretionDetails = false
    @State private var showingOnBlocksDetails = false
    @State private var showingHomeBaseEditor = false
    @State private var editingHomeBase: String = ""
    @State private var editingSecondHomeBase: String = ""
    @State private var showingHomeBaseLocationPicker = false
    @State private var editingHomeBaseType: String = "" // "primary" or "secondary"
    @State private var showingNightStandbyContactPopup = false
    @State private var wasContactedBefore0700 = false
    @State private var contactTimeLocal = Date()
    @State private var selectedContactHour: Int = 7
    @State private var selectedContactMinute: Int = 0
    
    // Initialize reporting location to user's primary home base
    private var defaultReportingLocation: String {
        return homeBase
    }
    
    // Initialize standby location to user's primary home base
    private var defaultStandbyLocation: String {
        return homeBase
    }
    
    // Date and time formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let utcTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    // MARK: - Standby Duration Calculation
    private func calculateStandbyDuration() -> Double {
        // Calculate the duration from standby start to reporting time
        let duration = reportingDateTime.timeIntervalSince(standbyStartDateTime)
        return duration / 3600.0 // Convert seconds to hours
    }
    
    private func checkTotalAwakeTimeLimit() -> Bool {
        // Check if total time awake (standby + duty) exceeds 18 hours
        let standbyDuration = calculateStandbyDuration()
        let maxFDP = calculateMaxFDP()
        let totalAwakeTime = standbyDuration + maxFDP
        
        return totalAwakeTime <= 18.0
    }
    
    private func checkNightStandbyContact() {
        // Check if standby starts between 23:00-07:00 local time to home base
        if isStandbyEnabled && selectedStandbyType == "Standby" {
            let standbyStartLocal = TimeUtilities.getLocalTime(for: utcTimeFormatter.string(from: standbyStartDateTime), airportCode: homeBase)
            let standbyStartHour = Int(standbyStartLocal.prefix(2)) ?? 0
            
            if (standbyStartHour >= 23 || standbyStartHour < 7) {
                showingNightStandbyContactPopup = true
            }
        }
    }
    
    // MARK: - Acclimatisation Calculation Functions
    private func calculateAcclimatisation() -> String {
        // Get the current reporting location (use selected location or default to home base)
        let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
        
        // Use the proper UK CAA acclimatisation logic from Models.swift
        let acclimatisationStatus = UKCAALimits.determineAcclimatisationStatus(
            timeZoneDifference: timezoneDifference,
            elapsedTimeHours: Double(elapsedTime),
            isFirstSector: false, // For manual calc, we want to test the full Table 1 logic
            homeBase: homeBase,
            departure: currentDeparture // Use the actual reporting location
        )
        
        // Extract the result from the reason string
        if acclimatisationStatus.reason.contains("Result B") {
            return "B"
        } else if acclimatisationStatus.reason.contains("Result D") {
            return "D"
        } else {
            return "X"
        }
    }
    
    private func getAcclimatisationDescription(for category: String) -> String {
        switch category {
        case "B":
            return "Acclimatised to home base - Use Table 2 with home base local time for FDP limits"
        case "D":
            return "Acclimatised to departure location - Use Table 2 with departure local time for FDP limits"
        case "X":
            return "Unknown acclimatisation state - Use Table 3 (reduced FDP limits) for calculations"
        default:
            return "Unknown acclimatisation status"
        }
    }
    
    private func calculateMaxFDP() -> Double {
        let acclimatisationResult = calculateAcclimatisation()
        
        // Get base FDP from acclimatisation status
        let baseFDP: Double
        switch acclimatisationResult {
        case "B", "D":
            // Use Table 2 (Acclimatised Crew) - need to convert reporting time to local time
            let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
            let timeString = utcTimeFormatter.string(from: reportingDateTime)
            
            // DEBUG: Show time conversion details
            let utcFormatter = DateFormatter()
            utcFormatter.timeZone = TimeZone(abbreviation: "UTC")
            utcFormatter.dateFormat = "HH:mm"
            print("DEBUG: calculateMaxFDP - reportingDateTime (UTC): \(utcFormatter.string(from: reportingDateTime))")
            print("DEBUG: calculateMaxFDP - timeString (UTC): \(timeString)")
            print("DEBUG: calculateMaxFDP - currentDeparture: \(currentDeparture)")
            
            let localTime = TimeUtilities.getLocalTime(for: timeString, airportCode: currentDeparture)
            print("DEBUG: calculateMaxFDP - localTime result: \(localTime)")
            
            // When numberOfSectors = 1, it represents 1-2 sectors, so use 2 for lookup
            let sectorsForLookup = numberOfSectors == 1 ? 2 : numberOfSectors
            baseFDP = RegulatoryTableLookup.lookupFDPAcclimatised(reportTime: localTime, sectors: sectorsForLookup)
            
        case "X":
            // Use Table 3 (Unknown Acclimatisation)
            let result = RegulatoryTableLookup.lookupFDPUnknownAcclimatised(sectors: numberOfSectors)
            print("DEBUG: ManualCalcView - Table 3 lookup for \(numberOfSectors) sectors returned: \(result)h")
            baseFDP = result
            
        default:
            baseFDP = 9.0 // Default fallback
        }
        
        // Apply Home Standby rules if applicable
        if isStandbyEnabled && selectedStandbyType == "Standby" {
            let standbyDuration = calculateStandbyDuration()
            let thresholdHours = (hasInFlightRest && restFacilityType != .none) || hasSplitDuty ? 8.0 : 6.0
            
            if standbyDuration > thresholdHours {
                let reduction = standbyDuration - thresholdHours
                let reducedFDP = baseFDP - reduction
                
                // Ensure FDP doesn't go below minimum
                let minimumFDP = 9.0 // Minimum FDP limit
                let finalFDP = max(reducedFDP, minimumFDP)
                
                print("DEBUG: Home Standby - Duration: \(String(format: "%.1f", standbyDuration))h, Threshold: \(String(format: "%.1f", thresholdHours))h, Reduction: \(String(format: "%.1f", reduction))h, Base FDP: \(String(format: "%.1f", baseFDP))h, Final FDP: \(String(format: "%.1f", finalFDP))h")
                
                return finalFDP
            }
        }
        
        return baseFDP
    }
    
    private func calculateInFlightRestExtension() -> Double {
        // Convert RestFacilityType to the string format expected by RegulatoryTableLookup
        let restClass: String
        switch restFacilityType {
        case .class1:
            restClass = "class_1"
        case .class2:
            restClass = "class_2"
        case .class3:
            restClass = "class_3"
        case .none:
            return 0.0
        }
        
        // Use the RegulatoryTableLookup function to get the FDP extension
        return RegulatoryTableLookup.lookupInflightRestExtension(
            restClass: restClass,
            additionalCrew: additionalCrewMembers,
            isLongFlight: isLongFlight
        )
    }
    
    private func calculateTotalFDP() -> Double {
        let baseFDP = calculateMaxFDP()
        
        if hasInFlightRest && restFacilityType != .none {
            // When in-flight rest is selected, start with the in-flight rest extension value
            let inFlightRestFDP = calculateInFlightRestExtension()
            
            // If home standby rules apply, reduce the in-flight rest FDP by standby time over threshold
            if isStandbyEnabled && selectedStandbyType == "Standby" {
                let standbyDuration = calculateStandbyDuration()
                let thresholdHours = 8.0 // In-flight rest always uses 8-hour threshold
                
                if standbyDuration > thresholdHours {
                    let reduction = standbyDuration - thresholdHours
                    let finalFDP = inFlightRestFDP - reduction
                    
                    // Ensure FDP doesn't go below minimum
                    let minimumFDP = 9.0
                    let result = max(finalFDP, minimumFDP)
                    
                    print("DEBUG: In-Flight Rest with Home Standby - In-Flight Rest FDP: \(String(format: "%.1f", inFlightRestFDP))h, Standby Duration: \(String(format: "%.1f", standbyDuration))h, Threshold: \(String(format: "%.1f", thresholdHours))h, Reduction: \(String(format: "%.1f", reduction))h, Final FDP: \(String(format: "%.1f", result))h")
                    
                    return result
                }
            }
            
            // No home standby reduction needed, return full in-flight rest FDP
            return inFlightRestFDP
        } else {
            // When no in-flight rest, use the base FDP (which already includes home standby reductions)
            return baseFDP
        }
    }
    
    // MARK: - Latest Off Blocks Time Calculations
    private func calculateLatestOffBlocksTime(withCommandersDiscretion: Bool) -> Date {
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        
        // DEBUG: Print the actual reportingDateTime value
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("DEBUG: reportingDateTime value: \(formatter.string(from: reportingDateTime))")
        
        // Calculate latest off blocks time
        // Latest off blocks = baseline time + total FDP - estimated block time
        
        // Determine the baseline time for calculations
        let baselineTime = getBaselineTimeForCalculations()
        
        // First, add the total FDP hours to the baseline time
        let timeWithFDP = baselineTime.addingTimeInterval(totalFDP * 3600)
        
        // Then subtract the estimated block time
        let latestOffBlocks = timeWithFDP.addingTimeInterval(-estimatedBlockTime * 3600)
        
        return latestOffBlocks
    }
    
    private func getCommandersDiscretionExtension() -> Double {
        if hasInFlightRest && restFacilityType != .none {
            // With additional crew: +3 hours
            return 3.0
        } else {
            // No additional crew: +2 hours
            return 2.0
        }
    }
    
    private func formatTimeForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        // Check if the date is on the next day compared to reporting date
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        let reportingDate = utcCalendar.startOfDay(for: reportingDateTime)
        let offBlocksDate = utcCalendar.startOfDay(for: date)
        
        if utcCalendar.isDate(offBlocksDate, inSameDayAs: reportingDate) {
            // Same day - just show time
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date) + "z"
        } else {
            // Next day - show date and time
            formatter.dateFormat = "dd MMM HH:mm"
            return formatter.string(from: date) + "z"
        }
    }
    
    private func formatCalculationBreakdown(withCommandersDiscretion: Bool) -> String {
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "HH:mm"
        
        // Get the baseline time for calculations
        let baselineTime = getBaselineTimeForCalculations()
        
        // DEBUG: Print the actual baseline time value
        print("DEBUG: formatCalculationBreakdown - baseline time: \(formatter.string(from: baselineTime))")
        
        // Calculate intermediate steps
        let timeWithFDP = baselineTime.addingTimeInterval(totalFDP * 3600)
        let timeString = formatter.string(from: timeWithFDP)
        
        // Show the baseline time in the breakdown
        let baselineTimeString = formatter.string(from: baselineTime)
        let baselineLabel = isStandbyEnabled && selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
        
        if withCommandersDiscretion {
            return "\(baselineTimeString)z (\(baselineLabel)) + \(String(format: "%.1f", totalFDP))h = \(timeString)z - \(String(format: "%.1f", estimatedBlockTime))h"
        } else {
            return "\(baselineTimeString)z (\(baselineLabel)) + \(String(format: "%.1f", totalFDP))h = \(timeString)z - \(String(format: "%.1f", estimatedBlockTime))h"
        }
    }
    
    // MARK: - Latest ON Blocks Time Calculations
    private func calculateLatestOnBlocksTime(withCommandersDiscretion: Bool = false) -> Date {
        // Latest ON blocks time = Baseline Time + Max FDP
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        
        // Determine the baseline time for calculations
        let baselineTime = getBaselineTimeForCalculations()
        
        return baselineTime.addingTimeInterval(totalFDP * 3600)
    }
    
    private func calculateTotalDutyTime(withCommandersDiscretion: Bool = false) -> Double {
        // Total duty time from baseline to ON blocks = Max FDP
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        
        return totalFDP
    }
    
    // MARK: - Baseline Time Calculation
    private func getBaselineTimeForCalculations() -> Date {
        // If airport duty is selected, use standby start time as baseline
        // Otherwise, use the flight reporting time
        if isStandbyEnabled && selectedStandbyType == "Airport Duty" {
            return standbyStartDateTime
        } else {
            return reportingDateTime
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section - Matching main calculator theme
                    VStack(spacing: 16) {
                        // Main Header Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Manual FTL Calculator")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Text("Enter flight information manually for FTL calculations")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                // Icon with background
                                Image(systemName: "pencil.and.outline")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                    .background(
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                    )
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    // Home Bases Display Section - Compact and clickable
                    Button(action: {
                        // Initialize editing values with current home bases
                        editingHomeBase = homeBase
                        editingSecondHomeBase = secondHomeBase
                        showingHomeBaseEditor = true
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header
                            HStack {
                                Image(systemName: "house.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                
                                Text("Your Home Bases")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                // Edit button
                                HStack(spacing: 4) {
                                    Text("Tap to edit")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                    Image(systemName: "pencil.circle")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                            }
                            
                            VStack(spacing: 8) {
                                // Primary Home Base - Compact
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Primary")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        Text(homeBase)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                        Text("UTC +1")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                                
                                // Second Home Base (only show if set) - Compact
                                if !secondHomeBase.isEmpty {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Secondary")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                            Text(secondHomeBase)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                            Text("UTC +1")
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.05))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Standby/Reserve Section - Enhanced styling
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.purple)
                                .font(.title2)
                            
                            Text("Standby/Reserve")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            // Toggle Row with enhanced styling
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Include Standby/Reserve Time")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Text("Configure standby or reserve periods")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $isStandbyEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                                    .onChange(of: isStandbyEnabled) { _, newValue in
                                        if newValue {
                                            showingStandbyOptions = true
                                        }
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Selected Type Display
                            if isStandbyEnabled && !selectedStandbyType.isEmpty {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text("Selected:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    Text(selectedStandbyType)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                                
                                // Night Standby Status (if applicable)
                                if isStandbyEnabled && selectedStandbyType == "Standby" {
                                    let standbyStartLocal = TimeUtilities.getLocalTime(for: utcTimeFormatter.string(from: standbyStartDateTime), airportCode: homeBase)
                                    let standbyStartHour = Int(standbyStartLocal.prefix(2)) ?? 0
                                    let isNightStandby = (standbyStartHour >= 23 || standbyStartHour < 7)
                                    
                                    if isNightStandby {
                                        HStack {
                                            Image(systemName: "moon.fill")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                            
                                            Text("Night Standby Active")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.orange)
                                            
                                            if wasContactedBefore0700 {
                                                Text("• Contacted at \(String(format: "%02d:%02d", selectedContactHour, selectedContactMinute)) local")
                                                    .font(.caption2)
                                                    .foregroundColor(.blue)
                                            } else {
                                                Text("• Not contacted before 07:00")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            
                            // Standby Location Selection (only show when standby is enabled)
                            if isStandbyEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "mappin.circle")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        Text("Standby Location")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Button(action: { showingLocationPicker = true }) {
                                        HStack {
                                            let currentLocation = selectedStandbyLocation.isEmpty ? defaultStandbyLocation : selectedStandbyLocation
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(currentLocation)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                
                                                if let airport = AirportsAndAirlines.airports.first(where: { $0.0 == currentLocation }) {
                                                    Text(airport.1)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(12)
                                    }
                                }
                                
                                // Standby Start Date/Time Selection
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "calendar.badge.clock")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text("Standby Start Date & Time")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Button(action: { showingDateTimePicker = true }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Date: \(standbyStartDateTime, formatter: dateFormatter)")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                
                                                Text("Time: \(formatTimeAsUTC(standbyStartDateTime))")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Reporting Section - Enhanced styling
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            Text("Reporting")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            // Reporting Location (always show)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "mappin.circle")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Reporting Location")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button(action: { showingReportingLocationPicker = true }) {
                                    HStack {
                                        let currentReportingLocation = selectedReportingLocation.isEmpty ? defaultReportingLocation : selectedReportingLocation
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(currentReportingLocation)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            if let airport = AirportsAndAirlines.airports.first(where: { $0.0 == currentReportingLocation }) {
                                                Text(airport.1)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Reporting Date/Time (always show)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("Reporting Date & Time")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Helpful instruction
                                Text("Enter time in UTC (Zulu time)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                
                                Button(action: { showingReportingDateTimePicker = true }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Date: \(reportingDateTime, formatter: dateFormatter)")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                                .onAppear {
                                                    logReportingTimeDisplay()
                                                }
                                            
                                            // Always show UTC time
                                            Text("Time: \(formatTimeAsUTC(reportingDateTime))")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Acclimatisation Selection
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(.purple)
                                        .font(.caption)
                                    Text("Acclimatisation")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button(action: { showingAcclimatisationPicker = true }) {
                                    HStack {
                                        if !selectedAcclimatisation.isEmpty {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(selectedAcclimatisation)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                
                                                Text("TZ: \(timezoneDifference)h, Elapsed: \(elapsedTime)h")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        } else {
                                            Text("Select Acclimatisation")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.purple)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Sectors and FDP Extensions Section - Enhanced styling
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            Text("Sectors and FDP Extensions")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            // Number of Sectors
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "number.circle")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Number of Sectors")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                Picker("Number of Sectors", selection: $numberOfSectors) {
                                    ForEach([1, 3, 4, 5, 6, 7, 8, 9, 10], id: \.self) { sector in
                                        if sector == 1 {
                                            Text("1-2 sectors").tag(1)
                                        } else {
                                            Text("\(sector) sectors").tag(sector)
                                        }
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 120)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // In-Flight Rest
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "bed.double")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("In-Flight Rest")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button(action: { showingInFlightRestPicker = true }) {
                                    HStack {
                                        if hasInFlightRest {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(restFacilityType.rawValue)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text("Sectors: \(inFlightRestSectors == 1 ? "1-2" : "3")")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    if inFlightRestSectors == 1 && isLongFlight {
                                                        Text("Long Flight (>9h)")
                                                            .font(.caption)
                                                            .foregroundColor(.blue)
                                                    }
                                                    
                                                    Text("Additional Crew: \(additionalCrewMembers)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        } else {
                                            Text("No In-Flight Rest")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Split Duty
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("Split Duty")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Duty period split by rest period")
                                            .font(.subheadline)
                                            .foregroundColor(hasInFlightRest && restFacilityType != .none ? .secondary : .primary)
                                        Text("Allows duty to be split by rest periods")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $hasSplitDuty)
                                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                                        .disabled(hasInFlightRest && restFacilityType != .none)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background((hasInFlightRest && restFacilityType != .none) ? Color(.systemGray4) : Color(.systemGray6))
                                .cornerRadius(12)
                                
                                if hasInFlightRest && restFacilityType != .none {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text("Split Duty not allowed with In-Flight Rest")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Extended FDP
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock.badge.plus")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("Extended FDP")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Extended flight duty period limits")
                                            .font(.subheadline)
                                            .foregroundColor(hasInFlightRest && restFacilityType != .none ? .secondary : .primary)
                                        Text("Allows extended FDP limits")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $hasExtendedFDP)
                                        .toggleStyle(SwitchToggleStyle(tint: .green))
                                        .disabled(hasInFlightRest && restFacilityType != .none)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background((hasInFlightRest && restFacilityType != .none) ? Color(.systemGray4) : Color(.systemGray6))
                                .cornerRadius(12)
                                
                                if hasInFlightRest && restFacilityType != .none {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text("Extended FDP not allowed with In-Flight Rest")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .fontWeight(.medium)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // FDP Results Section - Enhanced styling
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            Text("FDP Results")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            // Base FDP
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Base FDP")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    Text("\(String(format: "%.1f", calculateMaxFDP()))h")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Acclimatisation")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: selectedAcclimatisation == "X" ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                            .foregroundColor(selectedAcclimatisation == "X" ? .red : (selectedAcclimatisation == "D" ? .orange : .green))
                                            .font(.caption)
                                        Text(selectedAcclimatisation.isEmpty ? "Not Set" : selectedAcclimatisation)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(selectedAcclimatisation == "X" ? .red : (selectedAcclimatisation == "D" ? .orange : .green))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Home Standby Rules Applied (if applicable)
                            if isStandbyEnabled && selectedStandbyType == "Standby" {
                                let standbyDuration = calculateStandbyDuration()
                                let thresholdHours = (hasInFlightRest && restFacilityType != .none) || hasSplitDuty ? 8.0 : 6.0
                                let totalAwakeTime = standbyDuration + calculateMaxFDP()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(.purple)
                                            .font(.caption)
                                        Text("Home Standby Rules Applied")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.purple)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Standby Duration: \(String(format: "%.1f", standbyDuration))h")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("Threshold: \(String(format: "%.1f", thresholdHours))h (\(hasInFlightRest && restFacilityType != .none ? "In-Flight Rest" : hasSplitDuty ? "Split Duty" : "Standard"))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        if standbyDuration > thresholdHours {
                                            let reduction = standbyDuration - thresholdHours
                                            Text("FDP Reduction: -\(String(format: "%.1f", reduction))h")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                                .fontWeight(.medium)
                                            
                                            // Show in-flight rest reduction if applicable
                                            if hasInFlightRest && restFacilityType != .none {
                                                let inFlightRestFDP = calculateInFlightRestExtension()
                                                let finalFDP = inFlightRestFDP - reduction
                                                Text("In-Flight Rest FDP: \(String(format: "%.1f", inFlightRestFDP))h - \(String(format: "%.1f", reduction))h = \(String(format: "%.1f", finalFDP))h")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    .fontWeight(.medium)
                                            }
                                        }
                                        
                                        Text("Total Awake Time: \(String(format: "%.1f", totalAwakeTime))h / 18h")
                                            .font(.caption)
                                            .foregroundColor(totalAwakeTime > 18.0 ? .red : .green)
                                            .fontWeight(.medium)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // In-Flight Rest Extension (if applicable)
                            if hasInFlightRest && restFacilityType != .none {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("In-Flight Rest FDP")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        
                                        Text("\(String(format: "%.1f", calculateInFlightRestExtension()))h")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Rest Facility")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "bed.double.fill")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                            Text(restFacilityType.rawValue)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // Total FDP
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Max FDP")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    let totalFDP = calculateTotalFDP()
                                    Text("\(String(format: "%.1f", totalFDP))h")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Sectors")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "number.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        Text(numberOfSectors == 1 ? "1-2" : "\(numberOfSectors)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Latest OFF/ON Blocks Time Section - Enhanced styling
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack {
                            Image(systemName: "clock.badge.plus")
                                .foregroundColor(.purple)
                                .font(.title2)
                            
                            Text("Latest OFF/ON Blocks Time")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            // Estimated Block Time Input
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "timer")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Estimated Block Time")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                Button(action: { showingBlockTimePicker = true }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            let hours = Int(estimatedBlockTime)
                                            let minutes = Int(round((estimatedBlockTime - Double(hours)) * 60))
                                            Text("Estimated: \(hours)h \(minutes)m")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Latest Off Blocks Time Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "airplane.departure")
                                        .foregroundColor(.purple)
                                        .font(.title3)
                                    Text("Latest Off Blocks Time")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.purple)
                                }
                                
                                // Without Commander's Discretion
                                let latestWithoutDiscretion = calculateLatestOffBlocksTime(withCommandersDiscretion: false)
                                Button(action: { showingWithoutDiscretionDetails = true }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Without Commander's Discretion")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                            
                                            Text(formatTimeForDisplay(latestWithoutDiscretion))
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Max FDP")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        
                                            Text("\(String(format: "%.1f", calculateTotalFDP()))h")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // With Commander's Discretion
                                let latestWithDiscretion = calculateLatestOffBlocksTime(withCommandersDiscretion: true)
                                Button(action: { showingWithDiscretionDetails = true }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("With Commander's Discretion")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                            
                                            Text(formatTimeForDisplay(latestWithDiscretion))
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Max FDP + Extension")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Text("\(String(format: "%.1f", calculateTotalFDP() + getCommandersDiscretionExtension()))h")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Latest ON Blocks Time Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "airplane.arrival")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                    Text("Latest ON Blocks Time")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                
                                // Without Commander's Discretion
                                let latestOnBlocksWithoutDiscretion = calculateLatestOnBlocksTime(withCommandersDiscretion: false)
                                Button(action: { showingOnBlocksDetails = true }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Without Commander's Discretion")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                            
                                            Text(formatTimeForDisplay(latestOnBlocksWithoutDiscretion))
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Max FDP")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        
                                            Text("\(String(format: "%.1f", calculateTotalDutyTime(withCommandersDiscretion: false)))h")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // With Commander's Discretion
                                let latestOnBlocksWithDiscretion = calculateLatestOnBlocksTime(withCommandersDiscretion: true)
                                Button(action: { showingOnBlocksDetails = true }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("With Commander's Discretion")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.secondary)
                                            
                                            Text(formatTimeForDisplay(latestOnBlocksWithDiscretion))
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Max FDP + Extension")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        
                                            Text("\(String(format: "%.1f", calculateTotalDutyTime(withCommandersDiscretion: true)))h")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingStandbyOptions) {
                standbyOptionsSheet
            }
            .sheet(isPresented: $showingLocationPicker) {
                locationPickerSheet
            }
            .sheet(isPresented: $showingDateTimePicker) {
                dateTimePickerSheet
            }
            .sheet(isPresented: $showingReportingLocationPicker) {
                reportingLocationPickerSheet
            }
            .sheet(isPresented: $showingReportingDateTimePicker) {
                reportingDateTimePickerSheet
            }
            .sheet(isPresented: $showingAcclimatisationPicker) {
                acclimatisationPickerSheet
            }
            .sheet(isPresented: $showingInFlightRestPicker) {
                inFlightRestPickerSheet
            }
            .sheet(isPresented: $showingBlockTimePicker) {
                blockTimePickerSheet
            }
            .sheet(isPresented: $showingWithDiscretionDetails) {
                withDiscretionDetailsSheet
            }
            .sheet(isPresented: $showingWithoutDiscretionDetails) {
                withoutDiscretionDetailsSheet
            }
            .sheet(isPresented: $showingOnBlocksDetails) {
                onBlocksDetailsSheet
            }
            .sheet(isPresented: $showingHomeBaseEditor) {
                homeBaseEditorSheet
            }
            .sheet(isPresented: $showingHomeBaseLocationPicker) {
                homeBaseLocationPickerSheet
            }
            .sheet(isPresented: $showingNightStandbyContactPopup) {
                nightStandbyContactPopupSheet
            }
            .onAppear {
                // DEBUG: Print initial reportingDateTime value
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                print("DEBUG: onAppear - initial reportingDateTime: \(formatter.string(from: reportingDateTime))")
                
                // Initialize selected hour and minute from current reportingDateTime (in UTC)
                var utcCalendar = Calendar.current
                utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
                let components = utcCalendar.dateComponents([.hour, .minute], from: reportingDateTime)
                selectedHour = components.hour ?? 12
                selectedMinute = components.minute ?? 20
                
                // Initialize selected hour and minute for block time picker
                let blockTimeHours = Int(estimatedBlockTime)
                let blockTimeMinutes = Int((estimatedBlockTime - Double(blockTimeHours)) * 60)
                selectedBlockTimeHour = blockTimeHours
                selectedBlockTimeMinute = blockTimeMinutes
                
                // Initialize selected hour and minute for standby time picker
                var xutcCalendar = Calendar.current
                utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
                let standbyComponents = utcCalendar.dateComponents([.hour, .minute], from: standbyStartDateTime)
                selectedStandbyHour = standbyComponents.hour ?? 9
                selectedStandbyMinute = standbyComponents.minute ?? 0
                
                // Initialize in-flight rest configuration
                if hasInFlightRest && restFacilityType == .none {
                    // If in-flight rest is enabled but no facility type is set, reset to defaults
                    hasInFlightRest = false
                    inFlightRestSectors = 1
                    isLongFlight = false
                    additionalCrewMembers = 1
                }
            }
        }
    }
    
        // MARK: - Standby Options Sheet
    private var standbyOptionsSheet: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Button("Close") {
                    showingStandbyOptions = false
                }
                .foregroundColor(.blue)
                .font(.title3)
                
                Spacer()
                
                Text("Standby / Reserve")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Apply") {
                    showingStandbyOptions = false
                    isStandbyEnabled = true
                    // The selectedStandbyType is already stored and will be used for calculations
                }
                .foregroundColor(.blue)
                .font(.title3)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Segmented Control Tabs
            HStack(spacing: 3) {
                standbyTab(title: "Standby", isSelected: selectedStandbyType == "Standby", action: { selectedStandbyType = "Standby" })
                standbyTab(title: "Airport Duty", isSelected: selectedStandbyType == "Airport Duty", action: { selectedStandbyType = "Airport Duty" })
                standbyTab(title: "Airport Stby", isSelected: selectedStandbyType == "Airport Standby", action: { selectedStandbyType = "Airport Standby" })
                standbyTab(title: "Reserve", isSelected: selectedStandbyType == "Reserve", action: { selectedStandbyType = "Reserve" })
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if selectedStandbyType == "Standby" {
                        standbyContent
                    } else if selectedStandbyType == "Airport Standby" {
                        airportStandbyContent
                    } else if selectedStandbyType == "Airport Duty" {
                        airportDutyContent
                    } else if selectedStandbyType == "Reserve" {
                        reserveContent
                    } else {
                        // Default content - show Standby
                        standbyContent
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func standbyTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Location Picker Sheet
    private var locationPickerSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        showingLocationPicker = false
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Select Airport")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Done") {
                        showingLocationPicker = false
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Search and Filter
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search airports...", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Airport List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(AirportsAndAirlines.airports.prefix(50)), id: \.0) { airport in
                            Button(action: {
                                // Check if we're editing home bases or selecting standby location
                                if showingHomeBaseEditor {
                                    // We're editing home bases - determine which one to update
                                    if editingHomeBase.isEmpty {
                                        editingHomeBase = airport.0
                                    } else if editingSecondHomeBase.isEmpty {
                                        editingSecondHomeBase = airport.0
                                    }
                                } else {
                                    // We're selecting standby location
                                    selectedStandbyLocation = airport.0
                                }
                                showingLocationPicker = false
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
                                    
                                    // Show checkmark for current selection
                                    let currentLocation = showingHomeBaseEditor ? 
                                        (editingHomeBase.isEmpty ? "" : editingHomeBase) : 
                                        (selectedStandbyLocation.isEmpty ? defaultStandbyLocation : selectedStandbyLocation)
                                    
                                    if currentLocation == airport.0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Reporting Location Picker Sheet
    private var reportingLocationPickerSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        showingReportingLocationPicker = false
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Select Reporting Location")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Done") {
                        showingReportingLocationPicker = false
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Search and Filter
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search airports...", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Airport List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(AirportsAndAirlines.airports.prefix(50)), id: \.0) { airport in
                            Button(action: {
                                selectedReportingLocation = airport.0
                                showingReportingLocationPicker = false
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
                                    
                                    if selectedReportingLocation == airport.0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Date/Time Picker Sheet
    private var dateTimePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Standby Start Date & Time")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    // Date picker
                    DatePicker(
                        "Standby Start Date",
                        selection: $standbyStartDateTime,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .onChange(of: standbyStartDateTime) { _, _ in
                        checkNightStandbyContact()
                    }
                    
                    // Custom time input for UTC
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter UTC Time (Zulu)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            // Hour picker
                            Picker("Hour", selection: $selectedStandbyHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: selectedStandbyHour) { _, newHour in
                                updateStandbyTimeFromCustomInput()
                                checkNightStandbyContact()
                            }
                            
                            Text(":")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            // Minute picker
                            Picker("Minute", selection: $selectedStandbyMinute) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                                                            .onChange(of: selectedStandbyMinute) { _, newMinute in
                                    updateStandbyTimeFromCustomInput()
                                    checkNightStandbyContact()
                                }
                            
                            Text("z")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Text("Time is entered in UTC (Zulu time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        showingDateTimePicker = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    
                    Button("Done") {
                        showingDateTimePicker = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .navigationTitle("Standby Start Time")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingDateTimePicker = false
            })
        }
    }
    
    // MARK: - Reporting Date/Time Picker Sheet
    private var reportingDateTimePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Reporting Date & Time")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    // Date picker
                    DatePicker(
                        "Reporting Date",
                        selection: $reportingDateTime,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    
                    // Custom time input for UTC
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter UTC Time (Zulu)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            // Hour picker
                            Picker("Hour", selection: $selectedHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: selectedHour) { _, newHour in
                                updateReportingTimeFromCustomInput()
                            }
                            
                            Text(":")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            // Minute picker
                            Picker("Minute", selection: $selectedMinute) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: selectedMinute) { _, newMinute in
                                updateReportingTimeFromCustomInput()
                            }
                            
                            Text("z")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Text("Time is entered in UTC (Zulu time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        showingReportingDateTimePicker = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    
                    Button("Done") {
                        showingReportingDateTimePicker = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .navigationTitle("Reporting Time")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingReportingDateTimePicker = false
            })
        }
    }
    
    // MARK: - Acclimatisation Picker Sheet
    private var acclimatisationPickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Acclimatisation Calculator")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 8) {
                    // Timezone Difference Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timezone Difference (hours)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Picker("Timezone Difference", selection: $timezoneDifference) {
                            ForEach(0...12, id: \.self) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                        
                        Text("The timezone difference between where you reported and where you are currently")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Elapsed Time Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Elapsed Time Since Reporting for First Sector")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Picker("Elapsed Time", selection: $elapsedTime) {
                            ForEach(0...168, id: \.self) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                        
                        Text("Elapsed time is the time from reporting at home base on the first sector, to report for the current duty")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Acclimatisation Result
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Acclimatisation Category")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        let acclimatisationResult = calculateAcclimatisation()
                        Text(acclimatisationResult)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(acclimatisationResult == "X" ? .red : (acclimatisationResult == "D" ? .orange : .green))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Text(getAcclimatisationDescription(for: acclimatisationResult))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Max FDP Display
                        let maxFDP = calculateMaxFDP()
                        Text("Max FDP: \(String(format: "%.1f", maxFDP))h")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(.top, 8)
                        
                        // Sectors Info
                        if numberOfSectors == 1 {
                            Text("Based on 1-2 sectors")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        } else {
                            Text("Based on \(numberOfSectors) sectors")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        showingAcclimatisationPicker = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    
                    Button("Apply") {
                        selectedAcclimatisation = calculateAcclimatisation()
                        showingAcclimatisationPicker = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .navigationTitle("Acclimatisation")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                selectedAcclimatisation = calculateAcclimatisation()
                showingAcclimatisationPicker = false
            })
        }
    }
    
    // MARK: - In-Flight Rest Picker Sheet
    private var inFlightRestPickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("In-Flight Rest Configuration")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Sector Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Number of Sectors")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Picker("Sectors", selection: $inFlightRestSectors) {
                                Text("1-2 sectors").tag(1)
                                Text("3 sectors").tag(3)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Text("Select the number of sectors for this duty")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Long Flight Option (only for 1-2 sectors)
                        if inFlightRestSectors == 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Long Flight Option")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Text("One sector with flight time greater than 9 hours")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $isLongFlight)
                                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                
                                Text("This option provides extended FDP limits for long flights")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Additional Crew Members
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Flight Crew Members")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Picker("Additional Crew", selection: $additionalCrewMembers) {
                                Text("1 additional crew").tag(1)
                                Text("2 additional crew").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Text("Number of additional crew members providing in-flight rest")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Rest Facility Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Rest Facility Class")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                // No In-Flight Rest Option
                                Button(action: {
                                    hasInFlightRest = false
                                    restFacilityType = .none
                                    // Re-enable split duty and extended FDP when in-flight rest is disabled
                                    // Note: We don't automatically turn them on, just re-enable the toggles
                                    // Reset to defaults when no rest is selected
                                    inFlightRestSectors = 1
                                    isLongFlight = false
                                    additionalCrewMembers = 1
                                    showingInFlightRestPicker = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("No In-Flight Rest")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Text("No dedicated rest facility available")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if !hasInFlightRest {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title2)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Class 1 Rest Facility
                                Button(action: {
                                    hasInFlightRest = true
                                    restFacilityType = .class1
                                    // Disable split duty and extended FDP when in-flight rest is enabled
                                    hasSplitDuty = false
                                    hasExtendedFDP = false
                                    // Preserve current configuration
                                    showingInFlightRestPicker = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Class 1 Rest Facility")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Text("Bunk or flat bed in a separate compartment")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if hasInFlightRest && restFacilityType == .class1 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title2)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Class 2 Rest Facility
                                Button(action: {
                                    hasInFlightRest = true
                                    restFacilityType = .class2
                                    // Disable split duty and extended FDP when in-flight rest is enabled
                                    hasSplitDuty = false
                                    hasExtendedFDP = false
                                    // Preserve current configuration
                                    showingInFlightRestPicker = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Class 2 Rest Facility")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Text("Reclining seat with leg support in a separate compartment")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if hasInFlightRest && restFacilityType == .class2 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title2)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Class 3 Rest Facility
                                Button(action: {
                                    hasInFlightRest = true
                                    restFacilityType = .class3
                                    // Disable split duty and extended FDP when in-flight rest is enabled
                                    hasSplitDuty = false
                                    hasExtendedFDP = false
                                    // Preserve current configuration
                                    showingInFlightRestPicker = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Class 3 Rest Facility")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Text("Reclining seat with leg support in the passenger cabin")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if hasInFlightRest && restFacilityType == .class3 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title2)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // FDP Extension Preview
                        if hasInFlightRest && restFacilityType != .none {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("FDP Extension Preview")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                let extensionHours = calculateInFlightRestExtension()
                                let baseFDP = calculateMaxFDP()
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Base FDP:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(String(format: "%.1f", baseFDP))h")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    HStack {
                                        Text("In-Flight Rest FDP:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(String(format: "%.1f", extensionHours))h")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Max FDP:")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Text("\(String(format: "%.1f", extensionHours))h")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sectors: \(inFlightRestSectors == 1 ? "1-2" : "3")")
                                    Text("Long Flight: \(isLongFlight ? "Yes" : "No")")
                                    Text("Additional Crew: \(additionalCrewMembers)")
                                    Text("Rest Facility: \(restFacilityType.rawValue)")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("In-Flight Rest")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingInFlightRestPicker = false
            })
        }
    }
    
    // MARK: - With Discretion Details Sheet
    private var withDiscretionDetailsSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("With Commander's Discretion Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Calculation Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Details:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            let baselineTime = getBaselineTimeForCalculations()
                            let baselineLabel = isStandbyEnabled && selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
                            Text("• \(baselineLabel): \(formatTimeForDisplay(baselineTime))")
                            if hasInFlightRest && restFacilityType != .none {
                                Text("• In-Flight Rest FDP: \(String(format: "%.1f", calculateInFlightRestExtension()))h")
                                Text("• Max FDP: \(String(format: "%.1f", calculateTotalFDP()))h (In-Flight Rest)")
                            } else {
                                Text("• Max FDP: \(String(format: "%.1f", calculateTotalFDP()))h")
                            }
                            Text("• Estimated Block Time: \(String(format: "%.1f", estimatedBlockTime))h")
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Calculation Steps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Steps:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        Text(formatCalculationBreakdown(withCommandersDiscretion: true))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Commander's Discretion Extension
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Commander's Discretion Extension:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        Text("+\(String(format: "%.1f", getCommandersDiscretionExtension()))h")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        if hasInFlightRest && restFacilityType != .none {
                            Text("With additional crew: +3 hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No additional crew: +2 hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Done") {
                    showingWithDiscretionDetails = false
                }
                .foregroundColor(.blue)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
            }
            .navigationTitle("With Commander's Discretion")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingWithDiscretionDetails = false
            })
        }
    }
    
    // MARK: - Without Discretion Details Sheet
    private var withoutDiscretionDetailsSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Without Commander's Discretion Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Calculation Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Details:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            let baselineTime = getBaselineTimeForCalculations()
                            let baselineLabel = isStandbyEnabled && selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
                            Text("• \(baselineLabel): \(formatTimeForDisplay(baselineTime))")
                            if hasInFlightRest && restFacilityType != .none {
                                Text("• Max FDP: \(String(format: "%.1f", calculateInFlightRestExtension()))h")
                                Text("• Max FDP: \(String(format: "%.1f", calculateTotalFDP()))h (In-Flight Rest)")
                            } else {
                                Text("• Max FDP: \(String(format: "%.1f", calculateTotalFDP()))h")
                            }
                            Text("• Estimated Block Time: \(String(format: "%.1f", estimatedBlockTime))h")
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Calculation Steps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Steps:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text(formatCalculationBreakdown(withCommandersDiscretion: false))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Max FDP Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximum FDP:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text("\(String(format: "%.1f", calculateTotalFDP()))h")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        if hasInFlightRest && restFacilityType != .none {
                            Text("In-Flight Rest FDP Limit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Standard FDP Limit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Done") {
                    showingWithoutDiscretionDetails = false
                }
                .foregroundColor(.blue)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
            }
            .navigationTitle("Without Commander's Discretion")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingWithoutDiscretionDetails = false
            })
        }
    }
    
    // MARK: - ON Blocks Details Sheet
    private var onBlocksDetailsSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Latest ON Blocks Time Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Calculation Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Details:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            let baselineTime = getBaselineTimeForCalculations()
                            let baselineLabel = isStandbyEnabled && selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
                            Text("• \(baselineLabel): \(formatTimeForDisplay(baselineTime))")
                            if hasInFlightRest && restFacilityType != .none {
                                Text("• In-Flight Rest FDP: \(String(format: "%.1f", calculateInFlightRestExtension()))h")
                                Text("• Max FDP: \(String(format: "%.1f", calculateTotalFDP()))h (In-Flight Rest)")
                            } else {
                                Text("• Max FDP: \(String(format: "%.1f", calculateTotalFDP()))h")
                            }
                            Text("• Estimated Block Time: \(String(format: "%.1f", estimatedBlockTime))h")
                            Text("• Total Duty Time: \(String(format: "%.1f", calculateTotalDutyTime()))h")
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Calculation Steps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Steps:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Without Commander's Discretion:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            let baselineTime = getBaselineTimeForCalculations()
                            let baselineLabel = isStandbyEnabled && selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
                            Text("\(formatTimeForDisplay(baselineTime))z (\(baselineLabel)) + \(String(format: "%.1f", calculateTotalDutyTime(withCommandersDiscretion: false)))h = \(formatTimeForDisplay(calculateLatestOnBlocksTime(withCommandersDiscretion: false)))z")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Text("With Commander's Discretion:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            Text("\(formatTimeForDisplay(baselineTime))z (\(baselineLabel)) + \(String(format: "%.1f", calculateTotalDutyTime(withCommandersDiscretion: true)))h = \(formatTimeForDisplay(calculateLatestOnBlocksTime(withCommandersDiscretion: true)))z")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Total Duty Time Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Duty Time:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Without Commander's Discretion:")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Spacer()
                                Text("\(String(format: "%.1f", calculateTotalDutyTime(withCommandersDiscretion: false)))h")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("With Commander's Discretion:")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                Spacer()
                                Text("\(String(format: "%.1f", calculateTotalDutyTime(withCommandersDiscretion: true)))h")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        let baselineLabel = isStandbyEnabled && selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
                        Text("Latest ON Blocks = \(baselineLabel) + Max FDP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Done") {
                    showingOnBlocksDetails = false
                }
                .foregroundColor(.blue)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
            }
            .navigationTitle("Latest ON Blocks Time")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingOnBlocksDetails = false
            })
        }
    }
    
    // MARK: - Block Time Picker Sheet
    private var blockTimePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Estimated Block Time")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    Text("Estimated block time from blocks off to blocks on")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 20) {
                        // Hours picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hours")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Picker("Hours", selection: $selectedBlockTimeHour) {
                                ForEach(0..<25, id: \.self) { hour in
                                    Text("\(hour)h").tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: selectedBlockTimeHour) { _, newHour in
                                updateEstimatedBlockTimeFromCustomInput()
                            }
                        }
                        
                        // Minutes picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Minutes")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Picker("Minutes", selection: $selectedBlockTimeMinute) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text("\(minute)m").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: selectedBlockTimeMinute) { _, newMinute in
                                updateEstimatedBlockTimeFromCustomInput()
                            }
                        }
                    }
                    
                    // Preview of calculation
                    if estimatedBlockTime > 0 {
                        VStack(spacing: 8) {
                            Text("Calculation Preview:")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            
                            let latestWithDiscretion = calculateLatestOffBlocksTime(withCommandersDiscretion: true)
                            let latestWithoutDiscretion = calculateLatestOffBlocksTime(withCommandersDiscretion: false)
                            
                            VStack(spacing: 4) {
                                                                    HStack {
                                        Text("With Commander's Discretion:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(formatTimeForDisplay(latestWithDiscretion))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.orange)
                                    }
                                
                                                                    HStack {
                                        Text("Without Commander's Discretion:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(formatTimeForDisplay(latestWithoutDiscretion))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        showingBlockTimePicker = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    
                    Button("Done") {
                        showingBlockTimePicker = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .navigationTitle("Estimated Block Time")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingBlockTimePicker = false
            })
        }
    }
    
    // MARK: - Content Views
    private var standbyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Home Standby")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Rectangle()
                .fill(Color.blue)
                .frame(height: 3)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("• Home standby (other than at the airport)")
                Text("• Maximum duration 16 hours")
                Text("• Total time awake (standby + Duty) should not exceed 18 hours")
                Text("• Ends at designated reporting point")
            }
            .font(.title3)
            .foregroundColor(.primary)
            
            Text("FDP Calculation Rules:")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("• If reporting within first 6 hours of home standby, FDP starts at report time")
                Text("• If reporting after first 6 hours of home standby, max FDP is reduced by the amount of time exceeding 6 hours")
                Text("• In-flight rest or split duty increases these times to 8 hours")
                Text("• If standby starts between 23:00 and 07:00, the time does not reduce FDP until crew is contacted")
            }
            .font(.title3)
            .foregroundColor(.primary)
        }
    }
    
    private var airportStandbyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Airport Standby")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Rectangle()
                .fill(Color.orange)
                .frame(height: 3)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("• Accommodation away from the airport is provided by the operator")
                Text("• Maximum duration 16 hours (airport standby + FDP) unless split duty or in-flight rest")
                Text("• Counts in full towards daily and weekly duty limits and rest requirements")
                Text("• FDP calculation: maximum FDP is reduced by the amount of airport standby exceeding 4 hours")
            }
            .font(.title3)
            .foregroundColor(.primary)
            
            Text("FDP Calculation Rules:")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("• Airport standby counts towards duty limits and rest requirements")
                Text("• FDP begins at the reporting time for assigned duty")
                Text("• Maximum FDP is reduced by airport standby exceeding 4 hours")
                Text("• Split duty or in-flight rest may extend the 16-hour limit")
            }
            .font(.title3)
            .foregroundColor(.primary)
        }
    }
    
    private var airportDutyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Duties at the Airport")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Rectangle()
                .fill(Color.green)
                .frame(height: 3)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("• Accommodation is not provided (accommodation means somewhere away from the airport, if you are on standby in the airport then it is an airport duty)")
                Text("• Any airport duty counts towards FDP and rest requirements")
                Text("• FDP starts from reporting for airport duty")
                Text("• Max FDP is not reduced by airport duty (unlike home standby when it exceeds 6 hours)")
            }
            .font(.title3)
            .foregroundColor(.primary)
            
            Text("FDP Calculation Rules:")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("• Airport duty counts in full as a duty period")
                Text("• FDP begins at the reporting time for airport duty")
                Text("• Maximum FDP is not reduced by prior airport duty")
                Text("• Airport duty contributes to daily and weekly duty limits")
            }
            .font(.title3)
            .foregroundColor(.primary)
        }
    }
    
    private var reserveContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Reserve")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Rectangle()
                .fill(Color.purple)
                .frame(height: 3)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("• Reserve is a period that a crew member must be available to receive an assignment for a duty, they need to be given at least 10 hours notice for the duty")
                Text("• There must be a period of at least 8 hours for rest (aka sleep)")
                Text("• The 10 hour advanced notification may include the protected 8 hours sleep time")
                Text("• Reserve does not count towards daily and weekly limits or rest requirements")
                Text("• FDP starts from the report time of a duty that has been assigned on reserve")
            }
            .font(.title3)
            .foregroundColor(.primary)
            
            Text("FDP Calculation Rules:")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("• Reserve time does not count towards duty limits or rest requirements")
                Text("• FDP begins only when a duty is assigned and reporting time is set")
                Text("• The 10-hour notice period includes protected 8-hour sleep time")
                Text("• No FDP reduction due to reserve time (unlike standby)")
            }
            .font(.title3)
            .foregroundColor(.primary)
        }
    }
    
    // MARK: - Custom Time Input Helper Functions
    private func updateReportingTimeFromCustomInput() {
        // Get the current date from reportingDateTime
        let currentDate = reportingDateTime
        
        // Create a calendar with UTC timezone
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Get the current date components in UTC
        let utcComponents = utcCalendar.dateComponents([.year, .month, .day], from: currentDate)
        
        // Create new components with the selected hour and minute (treating them as UTC)
        var newComponents = DateComponents()
        newComponents.year = utcComponents.year
        newComponents.month = utcComponents.month
        newComponents.day = utcComponents.day
        newComponents.hour = selectedHour
        newComponents.minute = selectedMinute
        newComponents.second = 0
        
        // Create the date directly in UTC (this is what the user actually selected as UTC time)
        if let utcDate = utcCalendar.date(from: newComponents) {
            // Set the reporting time to the UTC date
            reportingDateTime = utcDate
            
            // DEBUG: Log the time change
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(abbreviation: "UTC")!
            formatter.dateFormat = "HH:mm"
            print("DEBUG: Custom time input - set UTC time to: \(formatter.string(from: utcDate))")
        }
    }
    
    private func logReportingTimeDisplay() {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("DEBUG: UI displaying reporting time: \(formatter.string(from: reportingDateTime))")
    }
    
    private func updateEstimatedBlockTimeFromCustomInput() {
        // Convert hours and minutes to decimal hours
        let totalHours = Double(selectedBlockTimeHour) + (Double(selectedBlockTimeMinute) / 60.0)
        estimatedBlockTime = totalHours
        
        // DEBUG: Log the time change
        print("DEBUG: Custom block time input - set to: \(selectedBlockTimeHour)h \(selectedBlockTimeMinute)m (\(String(format: "%.2f", totalHours))h)")
    }
    
    private func updateStandbyTimeFromCustomInput() {
        // Get the current date from standbyStartDateTime
        let currentDate = standbyStartDateTime
        
        // Create a calendar with UTC timezone
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Get the current date components in UTC
        let utcComponents = utcCalendar.dateComponents([.year, .month, .day], from: currentDate)
        
        // Create new components with the selected hour and minute (treating them as UTC)
        var newComponents = DateComponents()
        newComponents.year = utcComponents.year
        newComponents.month = utcComponents.month
        newComponents.day = utcComponents.day
        newComponents.hour = selectedStandbyHour
        newComponents.minute = selectedStandbyMinute
        newComponents.second = 0
        
        // Create the date directly in UTC (this is what the user actually selected as UTC time)
        if let utcDate = utcCalendar.date(from: newComponents) {
            // Set the standby start time to the UTC date
            standbyStartDateTime = utcDate
            
            // DEBUG: Log the time change
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(abbreviation: "UTC")!
            formatter.dateFormat = "HH:mm"
            print("DEBUG: Custom standby time input - set UTC time to: \(formatter.string(from: utcDate))")
        }
    }
    
    private func updateContactTimeFromCustomInput() {
        // Update the contact time based on selected hour and minute
        // This is stored as local time to home base
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        formatter.dateFormat = "HH:mm"
        
        print("DEBUG: Contact time input - set local time to: \(String(format: "%02d:%02d", selectedContactHour, selectedContactMinute))")
    }
    
    private func formatTimeAsUTC(_ date: Date) -> String {
        // Always format the time as if it were UTC, regardless of how it's stored
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date) + "z"
    }
    
    // MARK: - Home Base Editor Sheet
    private var homeBaseEditorSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Home Bases")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 24) {
                    // Primary Home Base Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Primary Home Base")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        Button(action: { 
                            editingHomeBaseType = "primary"
                            showingHomeBaseLocationPicker = true 
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(editingHomeBase.isEmpty ? "Select Primary Home Base" : editingHomeBase)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(editingHomeBase.isEmpty ? .secondary : .primary)
                                    
                                    if !editingHomeBase.isEmpty, let airport = AirportsAndAirlines.airports.first(where: { $0.0 == editingHomeBase }) {
                                        Text(airport.1)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                                            // Secondary Home Base Selection
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "house.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                Text("Secondary Home Base (Optional)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            Button(action: { 
                                editingHomeBaseType = "secondary"
                                showingHomeBaseLocationPicker = true 
                            }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(editingSecondHomeBase.isEmpty ? "Select Secondary Home Base" : editingSecondHomeBase)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(editingSecondHomeBase.isEmpty ? .secondary : .primary)
                                    
                                    if !editingSecondHomeBase.isEmpty, let airport = AirportsAndAirlines.airports.first(where: { $0.0 == editingSecondHomeBase }) {
                                        Text(airport.1)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Clear secondary home base button
                        if !editingSecondHomeBase.isEmpty {
                            Button(action: {
                                editingSecondHomeBase = ""
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text("Clear Secondary Home Base")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Help text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("• Your primary home base is used for acclimatisation calculations")
                        Text("• Secondary home base is optional and can be used for multi-base operations")
                        Text("• Both bases are assumed to be in UTC +1 timezone")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 20) {
                    Button("Cancel") {
                        showingHomeBaseEditor = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    
                    Button("Save Changes") {
                        // Update the home bases
                        homeBase = editingHomeBase
                        secondHomeBase = editingSecondHomeBase
                        showingHomeBaseEditor = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .disabled(editingHomeBase.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Edit Home Bases")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                // Update the home bases
                homeBase = editingHomeBase
                secondHomeBase = editingSecondHomeBase
                showingHomeBaseEditor = false
            })
        }
    }
    
    // MARK: - Home Base Location Picker Sheet
    private var homeBaseLocationPickerSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        showingHomeBaseLocationPicker = false
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Select \(editingHomeBaseType == "primary" ? "Primary" : "Secondary") Home Base")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Done") {
                        showingHomeBaseLocationPicker = false
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Search and Filter
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search airports...", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Airport List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(AirportsAndAirlines.airports.prefix(50)), id: \.0) { airport in
                            Button(action: {
                                // Update the appropriate home base based on type
                                if editingHomeBaseType == "primary" {
                                    editingHomeBase = airport.0
                                } else if editingHomeBaseType == "secondary" {
                                    editingSecondHomeBase = airport.0
                                }
                                showingHomeBaseLocationPicker = false
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
                                    
                                    // Show checkmark for current selection
                                    let currentLocation = editingHomeBaseType == "primary" ? editingHomeBase : editingSecondHomeBase
                                    
                                    if currentLocation == airport.0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Night Standby Contact Popup Sheet
    private var nightStandbyContactPopupSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Night Standby Contact")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    Text("Your standby starts between 23:00-07:00 local time to your home base.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Were you contacted before 07:00 local time?")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    // Contact toggle
                    HStack {
                        Text("Contacted before 07:00")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $wasContactedBefore0700)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Contact time input (only show if contacted)
                    if wasContactedBefore0700 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What time were you contacted? (Local time)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 20) {
                                // Hour picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Hour")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Picker("Hour", selection: $selectedContactHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(String(format: "%02d", hour)).tag(hour)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(width: 80, height: 120)
                                    .onChange(of: selectedContactHour) { _, newHour in
                                        updateContactTimeFromCustomInput()
                                    }
                                }
                                
                                // Minute picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Minute")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Picker("Minute", selection: $selectedContactMinute) {
                                        ForEach(0..<60, id: \.self) { minute in
                                            Text(String(format: "%02d", minute)).tag(minute)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(width: 80, height: 120)
                                    .onChange(of: selectedContactMinute) { _, newMinute in
                                        updateContactTimeFromCustomInput()
                                    }
                                }
                            }
                            
                            Text("Enter the local time when you were contacted")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        showingNightStandbyContactPopup = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    
                    Button("Done") {
                        showingNightStandbyContactPopup = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                }
                .padding()
            }
            .navigationTitle("Night Standby Contact")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingNightStandbyContactPopup = false
            })
        }
    }
}

#Preview {
    ManualCalcView()
}
