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
    @AppStorage("homeBase") var homeBase: String = "LHR" {
        didSet { 
            clearCache()
            homeBaseChanged = true
            currentHomeBase = homeBase
        }
    }
    @AppStorage("secondHomeBase") var secondHomeBase: String = "" {
        didSet { 
            clearCache()
            homeBaseChanged = true
            currentSecondHomeBase = secondHomeBase
        }
    }
    
    // MARK: - Home Base Change Tracking
    @Published var homeBaseChanged = false
    @Published var currentHomeBase: String = "LHR"
    @Published var currentSecondHomeBase: String = ""
    
    // MARK: - Standby/Reserve State
    @Published var showingStandbyOptions = false
    @Published var selectedStandbyType: String = "Standby" {
        didSet { clearCache() }
    }
    @Published var isStandbyEnabled = false {
        didSet { clearCache() }
    }
    @Published var standbyContactTime: String = "" // Contact time for night standby
    @Published var showingLocationPicker = false
    @Published var selectedStandbyLocation: String = ""
    @Published var showingDateTimePicker = false
    @Published var standbyStartDateTime = Date() {
        didSet {
            print("DEBUG: standbyStartDateTime changed to: \(standbyStartDateTime)")
            print("DEBUG: standbyStartDateTime - Call stack:")
            Thread.callStackSymbols.forEach { print("DEBUG: standbyStartDateTime -   \($0)") }
            clearCache()
        }
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
            print("DEBUG: cachedStandbyDuration - Returning from calculation results: \(results.standbyDuration)h")
            return results.standbyDuration
        }
        print("DEBUG: cachedStandbyDuration - No calculation results, returning 0.0")
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
    
    // Method to reset standby-related fields
    func resetStandbyFields() {
        standbyContactTime = ""
        clearCache()
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
        // Read directly from UserDefaults for initialization
        let storedHomeBase = UserDefaults.standard.string(forKey: "homeBase") ?? "LHR"
        let storedSecondHomeBase = UserDefaults.standard.string(forKey: "secondHomeBase") ?? ""
        
        // Initialize in-flight rest configuration
        if hasInFlightRest && restFacilityType == .none {
            hasInFlightRest = false
            inFlightRestSectors = 1
            isLongFlight = false
            additionalCrewMembers = 1
        }
        
        // Initialize editing values with current home base values
        editingHomeBase = storedHomeBase
        editingSecondHomeBase = storedSecondHomeBase
        
        // Initialize @Published properties
        currentHomeBase = storedHomeBase
        currentSecondHomeBase = storedSecondHomeBase
        
        // Ensure @Published properties are in sync with UserDefaults
        refreshPublishedHomeBases()
    }
}