//
//  ManualCalcViewModel.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

@MainActor
class ManualCalcViewModel: ObservableObject {
    // MARK: - Debug Configuration
    private let enableDebugOutput = false // Set to false to disable debug output
    
    // MARK: - App Storage
    @AppStorage("homeBase") var homeBase: String = "LHR" {
        didSet { clearCache() }
    }
    @AppStorage("secondHomeBase") var secondHomeBase: String = "" {
        didSet { clearCache() }
    }
    
    // MARK: - Standby/Reserve State
    @Published var showingStandbyOptions = false
    @Published var selectedStandbyType: String = "Standby" {
        didSet { clearCache() }
    }
    @Published var isStandbyEnabled = false {
        didSet { clearCache() }
    }
    @Published var showingLocationPicker = false
    @Published var selectedStandbyLocation: String = ""
    @Published var showingDateTimePicker = false
    @Published var standbyStartDateTime = Date() {
        didSet { clearCache() }
    }
    @Published var airportDutyStartDateTime = Date() { // NEW: Separate field for airport duty start time
        didSet { clearCache() }
    }
    @Published var showingAirportDutyDateTimePicker = false // NEW: Control airport duty date time picker sheet
    @Published var showingReportingLocationPicker = false
    @Published var selectedReportingLocation: String = ""
    @Published var showingReportingDateTimePicker = false
    @Published var reportingDateTime: Date = Date() {
        didSet { clearCache() }
    }
    
    // MARK: - Acclimatisation State
    @Published var showingAcclimatisationPicker = false
    @Published var selectedAcclimatisation: String = "" {
        didSet { clearCache() }
    }
    @Published var timezoneDifference: Int = 0 {
        didSet { clearCache() }
    }
    @Published var elapsedTime: Int = 0 {
        didSet { clearCache() }
    }
    
    // MARK: - Sectors and FDP Extensions State
    @Published var numberOfSectors: Int = 1 {
        didSet { clearCache() }
    }
    @Published var hasInFlightRest: Bool = false {
        didSet { clearCache() }
    }
    @Published var restFacilityType: RestFacilityType = .none {
        didSet { clearCache() }
    }
    @Published var hasSplitDuty: Bool = false {
        didSet { clearCache() }
    }
    
    // MARK: - Split Duty Configuration State
    @Published var showingSplitDutyOptions = false
    @Published var splitDutyAccommodationType: String = "Accommodation" { // "Accommodation" or "Suitable Accomm"
        didSet { clearCache() }
    }
    @Published var splitDutyBreakDuration: Double = 3.0 { // Break duration in hours
        didSet { clearCache() }
    }
    @Published var splitDutyBreakBegin: Date = Date() { // Break begin time
        didSet { clearCache() }
    }
    @Published var selectedBreakDurationHour: Int = 3 // Track selected hour for break duration input
    @Published var selectedBreakDurationMinute: Int = 0 // Track selected minute for break duration input
    @Published var selectedBreakBeginHour: Int = 14 // Track selected hour for break begin time input
    @Published var selectedBreakBeginMinute: Int = 0 // Track selected minute for break begin time input
    @Published var showingBreakDurationPicker = false
    @Published var showingBreakBeginPicker = false
    
    // MARK: - Extended FDP State
    @Published var hasExtendedFDP: Bool = false {
        didSet { clearCache() }
    }
    @Published var showingInFlightRestPicker = false
    @Published var inFlightRestSectors: Int = 1 { // 1 = 1-2 sectors, 3 = 3 sectors
        didSet { clearCache() }
    }
    @Published var isLongFlight: Bool = false { // Only applicable for 1-2 sectors
        didSet { clearCache() }
    }
    @Published var additionalCrewMembers: Int = 1 { // 1 or 2 additional crew
        didSet { clearCache() }
    }
    
    // MARK: - Block Time State
    @Published var estimatedBlockTime: Double = 0.0 { // Estimated flight time in hours
        didSet { clearCache() }
    }
    @Published var showingBlockTimePicker = false
    @Published var selectedHour: Int = 12 { // Track selected hour for reporting time input
        didSet { clearCache() }
    }
    @Published var selectedMinute: Int = 20 { // Track selected minute for reporting time input
        didSet { clearCache() }
    }
    @Published var selectedBlockTimeHour: Int = 0 { // Track selected hour for block time input
        didSet { clearCache() }
    }
    @Published var selectedBlockTimeMinute: Int = 0 { // Track selected minute for block time input
        didSet { clearCache() }
    }
    @Published var selectedStandbyHour: Int = 9 { // Track selected hour for standby time input
        didSet { clearCache() }
    }
    @Published var selectedStandbyMinute: Int = 0 { // Track selected minute for standby time input
        didSet { clearCache() }
    }
    @Published var selectedAirportDutyHour: Int = 9 { // NEW: Track selected hour for airport duty start time input
        didSet { clearCache() }
    }
    @Published var selectedAirportDutyMinute: Int = 0 { // NEW: Track selected minute for airport duty start time input
        didSet { clearCache() }
    }
    
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
    @Published var contactTimeLocal = Date() {
        didSet { clearCache() }
    }
    @Published var selectedContactHour: Int = 7 {
        didSet { clearCache() }
    }
    @Published var selectedContactMinute: Int = 0 {
        didSet { clearCache() }
    }
    
    // MARK: - Calculation Button State
    @Published var calculationResults: FTLCalculationResults?
    @Published var isCalculating = false
    @Published var hasCalculated = false
    
    // MARK: - Computed Properties
    var defaultReportingLocation: String {
        return homeBase
    }
    
    var defaultStandbyLocation: String {
        return homeBase
    }
    
    // Computed properties that use stored results
    var cachedMaxFDP: Double {
        if let results = calculationResults {
            return results.maxFDP
        }
        return 0.0 // Return 0 if no calculation has been performed
    }
    
    var cachedTotalFDP: Double {
        if let results = calculationResults {
            return results.totalFDP
        }
        return 0.0 // Return 0 if no calculation has been performed
    }
    
    var cachedInFlightRestExtension: Double {
        if let results = calculationResults {
            return results.inFlightRestExtension
        }
        return 0.0 // Return 0 if no calculation has been performed
    }
    
    var cachedStandbyDuration: Double {
        if let results = calculationResults {
            return results.standbyDuration
        }
        return 0.0 // Return 0 if no calculation has been performed
    }
    
    var cachedAcclimatisation: String {
        if let results = calculationResults {
            return results.acclimatisation
        }
        return "" // Return empty string if no calculation has been performed
    }
    
    var cachedSplitDutyExtension: Double {
        if let results = calculationResults {
            return results.splitDutyExtension
        }
        return 0.0 // Return 0 if no calculation has been performed
    }
    
    // Method to clear cache when values change
    func clearCache() {
        calculationResults = nil
        hasCalculated = false
    }
    
    // Method to apply split duty settings and force calculation update
    func applySplitDutySettings() {
        print("DEBUG: applySplitDutySettings - Starting")
        print("DEBUG: applySplitDutySettings - Current values:")
        print("DEBUG: applySplitDutySettings - hasSplitDuty: \(hasSplitDuty)")
        print("DEBUG: applySplitDutySettings - splitDutyAccommodationType: '\(splitDutyAccommodationType)'")
        print("DEBUG: applySplitDutySettings - splitDutyBreakDuration: \(splitDutyBreakDuration)")
        print("DEBUG: applySplitDutySettings - splitDutyBreakBegin: \(splitDutyBreakBegin)")
        print("DEBUG: applySplitDutySettings - selectedBreakDurationHour: \(selectedBreakDurationHour)")
        print("DEBUG: applySplitDutySettings - selectedBreakDurationMinute: \(selectedBreakDurationMinute)")
        print("DEBUG: applySplitDutySettings - selectedBreakBeginHour: \(selectedBreakBeginHour)")
        print("DEBUG: applySplitDutySettings - selectedBreakBeginMinute: \(selectedBreakBeginMinute)")
        
        // Update the actual split duty properties from the selected values
        updateBreakDurationFromCustomInput()
        updateBreakBeginTimeFromCustomInput()
        
        print("DEBUG: applySplitDutySettings - After updating properties:")
        print("DEBUG: applySplitDutySettings - splitDutyBreakDuration: \(splitDutyBreakDuration)")
        print("DEBUG: applySplitDutySettings - splitDutyBreakBegin: \(splitDutyBreakBegin)")
        
        clearCache()
        // Force UI update by triggering objectWillChange
        objectWillChange.send()
        
        print("DEBUG: applySplitDutySettings - Cache cleared and UI update triggered")
    }
    
    // Effective standby start time - for airport duty, this is the same as airport duty start time
    // For airport standby, this is the same as standby start time
    var effectiveStandbyStartTime: Date {
        switch selectedStandbyType {
        case "Airport Duty":
            return airportDutyStartDateTime
        case "Airport Standby":
            return standbyStartDateTime
        case "Standby":
            return standbyStartDateTime
        case "Reserve":
            return standbyStartDateTime
        default:
            return standbyStartDateTime
        }
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
        if isStandbyEnabled && (selectedStandbyType == "Standby" || selectedStandbyType == "Airport Standby") {
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
        
        print("DEBUG: calculateAcclimatisation - Current departure: \(currentDeparture)")
        print("DEBUG: calculateAcclimatisation - Home base: \(homeBase)")
        print("DEBUG: calculateAcclimatisation - Timezone difference: \(timezoneDifference)h")
        print("DEBUG: calculateAcclimatisation - Elapsed time: \(elapsedTime)h")
        
        let acclimatisationStatus = UKCAALimits.determineAcclimatisationStatus(
            timeZoneDifference: timezoneDifference,
            elapsedTimeHours: Double(elapsedTime),
            isFirstSector: false,
            homeBase: homeBase,
            departure: currentDeparture
        )
        
        print("DEBUG: calculateAcclimatisation - UKCAALimits result: \(acclimatisationStatus.reason)")
        
        if acclimatisationStatus.reason.contains("Result B") {
            print("DEBUG: calculateAcclimatisation - Returning Result B")
            return "B"
        } else if acclimatisationStatus.reason.contains("Result D") {
            print("DEBUG: calculateAcclimatisation - Returning Result D")
            return "D"
        } else {
            print("DEBUG: calculateAcclimatisation - Returning Result X")
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
        print("=== DEBUG: calculateMaxFDP START ===")
        print("DEBUG: calculateMaxFDP - Current state:")
        print("  - Home base: \(homeBase)")
        print("  - Selected reporting location: \(selectedReportingLocation)")
        print("  - Number of sectors: \(numberOfSectors)")
        print("  - Reporting date time: \(reportingDateTime)")
        print("  - Standby enabled: \(isStandbyEnabled)")
        print("  - Standby type: \(selectedStandbyType)")
        print("  - Timezone difference: \(timezoneDifference)")
        print("  - Elapsed time: \(elapsedTime)")
        print("  - Has in-flight rest: \(hasInFlightRest)")
        print("  - Has split duty: \(hasSplitDuty)")
        print("  - Has extended FDP: \(hasExtendedFDP)")
        print("=====================================")
        
        let acclimatisationResult = calculateAcclimatisation()
        
        print("DEBUG: calculateMaxFDP - Acclimatisation result: \(acclimatisationResult)")
        
        let baseFDP: Double
        switch acclimatisationResult {
        case "B", "D":
            let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
            
            print("DEBUG: calculateMaxFDP - Using acclimatised crew calculation (Result: \(acclimatisationResult))")
            print("DEBUG: calculateMaxFDP - Current departure: \(currentDeparture)")
            print("DEBUG: calculateMaxFDP - Home base: \(homeBase)")
            
            // Use the appropriate baseline time based on standby type
            let referenceDateTime: Date
            if isStandbyEnabled {
                switch selectedStandbyType {
                case "Airport Duty":
                    referenceDateTime = airportDutyStartDateTime
                case "Airport Standby":
                    referenceDateTime = reportingDateTime // Airport standby: FDP starts from report time
                case "Standby":
                    referenceDateTime = reportingDateTime // Home standby: FDP starts from report time
                case "Reserve":
                    referenceDateTime = reportingDateTime // Reserve: FDP starts from report time
                default:
                    referenceDateTime = reportingDateTime
                }
            } else {
                referenceDateTime = reportingDateTime
            }
            
            print("DEBUG: calculateMaxFDP - Reference date time: \(referenceDateTime)")
            
            let timeString = utcTimeFormatter.string(from: referenceDateTime)
            print("DEBUG: calculateMaxFDP - UTC time string: \(timeString)")
            
            let localTime = TimeUtilities.getLocalTime(for: timeString, airportCode: currentDeparture)
            print("DEBUG: calculateMaxFDP - Local time at \(currentDeparture): \(localTime)")
            
            let sectorsForLookup = numberOfSectors == 1 ? 2 : numberOfSectors
            print("DEBUG: calculateMaxFDP - Sectors for lookup: \(sectorsForLookup) (original: \(numberOfSectors))")
            
            baseFDP = RegulatoryTableLookup.lookupFDPAcclimatised(reportTime: localTime, sectors: sectorsForLookup)
            print("DEBUG: calculateMaxFDP - Base FDP from Table 2: \(baseFDP)h")
            
        case "X":
            print("DEBUG: calculateMaxFDP - Using unknown acclimatisation calculation (Result: \(acclimatisationResult))")
            print("DEBUG: calculateMaxFDP - Sectors: \(numberOfSectors)")
            
            let result = RegulatoryTableLookup.lookupFDPUnknownAcclimatised(sectors: numberOfSectors)
            baseFDP = result
            print("DEBUG: calculateMaxFDP - Base FDP from Table 3: \(baseFDP)h")
            
        default:
            print("DEBUG: calculateMaxFDP - Unknown acclimatisation result: \(acclimatisationResult), using default")
            baseFDP = 9.0
        }
        
        print("DEBUG: calculateMaxFDP - Final base FDP: \(baseFDP)h")
        
        // Apply split duty extension if enabled
        var finalFDP = baseFDP
        if hasSplitDuty {
            let splitDutyExtension = calculateSplitDutyExtension()
            finalFDP = baseFDP + splitDutyExtension
            print("DEBUG: calculateMaxFDP - Split duty extension: +\(splitDutyExtension)h")
            print("DEBUG: calculateMaxFDP - Final FDP with split duty: \(finalFDP)h")
        }
        
        // Return final FDP (base + split duty extension if applicable)
        // Standby reduction will be applied in calculateTotalFDP()
        return finalFDP
    }
    
    // Helper method to get base FDP without extensions (for breakdown display)
    func getBaseFDP() -> Double {
        let acclimatisationResult = calculateAcclimatisation()
        
        let baseFDP: Double
        switch acclimatisationResult {
        case "B", "D":
            let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
            
            // Use the appropriate baseline time based on standby type
            let referenceDateTime: Date
            if isStandbyEnabled {
                switch selectedStandbyType {
                case "Airport Duty":
                    referenceDateTime = airportDutyStartDateTime
                case "Airport Standby":
                    referenceDateTime = reportingDateTime
                case "Standby":
                    referenceDateTime = reportingDateTime
                case "Reserve":
                    referenceDateTime = reportingDateTime
                default:
                    referenceDateTime = reportingDateTime
                }
            } else {
                referenceDateTime = reportingDateTime
            }
            
            let timeString = utcTimeFormatter.string(from: referenceDateTime)
            let localTime = TimeUtilities.getLocalTime(for: timeString, airportCode: currentDeparture)
            let sectorsForLookup = numberOfSectors == 1 ? 2 : numberOfSectors
            
            baseFDP = RegulatoryTableLookup.lookupFDPAcclimatised(reportTime: localTime, sectors: sectorsForLookup)
            
        case "X":
            baseFDP = RegulatoryTableLookup.lookupFDPUnknownAcclimatised(sectors: numberOfSectors)
            
        default:
            baseFDP = 9.0
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
    
    func calculateSplitDutyExtension() -> Double {
        guard hasSplitDuty else { 
            print("DEBUG: calculateSplitDutyExtension - hasSplitDuty is false, returning 0.0")
            return 0.0 
        }
        
        print("DEBUG: calculateSplitDutyExtension - hasSplitDuty is true")
        print("DEBUG: calculateSplitDutyExtension - splitDutyBreakDuration: \(splitDutyBreakDuration)")
        print("DEBUG: calculateSplitDutyExtension - splitDutyAccommodationType: '\(splitDutyAccommodationType)'")
        print("DEBUG: calculateSplitDutyExtension - splitDutyBreakBegin: \(splitDutyBreakBegin)")
        
        // Base extension: 50% of break duration
        let baseExtension = splitDutyBreakDuration * 0.5
        print("DEBUG: calculateSplitDutyExtension - baseExtension: \(baseExtension)")
        
        if splitDutyAccommodationType == "Suitable Accomm" {
            // Suitable accommodation: full 50% extension
            print("DEBUG: calculateSplitDutyExtension - Using Suitable Accomm, returning: \(baseExtension)")
            return baseExtension
        } else {
            // Accommodation: apply restrictions
            var effectiveBreakTime = splitDutyBreakDuration
            
            // 6-hour rule: any time over 6 hours doesn't count
            if effectiveBreakTime > 6.0 {
                effectiveBreakTime = 6.0
            }
            
            // WOCL encroachment check (02:00-05:59 local time where user is acclimatised)
            let woclReduction = calculateWOCLEncroachment()
            effectiveBreakTime = max(0.0, effectiveBreakTime - woclReduction)
            
            let finalExtension = effectiveBreakTime * 0.5
            print("DEBUG: calculateSplitDutyExtension - Using Accommodation, effectiveBreakTime: \(effectiveBreakTime), woclReduction: \(woclReduction), finalExtension: \(finalExtension)")
            
            // Return 50% of effective break time
            return finalExtension
        }
    }
    
    private func calculateWOCLEncroachment() -> Double {
        guard splitDutyAccommodationType == "Accommodation" else { return 0.0 }
        
        // Get the local time at the user's acclimatised location
        let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
        let breakBeginTimeString = utcTimeFormatter.string(from: splitDutyBreakBegin)
        let localBreakBeginTime = TimeUtilities.getLocalTime(for: breakBeginTimeString, airportCode: currentDeparture)
        
        // Parse local time to get hour
        let hourString = String(localBreakBeginTime.prefix(2))
        let breakBeginHour = Int(hourString) ?? 0
        
        // Calculate break end time
        let breakEndHour = (breakBeginHour + Int(splitDutyBreakDuration)) % 24
        
        var woclEncroachment = 0.0
        
        // Check if break starts before WOCL (02:00-05:59)
        if breakBeginHour < 2 {
            // Break starts before WOCL, calculate encroachment
            let encroachmentStart = 2
            let encroachmentEnd = min(6, breakEndHour)
            if encroachmentEnd > encroachmentStart {
                woclEncroachment += Double(encroachmentEnd - encroachmentStart)
            }
        } else if breakBeginHour < 6 {
            // Break starts during WOCL
            let encroachmentStart = breakBeginHour
            let encroachmentEnd = min(6, breakEndHour)
            if encroachmentEnd > encroachmentStart {
                woclEncroachment += Double(encroachmentEnd - encroachmentStart)
            }
        }
        
        // Check if break extends past WOCL into next day
        if breakEndHour > breakBeginHour && breakEndHour > 6 {
            // Break extends past WOCL, check if it goes into next day's WOCL
            let nextDayWOCLStart = 2
            let nextDayWOCLEnd = min(6, breakEndHour)
            if nextDayWOCLEnd > nextDayWOCLStart {
                woclEncroachment += Double(nextDayWOCLEnd - nextDayWOCLStart)
            }
        }
        
        return woclEncroachment
    }
    
    func getSplitDutyExtensionDetails() -> (extension: Double, explanation: String) {
        guard hasSplitDuty else { return (0.0, "Split duty not enabled") }
        
        let baseExtension = splitDutyBreakDuration * 0.5
        let woclReduction = calculateWOCLEncroachment()
        
        if splitDutyAccommodationType == "Suitable Accomm" {
            return (baseExtension, "Suitable accommodation: full 50% extension (\(String(format: "%.1f", baseExtension))h)")
        } else {
            var effectiveBreakTime = splitDutyBreakDuration
            var explanation = "Accommodation: "
            
            // 6-hour rule
            if effectiveBreakTime > 6.0 {
                let overLimit = effectiveBreakTime - 6.0
                explanation += "6h limit applied (exceeded by \(String(format: "%.1f", overLimit))h). "
                effectiveBreakTime = 6.0
            }
            
            // WOCL encroachment
            if woclReduction > 0 {
                explanation += "WOCL encroachment: \(String(format: "%.1f", woclReduction))h excluded. "
            }
            
            let finalExtension = effectiveBreakTime * 0.5
            explanation += "Final extension: \(String(format: "%.1f", finalExtension))h (50% of \(String(format: "%.1f", effectiveBreakTime))h effective break time)"
            
            return (finalExtension, explanation)
        }
    }
    
    func calculateTotalFDP() -> Double {
        let baseFDP = calculateMaxFDP()
        
        // Apply in-flight rest extension if applicable
        var adjustedFDP = baseFDP
        if hasInFlightRest && restFacilityType != .none {
            let inFlightRestFDP = calculateInFlightRestExtension()
            adjustedFDP = inFlightRestFDP
        }
        
        // Split duty extension is now included in calculateMaxFDP()
        // No need to add it again here
        
        // Apply standby reduction if applicable
        if isStandbyEnabled {
            if selectedStandbyType == "Standby" {
                // Home Standby: FDP starts from report time, reduced by standby exceeding 6-8 hours
                let standbyDuration = calculateStandbyDuration()
                let thresholdHours = (hasInFlightRest && restFacilityType != .none) || hasSplitDuty ? 8.0 : 6.0
                
                if standbyDuration > thresholdHours {
                    let reduction = standbyDuration - thresholdHours
                    adjustedFDP = adjustedFDP - reduction
                }
                
            } else if selectedStandbyType == "Airport Standby" {
                // Airport Standby: FDP starts from report time, reduced by standby exceeding 4 hours
                let standbyDuration = calculateStandbyDuration()
                let thresholdHours = 4.0 // Airport standby threshold is always 4 hours
                
                if standbyDuration > thresholdHours {
                    let reduction = standbyDuration - thresholdHours
                    adjustedFDP = adjustedFDP - reduction
                }
                
            } else if selectedStandbyType == "Airport Duty" {
                // Airport Duty: No FDP reduction, all time counts towards duty
            } else if selectedStandbyType == "Reserve" {
                // Reserve: No FDP reduction, doesn't count towards duty
            }
        }
        
        // Apply minimum FDP limit after all adjustments
        // For home standby and airport standby cases, allow FDP to go below 9.0h as per UK CAA rules
        let minimumFDP = 9.0
        let isStandbyReduction = isStandbyEnabled && 
            ((selectedStandbyType == "Standby" && calculateStandbyDuration() > ((hasInFlightRest && restFacilityType != .none) || hasSplitDuty ? 8.0 : 6.0)) ||
             (selectedStandbyType == "Airport Standby" && calculateStandbyDuration() > 4.0))
        
        if adjustedFDP < minimumFDP && !isStandbyReduction {
            adjustedFDP = minimumFDP
        }
        
        // Check 16-hour total duty time rule for airport standby
        if isStandbyEnabled && selectedStandbyType == "Airport Standby" {
            let standbyDuration = calculateStandbyDuration()
            let totalDutyTime = standbyDuration + adjustedFDP
            let maxAllowedDutyTime = (hasInFlightRest && restFacilityType != .none) || hasSplitDuty ? 18.0 : 16.0
            
            if totalDutyTime > maxAllowedDutyTime {
                // TODO: Add user-facing warning for 16-hour rule violation
            }
        }
        
        return adjustedFDP
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
        let baselineTime: Date
        
        if isStandbyEnabled {
            switch selectedStandbyType {
            case "Airport Duty":
                baselineTime = airportDutyStartDateTime // Use airport duty start time for FDP calculations
            case "Airport Standby":
                baselineTime = reportingDateTime // Airport standby: FDP starts from report time
            case "Standby":
                baselineTime = reportingDateTime // Home standby: FDP starts from report time
            case "Reserve":
                baselineTime = reportingDateTime // Reserve: FDP starts from report time
            default:
                baselineTime = reportingDateTime
            }
        } else {
            baselineTime = reportingDateTime
        }
        
        return baselineTime
    }
    
    // MARK: - Time Update Functions
    func updateReportingTimeFromCustomInput() {
        // Get the currently selected date from the date picker
        let selectedDate = reportingDateTime
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Extract date components from the selected date
        let dateComponents = utcCalendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Create new date with selected date and time components
        var newComponents = DateComponents()
        newComponents.year = dateComponents.year
        newComponents.month = dateComponents.month
        newComponents.day = dateComponents.day
        newComponents.hour = selectedHour
        newComponents.minute = selectedMinute
        newComponents.second = 0
        
        if let utcDate = utcCalendar.date(from: newComponents) {
            reportingDateTime = utcDate
            clearCache() // Clear cache when reporting time changes
        }
    }
    
    func updateEstimatedBlockTimeFromCustomInput() {
        let totalHours = Double(selectedBlockTimeHour) + (Double(selectedBlockTimeMinute) / 60.0)
        estimatedBlockTime = totalHours
        clearCache() // Clear cache when block time changes
    }
    
    func updateStandbyTimeFromCustomInput() {
        // Get the currently selected date from the date picker
        let selectedDate = standbyStartDateTime
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Extract date components from the selected date
        let dateComponents = utcCalendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Create new date with selected date and time components
        var newComponents = DateComponents()
        newComponents.year = dateComponents.year
        newComponents.month = dateComponents.month
        newComponents.day = dateComponents.day
        newComponents.hour = selectedStandbyHour
        newComponents.minute = selectedStandbyMinute
        newComponents.second = 0
        
        if let utcDate = utcCalendar.date(from: newComponents) {
            standbyStartDateTime = utcDate
            clearCache() // Clear cache when standby time changes
        }
    }
    
    func updateAirportDutyTimeFromCustomInput() {
        // Get the currently selected date from the date picker
        let selectedDate = airportDutyStartDateTime
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Extract date components from the selected date
        let dateComponents = utcCalendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Create new date with selected date and time components
        var newComponents = DateComponents()
        newComponents.year = dateComponents.year
        newComponents.month = dateComponents.month
        newComponents.day = dateComponents.day
        newComponents.hour = selectedAirportDutyHour
        newComponents.minute = selectedAirportDutyMinute
        newComponents.second = 0
        
        if let utcDate = utcCalendar.date(from: newComponents) {
            airportDutyStartDateTime = utcDate
            clearCache() // Clear cache when airport duty time changes
        }
    }
    
    // Synchronize times when standby type changes
    func synchronizeStandbyTimes() {
        switch selectedStandbyType {
        case "Airport Duty":
            // For airport duty, synchronize with standby start time
            airportDutyStartDateTime = standbyStartDateTime
            selectedAirportDutyHour = selectedStandbyHour
            selectedAirportDutyMinute = selectedStandbyMinute
        case "Airport Standby":
            // For airport standby, no synchronization needed - uses standby start time directly
            break
        case "Standby":
            // For home standby, no synchronization needed - uses standby start time directly
            break
        case "Reserve":
            // For reserve, no synchronization needed - uses standby start time directly
            break
        default:
            break
        }
        clearCache() // Clear cache when times are synchronized
    }
    
    func updateContactTimeFromCustomInput() {
        // Update the contact time based on selected hour and minute
        // This is stored as local time to home base
    }
    
    // MARK: - Split Duty Time Update Functions
    func updateBreakDurationFromCustomInput() {
        let totalHours = Double(selectedBreakDurationHour) + (Double(selectedBreakDurationMinute) / 60.0)
        splitDutyBreakDuration = totalHours
        clearCache() // Clear cache when break duration changes
    }
    
    func updateBreakBeginTimeFromCustomInput() {
        // Get the currently selected date from the date picker
        let selectedDate = splitDutyBreakBegin
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Extract date components from the selected date
        let dateComponents = utcCalendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Create new date with selected date and time components
        var newComponents = DateComponents()
        newComponents.year = dateComponents.year
        newComponents.month = dateComponents.month
        newComponents.day = dateComponents.day
        newComponents.hour = selectedBreakBeginHour
        newComponents.minute = selectedBreakBeginMinute
        newComponents.second = 0
        
        if let utcDate = utcCalendar.date(from: newComponents) {
            splitDutyBreakBegin = utcDate
            clearCache() // Clear cache when break begin time changes
        }
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
        let baselineLabel: String
        if isStandbyEnabled {
            switch selectedStandbyType {
            case "Airport Duty":
                baselineLabel = "Airport Duty Start"
            case "Airport Standby":
                baselineLabel = "Standby Start"
            case "Standby":
                baselineLabel = "Reporting Time"
            case "Reserve":
                baselineLabel = "Reporting Time"
            default:
                baselineLabel = "Reporting Time"
            }
        } else {
            baselineLabel = "Reporting Time"
        }
        
        return "\(baselineTimeString)z (\(baselineLabel)) + \(String(format: "%.1f", totalFDP))h = \(timeString)z - \(String(format: "%.1f", estimatedBlockTime))h"
    }
    
    func formatTimeAsUTC(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date) + "z"
    }
    
    // MARK: - Calculate Button Method
    func performCalculation() {
        isCalculating = true
        hasCalculated = true
        
        // Run all calculations once using existing logic
        let maxFDP = calculateMaxFDP()
        let totalFDP = calculateTotalFDP()
        let inFlightRestExtension = calculateInFlightRestExtension()
        let splitDutyExtension = calculateSplitDutyExtension()
        let standbyDuration = calculateStandbyDuration()
        let acclimatisation = calculateAcclimatisation()
        let latestOffBlocksTime = calculateLatestOffBlocksTime(withCommandersDiscretion: false)
        let latestOnBlocksTime = calculateLatestOnBlocksTime(withCommandersDiscretion: false)
        let totalDutyTime = calculateTotalDutyTime(withCommandersDiscretion: false)
        let calculationBreakdown = formatCalculationBreakdown(withCommandersDiscretion: false)
        
        // Store results
        calculationResults = FTLCalculationResults(
            maxFDP: maxFDP,
            totalFDP: totalFDP,
            inFlightRestExtension: inFlightRestExtension,
            splitDutyExtension: splitDutyExtension,
            standbyDuration: standbyDuration,
            acclimatisation: acclimatisation,
            latestOffBlocksTime: latestOffBlocksTime,
            latestOnBlocksTime: latestOnBlocksTime,
            totalDutyTime: totalDutyTime,
            calculationBreakdown: calculationBreakdown
        )
        
        isCalculating = false
    }
}

// MARK: - FTL Calculation Results
struct FTLCalculationResults {
    let maxFDP: Double
    let totalFDP: Double
    let inFlightRestExtension: Double
    let splitDutyExtension: Double
    let standbyDuration: Double
    let acclimatisation: String
    let latestOffBlocksTime: Date
    let latestOnBlocksTime: Date
    let totalDutyTime: Double
    let calculationBreakdown: String
}

