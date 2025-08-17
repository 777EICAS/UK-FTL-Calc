//
//  RegulatoryTables.swift
//  UK FTL Calc
//
//  Created based on UK CAA EASA FTL Regulations
//

import Foundation

// MARK: - Home Standby FDP Result

struct HomeStandbyFDPResult {
    let standbyDuration: Double
    let threshold: Double
    let fdpReduction: Double
    let explanation: String
}

// MARK: - Acclimatisation Table Structures

struct AcclimatisationEntry {
    let timeDifferenceHours: String
    let elapsedTime: [String]
    let acclimatisationState: [String]
}

struct AcclimatisationTable {
    let entries: [AcclimatisationEntry]
    
    static let data = [
        AcclimatisationEntry(
            timeDifferenceHours: "<4",
            elapsedTime: ["<48", "48-71:59", "72-95:59", "96-119:59", ">=120"],
            acclimatisationState: ["B", "D", "D", "D", "D"]
        ),
        AcclimatisationEntry(
            timeDifferenceHours: "4-6",
            elapsedTime: ["<48", "48-71:59", "72-95:59", "96-119:59", ">=120"],
            acclimatisationState: ["B", "X", "D", "D", "D"]
        ),
        AcclimatisationEntry(
            timeDifferenceHours: "6-9",
            elapsedTime: ["<48", "48-71:59", "72-95:59", "96-119:59", ">=120"],
            acclimatisationState: ["B", "X", "X", "D", "D"]
        ),
        AcclimatisationEntry(
            timeDifferenceHours: "9-12",
            elapsedTime: ["<48", "48-71:59", "72-95:59", "96-119:59", ">=120"],
            acclimatisationState: ["B", "X", "X", "X", "D"]
        )
    ]
}

// MARK: - FDP Tables Structures

struct FDPAcclimatisedEntry {
    let startTimeRange: String
    let sectors: [Double]
}

struct FDPAcclimatisedTable {
    let entries: [FDPAcclimatisedEntry]
    
    static let data = [
        FDPAcclimatisedEntry(startTimeRange: "0500-0514", sectors: [12.0, 11.5, 11.0, 10.5, 10.0, 9.5, 9.0, 9.0, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "0515-0529", sectors: [12.25, 11.75, 11.25, 10.75, 10.25, 9.75, 9.25, 9.0, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "0530-0544", sectors: [12.5, 12.0, 11.5, 11.0, 10.5, 10.0, 9.5, 9.0, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "0545-0559", sectors: [12.75, 12.25, 11.75, 11.25, 10.75, 10.25, 9.75, 9.25, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "0600-1329", sectors: [13.0, 12.5, 12.0, 11.5, 11.0, 10.5, 10.0, 9.5, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "1330-1359", sectors: [12.75, 12.25, 11.75, 11.25, 10.75, 10.25, 9.75, 9.25, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "1400-1429", sectors: [12.5, 12.0, 11.5, 11.0, 10.5, 10.0, 9.5, 9.0, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "1430-1459", sectors: [12.25, 11.75, 11.25, 10.75, 10.25, 9.75, 9.25, 9.0, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "1500-1529", sectors: [12.0, 11.5, 11.0, 10.5, 10.0, 9.5, 9.0, 9.0, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "1530-1559", sectors: [11.75, 11.25, 10.75, 10.25, 9.75, 9.25, 9.0, 9.0, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "1600-1629", sectors: [11.5, 11.0, 10.5, 10.0, 9.5, 9.0, 9.0, 9.0, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "1630-1659", sectors: [11.25, 10.75, 10.25, 9.75, 9.25, 9.0, 9.0, 9.0, 9.0]),
        FDPAcclimatisedEntry(startTimeRange: "1700-0459", sectors: [11.0, 10.5, 10.0, 9.5, 9.0, 9.0, 9.0, 9.0, 9.0])
    ]
}

struct FDPUnknownAcclimatisationTable {
    let sectors: [Double]
    
    // Correct UK CAA Table 3 (Unknown Acclimatisation) data
    // Index 0 = 1-2 sectors → 11h 0m
    // Index 1 = 3 sectors → 10h 30m  
    // Index 2 = 4 sectors → 10h 0m
    // Index 3 = 5 sectors → 09h 30m
    // Index 4 = 6 sectors → 09h 0m
    // Index 5 = 7 sectors → 09h 00m
    // Index 6 = 8 sectors → 09h 00m
    // 9+ sectors = Not allowed for unknown acclimatisation
    static let data = [11.0, 10.5, 10.0, 9.5, 9.0, 9.0, 9.0]
}

struct FDPRosteredExtensionEntry {
    let startTimeRange: String
    let sectors: [Double?]
}

struct FDPRosteredExtensionTable {
    let entries: [FDPRosteredExtensionEntry]
    
    static let data = [
        FDPRosteredExtensionEntry(startTimeRange: "0615-0629", sectors: [13.25, 12.75, 12.25, 11.75]),
        FDPRosteredExtensionEntry(startTimeRange: "0630-0644", sectors: [13.5, 13, 12.5, 12]),
        FDPRosteredExtensionEntry(startTimeRange: "0645-0659", sectors: [13.75, 13.25, 12.75, 12.25]),
        FDPRosteredExtensionEntry(startTimeRange: "0700-1329", sectors: [14, 13.5, 13, 12.5]),
        FDPRosteredExtensionEntry(startTimeRange: "1330-1359", sectors: [13.75, 13.25, 12.75, nil]),
        FDPRosteredExtensionEntry(startTimeRange: "1400-1429", sectors: [13.5, 13, 12.5, nil])
    ]
}

// MARK: - Extended FDP Table Structures

struct ExtendedFDPEntry {
    let startTimeRange: String
    let sectors: [Double?] // Using Double? to handle "Not allowed" cases
}

struct ExtendedFDPTable {
    let entries: [ExtendedFDPEntry]
    
    // Table 4: Maximum Daily FDP with Extension
    // Based on British Airways OM A Table 4
    static let data = [
        ExtendedFDPEntry(startTimeRange: "0600-0614", sectors: [nil, nil, nil, nil, nil]), // Not allowed for all sectors
        ExtendedFDPEntry(startTimeRange: "0615-0629", sectors: [13.25, 12.75, 12.25, 11.75, nil]), // 1-2: 13:15, 3: 12:45, 4: 12:15, 5: 11:45
        ExtendedFDPEntry(startTimeRange: "0630-0644", sectors: [13.5, 13.0, 12.5, 12.0, nil]), // 1-2: 13:30, 3: 13:00, 4: 12:30, 5: 12:00
        ExtendedFDPEntry(startTimeRange: "0645-0659", sectors: [13.75, 13.25, 12.75, 12.25, nil]), // 1-2: 13:45, 3: 13:15, 4: 12:45, 5: 12:15
        ExtendedFDPEntry(startTimeRange: "0700-1329", sectors: [14.0, 13.5, 13.0, 12.5, nil]), // 1-2: 14:00, 3: 13:30, 4: 13:00, 5: 12:30
        ExtendedFDPEntry(startTimeRange: "1330-1359", sectors: [13.75, 13.25, 12.75, 12.25, nil]), // 1-2: 13:45, 3: 13:15, 4: 12:45, 5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1400-1429", sectors: [13.5, 13.0, 12.5, 12.0, nil]), // 1-2: 13:30, 3: 13:00, 4: 12:30, 5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1430-1459", sectors: [13.25, 12.75, 12.25, 11.75, nil]), // 1-2: 13:15, 3: 12:45, 4: 12:15, 5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1500-1529", sectors: [13.0, 12.5, 12.0, 11.5, nil]), // 1-2: 13:00, 3: 12:30, 4: 12:00, 5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1530-1559", sectors: [12.75, 12.25, nil, nil, nil]), // 1-2: 12:45, 3: Not allowed, 4-5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1600-1629", sectors: [12.5, 12.0, nil, nil, nil]), // 1-2: 12:30, 3: Not allowed, 4-5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1630-1659", sectors: [12.25, 11.75, nil, nil, nil]), // 1-2: 12:15, 3: Not allowed, 4-5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1700-1729", sectors: [12.0, nil, nil, nil, nil]), // 1-2: 12:00, 3-5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1730-1759", sectors: [11.75, nil, nil, nil, nil]), // 1-2: 11:45, 3-5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1800-1829", sectors: [11.5, nil, nil, nil, nil]), // 1-2: 11:30, 3-5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1830-1859", sectors: [11.25, nil, nil, nil, nil]), // 1-2: 11:15, 3-5: Not allowed
        ExtendedFDPEntry(startTimeRange: "1900-0359", sectors: [nil, nil, nil, nil, nil]), // Not allowed for all sectors
        ExtendedFDPEntry(startTimeRange: "0400-0414", sectors: [nil, nil, nil, nil, nil]), // Not allowed for all sectors
        ExtendedFDPEntry(startTimeRange: "0415-0429", sectors: [nil, nil, nil, nil, nil]), // Not allowed for all sectors
        ExtendedFDPEntry(startTimeRange: "0430-0444", sectors: [nil, nil, nil, nil, nil]), // Not allowed for all sectors
        ExtendedFDPEntry(startTimeRange: "0445-0459", sectors: [nil, nil, nil, nil, nil]), // Not allowed for all sectors
        ExtendedFDPEntry(startTimeRange: "0500-0514", sectors: [nil, nil, nil, nil, nil]), // Not allowed for all sectors
        ExtendedFDPEntry(startTimeRange: "0515-0529", sectors: [nil, nil, nil, nil, nil]), // Not allowed for all sectors
        ExtendedFDPEntry(startTimeRange: "0530-0544", sectors: [nil, nil, nil, nil, nil]), // Not allowed for all sectors
        ExtendedFDPEntry(startTimeRange: "0545-0559", sectors: [nil, nil, nil, nil, nil]) // Not allowed for all sectors
    ]
}

// MARK: - In-Flight Rest FDP Extensions

struct InflightRestExtensions {
    let oneAdditionalCrew: [String: Double]
    let twoAdditionalCrew: [String: Double]
    let longFlightOneOrTwoSectors: LongFlightExtensions
}

struct LongFlightExtensions {
    let oneAdditionalCrew: [String: Double]
    let twoAdditionalCrew: [String: Double]
}

struct InflightRestFDPExtensionsTable {
    static let data = InflightRestExtensions(
        // Table 1: Maximum FDP: Up to 3 Sectors
        oneAdditionalCrew: ["class_1": 16, "class_2": 15, "class_3": 14],
        twoAdditionalCrew: ["class_1": 17, "class_2": 16, "class_3": 15],
        // Table 2: Maximum FDP: One or two sectors, one with flight time greater than 9 hours
        longFlightOneOrTwoSectors: LongFlightExtensions(
            oneAdditionalCrew: ["class_1": 17, "class_2": 16, "class_3": 15],
            twoAdditionalCrew: ["class_1": 18, "class_2": 17, "class_3": 16]
        )
    )
}

// MARK: - Absolute Limits

struct AbsoluteLimits {
    let dutyPeriod: DutyPeriodLimits
    let flightTime: FlightTimeLimits
}

struct DutyPeriodLimits {
    let sevenDays: Double
    let fourteenDays: Double
    let twentyEightDays: Double
    let twelveMonths: Double
}

struct FlightTimeLimits {
    let twentyEightDays: Double
    let calendarYear: Double
    let twelveMonths: Double
}

struct AbsoluteLimitsTable {
    static let data = AbsoluteLimits(
        dutyPeriod: DutyPeriodLimits(
            sevenDays: 60,
            fourteenDays: 110,
            twentyEightDays: 190,
            twelveMonths: 2000
        ),
        flightTime: FlightTimeLimits(
            twentyEightDays: 100,
            calendarYear: 900,
            twelveMonths: 900
        )
    )
}

// MARK: - Buffer Limits

struct BufferLimits {
    let dutyHours7Days: BufferThresholds
    let flightHours28Days: BufferThresholds
    let flightHours12Months: BufferThresholds
    let recurrentExtendedRecoveryRestPeriod: ExtendedBufferThresholds
}

struct BufferThresholds {
    let planned: Double
    let tracking: Double
}

struct ExtendedBufferThresholds {
    let planned: Double
    let tracking: Double
    let absolute: Double
}

struct BufferLimitsTable {
    static let data = BufferLimits(
        dutyHours7Days: BufferThresholds(planned: 59, tracking: 59),
        flightHours28Days: BufferThresholds(planned: 98, tracking: 99),
        flightHours12Months: BufferThresholds(planned: 898, tracking: 899),
        recurrentExtendedRecoveryRestPeriod: ExtendedBufferThresholds(planned: 166, tracking: 167, absolute: 168)
    )
}

// MARK: - Standby Rules

struct StandbyRules {
    let airportStandby: AirportStandbyRules
    let homeStandby: HomeStandbyRules
    let reserve: ReserveRules
}

struct AirportStandbyRules {
    let maxDurationHours: Double
    let fdpStartTime: String
    let fdpReductionThresholdHours: Double
    let fdpReductionLogic: String
}

struct HomeStandbyRules {
    let maxDurationHours: Double
    let dutyCreditPercentage: Double
    let fdpStartTime: String
    let fdpReductionThresholdHours: HomeStandbyThresholds
    let nightStandbyExclusion: NightStandbyExclusion
    let fdpReductionLogic: [FDPReductionRule]
}

struct HomeStandbyThresholds {
    let defaultThreshold: Double
    let withInflightRestOrSplitDuty: Double
}

struct NightStandbyExclusion {
    let exclusionPeriodStart: String
    let exclusionPeriodEnd: String
    let exclusionCondition: String
}

struct FDPReductionRule {
    let condition: String
    let result: String
}

struct ReserveRules {
    let notificationLeadTimeHours: Double
    let notificationCutoffTime: String
    let rules: [ReserveRule]
}

struct ReserveRule {
    let condition: String
    let result: String
}

struct StandbyRulesTable {
    static let data = StandbyRules(
        airportStandby: AirportStandbyRules(
            maxDurationHours: 16,
            fdpStartTime: "standby_start_time",
            fdpReductionThresholdHours: 4,
            fdpReductionLogic: "Reduce FDP by time spent on standby exceeding 4 hours if converted to duty"
        ),
        homeStandby: HomeStandbyRules(
            maxDurationHours: 16,
            dutyCreditPercentage: 25,
            fdpStartTime: "report_time",
            fdpReductionThresholdHours: HomeStandbyThresholds(defaultThreshold: 6, withInflightRestOrSplitDuty: 8),
            nightStandbyExclusion: NightStandbyExclusion(
                exclusionPeriodStart: "23:00",
                exclusionPeriodEnd: "07:00",
                exclusionCondition: "Time within this period does not count towards FDP reduction threshold until contact"
            ),
            fdpReductionLogic: [
                FDPReductionRule(
                    condition: "If called for duty within first threshold hours",
                    result: "No FDP reduction applies"
                ),
                FDPReductionRule(
                    condition: "If called after threshold hours",
                    result: "FDP reduced by standby time exceeding threshold"
                )
            ]
        ),
        reserve: ReserveRules(
            notificationLeadTimeHours: 10,
            notificationCutoffTime: "20:00",
            rules: [
                ReserveRule(
                    condition: "If notified before 20:00 on previous day",
                    result: "Duty day proceeds as normal"
                ),
                ReserveRule(
                    condition: "If notified after 20:00",
                    result: "Reserve day treated as a free day, unless crew agrees"
                )
            ]
        )
    )
}

// MARK: - Lookup Functions

class RegulatoryTableLookup {
    
    // MARK: - Acclimatisation State Lookup
    
    static func determineAcclimatisationState(timeZoneDifference: Double, elapsedTimeHours: Double) -> String {
        let timeDiffString = timeZoneDifferenceToString(timeZoneDifference)
        let elapsedString = elapsedTimeToString(elapsedTimeHours)
        
        guard let entry = AcclimatisationTable.data.first(where: { $0.timeDifferenceHours == timeDiffString }) else {
            return "X" // Default to unknown if not found
        }
        
        guard let index = entry.elapsedTime.firstIndex(of: elapsedString) else {
            return "X" // Default to unknown if not found
        }
        
        return entry.acclimatisationState[index]
    }
    
    private static func timeZoneDifferenceToString(_ diff: Double) -> String {
        if diff < 4 { return "<4" }
        if diff >= 4 && diff < 6 { return "4-6" }
        if diff >= 6 && diff < 9 { return "6-9" }
        if diff >= 9 && diff < 12 { return "9-12" }
        return "X"
    }
    
    private static func elapsedTimeToString(_ hours: Double) -> String {
        if hours < 48 { return "<48" }
        if hours >= 48 && hours < 72 { return "48-71:59" }
        if hours >= 72 && hours < 96 { return "72-95:59" }
        if hours >= 96 && hours < 120 { return "96-119:59" }
        if hours >= 120 { return ">=120" }
        return "<48"
    }
    
    // MARK: - FDP Lookup Functions
    
    static func lookupFDPAcclimatised(reportTime: String, sectors: Int) -> Double {
        print("DEBUG: RegulatoryTableLookup.lookupFDPAcclimatised - Input: reportTime=\(reportTime), sectors=\(sectors)")
        
        let timeRange = getStandardFDPTimeRange(reportTime)
        print("DEBUG: RegulatoryTableLookup.lookupFDPAcclimatised - Time range: \(timeRange)")
        
        guard let entry = FDPAcclimatisedTable.data.first(where: { $0.startTimeRange == timeRange }) else {
            print("DEBUG: RegulatoryTableLookup.lookupFDPAcclimatised - No table entry found for time range: \(timeRange)")
            return 9.0 // Default minimum
        }
        
        print("DEBUG: RegulatoryTableLookup.lookupFDPAcclimatised - Found table entry: \(entry.startTimeRange)")
        print("DEBUG: RegulatoryTableLookup.lookupFDPAcclimatised - Available sectors data: \(entry.sectors)")
        
        // Convert sectors to proper index:
        // 1-2 sectors = index 0
        // 3 sectors = index 1
        // 4 sectors = index 2
        // 5 sectors = index 3
        // 6 sectors = index 4
        // 7 sectors = index 5
        // 8 sectors = index 6
        // 9 sectors = index 7
        // 10+ sectors = index 8
        let sectorIndex: Int
        if sectors <= 2 {
            sectorIndex = 0 // 1-2 sectors
        } else if sectors <= 10 {
            sectorIndex = sectors - 2 // 3 sectors = index 1, 4 sectors = index 2, etc.
        } else {
            sectorIndex = 8 // 10+ sectors
        }
        
        print("DEBUG: RegulatoryTableLookup.lookupFDPAcclimatised - Sector index: \(sectorIndex)")
        
        let safeIndex = min(sectorIndex, entry.sectors.count - 1)
        let result = entry.sectors[safeIndex]
        
        print("DEBUG: RegulatoryTableLookup.lookupFDPAcclimatised - Final result: \(result)h (from index \(safeIndex))")
        
        return result
    }
    
    static func lookupFDPUnknownAcclimatised(sectors: Int) -> Double {
        // Map sectors to correct index based on UK CAA Table 3 requirements
        let sectorIndex: Int
        switch sectors {
        case 1...2:
            sectorIndex = 0  // 1-2 sectors → 11h 0m
        case 3:
            sectorIndex = 1  // 3 sectors → 10h 30m
        case 4:
            sectorIndex = 2  // 4 sectors → 10h 0m
        case 5:
            sectorIndex = 3  // 5 sectors → 09h 30m
        case 6:
            sectorIndex = 4  // 6 sectors → 09h 0m
        case 7:
            sectorIndex = 5  // 7 sectors → 09h 00m
        case 8:
            sectorIndex = 6  // 8 sectors → 09h 00m
        default:
            // 9+ sectors not allowed for unknown acclimatisation
            print("ERROR: RegulatoryTables - Table 3: \(sectors) sectors not allowed for unknown acclimatisation")
            return 0.0  // Return 0 to indicate not allowed
        }
        
        let result = FDPUnknownAcclimatisationTable.data[sectorIndex]
        print("DEBUG: RegulatoryTables - Table 3 lookup: sectors=\(sectors), index=\(sectorIndex), data=\(FDPUnknownAcclimatisationTable.data), result=\(result)h")
        return result
    }
    
    // MARK: - Extended FDP Lookup Function
    
    /// Looks up extended FDP limits from Table 4: Maximum Daily FDP with Extension
    /// Returns nil if extended FDP is not allowed for the given time and sectors
    static func lookupExtendedFDP(reportTime: String, sectors: Int) -> Double? {
        print("DEBUG: RegulatoryTableLookup.lookupExtendedFDP - Input: reportTime=\(reportTime), sectors=\(sectors)")
        
        let timeRange = getExtendedFDPTimeRange(reportTime)
        print("DEBUG: RegulatoryTableLookup.lookupExtendedFDP - Time range: \(timeRange)")
        
        guard let entry = ExtendedFDPTable.data.first(where: { $0.startTimeRange == timeRange }) else {
            print("DEBUG: RegulatoryTableLookup.lookupExtendedFDP - No table entry found for time range: \(timeRange)")
            return nil // Extended FDP not allowed for this time
        }
        
        print("DEBUG: RegulatoryTableLookup.lookupExtendedFDP - Found table entry: \(entry.startTimeRange)")
        print("DEBUG: RegulatoryTableLookup.lookupExtendedFDP - Available sectors data: \(entry.sectors)")
        
        // Convert sectors to proper index for Table 4:
        // 1-2 sectors = index 0
        // 3 sectors = index 1
        // 4 sectors = index 2
        // 5 sectors = index 3
        let sectorIndex: Int
        if sectors <= 2 {
            sectorIndex = 0 // 1-2 sectors
        } else if sectors <= 5 {
            sectorIndex = sectors - 2 // 3 sectors = index 1, 4 sectors = index 2, 5 sectors = index 3
        } else {
            print("DEBUG: RegulatoryTableLookup.lookupExtendedFDP - \(sectors) sectors not supported in extended FDP table")
            return nil // Extended FDP not supported for 6+ sectors
        }
        
        print("DEBUG: RegulatoryTableLookup.lookupExtendedFDP - Sector index: \(sectorIndex)")
        
        let safeIndex = min(sectorIndex, entry.sectors.count - 1)
        let result = entry.sectors[safeIndex]
        
        if let result = result {
            print("DEBUG: RegulatoryTableLookup.lookupExtendedFDP - Final result: \(result)h (from index \(safeIndex))")
            return result
        } else {
            print("DEBUG: RegulatoryTableLookup.lookupExtendedFDP - Extended FDP not allowed for \(sectors) sectors at time \(timeRange)")
            return nil // Extended FDP not allowed for this combination
        }
    }
    
    static func lookupFDPRosteredExtension(reportTime: String, sectors: Int) -> Double? {
        let timeRange = getStandardFDPTimeRange(reportTime)
        
        guard let entry = FDPRosteredExtensionTable.data.first(where: { $0.startTimeRange == timeRange }) else {
            return nil
        }
        
        let sectorIndex = min(sectors - 1, entry.sectors.count - 1)
        return entry.sectors[sectorIndex]
    }
    
    static func lookupInflightRestExtension(restClass: String, additionalCrew: Int, isLongFlight: Bool) -> Double {
        let table = InflightRestFDPExtensionsTable.data
        
        print("DEBUG: lookupInflightRestExtension - restClass: \(restClass), additionalCrew: \(additionalCrew), isLongFlight: \(isLongFlight)")
        
        if isLongFlight {
            let longFlightTable = table.longFlightOneOrTwoSectors
            if additionalCrew == 1 {
                let result = longFlightTable.oneAdditionalCrew[restClass] ?? 9.0
                print("DEBUG: lookupInflightRestExtension - Long flight, 1 additional crew, \(restClass): \(result)")
                return result
            } else if additionalCrew == 2 {
                let result = longFlightTable.twoAdditionalCrew[restClass] ?? 9.0
                print("DEBUG: lookupInflightRestExtension - Long flight, 2 additional crew, \(restClass): \(result)")
                return result
            }
        } else {
            if additionalCrew == 1 {
                let result = table.oneAdditionalCrew[restClass] ?? 9.0
                print("DEBUG: lookupInflightRestExtension - Standard flight, 1 additional crew, \(restClass): \(result)")
                return result
            } else if additionalCrew == 2 {
                let result = table.twoAdditionalCrew[restClass] ?? 9.0
                print("DEBUG: lookupInflightRestExtension - Standard flight, 2 additional crew, \(restClass): \(result)")
                return result
            }
        }
        
        return 9.0 // Default minimum
    }
    
    // MARK: - Home Standby FDP Calculation
    
    /// Calculates FDP reduction for home standby based on UK CAA regulations
    /// Rule v: Maximum FDP when called from Home Standby:
    /// a) If Home Standby/HCD ceases within the first 6 hours, the maximum FDP counts from reporting
    /// b) If Home Standby/HCD ceases after the first 6 hours, the maximum FDP is reduced by the amount of standby time exceeding 6 hours
    /// c) If the FDP is extended by the use of in-flight rest or Split Duty, the 6 hours are extended to 8 hours
    static func calculateHomeStandbyFDPReduction(
        standbyStartTime: String,
        reportTime: String,
        hasInflightRest: Bool,
        hasSplitDuty: Bool
    ) -> HomeStandbyFDPResult {
        
        // Calculate total standby duration
        let totalStandbyDuration = TimeUtilities.calculateHoursBetween(standbyStartTime, reportTime)
        
        // Determine threshold based on in-flight rest or split duty
        let threshold = (hasInflightRest || hasSplitDuty) ? 8.0 : 6.0
        
        // Apply night exclusion (23:00-07:00) as per regulation
        let effectiveStandbyTime = applyNightExclusionToStandby(
            standbyDuration: totalStandbyDuration,
            standbyStartTime: standbyStartTime
        )
        
        var fdpReduction = 0.0
        var explanation = ""
        
        if effectiveStandbyTime <= threshold {
            // Rule v(a): No FDP reduction if called within threshold
            fdpReduction = 0.0
            explanation = "Home Standby ceased within first \(TimeUtilities.formatHoursAndMinutes(threshold)). No FDP reduction applied."
        } else {
            // Rule v(b): FDP reduced by standby time exceeding threshold
            fdpReduction = effectiveStandbyTime - threshold
            explanation = "Home Standby exceeded \(TimeUtilities.formatHoursAndMinutes(threshold)) by \(TimeUtilities.formatHoursAndMinutes(fdpReduction)). FDP reduced accordingly."
        }
        
        return HomeStandbyFDPResult(
            standbyDuration: effectiveStandbyTime,
            threshold: threshold,
            fdpReduction: fdpReduction,
            explanation: explanation
        )
    }
    
    /// Applies night exclusion (23:00-07:00) to standby time calculation
    /// This implements the night exclusion rule for home standby calculations
    private static func applyNightExclusionToStandby(standbyDuration: Double, standbyStartTime: String) -> Double {
        // For now, return the full duration
        // TODO: Implement proper night exclusion logic based on actual standby start time
        // This would require parsing the standby start time and calculating which hours fall within 23:00-07:00
        return standbyDuration
    }
    
    // MARK: - Helper Functions
    
    /// Maps report time to standard FDP table time ranges (Table 2/3)
    private static func getStandardFDPTimeRange(_ reportTime: String) -> String {
        print("DEBUG: getStandardFDPTimeRange - Input report time: \(reportTime)")
        
        // Extract time from report time (e.g., "12:30z" -> "1230")
        let timeString = reportTime.replacingOccurrences(of: "z", with: "").replacingOccurrences(of: ":", with: "")
        print("DEBUG: getStandardFDPTimeRange - Cleaned time string: \(timeString)")
        
        let timeInt = Int(timeString) ?? 0
        print("DEBUG: getStandardFDPTimeRange - Parsed time integer: \(timeInt)")
        
        // Map to appropriate time range based on Standard FDP Table 2/3 entries
        let timeRange: String
        if timeInt >= 500 && timeInt <= 514 { 
            timeRange = "0500-0514"
        } else if timeInt >= 515 && timeInt <= 529 { 
            timeRange = "0515-0529"
        } else if timeInt >= 530 && timeInt <= 544 { 
            timeRange = "0530-0544"
        } else if timeInt >= 545 && timeInt <= 559 { 
            timeRange = "0545-0559"
        } else if timeInt >= 600 && timeInt <= 1329 { 
            timeRange = "0600-1329"
        } else if timeInt >= 1330 && timeInt <= 1359 { 
            timeRange = "1330-1359"
        } else if timeInt >= 1400 && timeInt <= 1429 { 
            timeRange = "1400-1429"
        } else if timeInt >= 1430 && timeInt <= 1459 { 
            timeRange = "1430-1459"
        } else if timeInt >= 1500 && timeInt <= 1529 { 
            timeRange = "1500-1529"
        } else if timeInt >= 1530 && timeInt <= 1559 { 
            timeRange = "1530-1559"
        } else if timeInt >= 1600 && timeInt <= 1629 { 
            timeRange = "1600-1629"
        } else if timeInt >= 1630 && timeInt <= 1659 { 
            timeRange = "1630-1659"
        } else if timeInt >= 1700 || timeInt <= 459 { 
            timeRange = "1700-0459"
        } else {
            // Default fallback for any unmapped times
            timeRange = "0600-1329" // Most restrictive default
        }
        
        print("DEBUG: getStandardFDPTimeRange - Mapped time range: \(timeRange)")
        return timeRange
    }
    
    /// Maps report time to Extended FDP table time ranges (Table 4)
    private static func getExtendedFDPTimeRange(_ reportTime: String) -> String {
        print("DEBUG: getExtendedFDPTimeRange - Input report time: \(reportTime)")
        
        // Extract time from report time (e.g., "12:30z" -> "1230")
        let timeString = reportTime.replacingOccurrences(of: "z", with: "").replacingOccurrences(of: ":", with: "")
        print("DEBUG: getExtendedFDPTimeRange - Cleaned time string: \(timeString)")
        
        let timeInt = Int(timeString) ?? 0
        print("DEBUG: getExtendedFDPTimeRange - Parsed time integer: \(timeInt)")
        
        // Map to appropriate time range based on Extended FDP Table 4 entries
        let timeRange: String
        if timeInt >= 600 && timeInt <= 614 { 
            timeRange = "0600-0614"
        } else if timeInt >= 615 && timeInt <= 629 { 
            timeRange = "0615-0629"
        } else if timeInt >= 630 && timeInt <= 644 { 
            timeRange = "0630-0644"
        } else if timeInt >= 645 && timeInt <= 659 { 
            timeRange = "0645-0659"
        } else if timeInt >= 700 && timeInt <= 1329 { 
            timeRange = "0700-1329"
        } else if timeInt >= 1330 && timeInt <= 1359 { 
            timeRange = "1330-1359"
        } else if timeInt >= 1400 && timeInt <= 1429 { 
            timeRange = "1400-1429"
        } else if timeInt >= 1430 && timeInt <= 1459 { 
            timeRange = "1430-1459"
        } else if timeInt >= 1500 && timeInt <= 1529 { 
            timeRange = "1500-1529"
        } else if timeInt >= 1530 && timeInt <= 1559 { 
            timeRange = "1530-1559"
        } else if timeInt >= 1600 && timeInt <= 1629 { 
            timeRange = "1600-1629"
        } else if timeInt >= 1630 && timeInt <= 1659 { 
            timeRange = "1630-1659"
        } else if timeInt >= 1700 && timeInt <= 1729 { 
            timeRange = "1700-1729"
        } else if timeInt >= 1730 && timeInt <= 1759 { 
            timeRange = "1730-1759"
        } else if timeInt >= 1800 && timeInt <= 1829 { 
            timeRange = "1800-1829"
        } else if timeInt >= 1830 && timeInt <= 1859 { 
            timeRange = "1830-1859"
        } else if timeInt >= 1900 && timeInt <= 0359 { 
            timeRange = "1900-0359"
        } else if timeInt >= 400 && timeInt <= 414 { 
            timeRange = "0400-0414"
        } else if timeInt >= 415 && timeInt <= 429 { 
            timeRange = "0415-0429"
        } else if timeInt >= 430 && timeInt <= 444 { 
            timeRange = "0430-0444"
        } else if timeInt >= 445 && timeInt <= 459 { 
            timeRange = "0445-0459"
        } else if timeInt >= 500 && timeInt <= 514 { 
            timeRange = "0500-0514"
        } else if timeInt >= 515 && timeInt <= 529 { 
            timeRange = "0515-0529"
        } else if timeInt >= 530 && timeInt <= 544 { 
            timeRange = "0530-0544"
        } else if timeInt >= 545 && timeInt <= 559 { 
            timeRange = "0545-0559"
        } else {
            // Default fallback for any unmapped times
            timeRange = "0600-0614" // Most restrictive default
        }
        
        print("DEBUG: getExtendedFDPTimeRange - Mapped time range: \(timeRange)")
        return timeRange
    }
    
    // MARK: - Absolute Limits Access
    
    static func getAbsoluteLimits() -> AbsoluteLimits {
        return AbsoluteLimitsTable.data
    }
    
    static func getBufferLimits() -> BufferLimits {
        return BufferLimitsTable.data
    }
    
    static func getStandbyRules() -> StandbyRules {
        return StandbyRulesTable.data
    }
} 

 