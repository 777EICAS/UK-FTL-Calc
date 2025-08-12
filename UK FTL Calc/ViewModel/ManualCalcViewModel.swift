//
//  ManualCalcViewModel.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

@MainActor
class ManualCalcViewModel: ObservableObject {
    // MARK: - App Storage
    @AppStorage("homeBase") var homeBase: String = "LHR"
    @AppStorage("secondHomeBase") var secondHomeBase: String = ""
    
    // MARK: - Standby/Reserve State
    @Published var showingStandbyOptions = false
    @Published var selectedStandbyType: String = "Standby"
    @Published var isStandbyEnabled = false
    @Published var showingLocationPicker = false
    @Published var selectedStandbyLocation: String = ""
    @Published var showingDateTimePicker = false
    @Published var standbyStartDateTime = Date()
    @Published var showingReportingLocationPicker = false
    @Published var selectedReportingLocation: String = ""
    @Published var showingReportingDateTimePicker = false
    @Published var reportingDateTime: Date = Date()
    
    // MARK: - Acclimatisation State
    @Published var showingAcclimatisationPicker = false
    @Published var selectedAcclimatisation: String = ""
    @Published var timezoneDifference: Int = 0
    @Published var elapsedTime: Int = 0
    
    // MARK: - Sectors and FDP Extensions State
    @Published var numberOfSectors: Int = 1
    @Published var hasInFlightRest: Bool = false
    @Published var restFacilityType: RestFacilityType = .none
    @Published var hasSplitDuty: Bool = false
    @Published var hasExtendedFDP: Bool = false
    @Published var showingInFlightRestPicker = false
    @Published var inFlightRestSectors: Int = 1 // 1 = 1-2 sectors, 3 = 3 sectors
    @Published var isLongFlight: Bool = false // Only applicable for 1-2 sectors
    @Published var additionalCrewMembers: Int = 1 // 1 or 2 additional crew
    
    // MARK: - Block Time State
    @Published var estimatedBlockTime: Double = 0.0 // Estimated flight time in hours
    @Published var showingBlockTimePicker = false
    @Published var selectedHour: Int = 12 // Track selected hour for reporting time input
    @Published var selectedMinute: Int = 20 // Track selected minute for reporting time input
    @Published var selectedBlockTimeHour: Int = 0 // Track selected hour for block time input
    @Published var selectedBlockTimeMinute: Int = 0 // Track selected minute for block time input
    @Published var selectedStandbyHour: Int = 9 // Track selected hour for standby time input
    @Published var selectedStandbyMinute: Int = 0 // Track selected minute for standby time input
    
    // MARK: - Details Sheets State
    @Published var showingWithDiscretionDetails = false
    @Published var showingWithoutDiscretionDetails = false
    @Published var showingOnBlocksDetails = false
    
    // MARK: - Home Base Editor State
    @Published var showingHomeBaseEditor = false
    @Published var editingHomeBase: String = ""
    @Published var editingSecondHomeBase: String = ""
    @Published var showingHomeBaseLocationPicker = false
    @Published var editingHomeBaseType: String = "" // "primary" or "secondary"
    
    // MARK: - Night Standby Contact State
    @Published var showingNightStandbyContactPopup = false
    @Published var wasContactedBefore0700 = false
    @Published var contactTimeLocal = Date()
    @Published var selectedContactHour: Int = 7
    @Published var selectedContactMinute: Int = 0
    
    // MARK: - Computed Properties
    var defaultReportingLocation: String {
        return homeBase
    }
    
    var defaultStandbyLocation: String {
        return homeBase
    }
    
    // MARK: - Date and Time Formatters
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        return formatter
    }()
    
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    let utcTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    // MARK: - Initialization
    init() {
        // Initialize in-flight rest configuration
        if hasInFlightRest && restFacilityType == .none {
            hasInFlightRest = false
            inFlightRestSectors = 1
            isLongFlight = false
            additionalCrewMembers = 1
        }
    }
    
    // MARK: - Standby Duration Calculation
    func calculateStandbyDuration() -> Double {
        let duration = reportingDateTime.timeIntervalSince(standbyStartDateTime)
        return duration / 3600.0 // Convert seconds to hours
    }
    
    func checkTotalAwakeTimeLimit() -> Bool {
        let standbyDuration = calculateStandbyDuration()
        let maxFDP = calculateMaxFDP()
        let totalAwakeTime = standbyDuration + maxFDP
        return totalAwakeTime <= 18.0
    }
    
    func checkNightStandbyContact() {
        if isStandbyEnabled && selectedStandbyType == "Standby" {
            let standbyStartLocal = TimeUtilities.getLocalTime(for: utcTimeFormatter.string(from: standbyStartDateTime), airportCode: homeBase)
            let standbyStartHour = Int(standbyStartLocal.prefix(2)) ?? 0
            
            if (standbyStartHour >= 23 || standbyStartHour < 7) {
                showingNightStandbyContactPopup = true
            }
        }
    }
    
    // MARK: - Acclimatisation Calculation Functions
    func calculateAcclimatisation() -> String {
        let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
        
        let acclimatisationStatus = UKCAALimits.determineAcclimatisationStatus(
            timeZoneDifference: timezoneDifference,
            elapsedTimeHours: Double(elapsedTime),
            isFirstSector: false,
            homeBase: homeBase,
            departure: currentDeparture
        )
        
        if acclimatisationStatus.reason.contains("Result B") {
            return "B"
        } else if acclimatisationStatus.reason.contains("Result D") {
            return "D"
        } else {
            return "X"
        }
    }
    
    func getAcclimatisationDescription(for category: String) -> String {
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
    
    // MARK: - FDP Calculation Functions
    func calculateMaxFDP() -> Double {
        let acclimatisationResult = calculateAcclimatisation()
        
        let baseFDP: Double
        switch acclimatisationResult {
        case "B", "D":
            let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
            let timeString = utcTimeFormatter.string(from: reportingDateTime)
            
            let localTime = TimeUtilities.getLocalTime(for: timeString, airportCode: currentDeparture)
            let sectorsForLookup = numberOfSectors == 1 ? 2 : numberOfSectors
            baseFDP = RegulatoryTableLookup.lookupFDPAcclimatised(reportTime: localTime, sectors: sectorsForLookup)
            
        case "X":
            let result = RegulatoryTableLookup.lookupFDPUnknownAcclimatised(sectors: numberOfSectors)
            baseFDP = result
            
        default:
            baseFDP = 9.0
        }
        
        // Apply Home Standby rules if applicable
        if isStandbyEnabled && selectedStandbyType == "Standby" {
            let standbyDuration = calculateStandbyDuration()
            let thresholdHours = (hasInFlightRest && restFacilityType != .none) || hasSplitDuty ? 8.0 : 6.0
            
            if standbyDuration > thresholdHours {
                let reduction = standbyDuration - thresholdHours
                let reducedFDP = baseFDP - reduction
                let minimumFDP = 9.0
                let finalFDP = max(reducedFDP, minimumFDP)
                return finalFDP
            }
        }
        
        return baseFDP
    }
    
    func calculateInFlightRestExtension() -> Double {
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
        
        return RegulatoryTableLookup.lookupInflightRestExtension(
            restClass: restClass,
            additionalCrew: additionalCrewMembers,
            isLongFlight: isLongFlight
        )
    }
    
    func calculateTotalFDP() -> Double {
        let baseFDP = calculateMaxFDP()
        
        if hasInFlightRest && restFacilityType != .none {
            let inFlightRestFDP = calculateInFlightRestExtension()
            
            if isStandbyEnabled && selectedStandbyType == "Standby" {
                let standbyDuration = calculateStandbyDuration()
                let thresholdHours = 8.0
                
                if standbyDuration > thresholdHours {
                    let reduction = standbyDuration - thresholdHours
                    let finalFDP = inFlightRestFDP - reduction
                    let minimumFDP = 9.0
                    let result = max(finalFDP, minimumFDP)
                    return result
                }
            }
            
            return inFlightRestFDP
        } else {
            return baseFDP
        }
    }
    
    // MARK: - Latest Off/On Blocks Time Calculations
    func calculateLatestOffBlocksTime(withCommandersDiscretion: Bool) -> Date {
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        
        let baselineTime = getBaselineTimeForCalculations()
        let timeWithFDP = baselineTime.addingTimeInterval(totalFDP * 3600)
        let latestOffBlocks = timeWithFDP.addingTimeInterval(-estimatedBlockTime * 3600)
        
        return latestOffBlocks
    }
    
    func calculateLatestOnBlocksTime(withCommandersDiscretion: Bool = false) -> Date {
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        
        let baselineTime = getBaselineTimeForCalculations()
        return baselineTime.addingTimeInterval(totalFDP * 3600)
    }
    
    func calculateTotalDutyTime(withCommandersDiscretion: Bool = false) -> Double {
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        return totalFDP
    }
    
    // MARK: - Helper Functions
    func getCommandersDiscretionExtension() -> Double {
        if hasInFlightRest && restFacilityType != .none {
            return 3.0
        } else {
            return 2.0
        }
    }
    
    func getBaselineTimeForCalculations() -> Date {
        if isStandbyEnabled && selectedStandbyType == "Airport Duty" {
            return standbyStartDateTime
        } else {
            return reportingDateTime
        }
    }
    
    // MARK: - Time Update Functions
    func updateReportingTimeFromCustomInput() {
        let currentDate = reportingDateTime
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        let utcComponents = utcCalendar.dateComponents([.year, .month, .day], from: currentDate)
        var newComponents = DateComponents()
        newComponents.year = utcComponents.year
        newComponents.month = utcComponents.month
        newComponents.day = utcComponents.day
        newComponents.hour = selectedHour
        newComponents.minute = selectedMinute
        newComponents.second = 0
        
        if let utcDate = utcCalendar.date(from: newComponents) {
            reportingDateTime = utcDate
        }
    }
    
    func updateEstimatedBlockTimeFromCustomInput() {
        let totalHours = Double(selectedBlockTimeHour) + (Double(selectedBlockTimeMinute) / 60.0)
        estimatedBlockTime = totalHours
    }
    
    func updateStandbyTimeFromCustomInput() {
        let currentDate = standbyStartDateTime
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        let utcComponents = utcCalendar.dateComponents([.year, .month, .day], from: currentDate)
        var newComponents = DateComponents()
        newComponents.year = utcComponents.year
        newComponents.month = utcComponents.month
        newComponents.day = utcComponents.day
        newComponents.hour = selectedStandbyHour
        newComponents.minute = selectedStandbyMinute
        newComponents.second = 0
        
        if let utcDate = utcCalendar.date(from: newComponents) {
            standbyStartDateTime = utcDate
        }
    }
    
    func updateContactTimeFromCustomInput() {
        // Update the contact time based on selected hour and minute
        // This is stored as local time to home base
    }
    
    // MARK: - Formatting Functions
    func formatTimeForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        let reportingDate = utcCalendar.startOfDay(for: reportingDateTime)
        let offBlocksDate = utcCalendar.startOfDay(for: date)
        
        if utcCalendar.isDate(offBlocksDate, inSameDayAs: reportingDate) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date) + "z"
        } else {
            formatter.dateFormat = "dd MMM HH:mm"
            return formatter.string(from: date) + "z"
        }
    }
    
    func formatCalculationBreakdown(withCommandersDiscretion: Bool) -> String {
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "HH:mm"
        
        let baselineTime = getBaselineTimeForCalculations()
        let timeWithFDP = baselineTime.addingTimeInterval(totalFDP * 3600)
        let timeString = formatter.string(from: timeWithFDP)
        
        let baselineTimeString = formatter.string(from: baselineTime)
        let baselineLabel = isStandbyEnabled && selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
        
        return "\(baselineTimeString)z (\(baselineLabel)) + \(String(format: "%.1f", totalFDP))h = \(timeString)z - \(String(format: "%.1f", estimatedBlockTime))h"
    }
    
    func formatTimeAsUTC(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date) + "z"
    }
}

