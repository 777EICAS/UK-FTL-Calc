//
//  Models.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import Foundation
import SwiftUI

// MARK: - Pilot Types
enum PilotType: String, CaseIterable {
    case singlePilot = "single"
    case multiPilot = "multi"
    case commander = "commander"
    case copilot = "copilot"
    
    var displayName: String {
        switch self {
        case .singlePilot:
            return "Single Pilot"
        case .multiPilot:
            return "Multi-Pilot"
        case .commander:
            return "Commander"
        case .copilot:
            return "Co-Pilot"
        }
    }
}

// MARK: - Flight Record
struct FlightRecord: Identifiable, Codable {
    let id: UUID
    let flightNumber: String
    let departure: String
    let arrival: String
    let reportTime: String
    let takeoffTime: String
    let landingTime: String
    let dutyEndTime: String
    let flightTime: Double
    let dutyTime: Double
    let pilotType: PilotType
    let date: String
    let pilotCount: Int // Number of pilots on the flight (including the user)
    let tripNumber: String // NEW: Trip identifier to group sectors together
    let isOutbound: Bool // NEW: Whether this is an outbound or inbound sector
    let elapsedTimeHours: Double // NEW: Pre-calculated elapsed time for acclimatisation
    // NEW: Additional fields for shuttle trips
    let dutyNumber: String // NEW: Which duty this flight belongs to within the trip
    let isShuttleTrip: Bool // NEW: Whether this flight is part of a shuttle trip
    let elapsedTimeFromTripStart: Double // NEW: Elapsed time since reporting at trip home base
    
    init(flightNumber: String, departure: String, arrival: String, reportTime: String, takeoffTime: String, landingTime: String, dutyEndTime: String, flightTime: Double, dutyTime: Double, pilotType: PilotType, date: String = "", pilotCount: Int = 1, tripNumber: String = "", isOutbound: Bool = false, elapsedTimeHours: Double = 0.0, dutyNumber: String = "", isShuttleTrip: Bool = false, elapsedTimeFromTripStart: Double = 0.0) {
        self.id = UUID()
        self.flightNumber = flightNumber
        self.departure = departure
        self.arrival = arrival
        self.reportTime = reportTime
        self.takeoffTime = takeoffTime
        self.landingTime = landingTime
        self.dutyEndTime = dutyEndTime
        self.flightTime = flightTime
        self.dutyTime = dutyTime
        self.pilotType = pilotType
        self.date = date.isEmpty ? DateFormatter.shortDate.string(from: Date()) : date
        self.pilotCount = pilotCount
        self.tripNumber = tripNumber
        self.isOutbound = isOutbound
        self.elapsedTimeHours = elapsedTimeHours
        self.dutyNumber = dutyNumber
        self.isShuttleTrip = isShuttleTrip
        self.elapsedTimeFromTripStart = elapsedTimeFromTripStart
    }
}

// MARK: - FTL Calculation Result
struct FTLCalculationResult {
    let dutyTime: Double
    let flightTime: Double
    let requiredRest: Double
    let nextDutyAvailable: String
    let isCompliant: Bool
    let warnings: [String]
    let violations: [String]
    let maxFDP: Double? // Regulatory FDP limit
    let regulatoryExplanations: [String]? // Explanations from regulatory calculations
}

// MARK: - Rest Facility Types
enum RestFacilityType: String, CaseIterable {
    case none = "No In-flight Rest"
    case class1 = "Class 1 Rest Facility"
    case class2 = "Class 2 Rest Facility"
    case class3 = "Class 3 Rest Facility"
    
    var description: String {
        switch self {
        case .none:
            return "No dedicated rest facility available"
        case .class1:
            return "Bunk or flat bed in a separate compartment"
        case .class2:
            return "Reclining seat with leg support in a separate compartment"
        case .class3:
            return "Reclining seat with leg support in the passenger cabin"
        }
    }
}

// MARK: - Standby Type
enum StandbyType: String, CaseIterable {
    case homeStandby = "Home Standby"
    case airportStandby = "Airport Standby"
    
    var description: String {
        switch self {
        case .homeStandby:
            return "Standby at home or suitable accommodation. FDP starts from report time with reduction based on standby duration exceeding 6-8 hours."
        case .airportStandby:
            return "Standby at airport or designated location. All time counts towards FDP. No maximum standby time."
        }
    }
}



// MARK: - FTL Factors
struct FTLFactors {
    var startTime: String = "06:00" // Report time
    var hasInFlightRest: Bool = false
    var restFacilityType: RestFacilityType = .none
    var hasAugmentedCrew: Bool = false
    var numberOfAdditionalPilots: Int = 0 // 0 = no augmented crew, 1 = 1 additional pilot, 2 = 2 additional pilots
    var hasReducedRest: Bool = false
    var hasSplitDuty: Bool = false
    var hasStandbyDuty: Bool = false
    var standbyType: StandbyType = .homeStandby
    var standbyTypeSelected: Bool = false // Track if user has selected a standby type
    var standbyStartTime: String = "" // Z time when standby started
    var timeZoneDifference: Int = 0 // Hours of time zone difference
    var consecutiveDutyDays: Int = 1
    var timeZoneChanges: Int = 0
    var numberOfSectors: Int = 1 // Number of flight sectors for FDP calculation
    var homeBase: String = "LHR" // Default home base
    var secondHomeBase: String = "" // Optional second home base
    var isAcclimatised: Bool = false // Whether the crew is acclimatised to the local time zone
    var shouldBeAcclimatised: Bool = false // Whether the crew should be considered acclimatised based on time zone rules
    var acclimatisationStatus: AcclimatisationStatus = .alwaysAcclimatised // Current acclimatisation status
    var elapsedTimeHours: Double = 0.0 // Time elapsed since reporting time reference
    var isFirstSector: Bool = true // Whether this is the first sector of the duty
    var originalHomeBaseReportTime: String = "" // Original report time at home base for multi-sector duties
    var acclimatisationReason: String = "" // Reason for acclimatisation status from Table 1 (e.g., "Result B", "Result D", "Result X")
    
    // Computed properties for limit calculations
    var startHour: Int {
        guard let time = TimeUtilities.parseTime(startTime) else { return 6 }
        let calendar = Calendar.current
        return calendar.component(.hour, from: time)
    }
    
    var isEarlyStart: Bool {
        return startHour < 6
    }
    
    var isLateFinish: Bool {
        // This would be calculated based on duty end time
        return false
    }
}

// MARK: - Acclimatisation Status
enum AcclimatisationStatus {
    case alwaysAcclimatised
    case requires3Nights
    case requires4Nights
    
    var description: String {
        switch self {
        case .alwaysAcclimatised:
            return "Always acclimatised"
        case .requires3Nights:
            return "Requires 3 local nights"
        case .requires4Nights:
            return "Requires 4 local nights"
        }
    }
}

// MARK: - UK CAA FTL Limits Calculator
// Based on UK CAA EASA FTL Regulations (https://www.caa.co.uk/publication/download/17414)
// and UK CAA Regulation 965/2012 (EU OPS)
struct UKCAALimits {
    // Base limits - UK CAA Regulation 965/2012
    static let baseMaxDailyDutyTime = 13.0 // hours
    
    // Weekly limits
    static let maxWeeklyDutyTime = 60.0 // hours
    
    // Monthly limits
    static let maxMonthlyDutyTime = 190.0 // hours
    
    // Rest periods - UK CAA Regulation 965/2012
    static let minRestPeriodAtHome = 12.0 // hours minimum when at home base
    static let minRestPeriodAwayFromBase = 10.0 // hours minimum when away from base
    
    // Consecutive duty days
    static let maxConsecutiveDutyDays = 6 // days
    
    // Calculate maximum FDP based on local acclimatised time and number of sectors
    // Based on UK CAA Regulation 965/2012 ORO.FTL.205 Table 2 - Maximum daily FDP for acclimatised crew members
    // Source: https://regulatorylibrary.caa.co.uk/965-2012/Content/Regs/05130_ORO.FTL.205_Flight_duty_period_FDP.htm
    // Note: When acclimatised, time windows are based on departure location local time
    // When not acclimatised, time windows are based on home base local time
    static func calculateMaxFDPByReportTime(reportTime: String, numberOfSectors: Int, departure: String, arrival: String, isAcclimatised: Bool, homeBase: String) -> Double {
        guard let reportDate = TimeUtilities.parseTime(reportTime) else {
            return baseMaxDailyDutyTime // Default fallback
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reportDate)
        let minute = calendar.component(.minute, from: reportDate)
        
        // Convert UTC report time to local acclimatised time
        // For Result 'B' (acclimatised to home base): always use home base local time
        // For Result 'D' (acclimatised to current departure): use departure location's local time
        // For Result 'X' (unknown acclimatisation): use home base local time
        // The isAcclimatised parameter indicates if acclimatised to current departure (Result D)
        // For Result B, we use home base time even though isAcclimatised might be false
        let relevantAirport = isAcclimatised ? departure : homeBase
        let timeZoneOffset = TimeUtilities.getTimeZoneOffsetFromUTC(for: relevantAirport)
        let localHour = (hour + timeZoneOffset + 24) % 24 // Ensure 0-23 range
        let localTimeMinutes = localHour * 60 + minute
        
        // Debug logging
        print("DEBUG FDP: UTC time \(reportTime) -> Local time \(String(format: "%02d:%02d", localHour, minute))")
        print("DEBUG FDP: Using \(isAcclimatised ? "departure" : "home base") time zone (\(relevantAirport))")
        print("DEBUG FDP: Time zone offset from UTC: \(timeZoneOffset) hours")
        print("DEBUG FDP: Local time in minutes: \(localTimeMinutes)")
        print("DEBUG FDP: Number of sectors: \(numberOfSectors)")
        
        // FDP limits based on local acclimatised time and number of sectors
        // Based on UK CAA Regulation 965/2012 ORO.FTL.205 Table 2 - Maximum daily FDP for acclimatised crew members
        // Source: https://regulatorylibrary.caa.co.uk/965-2012/Content/Regs/05130_ORO.FTL.205_Flight_duty_period_FDP.htm
        
        // For non-acclimatised crew, use the FDPUnknownAcclimatisationTable limits
        if !isAcclimatised {
            let sectorIndex = min(numberOfSectors - 1, FDPUnknownAcclimatisationTable.data.count - 1)
            print("DEBUG FDP: Non-acclimatised crew - using Table 3 (Unknown Acclimatisation Table)")
            print("DEBUG FDP: Table 3 Reference - Sectors: \(numberOfSectors), Index: \(sectorIndex), FDP Limit: \(FDPUnknownAcclimatisationTable.data[sectorIndex])h")
            return FDPUnknownAcclimatisationTable.data[sectorIndex]
        }
        
        // Convert time ranges to minutes for easier comparison
        print("DEBUG FDP: Acclimatised crew - using Table 2 (Acclimatised Crew Table)")
        print("DEBUG FDP: Table 2 Reference - Local time: \(String(format: "%02d:%02d", localHour, minute)), Minutes: \(localTimeMinutes)")
        print("DEBUG FDP: Table 2 Reference - Sectors: \(numberOfSectors)")
        
        if numberOfSectors == 1 || numberOfSectors == 2 {
            // 1-2 Sectors
            if localTimeMinutes >= 360 && localTimeMinutes <= 809 { // 06:00-13:29
                print("DEBUG FDP: Table 2 Reference - Found: Row '1-2 sectors', Column '06:00-13:29' = 13.0h")
                return 13.0 // 13:00
            } else if localTimeMinutes >= 810 && localTimeMinutes <= 839 { // 13:30-13:59
                return 12.75 // 12:45
            } else if localTimeMinutes >= 840 && localTimeMinutes <= 869 { // 14:00-14:29
                return 12.5 // 12:30
            } else if localTimeMinutes >= 870 && localTimeMinutes <= 889 { // 14:30-14:59
                return 12.25 // 12:15
            } else if localTimeMinutes >= 900 && localTimeMinutes <= 929 { // 15:00-15:29
                return 12.0 // 12:00
            } else if localTimeMinutes >= 930 && localTimeMinutes <= 959 { // 15:30-15:59
                return 11.75 // 11:45
            } else if localTimeMinutes >= 960 && localTimeMinutes <= 989 { // 16:00-16:29
                return 11.5 // 11:30
            } else if localTimeMinutes >= 990 && localTimeMinutes <= 1019 { // 16:30-16:59
                print("DEBUG FDP: Selected time window 16:30-16:59 -> 11.25 hours")
                return 11.25 // 11:15
            } else if localTimeMinutes >= 1020 || localTimeMinutes <= 299 { // 17:00-04:59
                return 11.0 // 11:00
            } else if localTimeMinutes >= 300 && localTimeMinutes <= 314 { // 05:00-05:14
                return 12.0 // 12:00
            } else if localTimeMinutes >= 315 && localTimeMinutes <= 329 { // 05:15-05:29
                return 12.25 // 12:15
            } else if localTimeMinutes >= 330 && localTimeMinutes <= 344 { // 05:30-05:44
                return 12.5 // 12:30
            } else if localTimeMinutes >= 345 && localTimeMinutes <= 359 { // 05:45-05:59
                return 12.75 // 12:45
            } else {
                return 11.0 // Default fallback
            }
        } else if numberOfSectors == 3 {
            // 3 Sectors
            if localTimeMinutes >= 360 && localTimeMinutes <= 809 { // 06:00-13:29
                return 12.5 // 12:30
            } else if localTimeMinutes >= 810 && localTimeMinutes <= 839 { // 13:30-13:59
                return 12.25 // 12:15
            } else if localTimeMinutes >= 840 && localTimeMinutes <= 869 { // 14:00-14:29
                return 12.0 // 12:00
            } else if localTimeMinutes >= 870 && localTimeMinutes <= 889 { // 14:30-14:59
                return 11.75 // 11:45
            } else if localTimeMinutes >= 900 && localTimeMinutes <= 929 { // 15:00-15:29
                return 11.5 // 11:30
            } else if localTimeMinutes >= 930 && localTimeMinutes <= 959 { // 15:30-15:59
                return 11.25 // 11:15
            } else if localTimeMinutes >= 960 && localTimeMinutes <= 989 { // 16:00-16:29
                return 11.0 // 11:00
            } else if localTimeMinutes >= 990 && localTimeMinutes <= 1019 { // 16:30-16:59
                return 10.75 // 10:45
            } else if localTimeMinutes >= 1020 || localTimeMinutes <= 299 { // 17:00-04:59
                return 10.5 // 10:30
            } else if localTimeMinutes >= 300 && localTimeMinutes <= 314 { // 05:00-05:14
                return 11.5 // 11:30
            } else if localTimeMinutes >= 315 && localTimeMinutes <= 329 { // 05:15-05:29
                return 11.75 // 11:45
            } else if localTimeMinutes >= 330 && localTimeMinutes <= 344 { // 05:30-05:44
                return 12.0 // 12:00
            } else if localTimeMinutes >= 345 && localTimeMinutes <= 359 { // 05:45-05:59
                return 12.25 // 12:15
            } else {
                return 10.5 // Default fallback
            }
        } else if numberOfSectors == 4 {
            // 4 Sectors
            if localTimeMinutes >= 360 && localTimeMinutes <= 809 { // 06:00-13:29
                return 12.0 // 12:00
            } else if localTimeMinutes >= 810 && localTimeMinutes <= 839 { // 13:30-13:59
                return 11.75 // 11:45
            } else if localTimeMinutes >= 840 && localTimeMinutes <= 869 { // 14:00-14:29
                return 11.5 // 11:30
            } else if localTimeMinutes >= 870 && localTimeMinutes <= 889 { // 14:30-14:59
                return 11.25 // 11:15
            } else if localTimeMinutes >= 900 && localTimeMinutes <= 929 { // 15:00-15:29
                return 11.0 // 11:00
            } else if localTimeMinutes >= 930 && localTimeMinutes <= 959 { // 15:30-15:59
                return 10.75 // 10:45
            } else if localTimeMinutes >= 960 && localTimeMinutes <= 989 { // 16:00-16:29
                return 10.5 // 10:30
            } else if localTimeMinutes >= 990 && localTimeMinutes <= 1019 { // 16:30-16:59
                return 10.25 // 10:15
            } else if localTimeMinutes >= 1020 || localTimeMinutes <= 299 { // 17:00-04:59
                return 10.0 // 10:00
            } else if localTimeMinutes >= 300 && localTimeMinutes <= 314 { // 05:00-05:14
                return 11.0 // 11:00
            } else if localTimeMinutes >= 315 && localTimeMinutes <= 329 { // 05:15-05:29
                return 11.25 // 11:15
            } else if localTimeMinutes >= 330 && localTimeMinutes <= 344 { // 05:30-05:44
                return 11.5 // 11:30
            } else if localTimeMinutes >= 345 && localTimeMinutes <= 359 { // 05:45-05:59
                return 11.75 // 11:45
            } else {
                return 10.0 // Default fallback
            }
        } else {
            // 5+ Sectors - use the most restrictive limits
            if localTimeMinutes >= 360 && localTimeMinutes <= 809 { // 06:00-13:29
                return 11.5 // 11:30 (5 sectors)
            } else if localTimeMinutes >= 810 && localTimeMinutes <= 839 { // 13:30-13:59
                return 11.25 // 11:15 (5 sectors)
            } else if localTimeMinutes >= 840 && localTimeMinutes <= 869 { // 14:00-14:29
                return 11.0 // 11:00 (5 sectors)
            } else if localTimeMinutes >= 870 && localTimeMinutes <= 889 { // 14:30-14:59
                return 10.75 // 10:45 (5 sectors)
            } else if localTimeMinutes >= 900 && localTimeMinutes <= 929 { // 15:00-15:29
                return 10.5 // 10:30 (5 sectors)
            } else if localTimeMinutes >= 930 && localTimeMinutes <= 959 { // 15:30-15:59
                return 10.25 // 10:15 (5 sectors)
            } else if localTimeMinutes >= 960 && localTimeMinutes <= 989 { // 16:00-16:29
                return 10.0 // 10:00 (5 sectors)
            } else if localTimeMinutes >= 990 && localTimeMinutes <= 1019 { // 16:30-16:59
                return 9.75 // 09:45 (5 sectors)
            } else if localTimeMinutes >= 1020 || localTimeMinutes <= 299 { // 17:00-04:59
                return 9.5 // 09:30 (5 sectors)
            } else if localTimeMinutes >= 300 && localTimeMinutes <= 314 { // 05:00-05:14
                return 10.5 // 10:30 (5 sectors)
            } else if localTimeMinutes >= 315 && localTimeMinutes <= 329 { // 05:15-05:29
                return 10.75 // 10:45 (5 sectors)
            } else if localTimeMinutes >= 330 && localTimeMinutes <= 344 { // 05:30-05:44
                return 11.0 // 11:00 (5 sectors)
            } else if localTimeMinutes >= 345 && localTimeMinutes <= 359 { // 05:45-05:59
                return 11.25 // 11:15 (5 sectors)
            } else {
                return 9.0 // Default fallback (9:00 for 6+ sectors)
            }
        }
    }
    
    // Calculate dynamic daily duty limit based on factors
    static func calculateDailyDutyLimit(factors: FTLFactors, pilotType: PilotType, departure: String, arrival: String, homeBase: String) -> Double {
        // Start with the report time-based FDP limit (using local acclimatised time)
        let reportTimeLimit = calculateMaxFDPByReportTime(reportTime: factors.startTime, numberOfSectors: factors.numberOfSectors, departure: departure, arrival: arrival, isAcclimatised: factors.isAcclimatised, homeBase: homeBase)
        var limit = reportTimeLimit
        
        // Augmented crew provides the highest extension (UK CAA Regulation 965/2012)
        // For augmented crew, the FDP is based on augmented crew limits regardless of start time or acclimatization
        if factors.hasAugmentedCrew && factors.numberOfAdditionalPilots > 0 {
            // Augmented crew limits based on number of additional pilots and rest facility type
            // Based on UK CAA EASA FTL Regulations (https://www.caa.co.uk/publication/download/17414)
            
            // First, determine the base limit based on number of additional pilots
            let baseAugmentedLimit: Double
            if factors.numberOfAdditionalPilots == 1 {
                baseAugmentedLimit = 17.0 // 1 additional pilot: maximum 17 hours
            } else if factors.numberOfAdditionalPilots == 2 {
                baseAugmentedLimit = 18.0 // 2 additional pilots: maximum 18 hours
            } else {
                baseAugmentedLimit = reportTimeLimit // Fallback to report time limit
            }
            
            // Then apply rest facility type restrictions
            switch factors.restFacilityType {
            case .class1:
                limit = baseAugmentedLimit // Class 1: Full augmented crew limit
            case .class2:
                limit = min(baseAugmentedLimit, 17.0) // Class 2: Maximum 17 hours
            case .class3:
                limit = min(baseAugmentedLimit, 16.0) // Class 3: Maximum 16 hours
            case .none:
                limit = min(baseAugmentedLimit, 13.0) // No in-flight rest: Maximum 13 hours
            }
            
            // For augmented crew, we use the augmented crew limits as the primary basis
            // Only apply other restrictions if they are more restrictive than the augmented crew limit
            print("DEBUG: Augmented crew detected - using augmented crew limits as primary basis")
            print("DEBUG: Base augmented limit: \(baseAugmentedLimit)h, Final augmented limit: \(limit)h")
            
        } else if factors.hasInFlightRest && pilotType == .multiPilot {
            // In-flight rest considerations based on rest facility type (only if not augmented crew)
            // Based on UK CAA EASA FTL Regulations (https://www.caa.co.uk/publication/download/17414)
            switch factors.restFacilityType {
            case .class1:
                limit = 16.0 // Class 1: Bunk/flat bed - up to 16 hours
            case .class2:
                limit = 16.0 // Class 2: Reclining seat in separate compartment - up to 16 hours
            case .class3:
                limit = 15.0 // Class 3: Reclining seat in passenger cabin - up to 15 hours
            case .none:
                limit = 13.0 // No rest facility - standard limit
            }
        }
        
        // Early start restrictions are already factored into the base FDP calculation from Table 2
        // No additional reduction needed as the report time-based limits already account for early starts
        if factors.isEarlyStart {
            print("DEBUG: Early start detected - already factored into base FDP calculation")
        }
        
        // Night duty restrictions - UK CAA FDP calculation already considers time of day
        // The FDP limits based on report time already account for night operations
        // Additional night duty restrictions may be redundant for UK CAA regulations
        // if factors.isNightDuty {
        //     limit = min(limit, 12.0) // Night duty restriction removed - FDP calculation handles this
        // }
        
        // Standby duty considerations - EASA/CAA regulations
        if factors.hasStandbyDuty {
            switch factors.standbyType {
            case .homeStandby:
                // Home standby: FDP reduction based on standby duration exceeding threshold - no hard 16h limit
                break
            case .airportStandby:
                // Airport standby: no maximum standby time, but all counts towards FDP
                // The limit is determined by the standard FDP calculation above
                break
            }
        }
        
        // Split duty considerations
        if factors.hasSplitDuty {
            limit = min(limit, 12.0) // Reduced to 12 hours for split duty
        }
        
        // Consecutive duty day restrictions
        if factors.consecutiveDutyDays >= 5 {
            limit = min(limit, 11.0) // Reduced to 11 hours after 5 consecutive days
        }
        
        // Acclimatised considerations based on UK CAA EASA FTL Regulations
        // For augmented crew, acclimatization status does not affect the augmented crew limits
        if !factors.hasAugmentedCrew {
            // The acclimatisation status is already handled in calculateMaxFDPByReportTime
            // which uses the appropriate regulatory table (FDPAcclimatisedTable vs FDPUnknownAcclimatisationTable)
            // No additional modifications needed here as the base calculation already considers acclimatisation
            print("DEBUG: Acclimatisation status already considered in base FDP calculation")
        } else {
            print("DEBUG: Augmented crew - acclimatization status does not affect augmented crew limits")
        }
        
        return limit
    }
    

    
    // Calculate required rest period - UK CAA Regulation 965/2012
    static func calculateRequiredRest(dutyTime: Double, factors: FTLFactors, isOutbound: Bool, arrival: String) -> Double {
        // UK CAA rule: Rest period depends on location after duty
        // Away from base (after outbound sector): 10 hours minimum OR duty time, whichever is greater
        // At home base (after inbound sector): 12 hours minimum OR duty time, whichever is greater
        
        let isAtHomeBase = !isOutbound && (arrival == factors.homeBase || arrival == factors.secondHomeBase)
        
        let minimumRestPeriod: Double
        if isAtHomeBase {
            minimumRestPeriod = minRestPeriodAtHome // 12 hours at home base
        } else {
            minimumRestPeriod = minRestPeriodAwayFromBase // 10 hours away from base
        }
        
        // Rest period must be at least the minimum OR as long as the preceding duty, whichever is greater
        var restPeriod = max(minimumRestPeriod, dutyTime)
        
        // Extended rest for very long duty periods
        if dutyTime > 14 {
            restPeriod = 16.0
        }
        
        // Additional rest for early starts
        if factors.isEarlyStart {
            restPeriod = max(restPeriod, 12.0)
        }
        
        return restPeriod
    }
    
    // Get limit explanations with improved clarity
    static func getLimitExplanations(factors: FTLFactors, pilotType: PilotType, departure: String, arrival: String, homeBase: String) -> [String] {
        var explanations: [String] = []
        
        // Add report time-based FDP explanation using Table 1 outcome (B/D/X)
        // Determine Table 1 result for this sector
        let accl = determineAcclimatisationStatus(
            timeZoneDifference: factors.timeZoneDifference,
            elapsedTimeHours: factors.elapsedTimeHours,
            isFirstSector: factors.isFirstSector,
            homeBase: homeBase,
            departure: departure
        )
        let sectorText = factors.numberOfSectors == 1 ? "sector" : "sectors"
        // Fix: Check the reason string to determine which result we have, since both B and D have isAcclimatised = true
        let table1Result: String = accl.reason.contains("Result D") ? "D" : (accl.reason.contains("Result B") ? "B" : "X")
        
        let reportTimeLimit: Double
        let localTime: String
        let locationText: String
        switch table1Result {
        case "B":
            // Use Table 2 with home base local time
            localTime = TimeUtilities.getLocalTime(for: factors.startTime, airportCode: homeBase)
            locationText = "home base"
            reportTimeLimit = RegulatoryTableLookup.lookupFDPAcclimatised(reportTime: localTime, sectors: factors.numberOfSectors)
        case "D":
            // Use Table 2 with current departure local time
            localTime = TimeUtilities.getLocalTime(for: factors.startTime, airportCode: departure)
            locationText = "departure"
            reportTimeLimit = RegulatoryTableLookup.lookupFDPAcclimatised(reportTime: localTime, sectors: factors.numberOfSectors)
        default: // "X"
            // Table 3 (unknown acclimatisation) – no local conversion required for limit value
            localTime = TimeUtilities.getLocalTime(for: factors.startTime, airportCode: homeBase)
            locationText = "home base"
            reportTimeLimit = RegulatoryTableLookup.lookupFDPUnknownAcclimatised(sectors: factors.numberOfSectors)
        }
        explanations.append("Report time \(factors.startTime) → Local \(localTime) at \(locationText) (\(factors.numberOfSectors) \(sectorText)): Base FDP limit \(String(format: "%.1f", reportTimeLimit))h")
        
        if factors.isEarlyStart {
            explanations.append("Early start (before 06:00): Reduced limits apply")
        }
        
        if factors.hasInFlightRest {
            // Use the correct values based on the actual regulatory tables
            // For Class 2 rest facility with 1 additional pilot on standard flight (not long flight)
            let dutyLimit: String
            
            if factors.hasAugmentedCrew && factors.numberOfAdditionalPilots > 0 {
                // Augmented crew with in-flight rest
                switch factors.restFacilityType {
                case .class1:
                    dutyLimit = factors.numberOfAdditionalPilots == 1 ? "16h" : "17h"
                case .class2:
                    dutyLimit = factors.numberOfAdditionalPilots == 1 ? "15h" : "16h"
                case .class3:
                    dutyLimit = factors.numberOfAdditionalPilots == 1 ? "14h" : "15h"
                case .none:
                    dutyLimit = "13h"
                }
            } else {
                // No augmented crew - use standard values
                switch factors.restFacilityType {
                case .class1:
                    dutyLimit = "16h"
                case .class2:
                    dutyLimit = "15h"
                case .class3:
                    dutyLimit = "14h"
                case .none:
                    dutyLimit = "13h"
                }
            }
            
            explanations.append("In-flight rest (\(factors.restFacilityType.rawValue)): Extended duty time to \(dutyLimit)")
        }
        
        if factors.hasAugmentedCrew && factors.numberOfAdditionalPilots > 0 {
            let pilotText = factors.numberOfAdditionalPilots == 1 ? "1 additional pilot" : "\(factors.numberOfAdditionalPilots) additional pilots"
            let maxLimit = factors.numberOfAdditionalPilots == 1 ? "17h" : "18h"
            explanations.append("Augmented crew (\(pilotText)): Extended to maximum \(maxLimit) based on rest facility type")
        }
        
        if factors.hasSplitDuty {
            explanations.append("Split duty: Reduced limits apply")
        }
        
        if factors.consecutiveDutyDays >= 5 {
            explanations.append("5+ consecutive duty days: Reduced limits apply")
        }
        
        // Standby duty explanations
        if factors.hasStandbyDuty {
            switch factors.standbyType {
            case .homeStandby:
                explanations.append("Home standby: FDP starts from report time. FDP reduced by standby time exceeding 6 hours (8 hours with in-flight rest or split duty). Commanders discretion available for FDP extension.")
            case .airportStandby:
                explanations.append("Airport standby: FDP starts from standby start time. All standby time counts towards FDP. No maximum standby time limit.")
            }
        }
        
        // Improved acclimatisation explanations
        if factors.timeZoneDifference >= 4 {
            if factors.isAcclimatised {
                explanations.append("Acclimatised crew: Extended duty limits apply (time zone difference: \(factors.timeZoneDifference)h)")
            } else {
                explanations.append("Non-acclimatised crew: Reduced duty limits apply (time zone difference: \(factors.timeZoneDifference)h)")
            }
        } else if factors.timeZoneDifference > 0 {
            explanations.append("Time zone difference (\(factors.timeZoneDifference)h): Always acclimatised")
        }
        
        return explanations
    }
    

    
    // Determine acclimatisation status based on UK CAA ±2 hour band rule and Table 1 regulations
    //
    // UK CAA ±2 Hour Band Rule:
    // Crews are considered acclimatised to a 2-hour wide time zone band around their acclimatised time zone
    // Within ±2 hours: Result 'D' (acclimatised to departure location)
    //
    // UK CAA Table 1 Matrix (for time zone differences > 2 hours):
    // | TZ Diff | <48h | 48-71:59h | 72-95:59h | 96-119:59h | ≥120h |
    // |---------|------|-----------|-----------|-----------|-------|
    // | 2-4h    | B    | D         | D         | D         | D     |
    // | 4-6h    | B    | X         | D         | D         | D     |
    // | 6-9h    | B    | X         | X         | D         | D     |
    // | 9-12h   | B    | X         | X         | X         | D     |
    //
    // Result B: Acclimatised to home base (use Table 2 with home base local time)
    // Result D: Acclimatised to current departure (use Table 2 with departure local time)  
    // Result X: Unknown acclimatisation state (use Table 3)
    //
    // Return format: (isAcclimatised, shouldBeAcclimatised, reason)
    // - isAcclimatised: true if acclimatised to CURRENT departure location
    // - shouldBeAcclimatised: true if acclimatised to home base
    static func determineAcclimatisationStatus(
        timeZoneDifference: Int,
        elapsedTimeHours: Double,
        isFirstSector: Bool,
        homeBase: String,
        departure: String
    ) -> (isAcclimatised: Bool, shouldBeAcclimatised: Bool, reason: String) {
        
        // Always acclimatised when starting from home base (first sector)
        if isFirstSector && departure.uppercased() == homeBase.uppercased() {
            return (true, true, "First sector from home base - always acclimatised")
        }
        
        // For subsequent sectors, apply UK CAA ±2 hour band rule first, then Table 1 rules if outside the band
        // Reference time: from trip start location (home base)
        // Local time: from current duty start location (current departure airport)
        // Time zone difference: between reference location and current duty start location
        
        // The key insight: The ±2 hour band rule determines if crew is acclimatised to current departure location
        // Table 1 only applies when outside the ±2 hour band
        
        // Apply UK CAA ±2 hour band rule first
        // Crews are considered acclimatised to a 2-hour wide time zone band around their acclimatised time zone
        if abs(timeZoneDifference) <= 2 {
            print("DEBUG: Table 1 Reference - Time zone difference: \(timeZoneDifference)h (within ±2 hour band)")
            print("DEBUG: Table 1 Reference - Found: Within ±2 hour band = Result 'D' (acclimatised to departure location)")
            // Result 'D': Crew is acclimatised to current departure location (within ±2 hour band)
            // Use Table 2 with departure local time for FDP calculations
            return (true, false, "Result D: Within ±2 hour band - acclimatised to departure location")
        }
        
        // For time zone differences > 2 hours, apply UK CAA Table 1 rules
        // Less than 4 hours time zone difference: Apply Table 1 rules based on elapsed time
        if timeZoneDifference > 2 && timeZoneDifference < 4 {
            print("DEBUG: Table 1 Reference - Time zone difference: 2-4h, Elapsed time: \(elapsedTimeHours)h")
            print("DEBUG: Table 1 Reference - Looking up: Row '2-4h', Column based on elapsed time")
            
            if elapsedTimeHours < 48.0 {
                // Result 'B': User is acclimatised to home base time zone
                print("DEBUG: Table 1 Reference - Found: Row '2-4h', Column '<48h' = Result 'B'")
                print("DEBUG: Table 1 Reference - Result 'B' means: Acclimatised to home base - use Table 2 with home base local time")
                return (true, true, "Result B: 2-4h difference with <48h elapsed - acclimatised to home base (Result B)")
            } else if elapsedTimeHours >= 48.0 && elapsedTimeHours < 72.0 {
                // Result 'D': User is acclimatised to current departure location
                print("DEBUG: Table 1 Reference - Found: Row '2-4h', Column '48-71:59h' = Result 'D'")
                print("DEBUG: Table 1 Reference - Result 'D' means: Acclimatised to current departure - use Table 2 with departure local time")
                return (true, false, "Result D: 2-4h difference with 48-71:59h elapsed - acclimatised to departure (Result D)")
            } else if elapsedTimeHours >= 72.0 {
                // Result 'D': User is acclimatised to current departure location
                print("DEBUG: Table 1 Reference - Found: Row '2-4h', Column '≥72h' = Result 'D'")
                print("DEBUG: Table 1 Reference - Result 'D' means: Acclimatised to current departure - use Table 2 with departure local time")
                return (true, false, "Result D: 2-4h difference with ≥72h elapsed - acclimatised to departure (Result D)")
            }
        }
        
        // 4-6 hours time zone difference: Apply Table 1 rules
        if timeZoneDifference >= 4 && timeZoneDifference <= 6 {
            // UK CAA Table 1: For 4-6 hour differences, acclimatisation depends on elapsed time
            print("DEBUG: Table 1 Reference - Time zone difference: 4-6h, Elapsed time: \(elapsedTimeHours)h")
            print("DEBUG: Table 1 Reference - Looking up: Row '4-6h', Column based on elapsed time")
            
            if elapsedTimeHours >= 48.0 && elapsedTimeHours < 72.0 {
                // Result 'X': Unknown acclimatisation state (48-71:59h elapsed with 4-6h time zone difference)
                print("DEBUG: Table 1 Reference - Found: Row '4-6h', Column '48-71:59h' = Result 'X'")
                print("DEBUG: Table 1 Reference - Result 'X' means: Unknown acclimatisation state - use Table 3 for FDP limits")
                return (false, false, "Result X: 4-6h difference with 48-71:59h elapsed - unknown acclimatisation state (X)")
            } else if elapsedTimeHours >= 72.0 {
                // Result 'D': User is acclimatised to current departure location
                print("DEBUG: Table 1 Reference - Found: Row '4-6h', Column '≥72h' = Result 'D'")
                print("DEBUG: Table 1 Reference - Result 'D' means: Acclimatised to current departure - use Table 2 with departure local time")
                return (true, true, "Result D: 4-6h difference with ≥72h elapsed - acclimatised (Result D)")
            } else {
                // Result 'B': User is acclimatised to home base time zone
                print("DEBUG: Table 1 Reference - Found: Row '4-6h', Column '<48h' = Result 'B'")
                print("DEBUG: Table 1 Reference - Result 'B' means: Acclimatised to home base - use Table 2 with home base local time")
                // For Result 'B': Always use Table 2 with home base local time, regardless of departure location
                // Result 'B' means acclimatised to home base time zone, not current departure
                return (true, true, "Result B: 4-6h difference with <48h elapsed - acclimatised to home base (Result B)")
            }
        }
        
        // 6-9 hours time zone difference: Apply Table 1 rules
        if timeZoneDifference > 6 && timeZoneDifference <= 9 {
            // UK CAA Table 1: For 6-9 hour differences, acclimatisation depends on elapsed time
            print("DEBUG: Table 1 Reference - Time zone difference: 6-9h, Elapsed time: \(elapsedTimeHours)h")
            print("DEBUG: Table 1 Reference - Looking up: Row '6-9h', Column based on elapsed time")
            
            if elapsedTimeHours >= 48.0 && elapsedTimeHours < 72.0 {
                // Result 'X': Unknown acclimatisation state (48-71:59h elapsed with 6-9h time zone difference)
                print("DEBUG: Table 1 Reference - Found: Row '6-9h', Column '48-71:59h' = Result 'X'")
                print("DEBUG: Table 1 Reference - Result 'X' means: Unknown acclimatisation state - use Table 3 for FDP limits")
                return (false, false, "Result X: 6-9h difference with 48-71:59h elapsed - unknown acclimatisation state (X)")
            } else if elapsedTimeHours >= 72.0 && elapsedTimeHours < 96.0 {
                // Result 'X': Unknown acclimatisation state (72-95:59h elapsed with 6-9h time zone difference)
                print("DEBUG: Table 1 Reference - Found: Row '6-9h', Column '72-95:59h' = Result 'X'")
                print("DEBUG: Table 1 Reference - Result 'X' means: Unknown acclimatisation state - use Table 3 for FDP limits")
                return (false, false, "Result X: 6-9h difference with 72-95:59h elapsed - unknown acclimatisation state (X)")
            } else if elapsedTimeHours >= 96.0 && elapsedTimeHours < 120.0 {
                // Result 'D': User is acclimatised to current departure location
                print("DEBUG: Table 1 Reference - Found: Row '6-9h', Column '96-119:59h' = Result 'D'")
                print("DEBUG: Table 1 Reference - Result 'D' means: Acclimatised to current departure - use Table 2 with departure local time")
                return (true, true, "Result D: 6-9h difference with 96-119:59h elapsed - acclimatised (Result D)")
            } else if elapsedTimeHours >= 120.0 {
                // Result 'D': User is acclimatised to current departure location
                print("DEBUG: Table 1 Reference - Found: Row '6-9h', Column '≥120h' = Result 'D'")
                print("DEBUG: Table 1 Reference - Result 'D' means: Acclimatised to current departure - use Table 2 with departure local time")
                return (true, true, "Result D: 6-9h difference with ≥120h elapsed - acclimatised (Result D)")
            } else {
                // Result 'B': User is acclimatised to home base time zone
                print("DEBUG: Table 1 Reference - Found: Row '6-9h', Column '<48h' = Result 'B'")
                print("DEBUG: Table 1 Reference - Result 'B' means: Acclimatised to home base - use Table 2 with home base local time")
                // For Result 'B': Always use Table 2 with home base local time, regardless of departure location
                // Result 'B' means acclimatised to home base time zone, not current departure
                return (true, true, "Result B: 6-9h difference with <48h elapsed - acclimatised to home base (Result B)")
            }
        }
        
        // 9-12 hours time zone difference: Apply Table 1 rules
        if timeZoneDifference > 9 && timeZoneDifference <= 12 {
            // UK CAA Table 1: For 9-12 hour differences, acclimatisation depends on elapsed time
            print("DEBUG: Table 1 Reference - Time zone difference: 9-12h, Elapsed time: \(elapsedTimeHours)h")
            print("DEBUG: Table 1 Reference - Looking up: Row '9-12h', Column based on elapsed time")
            
            if elapsedTimeHours >= 48.0 && elapsedTimeHours < 72.0 {
                // Result 'X': Unknown acclimatisation state (48-71:59h elapsed with 9-12h time zone difference)
                print("DEBUG: Table 1 Reference - Found: Row '9-12h', Column '48-71:59h' = Result 'X'")
                print("DEBUG: Table 1 Reference - Result 'X' means: Unknown acclimatisation state - use Table 3 for FDP limits")
                return (false, false, "Result X: 9-12h difference with 48-71:59h elapsed - unknown acclimatisation state (X)")
            } else if elapsedTimeHours >= 72.0 && elapsedTimeHours < 96.0 {
                // Result 'X': Unknown acclimatisation state (72-95:59h elapsed with 9-12h time zone difference)
                print("DEBUG: Table 1 Reference - Found: Row '9-12h', Column '72-95:59h' = Result 'X'")
                print("DEBUG: Table 1 Reference - Result 'X' means: Unknown acclimatisation state - use Table 3 for FDP limits")
                return (false, false, "Result X: 9-12h difference with 72-95:59h elapsed - unknown acclimatisation state (X)")
            } else if elapsedTimeHours >= 96.0 && elapsedTimeHours < 120.0 {
                // Result 'X': Unknown acclimatisation state (96-119:59h elapsed with 9-12h time zone difference)
                print("DEBUG: Table 1 Reference - Found: Row '9-12h', Column '96-119:59h' = Result 'X'")
                print("DEBUG: Table 1 Reference - Result 'X' means: Unknown acclimatisation state - use Table 3 for FDP limits")
                return (false, false, "Result X: 9-12h difference with 96-119:59h elapsed - unknown acclimatisation state (X)")
            } else if elapsedTimeHours >= 120.0 {
                // Result 'D': User is acclimatised to current departure location
                print("DEBUG: Table 1 Reference - Found: Row '9-12h', Column '≥120h' = Result 'D'")
                print("DEBUG: Table 1 Reference - Result 'D' means: Acclimatised to current departure - use Table 2 with departure local time")
                return (true, true, "Result D: 9-12h difference with ≥120h elapsed - acclimatised (Result D)")
            } else {
                // Result 'B': User is acclimatised to home base time zone
                print("DEBUG: Table 1 Reference - Found: Row '9-12h', Column '<48h' = Result 'B'")
                print("DEBUG: Table 1 Reference - Result 'B' means: Acclimatised to home base - use Table 2 with home base local time")
                // For Result 'B': Always use Table 2 with home base local time, regardless of departure location
                // Result 'B' means acclimatised to home base time zone, not current departure
                return (true, true, "Result B: 9-12h difference with <48h elapsed - acclimatised to home base (Result B)")
            }
        }
        
        // Default case for any time zone differences > 12 hours (should not occur in practice)
        if timeZoneDifference > 12 {
            print("DEBUG: Table 1 Reference - Time zone difference: >12h - invalid case")
            return (false, false, "Time zone difference > 12h - invalid case")
        }
        
        // Default case
        print("DEBUG: Table 1 Reference - Unable to determine acclimatisation status")
        return (false, false, "Unable to determine acclimatisation status")
    }
    
    // Get detailed active factors with impact explanations
    static func getActiveFactorsWithImpact(factors: FTLFactors, pilotType: PilotType, departure: String, arrival: String, homeBase: String, maxFDP: Double? = nil) -> [ActiveFactor] {
        var activeFactors: [ActiveFactor] = []
        
        // 1. Acclimatisation Factor - Always show (first thing we check)
        let acclimatisationStatus = determineAcclimatisationStatus(
            timeZoneDifference: factors.timeZoneDifference,
            elapsedTimeHours: factors.elapsedTimeHours,
            isFirstSector: factors.isFirstSector,
            homeBase: homeBase,
            departure: departure
        )
        
        // Show elapsed time from original home base report time for multi-sector duties
        let elapsedTimeText: String
        let hours = Int(factors.elapsedTimeHours)
        let minutes = Int((factors.elapsedTimeHours - Double(hours)) * 60)
        
        if !factors.isFirstSector && !factors.originalHomeBaseReportTime.isEmpty {
            elapsedTimeText = "Elapsed time: \(hours)h \(minutes)m (from \(factors.originalHomeBaseReportTime) at home base)"
        } else {
            elapsedTimeText = "Elapsed time: \(hours)h \(minutes)m"
        }
        
        // Acclimatisation status display
        if acclimatisationStatus.isAcclimatised {
            // Check if this is Result 'B' (acclimatised to home base) or Result 'D' (acclimatised to departure location)
            if acclimatisationStatus.shouldBeAcclimatised && acclimatisationStatus.reason.contains("Result B") {
                // Result 'B': User is acclimatised to home base time zone
                activeFactors.append(ActiveFactor(
                    title: "Acclimatisation",
                    description: "Crew acclimatised to home base time zone",
                    details: "Time zone difference: \(factors.timeZoneDifference)h from home base, \(elapsedTimeText)",
                    impact: "Use home base local time for FDP calculation",
                    impactType: .base,
                    isActive: true,
                    calculationDetails: "Acclimatisation determined by UK CAA Table 1: Time zone difference \(factors.timeZoneDifference)h, elapsed time \(String(format: "%.1f", factors.elapsedTimeHours))h since departure from home base",
                    regulatoryBasis: "UK CAA Table 1: Acclimatisation Status Determination",
                    factorValue: "Result B: Acclimatised to home base time zone",
                    beforeAfter: ("Table 3 limits", "Table 2 limits with home base local time"),
                    priority: 1,
                    dependencies: ["Time zone difference", "Elapsed time from home base"]
                ))
            } else {
                // Result 'D': User is acclimatised to current departure location
                activeFactors.append(ActiveFactor(
                    title: "Acclimatisation",
                    description: "Crew acclimatised to departure location",
                    details: "Time zone difference: \(factors.timeZoneDifference)h from home base, \(elapsedTimeText)",
                    impact: "Extended duty limits apply",
                    impactType: .extension,
                    isActive: true,
                    calculationDetails: "Acclimatisation determined by UK CAA Table 1: Time zone difference \(factors.timeZoneDifference)h, elapsed time \(String(format: "%.1f", factors.elapsedTimeHours))h since departure from home base",
                    regulatoryBasis: "UK CAA Table 1: Acclimatisation Status Determination",
                    factorValue: "Result D: Acclimatised to departure location",
                    beforeAfter: ("Table 3 limits", "Table 2 limits"),
                    priority: 1,
                    dependencies: ["Time zone difference", "Elapsed time from home base"]
                ))
            }
        } else {
            // User is not acclimatised to current departure location - show orange with reduction
            if acclimatisationStatus.reason.contains("unknown acclimatisation state") {
                // Result 'X': Unknown acclimatisation state
                activeFactors.append(ActiveFactor(
                    title: "Acclimatisation",
                    description: "Unknown acclimatisation state (X)",
                    details: "Time zone difference: \(factors.timeZoneDifference)h from home base, \(elapsedTimeText)",
                    impact: "Reduced duty limits apply (unknown state)",
                    impactType: .reduction,
                    isActive: true,
                    calculationDetails: "Acclimatisation determined by UK CAA Table 1: Time zone difference \(factors.timeZoneDifference)h, elapsed time \(String(format: "%.1f", factors.elapsedTimeHours))h since departure from home base",
                    regulatoryBasis: "UK CAA Table 1: Acclimatisation Status Determination",
                    factorValue: "Result X: Unknown acclimatisation state",
                    beforeAfter: ("Table 2 limits", "Table 3 limits"),
                    priority: 1,
                    dependencies: ["Time zone difference", "Elapsed time from home base"]
                ))
            } else if acclimatisationStatus.shouldBeAcclimatised {
                // This case should not occur with corrected logic - Result 'B' is now handled above
                activeFactors.append(ActiveFactor(
                    title: "Acclimatisation",
                    description: "Crew not acclimatised",
                    details: "Time zone difference: \(factors.timeZoneDifference)h from home base, \(elapsedTimeText)",
                    impact: "Reduced duty limits apply",
                    impactType: .reduction,
                    isActive: true,
                    calculationDetails: "Acclimatisation determined by UK CAA Table 1: Time zone difference \(factors.timeZoneDifference)h, elapsed time \(String(format: "%.1f", factors.elapsedTimeHours))h since departure from home base",
                    regulatoryBasis: "UK CAA Table 1: Acclimatisation Status Determination",
                    factorValue: "Result A: Not acclimatised",
                    beforeAfter: ("Table 2 limits", "Table 3 limits"),
                    priority: 1,
                    dependencies: ["Time zone difference", "Elapsed time from home base"]
                ))
            } else {
                // This should not occur with corrected Table 1 logic (no Result 'A')
                activeFactors.append(ActiveFactor(
                    title: "Acclimatisation",
                    description: "Crew not acclimatised",
                    details: "Time zone difference: \(factors.timeZoneDifference)h from home base, \(elapsedTimeText)",
                    impact: "Reduced duty limits apply",
                    impactType: .reduction,
                    isActive: true,
                    calculationDetails: "Acclimatisation determined by UK CAA Table 1: Time zone difference \(factors.timeZoneDifference)h, elapsed time \(String(format: "%.1f", factors.elapsedTimeHours))h since departure from home base",
                    regulatoryBasis: "UK CAA Table 1: Acclimatisation Status Determination",
                    factorValue: "Result A: Not acclimatised",
                    beforeAfter: ("Table 2 limits", "Table 3 limits"),
                    priority: 1,
                    dependencies: ["Time zone difference", "Elapsed time from home base"]
                ))
            }
        }
        
        // 2. Report Time Factor (second thing we check - respect Table 1 outcome B/D/X)
        let sectorText = factors.numberOfSectors == 1 ? "sector" : "sectors"
        let accl = determineAcclimatisationStatus(
            timeZoneDifference: factors.timeZoneDifference,
            elapsedTimeHours: factors.elapsedTimeHours,
            isFirstSector: factors.isFirstSector,
            homeBase: homeBase,
            departure: departure
        )
        // Fix: Check the reason string to determine which result we have, since both B and D have isAcclimatised = true
        let table1Result: String = accl.reason.contains("Result D") ? "D" : (accl.reason.contains("Result B") ? "B" : "X")
        
        let reportTimeLimit: Double
        let localTime: String
        let locationText: String
        switch table1Result {
        case "B":
            localTime = TimeUtilities.getLocalTime(for: factors.startTime, airportCode: homeBase)
            locationText = "home base"
            reportTimeLimit = RegulatoryTableLookup.lookupFDPAcclimatised(reportTime: localTime, sectors: factors.numberOfSectors)
        case "D":
            localTime = TimeUtilities.getLocalTime(for: factors.startTime, airportCode: departure)
            locationText = "departure"
            reportTimeLimit = RegulatoryTableLookup.lookupFDPAcclimatised(reportTime: localTime, sectors: factors.numberOfSectors)
        default:
            localTime = TimeUtilities.getLocalTime(for: factors.startTime, airportCode: homeBase)
            locationText = "home base"
            reportTimeLimit = RegulatoryTableLookup.lookupFDPUnknownAcclimatised(sectors: factors.numberOfSectors)
        }
        
        // Only show Report Time factor when using Table 2 (Results B or D)
        // When result is 'X', we use Table 3 and don't show local time considerations
        if table1Result != "X" {
            activeFactors.append(ActiveFactor(
                title: "Report Time",
                description: "Report time \(factors.startTime) → Local \(localTime) at \(locationText)",
                details: "\(factors.numberOfSectors) \(sectorText)",
                impact: "Max FDP: \(maxFDP != nil ? TimeUtilities.formatHoursAndMinutes(maxFDP!) : String(format: "%.1f", reportTimeLimit) + "h")",
                impactType: .base,
                isActive: true,
                calculationDetails: "Base FDP limit determined from UK CAA Table 2 using local report time \(localTime) at \(locationText) for \(factors.numberOfSectors) \(sectorText)",
                regulatoryBasis: "UK CAA Table 2: Acclimatised Duty Limits",
                factorValue: "Report time \(factors.startTime) → Local \(localTime) at \(locationText)",
                beforeAfter: nil,
                priority: 2,
                dependencies: ["Acclimatisation status", "Number of sectors"]
            ))
        }
        
        // Early start information is redundant - already factored into base FDP calculation from report time
        
        // 3. Augmented Crew Factor (checked when 3+ crew detected)
        if factors.hasAugmentedCrew && factors.numberOfAdditionalPilots > 0 {
            let pilotText = factors.numberOfAdditionalPilots == 1 ? "1 additional pilot" : "\(factors.numberOfAdditionalPilots) additional pilots"
            let maxLimit = factors.numberOfAdditionalPilots == 1 ? "17h" : "18h"
            
            activeFactors.append(ActiveFactor(
                title: "Augmented Crew",
                description: pilotText,
                details: "Additional pilots on board",
                impact: "Extended to maximum \(maxLimit) duty time",
                impactType: .extension,
                isActive: true,
                calculationDetails: "Augmented crew detected: \(factors.numberOfAdditionalPilots) additional pilot\(factors.numberOfAdditionalPilots == 1 ? "" : "s") on board. Maximum duty limit extended from base limit to \(maxLimit) based on crew size.",
                regulatoryBasis: "UK CAA Regulations: Augmented Crew Operations (CAP 371)",
                factorValue: "\(factors.numberOfAdditionalPilots) additional pilot\(factors.numberOfAdditionalPilots == 1 ? "" : "s")",
                beforeAfter: ("Base FDP limit", "\(maxLimit) maximum"),
                priority: 3,
                dependencies: ["Base FDP limit", "Rest facility type"]
            ))
        }
        
        // 4. In-Flight Rest Factor (selected by user when augmented crew)
        if factors.hasInFlightRest {
            let dutyLimit: String
            if let calculatedFDP = maxFDP {
                // Use the actual calculated FDP value
                dutyLimit = TimeUtilities.formatHoursAndMinutes(calculatedFDP)
            } else {
                // Fallback to hardcoded values if no calculated FDP available
                // Use the correct values from regulatory tables for augmented crew scenarios
                if factors.hasAugmentedCrew && factors.numberOfAdditionalPilots > 0 {
                    // Augmented crew with in-flight rest
                    switch factors.restFacilityType {
                    case .class1:
                        dutyLimit = factors.numberOfAdditionalPilots == 1 ? "16h" : "17h"
                    case .class2:
                        dutyLimit = factors.numberOfAdditionalPilots == 1 ? "15h" : "16h"
                    case .class3:
                        dutyLimit = factors.numberOfAdditionalPilots == 1 ? "14h" : "15h"
                    case .none:
                        dutyLimit = "13h"
                    }
                } else {
                    // No augmented crew - use standard values
                    switch factors.restFacilityType {
                    case .class1:
                        dutyLimit = "16h"
                    case .class2:
                        dutyLimit = "15h"
                    case .class3:
                        dutyLimit = "14h"
                    case .none:
                        dutyLimit = "13h"
                    }
                }
            }
            
            activeFactors.append(ActiveFactor(
                title: "In-Flight Rest",
                description: factors.restFacilityType.rawValue,
                details: "Rest facility available during flight",
                impact: "Extended duty time to \(dutyLimit)",
                impactType: .extension,
                isActive: true,
                calculationDetails: "In-flight rest facility: \(factors.restFacilityType.rawValue). Duty time extended based on rest facility class and \(factors.hasAugmentedCrew ? "augmented crew" : "standard crew") configuration.",
                regulatoryBasis: "UK CAA Regulations: In-Flight Rest Facilities (CAP 371)",
                factorValue: "\(factors.restFacilityType.rawValue) with \(factors.hasAugmentedCrew ? "augmented crew" : "standard crew")",
                beforeAfter: ("Previous limit", dutyLimit),
                priority: 4,
                dependencies: ["Base FDP limit", "Augmented crew status", "Rest facility type"]
            ))
        }
        
        // 5. Split Duty Factor
        if factors.hasSplitDuty {
            activeFactors.append(ActiveFactor(
                title: "Split Duty",
                description: "Duty period split by rest period",
                details: "Rest period during duty day",
                impact: "Reduced duty limits apply",
                impactType: .reduction,
                isActive: true,
                calculationDetails: "Split duty detected: Duty period includes rest break. Duty limits reduced to ensure adequate recovery time during the duty period.",
                regulatoryBasis: "UK CAA Regulations: Split Duty Operations (CAP 371)",
                factorValue: "Split duty with rest break",
                beforeAfter: ("Previous limit", "Reduced limit"),
                priority: 5,
                dependencies: ["Base FDP limit", "Rest period duration"]
            ))
        }
        
        // 6. Consecutive Duty Days Factor
        if factors.consecutiveDutyDays >= 5 {
            activeFactors.append(ActiveFactor(
                title: "Consecutive Duty Days",
                description: "\(factors.consecutiveDutyDays) consecutive duty days",
                details: "Extended duty period",
                impact: "Reduced limits apply",
                impactType: .reduction,
                isActive: true,
                calculationDetails: "Consecutive duty days: \(factors.consecutiveDutyDays) consecutive days detected. Cumulative fatigue requires reduced duty limits for safety.",
                regulatoryBasis: "UK CAA Regulations: Consecutive Duty Days (CAP 371)",
                factorValue: "\(factors.consecutiveDutyDays) consecutive days",
                beforeAfter: ("Previous limit", "Reduced limit"),
                priority: 6,
                dependencies: ["Base FDP limit", "Previous duty days"]
            ))
        }
        
        // 7. Standby Duty Factor
        if factors.hasStandbyDuty {
            let standbyDescription: String
            let standbyImpact: String
            
            switch factors.standbyType {
            case .homeStandby:
                standbyDescription = "Home standby duty"
                standbyImpact = "FDP starts from report time with reduction based on standby duration"
            case .airportStandby:
                standbyDescription = "Airport standby duty"
                standbyImpact = "All standby time counts towards FDP"
            }
            
            activeFactors.append(ActiveFactor(
                title: "Standby Duty",
                description: standbyDescription,
                details: factors.standbyStartTime.isEmpty ? "Standby time not specified" : "Started at \(factors.standbyStartTime)",
                impact: standbyImpact,
                impactType: .modification,
                isActive: true,
                calculationDetails: "Standby duty: \(factors.standbyType.rawValue). \(factors.standbyType == .homeStandby ? "FDP starts from report time with reduction based on standby duration" : "All standby time counts toward FDP limits")",
                regulatoryBasis: "UK CAA Regulations: Standby Duty (CAP 371)",
                factorValue: "\(factors.standbyType.rawValue)\(factors.standbyStartTime.isEmpty ? "" : " from \(factors.standbyStartTime)")",
                beforeAfter: ("Standard FDP start", factors.standbyType == .homeStandby ? "FDP reduction based on standby duration" : "Immediate FDP start"),
                priority: 7,
                dependencies: ["Base FDP limit", "Standby start time"]
            ))
        }
        

        
        return activeFactors
    }
}

// MARK: - Date Formatters
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Time Utilities
struct TimeUtilities {
    static func parseTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        // Remove 'z' suffix if present (UTC indicator)
        let cleanTimeString = timeString.replacingOccurrences(of: "z", with: "")
        
        return formatter.date(from: cleanTimeString)
    }
    
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    static func calculateHoursBetween(_ startTime: String, _ endTime: String) -> Double {
        guard let start = parseTime(startTime),
              let end = parseTime(endTime) else {
            return 0.0
        }
        
        let _ = Calendar.current
        
        // Check if end time is earlier than start time (overnight period)
        if end < start {
            // Add 24 hours to the end time to handle overnight periods
            let adjustedEnd = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
            let components = Calendar.current.dateComponents([.hour, .minute], from: start, to: adjustedEnd)
            
            let hours = Double(components.hour ?? 0)
            let minutes = Double(components.minute ?? 0)
            
            return hours + (minutes / 60.0)
        } else {
            // Same day calculation
            let components = Calendar.current.dateComponents([.hour, .minute], from: start, to: end)
            
            let hours = Double(components.hour ?? 0)
            let minutes = Double(components.minute ?? 0)
            
            return hours + (minutes / 60.0)
        }
    }
    
    // New function to calculate elapsed time between two times with date information
    // FIXED: This function now correctly handles multi-day trips by properly calculating
    // the elapsed time between outbound and inbound sectors on different days.
    // 
    // Example: Trip 7165 (LHR-JFK-JFK-LHR)
    // - Outbound: Aug 5th, 15:35 report time (RelativeDepartureDay: 0)
    // - Inbound:  Aug 7th, 00:15 report time (RelativeDepartureDay: 2)
    // - Day difference: 2 days
    // - Correct elapsed time: From 15:35 on 5th to 00:15 on 7th
    //   = (24:00 - 15:35) + 24h + (00:15 - 00:00) = 8h 25m + 24h + 15m = 32h 40m
    // 
    // Previous bug: The function incorrectly added full days for each day difference,
    // leading to inflated elapsed time values and incorrect acclimatisation calculations.
    static func calculateElapsedTimeWithDates(startDate: String, startTime: String, endDate: String, endTime: String) -> Double {
        // For the specific case of LHR-JFK to JFK-LHR trip
        // startDate: "5 Tuesday", startTime: "15:35z" (LHR-JFK report)
        // endDate: "7 Thursday", endTime: "00:15z" (JFK-LHR report)
        
        print("DEBUG: calculateElapsedTimeWithDates - startDate: \(startDate), startTime: \(startTime), endDate: \(endDate), endTime: \(endTime)")
        
        // First, try to parse as ISO dates (yyyy-MM-dd format)
        if startDate.contains("-") && endDate.contains("-") {
            return calculateElapsedTimeWithISODates(startDate: startDate, startTime: startTime, endDate: endDate, endTime: endTime)
        }
        
        // Fallback to the old logic for relative day numbers
        return calculateElapsedTimeWithRelativeDays(startDate: startDate, startTime: startTime, endDate: endDate, endTime: endTime)
    }
    
    // New function to handle ISO date strings (yyyy-MM-dd format)
    private static func calculateElapsedTimeWithISODates(startDate: String, startTime: String, endDate: String, endTime: String) -> Double {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        guard let startDateObj = dateFormatter.date(from: startDate),
              let endDateObj = dateFormatter.date(from: endDate) else {
            print("DEBUG: calculateElapsedTimeWithISODates - Failed to parse ISO dates, using fallback")
            return calculateHoursBetween(startTime, endTime)
        }
        
        // Parse the times
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        guard let startTimeDate = timeFormatter.date(from: startTime),
              let endTimeDate = timeFormatter.date(from: endTime) else {
            print("DEBUG: calculateElapsedTimeWithISODates - Failed to parse times, using fallback")
            return calculateHoursBetween(startTime, endTime)
        }
        
        // Create full datetime objects using Calendar with UTC timezone
        let _ = Calendar.current
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        let startComponents = utcCalendar.dateComponents([.year, .month, .day], from: startDateObj)
        let endComponents = utcCalendar.dateComponents([.year, .month, .day], from: endDateObj)
        
        let startHour = utcCalendar.component(.hour, from: startTimeDate)
        let startMinute = utcCalendar.component(.minute, from: startTimeDate)
        let endHour = utcCalendar.component(.hour, from: endTimeDate)
        let endMinute = utcCalendar.component(.minute, from: endTimeDate)
        
        // Create full datetime objects in UTC
        guard let startDateTime = utcCalendar.date(from: DateComponents(year: startComponents.year, month: startComponents.month, day: startComponents.day, hour: startHour, minute: startMinute)),
              let endDateTime = utcCalendar.date(from: DateComponents(year: endComponents.year, month: endComponents.month, day: endComponents.day, hour: endHour, minute: endMinute)) else {
            print("DEBUG: calculateElapsedTimeWithISODates - Failed to create datetime objects, using fallback")
            return calculateHoursBetween(startTime, endTime)
        }
        
        // Calculate the time difference in hours
        let timeDifference = endDateTime.timeIntervalSince(startDateTime) / 3600.0
        
        print("DEBUG: calculateElapsedTimeWithISODates - startDateTime: \(startDateTime), endDateTime: \(endDateTime)")
        print("DEBUG: calculateElapsedTimeWithISODates - timeDifference: \(timeDifference) hours")
        
        return timeDifference
    }
    
    // Original function for relative day numbers (kept for backward compatibility)
    private static func calculateElapsedTimeWithRelativeDays(startDate: String, startTime: String, endDate: String, endTime: String) -> Double {
        // Parse the dates to get day numbers
        let startDay = extractDayNumber(from: startDate)
        let endDay = extractDayNumber(from: endDate)
        
        // Calculate the day difference
        let dayDifference = endDay - startDay
        
        // Validate day difference to prevent unrealistic values
        if dayDifference < 0 || dayDifference > 31 {
            print("DEBUG: calculateElapsedTimeWithRelativeDays - Invalid day difference: \(dayDifference) days. Using fallback calculation.")
            // Fallback to time-only calculation if day difference is invalid
            return calculateHoursBetween(startTime, endTime)
        }
        
        // Calculate the total elapsed time correctly
        let adjustedTimeDifference: Double
        if dayDifference == 0 {
            // Same day - just calculate time difference
            adjustedTimeDifference = calculateHoursBetween(startTime, endTime)
        } else {
            // Different days - need to calculate the actual elapsed time
            // Convert times to Date objects for proper calculation
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            
            guard let startTimeDate = timeFormatter.date(from: startTime),
                  let endTimeDate = timeFormatter.date(from: endTime) else {
                print("DEBUG: calculateElapsedTimeWithRelativeDays - Failed to parse times, using fallback")
                return calculateHoursBetween(startTime, endTime)
            }
            
            // Calculate the actual elapsed time by considering the full date range
            // We need to account for the fact that we're going from one time on one day
            // to another time on a different day
            
            if dayDifference == 1 {
                // Adjacent days: from start time on day 1 to end time on day 2
                // This is the time from start time to midnight (day 1) plus time from midnight to end time (day 2)
                let timeToMidnight = 24.0 - (startTimeDate.timeIntervalSince1970.truncatingRemainder(dividingBy: 86400) / 3600)
                let timeFromMidnight = endTimeDate.timeIntervalSince1970.truncatingRemainder(dividingBy: 86400) / 3600
                adjustedTimeDifference = timeToMidnight + timeFromMidnight
            } else {
                // Multiple days: we need to calculate the actual elapsed time
                // For simplicity and accuracy, let's use a different approach
                // Calculate the time from start time to midnight on start day
                let startHour = Double(Calendar.current.component(.hour, from: startTimeDate))
                let startMinute = Double(Calendar.current.component(.minute, from: startTimeDate))
                let timeToMidnight = 24.0 - startHour - (startMinute / 60.0)
                
                // Calculate the time from midnight to end time on end day
                let endHour = Double(Calendar.current.component(.hour, from: endTimeDate))
                let endMinute = Double(Calendar.current.component(.minute, from: endTimeDate))
                let timeFromMidnight = endHour + (endMinute / 60.0)
                
                // Add full days in between
                let fullDays = Double(dayDifference - 1)
                adjustedTimeDifference = timeToMidnight + (fullDays * 24.0) + timeFromMidnight
            }
        }
        
        print("DEBUG: calculateElapsedTimeWithRelativeDays - startDate: \(startDate), startTime: \(startTime), endDate: \(endDate), endTime: \(endTime)")
        print("DEBUG: calculateElapsedTimeWithRelativeDays - startDay: \(startDay), endDay: \(endDay), dayDifference: \(dayDifference)")
        print("DEBUG: calculateElapsedTimeWithRelativeDays - adjustedTimeDifference: \(adjustedTimeDifference)")
        
        return adjustedTimeDifference
    }
    
    private static func extractDayNumber(from dateString: String) -> Int {
        // Extract day number from strings like "5 Tuesday" or "7 Thursday"
        // Also handle formatted dates like "05/08/2025" or "07/08/2025"
        // And handle system short date format like "8/10/25" (M/d/yy)
        // And handle ISO format like "2025-08-05" (yyyy-MM-dd)
        
        print("DEBUG: extractDayNumber parsing: '\(dateString)'")
        
        // First try to parse as ISO format "2025-08-05" (yyyy-MM-dd)
        let isoComponents = dateString.components(separatedBy: "-")
        if isoComponents.count >= 3 {
            let dayString = isoComponents[2]
            if let day = Int(dayString) {
                print("DEBUG: extractDayNumber found day: \(day) from '\(dayString)' (ISO format)")
                return day
            }
        }
        
        // Then try to parse as "5 Tuesday" format
        let components = dateString.components(separatedBy: " ")
        if let dayString = components.first, let day = Int(dayString) {
            print("DEBUG: extractDayNumber found day: \(day) from '\(dayString)'")
            return day
        }
        
        // If that fails, try to parse as "05/08/2025" format (dd/MM/yyyy)
        let dateComponents = dateString.components(separatedBy: "/")
        if dateComponents.count >= 3 {
            if let dayString = dateComponents.first, let day = Int(dayString) {
                print("DEBUG: extractDayNumber found day: \(day) from '\(dayString)' (dd/MM/yyyy format)")
                return day
            }
        }
        
        // If that fails, try to parse as "10/08/2025" format (single digit day)
        if dateString.contains("/") {
            let parts = dateString.components(separatedBy: "/")
            if parts.count >= 3 {
                let dayString = parts[0]
                if let day = Int(dayString) {
                    print("DEBUG: extractDayNumber found day: \(day) from '\(dayString)' (single digit format)")
                    return day
                }
            }
        }
        
        // Handle system short date format like "8/10/25" (M/d/yy)
        // In this case, the first part is the month, second is day, third is year
        if dateString.contains("/") {
            let parts = dateString.components(separatedBy: "/")
            if parts.count >= 2 {
                // For "8/10/25" format, day is the second part
                let dayString = parts[1]
                if let day = Int(dayString) {
                    print("DEBUG: extractDayNumber found day: \(day) from '\(dayString)' (M/d/yy format)")
                    return day
                }
            }
        }
        
        print("DEBUG: extractDayNumber failed to parse date string: '\(dateString)' - returning 0")
        return 0
    }
    
    static func addHours(_ timeString: String, hours: Double) -> String {
        guard let time = parseTime(timeString) else {
            return timeString
        }
        
        let newTime = time.addingTimeInterval(hours * 3600)
        return formatTime(newTime)
    }
    
    static func formatHoursAndMinutes(_ decimalHours: Double) -> String {
        let totalMinutes = Int(decimalHours * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours == 0 {
            return "\(minutes)m"
        } else if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    // MARK: - Time Zone Utilities
    
    // MARK: - British Airways Destinations Timezone Database
    // Generated on: 2025-08-08 23:18:14
    // This database contains all British Airways destinations with their corresponding timezones
    
    static let baDestinations: [(String, String)] = [
        ("ABZ", "Europe/London"),  // ABZ
        ("ABV", "Africa/Lagos"),  // ABV
        ("ACC", "Africa/Accra"),  // ACC
        ("AKL", "Pacific/Auckland"),  // AKL
        ("AMM", "Asia/Amman"),  // AMM
        ("AMS", "Europe/Amsterdam"),  // AMS
        ("ANU", "America/Antigua"),  // ANU
        ("ATH", "Europe/Athens"),  // ATH
        ("AGP", "Europe/Madrid"),  // AGP
        ("ATL", "America/New_York"),  // ATL
        ("AUS", "America/Chicago"),  // AUS
        ("AUH", "Asia/Dubai"),  // AUH
        ("BAH", "Asia/Bahrain"),  // BAH
        ("BCN", "Europe/Madrid"),  // BCN
        ("BER", "Europe/Berlin"),  // BER
        ("BEY", "Asia/Beirut"),  // BEY
        ("BFS", "Europe/London"),  // BFS
        ("BGI", "America/Barbados"),  // BGI
        ("BHX", "Europe/London"),  // BHX
        ("BKK", "Asia/Bangkok"),  // BKK
        ("BLR", "Asia/Kolkata"),  // BLR
        ("BNE", "Australia/Brisbane"),  // BNE
        ("BOG", "America/Bogota"),  // BOG
        ("BOM", "Asia/Kolkata"),  // BOM
        ("BOS", "America/New_York"),  // BOS
        ("BRS", "Europe/London"),  // BRS
        ("BWI", "America/New_York"),  // BWI
        ("BUD", "Europe/Budapest"),  // BUD
        ("BDA", "Atlantic/Bermuda"),  // BDA
        ("BES", "Europe/Paris"),  // BES
        ("BIO", "Europe/Madrid"),  // BIO
        ("BOD", "Europe/Paris"),  // BOD
        ("BRQ", "Europe/Prague"),  // BRQ
        ("CAI", "Africa/Cairo"),  // CAI
        ("CAN", "Asia/Shanghai"),  // CAN
        ("CCU", "Asia/Kolkata"),  // CCU
        ("CDG", "Europe/Paris"),  // CDG
        ("CGK", "Asia/Jakarta"),  // CGK
        ("CLJ", "Europe/Bucharest"),  // CLJ
        ("CPH", "Europe/Copenhagen"),  // CPH
        ("CPT", "Africa/Johannesburg"),  // CPT
        ("CRA", "Europe/Bucharest"),  // CRA
        ("CUN", "America/Cancun"),  // CUN
        ("CVG", "America/New_York"),  // CVG
        ("DAR", "Africa/Dar_es_Salaam"),  // DAR
        ("DEL", "Asia/Kolkata"),  // DEL
        ("DEN", "America/Denver"),  // DEN
        ("DFW", "America/Chicago"),  // DFW
        ("GIG", "America/Sao_Paulo"),  // GIG
        ("DOH", "Asia/Qatar"),  // DOH
        ("DUB", "Europe/Dublin"),  // DUB
        ("DUR", "Africa/Johannesburg"),  // DUR
        ("DXB", "Asia/Dubai"),  // DXB
        ("DUS", "Europe/Berlin"),  // DUS
        ("EDI", "Europe/London"),  // EDI
        ("EWR", "America/New_York"),  // EWR
        ("EIN", "Europe/Amsterdam"),  // EIN
        ("EZE", "America/Argentina/Buenos_Aires"),  // EZE
        ("FCO", "Europe/Rome"),  // FCO
        ("FRA", "Europe/Berlin"),  // FRA
        ("FAO", "Europe/Lisbon"),  // FAO
        ("FMM", "Europe/Berlin"),  // FMM
        ("FMO", "Europe/Berlin"),  // FMO
        ("FSC", "Europe/Paris"),  // FSC
        ("GCM", "America/Cayman"),  // GCM
        ("GIG", "America/Sao_Paulo"),  // GIG
        ("GLA", "Europe/London"),  // GLA
        ("GND", "America/Grenada"),  // GND
        ("GOA", "Europe/Rome"),  // GOA
        ("GOT", "Europe/Stockholm"),  // GOT
        ("GRU", "America/Sao_Paulo"),  // GRU
        ("GVA", "Europe/Zurich"),  // GVA
        ("HAM", "Europe/Berlin"),  // HAM
        ("HEL", "Europe/Helsinki"),  // HEL
        ("HHN", "Europe/Berlin"),  // HHN
        ("HKG", "Asia/Hong_Kong"),  // HKG
        ("HND", "Asia/Tokyo"),  // HND
        ("HYD", "Asia/Kolkata"),  // HYD
        ("IAD", "America/New_York"),  // IAD
        ("IAH", "America/Chicago"),  // IAH
        ("ICN", "Asia/Seoul"),  // ICN
        ("IST", "Europe/Istanbul"),  // IST
        ("ISB", "Asia/Karachi"),  // ISB
        ("JFK", "America/New_York"),  // JFK
        ("JSI", "Europe/Athens"),  // JSI
        ("JTR", "Europe/Athens"),  // JTR
        ("JED", "Asia/Riyadh"),  // JED
        ("JNB", "Africa/Johannesburg"),  // JNB
        ("KGL", "Africa/Kigali"),  // KGL
        ("KGS", "Europe/Athens"),  // KGS
        ("KIN", "America/Jamaica"),  // KIN
        ("KSC", "Europe/Bratislava"),  // KSC
        ("KUN", "Europe/Vilnius"),  // KUN
        ("KUL", "Asia/Kuala_Lumpur"),  // KUL
        ("KWI", "Asia/Kuwait"),  // KWI
        ("LAD", "Africa/Luanda"),  // LAD
        ("LAS", "America/Los_Angeles"),  // LAS
        ("LAX", "America/Los_Angeles"),  // LAX
        ("LCY", "Europe/London"),  // LCY
        ("LGW", "Europe/London"),  // LGW
        ("LHR", "Europe/London"),  // LHR
        ("LIM", "America/Lima"),  // LIM
        ("LIS", "Europe/Lisbon"),  // LIS
        ("LJU", "Europe/Ljubljana"),  // LJU
        ("LOS", "Africa/Lagos"),  // LOS
        ("LPA", "Atlantic/Canary"),  // LPA
        ("MAA", "Asia/Kolkata"),  // MAA
        ("MAD", "Europe/Madrid"),  // MAD
        ("MAN", "Europe/London"),  // MAN
        ("MEX", "America/Mexico_City"),  // MEX
        ("MBX", "Europe/Ljubljana"),  // MBX
        ("MBJ", "America/Jamaica"),  // MBJ
        ("MCO", "America/New_York"),  // MCO
        ("MCT", "Asia/Muscat"),  // MCT
        ("MEL", "Australia/Melbourne"),  // MEL
        ("MIA", "America/New_York"),  // MIA
        ("MLE", "Indian/Maldives"),  // MLE
        ("MRU", "Indian/Mauritius"),  // MRU
        ("MUC", "Europe/Berlin"),  // MUC
        ("MXP", "Europe/Rome"),  // MXP
        ("MSY", "America/Chicago"),  // MSY
        ("NAS", "America/Nassau"),  // NAS
        ("NCE", "Europe/Paris"),  // NCE
        ("NRN", "Europe/Berlin"),  // NRN
        ("NUE", "Europe/Berlin"),  // NUE
        ("NBO", "Africa/Nairobi"),  // NBO
        ("NCL", "Europe/London"),  // NCL
        ("NRT", "Asia/Tokyo"),  // NRT
        ("ORD", "America/Chicago"),  // ORD
        ("ORY", "Europe/Paris"),  // ORY
        ("OSR", "Europe/Prague"),  // OSR
        ("OSL", "Europe/Oslo"),  // OSL
        ("PDX", "America/Los_Angeles"),  // PDX
        ("PEK", "Asia/Shanghai"),  // PEK
        ("PGF", "Europe/Paris"),  // PGF
        ("PHL", "America/New_York"),  // PHL
        ("PER", "Australia/Perth"),  // PER
        ("PHX", "America/Phoenix"),  // PHX
        ("PIT", "America/New_York"),  // PIT
        ("PMI", "Europe/Madrid"),  // PMI
        ("PMO", "Europe/Rome"),  // PMO
        ("POS", "America/Port_of_Spain"),  // POS
        ("PRG", "Europe/Prague"),  // PRG
        ("PSA", "Europe/Rome"),  // PSA
        ("PUJ", "America/Santo_Domingo"),  // PUJ
        ("PVG", "Asia/Shanghai"),  // PVG
        ("PUF", "Europe/Paris"),  // PUF
        ("RUH", "Asia/Riyadh"),  // RUH
        ("RNS", "Europe/Paris"),  // RNS
        ("RZE", "Europe/Warsaw"),  // RZE
        ("SCL", "America/Santiago"),  // SCL
        ("SEA", "America/Los_Angeles"),  // SEA
        ("SFO", "America/Los_Angeles"),  // SFO
        ("SAN", "America/Los_Angeles"),  // SAN
        ("SIN", "Asia/Singapore"),  // SIN
        ("SKG", "Europe/Athens"),  // SKG
        ("SKP", "Europe/Skopje"),  // SKP
        ("SOF", "Europe/Sofia"),  // SOF
        ("SPU", "Europe/Zagreb"),  // SPU
        ("SSA", "America/Bahia"),  // SSA
        ("SOU", "Europe/London"),  // SOU
        ("STN", "Europe/London"),  // STN
        ("STO", "Europe/Stockholm"),  // STO
        ("STT", "America/St_Thomas"),  // STT
        ("STR", "Europe/Berlin"),  // STR
        ("SUF", "Europe/Rome"),  // SUF
        ("SVG", "Europe/Oslo"),  // SVG
        ("SYD", "Australia/Sydney"),  // SYD
        ("TLV", "Asia/Jerusalem"),  // TLV
        ("TAT", "Europe/Bratislava"),  // TAT
        ("TFN", "Atlantic/Canary"),  // TFN
        ("TOS", "Europe/Oslo"),  // TOS
        ("TPA", "America/New_York"),  // TPA
        ("TPS", "Europe/Rome"),  // TPS
        ("TUF", "Europe/Paris"),  // TUF
        ("TUN", "Africa/Tunis"),  // TUN
        ("UVF", "America/St_Lucia"),  // UVF
        ("VCE", "Europe/Rome"),  // VCE
        ("VIE", "Europe/Vienna"),  // VIE
        ("VLC", "Europe/Madrid"),  // VLC
        ("VNO", "Europe/Vilnius"),  // VNO
        ("WAW", "Europe/Warsaw"),  // WAW
        ("WRO", "Europe/Warsaw"),  // WRO
        ("XCR", "Europe/Paris"),  // XCR
        ("YUL", "America/Toronto"),  // YUL
        ("YVR", "America/Vancouver"),  // YVR
        ("YYZ", "America/Toronto"),  // YYZ
        ("ZAD", "Europe/Zagreb"),  // ZAD
        ("ZAG", "Europe/Zagreb"),  // ZAG
        ("ZRH", "Europe/Zurich")  // ZRH
    ]
    
    static func getTimeZoneDifference(from homeBase: String, to destination: String) -> Int {
        print("DEBUG: getTimeZoneDifference called with '\(homeBase)' to '\(destination)'")
        
        let homeBaseUpper = homeBase.uppercased()
        let destinationUpper = destination.uppercased()
        
        print("DEBUG: Looking for '\(homeBaseUpper)' and '\(destinationUpper)' in BA destinations list")
        
        guard let homeTimeZone = baDestinations.first(where: { $0.0 == homeBaseUpper })?.1,
              let destTimeZone = baDestinations.first(where: { $0.0 == destinationUpper })?.1,
              let homeTZ = TimeZone(identifier: homeTimeZone),
              let destTZ = TimeZone(identifier: destTimeZone) else {
            print("DEBUG: Failed to find airports or time zones")
            print("DEBUG: homeBase '\(homeBaseUpper)' -> timeZone: \(baDestinations.first(where: { $0.0 == homeBaseUpper })?.1 ?? "NOT FOUND")")
            print("DEBUG: destination '\(destinationUpper)' -> timeZone: \(baDestinations.first(where: { $0.0 == destinationUpper })?.1 ?? "NOT FOUND")")
            return 0
        }
        
        print("DEBUG: Found time zones - home: \(homeTimeZone), dest: \(destTimeZone)")
        
        let now = Date()
        let homeOffset = homeTZ.secondsFromGMT(for: now)
        let destOffset = destTZ.secondsFromGMT(for: now)
        let differenceSeconds = destOffset - homeOffset
        
        let result = Int(differenceSeconds / 3600)
        let absoluteResult = abs(result)
        print("DEBUG: Calculated time zone difference: \(result) hours (absolute: \(absoluteResult) hours)")
        
        return absoluteResult
    }
    
    static func getLocalTime(for airportCode: String) -> String {
        guard let timeZoneString = baDestinations.first(where: { $0.0 == airportCode.uppercased() })?.1,
              let timeZone = TimeZone(identifier: timeZoneString) else {
            return "Unknown"
        }
        
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    // Get time zone offset from UTC for a given airport code
    static func getTimeZoneOffsetFromUTC(for airportCode: String) -> Int {
        guard let timeZoneString = baDestinations.first(where: { $0.0 == airportCode.uppercased() })?.1,
              let timeZone = TimeZone(identifier: timeZoneString) else {
            return 0 // Default to UTC if airport not found
        }
        
        let now = Date()
        let offsetSeconds = timeZone.secondsFromGMT(for: now)
        return offsetSeconds / 3600 // Convert seconds to hours
    }
    
    // Convert UTC time to local time using time zone difference
    static func getLocalTime(for utcTime: String, timeZoneDifference: Int) -> String {
        guard let utcDate = parseTime(utcTime) else {
            return utcTime
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: utcDate)
        let minute = calendar.component(.minute, from: utcDate)
        
        // Add time zone difference to get local time
        let localHour = (hour + timeZoneDifference + 24) % 24 // Ensure 0-23 range
        let localMinute = minute
        
        return String(format: "%02d:%02d", localHour, localMinute)
    }
    
    // Convert UTC time to local time using airport code
    static func getLocalTime(for utcTime: String, airportCode: String) -> String {
        guard let utcDate = parseTime(utcTime) else {
            return utcTime
        }
        
        let timeZoneOffset = getTimeZoneOffsetFromUTC(for: airportCode)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: utcDate)
        let minute = calendar.component(.minute, from: utcDate)
        
        // Add time zone offset to get local time
        let localHour = (hour + timeZoneOffset + 24) % 24 // Ensure 0-23 range
        let localMinute = minute
        
        return String(format: "%02d:%02d", localHour, localMinute)
    }
}

// MARK: - Active Factors
struct ActiveFactor {
    let title: String
    let description: String
    let details: String
    let impact: String
    let impactType: ImpactType
    let isActive: Bool
    
    // Enhanced properties for better user understanding
    let calculationDetails: String // How this factor was calculated
    let regulatoryBasis: String // Which regulation this factor is based on
    let factorValue: String // The actual value that triggered this factor
    let beforeAfter: (before: String, after: String)? // Before/after values if applicable
    let priority: Int // Calculation priority order
    let dependencies: [String] // Other factors this depends on
}

enum ImpactType: String {
    case base = "base"
    case `extension` = "extension"
    case reduction = "reduction"
    case modification = "modification"
    
    var color: Color {
        switch self {
        case .base:
            return .blue
        case .extension:
            return .green
        case .reduction:
            return .orange
        case .modification:
            return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .base:
            return "clock"
        case .extension:
            return "plus.circle"
        case .reduction:
            return "minus.circle"
        case .modification:
            return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Validation
struct ValidationRules {
    static func isValidTimeFormat(_ time: String) -> Bool {
        // Remove 'z' suffix if present for validation
        let cleanTime = time.replacingOccurrences(of: "z", with: "")
        let timeRegex = "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$"
        return cleanTime.range(of: timeRegex, options: .regularExpression) != nil
    }
    
    static func isValidFlightNumber(_ flightNumber: String) -> Bool {
        // Accept formats like: BA179, BA 179, XBA 197, BA 2205, BA2205A
        let trimmed = flightNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let pattern = "^[A-Z]{2,3}\\s?\\d{1,4}[A-Z]?$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }
    
    static func isValidAirportCode(_ code: String) -> Bool {
        // Support both IATA (3 letters) and ICAO (4 letters) airport codes
        return (code.count == 3 || code.count == 4) && code.uppercased() == code
    }
} 