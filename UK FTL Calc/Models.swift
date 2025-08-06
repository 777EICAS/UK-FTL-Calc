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
    let id = UUID()
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
    
    init(flightNumber: String, departure: String, arrival: String, reportTime: String, takeoffTime: String, landingTime: String, dutyEndTime: String, flightTime: Double, dutyTime: Double, pilotType: PilotType, date: String = "", pilotCount: Int = 1) {
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
            return "Standby at home or suitable accommodation. First 2 hours don't count towards FDP. Max 16h total duty."
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
    var isNightDuty: Bool = false
    var hasSplitDuty: Bool = false
    var hasStandbyDuty: Bool = false
    var standbyType: StandbyType = .homeStandby
    var standbyTypeSelected: Bool = false // Track if user has selected a standby type
    var standbyStartTime: String = "" // Z time when standby started
    var isAcclimatised: Bool = false
    var timeZoneDifference: Int = 0 // Hours of time zone difference
    var consecutiveDutyDays: Int = 1
    var timeZoneChanges: Int = 0
    var numberOfSectors: Int = 1 // Number of flight sectors for FDP calculation
    var homeBase: String = "LHR" // Default home base
    var secondHomeBase: String = "" // Optional second home base
    
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
    
    // Determine acclimatisation status based on time zone difference
    var acclimatisationStatus: AcclimatisationStatus {
        if timeZoneDifference < 4 {
            return .alwaysAcclimatised
        } else if timeZoneDifference >= 4 && timeZoneDifference <= 6 {
            return .requires3Nights
        } else if timeZoneDifference >= 7 {
            return .requires4Nights
        } else {
            return .alwaysAcclimatised
        }
    }
    
    // Check if crew should be considered acclimatised based on current setting and time zone difference
    var shouldBeAcclimatised: Bool {
        if timeZoneDifference < 4 {
            return isAcclimatised // Allow manual control even for < 4 hours
        } else {
            return isAcclimatised // User must manually select for 4+ hours
        }
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
    static let minRestPeriod = 12.0 // hours minimum
    static let minRestPeriodReduced = 10.0 // hours (with specific conditions)
    
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
        // When acclimatised: use departure location's local time
        // When not acclimatised: use home base local time
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
        
        // Convert time ranges to minutes for easier comparison
        if numberOfSectors == 1 || numberOfSectors == 2 {
            // 1-2 Sectors
            if localTimeMinutes >= 360 && localTimeMinutes <= 809 { // 06:00-13:29
                print("DEBUG FDP: Selected time window 06:00-13:29 -> 13.0 hours")
                return 13.0 // 13:00
            } else if localTimeMinutes >= 810 && localTimeMinutes <= 819 { // 13:30-13:59
                return 12.75 // 12:45
            } else if localTimeMinutes >= 840 && localTimeMinutes <= 849 { // 14:00-14:29
                return 12.5 // 12:30
            } else if localTimeMinutes >= 870 && localTimeMinutes <= 879 { // 14:30-14:59
                return 12.25 // 12:15
            } else if localTimeMinutes >= 900 && localTimeMinutes <= 909 { // 15:00-15:29
                return 12.0 // 12:00
            } else if localTimeMinutes >= 930 && localTimeMinutes <= 939 { // 15:30-15:59
                return 11.75 // 11:45
            } else if localTimeMinutes >= 960 && localTimeMinutes <= 989 { // 16:00-16:29
                return 11.5 // 11:30
            } else if localTimeMinutes >= 990 && localTimeMinutes <= 1019 { // 16:30-16:59
                print("DEBUG FDP: Selected time window 16:30-16:59 -> 11.25 hours")
                return 11.25 // 11:15
            } else if localTimeMinutes >= 1020 && localTimeMinutes <= 299 { // 17:00-04:59
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
            } else if localTimeMinutes >= 810 && localTimeMinutes <= 819 { // 13:30-13:59
                return 12.25 // 12:15
            } else if localTimeMinutes >= 840 && localTimeMinutes <= 849 { // 14:00-14:29
                return 12.0 // 12:00
            } else if localTimeMinutes >= 870 && localTimeMinutes <= 879 { // 14:30-14:59
                return 11.75 // 11:45
            } else if localTimeMinutes >= 900 && localTimeMinutes <= 909 { // 15:00-15:29
                return 11.5 // 11:30
            } else if localTimeMinutes >= 930 && localTimeMinutes <= 939 { // 15:30-15:59
                return 11.25 // 11:15
            } else if localTimeMinutes >= 960 && localTimeMinutes <= 989 { // 16:00-16:29
                return 11.0 // 11:00
            } else if localTimeMinutes >= 990 && localTimeMinutes <= 1019 { // 16:30-16:59
                return 10.75 // 10:45
            } else if localTimeMinutes >= 1020 && localTimeMinutes <= 299 { // 17:00-04:59
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
            } else if localTimeMinutes >= 810 && localTimeMinutes <= 819 { // 13:30-13:59
                return 11.75 // 11:45
            } else if localTimeMinutes >= 840 && localTimeMinutes <= 849 { // 14:00-14:29
                return 11.5 // 11:30
            } else if localTimeMinutes >= 870 && localTimeMinutes <= 879 { // 14:30-14:59
                return 11.25 // 11:15
            } else if localTimeMinutes >= 900 && localTimeMinutes <= 909 { // 15:00-15:29
                return 11.0 // 11:00
            } else if localTimeMinutes >= 930 && localTimeMinutes <= 939 { // 15:30-15:59
                return 10.75 // 10:45
            } else if localTimeMinutes >= 960 && localTimeMinutes <= 989 { // 16:00-16:29
                return 10.5 // 10:30
            } else if localTimeMinutes >= 990 && localTimeMinutes <= 1019 { // 16:30-16:59
                return 10.25 // 10:15
            } else if localTimeMinutes >= 1020 && localTimeMinutes <= 299 { // 17:00-04:59
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
            } else if localTimeMinutes >= 810 && localTimeMinutes <= 819 { // 13:30-13:59
                return 11.25 // 11:15 (5 sectors)
            } else if localTimeMinutes >= 840 && localTimeMinutes <= 849 { // 14:00-14:29
                return 11.0 // 11:00 (5 sectors)
            } else if localTimeMinutes >= 870 && localTimeMinutes <= 879 { // 14:30-14:59
                return 10.75 // 10:45 (5 sectors)
            } else if localTimeMinutes >= 900 && localTimeMinutes <= 909 { // 15:00-15:29
                return 10.5 // 10:30 (5 sectors)
            } else if localTimeMinutes >= 930 && localTimeMinutes <= 939 { // 15:30-15:59
                return 10.25 // 10:15 (5 sectors)
            } else if localTimeMinutes >= 960 && localTimeMinutes <= 989 { // 16:00-16:29
                return 10.0 // 10:00 (5 sectors)
            } else if localTimeMinutes >= 990 && localTimeMinutes <= 1019 { // 16:30-16:59
                return 9.75 // 09:45 (5 sectors)
            } else if localTimeMinutes >= 1020 && localTimeMinutes <= 299 { // 17:00-04:59
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
        
        // Early start restrictions (before 06:00) - only apply if not augmented crew
        if factors.isEarlyStart && !factors.hasAugmentedCrew {
            limit = min(limit, 11.0) // Reduced to 11 hours for early starts
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
                limit = min(limit, 16.0) // Home standby: maximum 16 hours total duty (standby + FDP) - but more restrictive limits still apply
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
            if factors.shouldBeAcclimatised {
                // For acclimatised crew, extended limits apply
                // Based on UK CAA EASA FTL Regulations (https://www.caa.co.uk/publication/download/17414)
                if factors.timeZoneDifference < 4 {
                    // Less than 4 hours: Always acclimatised, standard limits apply
                    // No additional extension needed as this is the baseline
                } else if factors.timeZoneDifference >= 4 && factors.timeZoneDifference <= 6 {
                    // 4-6 hours: Extended limits apply when acclimatised
                    limit = min(limit, 14.0) // Extended to 14 hours for acclimatised crew
                } else if factors.timeZoneDifference >= 7 {
                    // 7+ hours: Extended limits apply when acclimatised
                    limit = min(limit, 14.0) // Extended to 14 hours for acclimatised crew
                }
            } else {
                // Non-acclimatised crew for 4+ hour time zone differences
                // Reduced limits apply based on UK CAA regulations
                if factors.timeZoneDifference >= 4 && factors.timeZoneDifference <= 6 {
                    limit = min(limit, 12.0) // Reduced to 12 hours for non-acclimatised crew
                } else if factors.timeZoneDifference >= 7 {
                    limit = min(limit, 11.0) // Further reduced to 11 hours for large time zone differences
                }
            }
        } else {
            print("DEBUG: Augmented crew - acclimatization status does not affect augmented crew limits")
        }
        
        return limit
    }
    

    
    // Calculate required rest period - UK CAA Regulation 965/2012
    static func calculateRequiredRest(dutyTime: Double, factors: FTLFactors) -> Double {
        // UK CAA rule: Rest must be at least 12 hours OR at least as long as the preceding duty, whichever is greater
        var restPeriod = max(minRestPeriod, dutyTime)
        
        // Reduced rest conditions (10 hours) - only under specific circumstances
        if factors.hasReducedRest && dutyTime <= 10 {
            restPeriod = minRestPeriodReduced
        }
        
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
    
    // Get limit explanations
    static func getLimitExplanations(factors: FTLFactors, pilotType: PilotType, departure: String, arrival: String, homeBase: String) -> [String] {
        var explanations: [String] = []
        
        // Add report time-based FDP explanation (using local acclimatised time)
        let reportTimeLimit = calculateMaxFDPByReportTime(reportTime: factors.startTime, numberOfSectors: factors.numberOfSectors, departure: departure, arrival: arrival, isAcclimatised: factors.isAcclimatised, homeBase: homeBase)
        let sectorText = factors.numberOfSectors == 1 ? "sector" : "sectors"
        
        // Calculate local time based on acclimatisation status
        let relevantAirport = factors.isAcclimatised ? departure : homeBase
        let localTime = TimeUtilities.getLocalTime(for: factors.startTime, airportCode: relevantAirport)
        let locationText = factors.isAcclimatised ? "departure" : "home base"
        explanations.append("Report time \(factors.startTime) → Local \(localTime) at \(locationText) (\(factors.numberOfSectors) \(sectorText)): Base FDP limit \(String(format: "%.1f", reportTimeLimit))h")
        
        if factors.isEarlyStart {
            explanations.append("Early start (before 06:00): Reduced limits apply")
        }
        
        if factors.hasInFlightRest {
            let dutyLimit: String
            
            switch factors.restFacilityType {
            case .class1:
                dutyLimit = "16h"
            case .class2:
                dutyLimit = "16h"
            case .class3:
                dutyLimit = "15h"
            case .none:
                dutyLimit = "13h"
            }
            
            explanations.append("In-flight rest (\(factors.restFacilityType.rawValue)): Extended to \(dutyLimit) duty time")
        }
        
        if factors.hasAugmentedCrew && factors.numberOfAdditionalPilots > 0 {
            let pilotText = factors.numberOfAdditionalPilots == 1 ? "1 additional pilot" : "\(factors.numberOfAdditionalPilots) additional pilots"
            let maxLimit = factors.numberOfAdditionalPilots == 1 ? "17h" : "18h"
            explanations.append("Augmented crew (\(pilotText)): Extended to maximum \(maxLimit) based on rest facility type")
        }
        
        if factors.isNightDuty {
            explanations.append("Night duty: Reduced limits apply")
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
                explanations.append("Home standby: FDP starts 2 hours after standby start time. Maximum 16 hours total duty (standby + FDP). Commanders discretion only available if more restrictive limits apply, and can extend by maximum 2 hours (never beyond 16h).")
            case .airportStandby:
                explanations.append("Airport standby: FDP starts from standby start time. All standby time counts towards FDP. No maximum standby time limit.")
            }
        }
        
        // Acclimatisation explanations
        if factors.timeZoneDifference >= 4 {
            if factors.shouldBeAcclimatised {
                explanations.append("Acclimatised crew (\(factors.acclimatisationStatus.description)): Extended duty limits apply")
            } else {
                explanations.append("Non-acclimatised crew (\(factors.acclimatisationStatus.description)): Reduced duty limits apply")
            }
        } else if factors.timeZoneDifference > 0 {
            explanations.append("Time zone difference (\(factors.timeZoneDifference)h): Always acclimatised")
        }
        
        return explanations
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
        
        let calendar = Calendar.current
        
        // Check if end time is earlier than start time (overnight period)
        if end < start {
            // Add 24 hours to the end time to handle overnight periods
            let adjustedEnd = calendar.date(byAdding: .day, value: 1, to: end) ?? end
            let components = calendar.dateComponents([.hour, .minute], from: start, to: adjustedEnd)
            
            let hours = Double(components.hour ?? 0)
            let minutes = Double(components.minute ?? 0)
            
            return hours + (minutes / 60.0)
        } else {
            // Same day calculation
            let components = calendar.dateComponents([.hour, .minute], from: start, to: end)
            
            let hours = Double(components.hour ?? 0)
            let minutes = Double(components.minute ?? 0)
            
            return hours + (minutes / 60.0)
        }
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
    static func getTimeZoneDifference(from homeBase: String, to destination: String) -> Int {
        print("DEBUG: getTimeZoneDifference called with '\(homeBase)' to '\(destination)'")
        
        let airports = [
            // IATA codes
            ("LHR", "Europe/London"), ("LGW", "Europe/London"), ("STN", "Europe/London"),
            ("JFK", "America/New_York"), ("LAX", "America/Los_Angeles"), ("ORD", "America/Chicago"),
            ("DFW", "America/Chicago"), ("ATL", "America/New_York"), ("DEN", "America/Denver"),
            ("SFO", "America/Los_Angeles"), ("MIA", "America/New_York"), ("BOS", "America/New_York"),
            ("IAH", "America/Chicago"), ("EWR", "America/New_York"), ("SEA", "America/Los_Angeles"), ("MCO", "America/New_York"), ("TPA", "America/New_York"), ("PUJ", "America/Santo_Domingo"), ("CDG", "Europe/Paris"), ("FRA", "Europe/Berlin"),
            ("AMS", "Europe/Amsterdam"), ("MAD", "Europe/Madrid"), ("BCN", "Europe/Madrid"),
            ("FCO", "Europe/Rome"), ("MXP", "Europe/Rome"), ("ZRH", "Europe/Zurich"),
            ("VIE", "Europe/Vienna"), ("CPH", "Europe/Copenhagen"), ("ARN", "Europe/Stockholm"),
            ("OSL", "Europe/Oslo"), ("HEL", "Europe/Helsinki"), ("WAW", "Europe/Warsaw"),
            ("PRG", "Europe/Prague"), ("BUD", "Europe/Budapest"), ("ATH", "Europe/Athens"),
            ("IST", "Europe/Istanbul"), ("DXB", "Asia/Dubai"), ("DOH", "Asia/Qatar"),
            ("AUH", "Asia/Dubai"), ("BKK", "Asia/Bangkok"), ("SIN", "Asia/Singapore"),
            ("HKG", "Asia/Hong_Kong"), ("NRT", "Asia/Tokyo"), ("HND", "Asia/Tokyo"),
            ("ICN", "Asia/Seoul"), ("SYD", "Australia/Sydney"), ("MEL", "Australia/Melbourne"),
            ("BNE", "Australia/Brisbane"), ("PER", "Australia/Perth"), ("AKL", "Pacific/Auckland"),
            ("YVR", "America/Vancouver"), ("YYZ", "America/Toronto"), ("YUL", "America/Toronto"),
            ("YYC", "America/Edmonton"), ("YEG", "America/Edmonton"), ("YOW", "America/Toronto"),
            ("YHZ", "America/Halifax"), ("YWG", "America/Winnipeg"),
            // ICAO codes for major airports
            ("EGLL", "Europe/London"), ("EGKK", "Europe/London"), ("EGSS", "Europe/London"),
            ("KJFK", "America/New_York"), ("KLAX", "America/Los_Angeles"), ("KORD", "America/Chicago"),
            ("KDFW", "America/Chicago"), ("KATL", "America/New_York"), ("KDEN", "America/Denver"),
            ("KSFO", "America/Los_Angeles"), ("KMIA", "America/New_York"), ("KBOS", "America/New_York"),
            ("KSEA", "America/Los_Angeles"), ("LFPG", "Europe/Paris"), ("EDDF", "Europe/Berlin"),
            ("EHAM", "Europe/Amsterdam"), ("LEMD", "Europe/Madrid"), ("LEBL", "Europe/Madrid"),
            ("LIRF", "Europe/Rome"), ("LIMC", "Europe/Rome"), ("LSZH", "Europe/Zurich"),
            ("LOWW", "Europe/Vienna"), ("EKCH", "Europe/Copenhagen"), ("ESSA", "Europe/Stockholm"),
            ("ENGM", "Europe/Oslo"), ("EFHK", "Europe/Helsinki"), ("EPWA", "Europe/Warsaw"),
            ("LKPR", "Europe/Prague"), ("LHBP", "Europe/Budapest"), ("LGAV", "Europe/Athens"),
            ("LTFM", "Europe/Istanbul"), ("OMDB", "Asia/Dubai"), ("OTBD", "Asia/Qatar"),
            ("OMAA", "Asia/Dubai"), ("VTBS", "Asia/Bangkok"), ("WSSS", "Asia/Singapore"),
            ("VHHH", "Asia/Hong_Kong"), ("RJAA", "Asia/Tokyo"), ("RJTT", "Asia/Tokyo"),
            ("RKSI", "Asia/Seoul"), ("YSSY", "Australia/Sydney"), ("YMML", "Australia/Melbourne"),
            ("YBBN", "Australia/Brisbane"), ("YPPH", "Australia/Perth"), ("NZAA", "Pacific/Auckland"),
            ("CYVR", "America/Vancouver"), ("CYYZ", "America/Toronto"), ("CYUL", "America/Toronto"),
            ("CYYC", "America/Edmonton"), ("CYEG", "America/Edmonton"), ("CYOW", "America/Toronto"),
            ("CYHZ", "America/Halifax"), ("CYWG", "America/Winnipeg")
        ]
        
        let homeBaseUpper = homeBase.uppercased()
        let destinationUpper = destination.uppercased()
        
        print("DEBUG: Looking for '\(homeBaseUpper)' and '\(destinationUpper)' in airports list")
        
        guard let homeTimeZone = airports.first(where: { $0.0 == homeBaseUpper })?.1,
              let destTimeZone = airports.first(where: { $0.0 == destinationUpper })?.1,
              let homeTZ = TimeZone(identifier: homeTimeZone),
              let destTZ = TimeZone(identifier: destTimeZone) else {
            print("DEBUG: Failed to find airports or time zones")
            print("DEBUG: homeBase '\(homeBaseUpper)' -> timeZone: \(airports.first(where: { $0.0 == homeBaseUpper })?.1 ?? "NOT FOUND")")
            print("DEBUG: destination '\(destinationUpper)' -> timeZone: \(airports.first(where: { $0.0 == destinationUpper })?.1 ?? "NOT FOUND")")
            return 0
        }
        
        print("DEBUG: Found time zones - home: \(homeTimeZone), dest: \(destTimeZone)")
        
        let now = Date()
        let homeOffset = homeTZ.secondsFromGMT(for: now)
        let destOffset = destTZ.secondsFromGMT(for: now)
        let differenceSeconds = destOffset - homeOffset
        
        let result = Int(differenceSeconds / 3600)
        print("DEBUG: Calculated time zone difference: \(result) hours")
        
        return result
    }
    
    static func getLocalTime(for airportCode: String) -> String {
        let airports = [
            // IATA codes
            ("LHR", "Europe/London"), ("LGW", "Europe/London"), ("STN", "Europe/London"),
            ("JFK", "America/New_York"), ("LAX", "America/Los_Angeles"), ("ORD", "America/Chicago"),
            ("DFW", "America/Chicago"), ("ATL", "America/New_York"), ("DEN", "America/Denver"),
            ("SFO", "America/Los_Angeles"), ("MIA", "America/New_York"), ("BOS", "America/New_York"),
            ("IAH", "America/Chicago"), ("EWR", "America/New_York"), ("SEA", "America/Los_Angeles"), ("MCO", "America/New_York"), ("TPA", "America/New_York"), ("PUJ", "America/Santo_Domingo"), ("CDG", "Europe/Paris"), ("FRA", "Europe/Berlin"),
            ("AMS", "Europe/Amsterdam"), ("MAD", "Europe/Madrid"), ("BCN", "Europe/Madrid"),
            ("FCO", "Europe/Rome"), ("MXP", "Europe/Rome"), ("ZRH", "Europe/Zurich"),
            ("VIE", "Europe/Vienna"), ("CPH", "Europe/Copenhagen"), ("ARN", "Europe/Stockholm"),
            ("OSL", "Europe/Oslo"), ("HEL", "Europe/Helsinki"), ("WAW", "Europe/Warsaw"),
            ("PRG", "Europe/Prague"), ("BUD", "Europe/Budapest"), ("ATH", "Europe/Athens"),
            ("IST", "Europe/Istanbul"), ("DXB", "Asia/Dubai"), ("DOH", "Asia/Qatar"),
            ("AUH", "Asia/Dubai"), ("BKK", "Asia/Bangkok"), ("SIN", "Asia/Singapore"),
            ("HKG", "Asia/Hong_Kong"), ("NRT", "Asia/Tokyo"), ("HND", "Asia/Tokyo"),
            ("ICN", "Asia/Seoul"), ("SYD", "Australia/Sydney"), ("MEL", "Australia/Melbourne"),
            ("BNE", "Australia/Brisbane"), ("PER", "Australia/Perth"), ("AKL", "Pacific/Auckland"),
            ("YVR", "America/Vancouver"), ("YYZ", "America/Toronto"), ("YUL", "America/Toronto"),
            ("YYC", "America/Edmonton"), ("YEG", "America/Edmonton"), ("YOW", "America/Toronto"),
            ("YHZ", "America/Halifax"), ("YWG", "America/Winnipeg"),
            // ICAO codes for major airports
            ("EGLL", "Europe/London"), ("EGKK", "Europe/London"), ("EGSS", "Europe/London"),
            ("KJFK", "America/New_York"), ("KLAX", "America/Los_Angeles"), ("KORD", "America/Chicago"),
            ("KDFW", "America/Chicago"), ("KATL", "America/New_York"), ("KDEN", "America/Denver"),
            ("KSFO", "America/Los_Angeles"), ("KMIA", "America/New_York"), ("KBOS", "America/New_York"),
            ("KSEA", "America/Los_Angeles"), ("LFPG", "Europe/Paris"), ("EDDF", "Europe/Berlin"),
            ("EHAM", "Europe/Amsterdam"), ("LEMD", "Europe/Madrid"), ("LEBL", "Europe/Madrid"),
            ("LIRF", "Europe/Rome"), ("LIMC", "Europe/Rome"), ("LSZH", "Europe/Zurich"),
            ("LOWW", "Europe/Vienna"), ("EKCH", "Europe/Copenhagen"), ("ESSA", "Europe/Stockholm"),
            ("ENGM", "Europe/Oslo"), ("EFHK", "Europe/Helsinki"), ("EPWA", "Europe/Warsaw"),
            ("LKPR", "Europe/Prague"), ("LHBP", "Europe/Budapest"), ("LGAV", "Europe/Athens"),
            ("LTFM", "Europe/Istanbul"), ("OMDB", "Asia/Dubai"), ("OTBD", "Asia/Qatar"),
            ("OMAA", "Asia/Dubai"), ("VTBS", "Asia/Bangkok"), ("WSSS", "Asia/Singapore"),
            ("VHHH", "Asia/Hong_Kong"), ("RJAA", "Asia/Tokyo"), ("RJTT", "Asia/Tokyo"),
            ("RKSI", "Asia/Seoul"), ("YSSY", "Australia/Sydney"), ("YMML", "Australia/Melbourne"),
            ("YBBN", "Australia/Brisbane"), ("YPPH", "Australia/Perth"), ("NZAA", "Pacific/Auckland"),
            ("CYVR", "America/Vancouver"), ("CYYZ", "America/Toronto"), ("CYUL", "America/Toronto"),
            ("CYYC", "America/Edmonton"), ("CYEG", "America/Edmonton"), ("CYOW", "America/Toronto"),
            ("CYHZ", "America/Halifax"), ("CYWG", "America/Winnipeg")
        ]
        
        guard let timeZoneString = airports.first(where: { $0.0 == airportCode.uppercased() })?.1,
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
        let airports = [
            // IATA codes
            ("LHR", "Europe/London"), ("LGW", "Europe/London"), ("STN", "Europe/London"),
            ("JFK", "America/New_York"), ("LAX", "America/Los_Angeles"), ("ORD", "America/Chicago"),
            ("DFW", "America/Chicago"), ("ATL", "America/New_York"), ("DEN", "America/Denver"),
            ("SFO", "America/Los_Angeles"), ("MIA", "America/New_York"), ("BOS", "America/New_York"),
            ("IAH", "America/Chicago"), ("EWR", "America/New_York"), ("SEA", "America/Los_Angeles"), ("CDG", "Europe/Paris"), ("FRA", "Europe/Berlin"),
            ("AMS", "Europe/Amsterdam"), ("MAD", "Europe/Madrid"), ("BCN", "Europe/Madrid"),
            ("FCO", "Europe/Rome"), ("MXP", "Europe/Rome"), ("ZRH", "Europe/Zurich"),
            ("VIE", "Europe/Vienna"), ("CPH", "Europe/Copenhagen"), ("ARN", "Europe/Stockholm"),
            ("OSL", "Europe/Oslo"), ("HEL", "Europe/Helsinki"), ("WAW", "Europe/Warsaw"),
            ("PRG", "Europe/Prague"), ("BUD", "Europe/Budapest"), ("ATH", "Europe/Athens"),
            ("IST", "Europe/Istanbul"), ("DXB", "Asia/Dubai"), ("DOH", "Asia/Qatar"),
            ("AUH", "Asia/Dubai"), ("BKK", "Asia/Bangkok"), ("SIN", "Asia/Singapore"),
            ("HKG", "Asia/Hong_Kong"), ("NRT", "Asia/Tokyo"), ("HND", "Asia/Tokyo"),
            ("ICN", "Asia/Seoul"), ("SYD", "Australia/Sydney"), ("MEL", "Australia/Melbourne"),
            ("BNE", "Australia/Brisbane"), ("PER", "Australia/Perth"), ("AKL", "Pacific/Auckland"),
            ("YVR", "America/Vancouver"), ("YYZ", "America/Toronto"), ("YUL", "America/Toronto"),
            ("YYC", "America/Edmonton"), ("YEG", "America/Edmonton"), ("YOW", "America/Toronto"),
            ("YHZ", "America/Halifax"), ("YWG", "America/Winnipeg"),
            // ICAO codes for major airports
            ("EGLL", "Europe/London"), ("EGKK", "Europe/London"), ("EGSS", "Europe/London"),
            ("KJFK", "America/New_York"), ("KLAX", "America/Los_Angeles"), ("KORD", "America/Chicago"),
            ("KDFW", "America/Chicago"), ("KATL", "America/New_York"), ("KDEN", "America/Denver"),
            ("KSFO", "America/Los_Angeles"), ("KMIA", "America/New_York"), ("KBOS", "America/New_York"),
            ("KSEA", "America/Los_Angeles"), ("LFPG", "Europe/Paris"), ("EDDF", "Europe/Berlin"),
            ("EHAM", "Europe/Amsterdam"), ("LEMD", "Europe/Madrid"), ("LEBL", "Europe/Madrid"),
            ("LIRF", "Europe/Rome"), ("LIMC", "Europe/Rome"), ("LSZH", "Europe/Zurich"),
            ("LOWW", "Europe/Vienna"), ("EKCH", "Europe/Copenhagen"), ("ESSA", "Europe/Stockholm"),
            ("ENGM", "Europe/Oslo"), ("EFHK", "Europe/Helsinki"), ("EPWA", "Europe/Warsaw"),
            ("LKPR", "Europe/Prague"), ("LHBP", "Europe/Budapest"), ("LGAV", "Europe/Athens"),
            ("LTFM", "Europe/Istanbul"), ("OMDB", "Asia/Dubai"), ("OTBD", "Asia/Qatar"),
            ("OMAA", "Asia/Dubai"), ("VTBS", "Asia/Bangkok"), ("WSSS", "Asia/Singapore"),
            ("VHHH", "Asia/Hong_Kong"), ("RJAA", "Asia/Tokyo"), ("RJTT", "Asia/Tokyo"),
            ("RKSI", "Asia/Seoul"), ("YSSY", "Australia/Sydney"), ("YMML", "Australia/Melbourne"),
            ("YBBN", "Australia/Brisbane"), ("YPPH", "Australia/Perth"), ("NZAA", "Pacific/Auckland"),
            ("CYVR", "America/Vancouver"), ("CYYZ", "America/Toronto"), ("CYUL", "America/Toronto"),
            ("CYYC", "America/Edmonton"), ("CYEG", "America/Edmonton"), ("CYOW", "America/Toronto"),
            ("CYHZ", "America/Halifax"), ("CYWG", "America/Winnipeg")
        ]
        
        guard let timeZoneString = airports.first(where: { $0.0 == airportCode.uppercased() })?.1,
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

// MARK: - Validation
struct ValidationRules {
    static func isValidTimeFormat(_ time: String) -> Bool {
        // Remove 'z' suffix if present for validation
        let cleanTime = time.replacingOccurrences(of: "z", with: "")
        let timeRegex = "^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$"
        return cleanTime.range(of: timeRegex, options: .regularExpression) != nil
    }
    
    static func isValidFlightNumber(_ flightNumber: String) -> Bool {
        return !flightNumber.isEmpty && flightNumber.count >= 2
    }
    
    static func isValidAirportCode(_ code: String) -> Bool {
        // Support both IATA (3 letters) and ICAO (4 letters) airport codes
        return (code.count == 3 || code.count == 4) && code.uppercased() == code
    }
} 