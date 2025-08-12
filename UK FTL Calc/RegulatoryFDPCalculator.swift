//
//  RegulatoryFDPCalculator.swift
//  UK FTL Calc
//
//  Implements the 7-step FDP calculation algorithm using regulatory tables
//

import Foundation

// MARK: - FDP Calculation Input Structure

struct FDPCalculationInput {
    let reportTime: String // UTC/local time
    let sectors: Int
    let lastHomebaseReportTime: String?
    let currentLocationTimeZone: String
    let previousAcclimatisedTimeZone: String
    let inflightRestFacility: String? // "class_1", "class_2", "class_3", or nil
    let additionalCrew: Int
    let delayedReportingNotifications: [String]? // List of delayed report times
    let rosteredExtensionUsed: Bool
    let commanderDiscretionUsed: Bool
    let standbyStartTime: String?
    let standbyType: StandbyType?
    let dutyEndTime: String
    let flightTimes: [Double]? // Individual sector flight times for long flight detection
    let preCalculatedElapsedTime: Double? // NEW: Pre-calculated elapsed time from XML data
    let hasSplitDuty: Bool // Whether split duty is being used
}

// MARK: - FDP Calculation Result

struct FDPCalculationResult {
    let maxFDP: Double
    let acclimatisationState: String
    let baseFDP: Double
    let adjustments: [String: Double]
    let explanations: [String]
    let warnings: [String]
    let violations: [String]
}

// MARK: - Main FDP Calculator

class RegulatoryFDPCalculator {
    
    // MARK: - Main Calculation Function
    
    static func calculateMaxFDP(input: FDPCalculationInput) -> FDPCalculationResult {
        var adjustments: [String: Double] = [:]
        var explanations: [String] = []
        var warnings: [String] = []
        let violations: [String] = []
        
        print("DEBUG: RegulatoryFDPCalculator - Starting FDP calculation")
        print("DEBUG: Input - reportTime: \(input.reportTime), sectors: \(input.sectors)")
        
        // Step 1: Determine Acclimatisation State
        let acclimatisationState = determineAcclimatisationState(input: input)
        explanations.append("Acclimatisation state: \(acclimatisationState)")
        print("DEBUG: Step 1 - Acclimatisation state: \(acclimatisationState)")
        
        // Step 2: Determine Base FDP from FDP Tables
        var baseFDP = determineBaseFDP(input: input, acclimatisationState: acclimatisationState)
        explanations.append("Base FDP: \(TimeUtilities.formatHoursAndMinutes(baseFDP))")
        print("DEBUG: Step 2 - Base FDP: \(baseFDP)")
        
        // Step 3: Adjust FDP for Rostered Extension (if applicable)
        if input.rosteredExtensionUsed {
            if let rosteredFDP = RegulatoryTableLookup.lookupFDPRosteredExtension(reportTime: input.reportTime, sectors: input.sectors) {
                baseFDP = rosteredFDP
                adjustments["rostered_extension"] = rosteredFDP
                explanations.append("Rostered extension applied: \(TimeUtilities.formatHoursAndMinutes(rosteredFDP))")
                print("DEBUG: Step 3 - Rostered extension applied: \(rosteredFDP)")
            } else {
                warnings.append("Rostered extension requested but not available for this time/sector combination")
                print("DEBUG: Step 3 - Rostered extension not available")
            }
        }
        
        // Step 4: Adjust FDP for In-Flight Rest (if applicable)
        if let restFacility = input.inflightRestFacility, input.additionalCrew > 0 {
            let isLongFlight = determineIfLongFlight(input: input)
            let inflightFDP = RegulatoryTableLookup.lookupInflightRestExtension(
                restClass: restFacility,
                additionalCrew: input.additionalCrew,
                isLongFlight: isLongFlight
            )
            baseFDP = inflightFDP
            adjustments["inflight_rest"] = inflightFDP
            let longFlightText = isLongFlight ? " (long flight)" : ""
            explanations.append("In-flight rest applied: \(TimeUtilities.formatHoursAndMinutes(inflightFDP))\(longFlightText)")
            print("DEBUG: Step 4 - In-flight rest applied: \(inflightFDP), long flight: \(isLongFlight)")
        }
        
        // Step 5: Adjust FDP for Delayed Reporting
        if let delayedNotifications = input.delayedReportingNotifications, !delayedNotifications.isEmpty {
            let delayAdjustment = calculateDelayAdjustment(input: input, delayedNotifications: delayedNotifications)
            if delayAdjustment != 0 {
                baseFDP += delayAdjustment
                adjustments["delayed_reporting"] = delayAdjustment
                explanations.append("Delayed reporting adjustment: \(TimeUtilities.formatHoursAndMinutes(delayAdjustment))")
                print("DEBUG: Step 5 - Delay adjustment: \(delayAdjustment)")
            }
        }
        
        // Step 6: Commander's Discretion (if applied)
        if input.commanderDiscretionUsed {
            let discretionExtension = calculateCommandersDiscretion(input: input)
            baseFDP += discretionExtension
            adjustments["commanders_discretion"] = discretionExtension
            explanations.append("Commander's discretion: +\(TimeUtilities.formatHoursAndMinutes(discretionExtension))")
            print("DEBUG: Step 6 - Commander's discretion: +\(discretionExtension)")
        }
        
        // Step 7: Apply Standby Adjustments
        if let standbyType = input.standbyType, let standbyStartTime = input.standbyStartTime {
            let standbyAdjustment = calculateStandbyAdjustment(input: input, standbyType: standbyType, standbyStartTime: standbyStartTime)
            if standbyAdjustment != 0 {
                baseFDP += standbyAdjustment
                adjustments["standby"] = standbyAdjustment
                explanations.append("Standby adjustment: \(TimeUtilities.formatHoursAndMinutes(standbyAdjustment))")
                print("DEBUG: Step 7 - Standby adjustment: \(standbyAdjustment)")
            }
        }
        
        // Ensure minimum FDP
        baseFDP = max(baseFDP, 9.0)
        
        return FDPCalculationResult(
            maxFDP: baseFDP,
            acclimatisationState: acclimatisationState,
            baseFDP: baseFDP,
            adjustments: adjustments,
            explanations: explanations,
            warnings: warnings,
            violations: violations
        )
    }
    
    // MARK: - Step 1: Determine Acclimatisation State
    
    private static func determineAcclimatisationState(input: FDPCalculationInput) -> String {
        // NEW: Use pre-calculated elapsed time if available, otherwise calculate manually
        let elapsedTimeHours: Double
        if let preCalculated = input.preCalculatedElapsedTime {
            elapsedTimeHours = preCalculated
            print("DEBUG: RegulatoryFDPCalculator - Using pre-calculated elapsed time: \(elapsedTimeHours) hours")
        } else {
            // Fallback to manual calculation
            guard let lastHomebaseReportTime = input.lastHomebaseReportTime else {
                return "X" // Unknown if no previous homebase report time
            }
            elapsedTimeHours = TimeUtilities.calculateHoursBetween(lastHomebaseReportTime, input.reportTime)
            print("DEBUG: RegulatoryFDPCalculator - Using manually calculated elapsed time: \(elapsedTimeHours) hours")
        }
        
        // Calculate time zone difference
        let timeZoneDiff = TimeUtilities.getTimeZoneDifference(
            from: input.previousAcclimatisedTimeZone,
            to: input.currentLocationTimeZone
        )
        
        // Use UK CAA Table 1 logic from Models.swift
        let acclimatisationResult = UKCAALimits.determineAcclimatisationStatus(
            timeZoneDifference: timeZoneDiff,
            elapsedTimeHours: elapsedTimeHours,
            isFirstSector: false, // This should be determined based on context
            homeBase: input.previousAcclimatisedTimeZone, // This should be the actual home base airport
            departure: input.currentLocationTimeZone // This should be the actual departure airport
        )
        
        // Convert the result to the expected format
        // acclimatisationResult returns (isAcclimatised, shouldBeAcclimatised, reason)
        // We need to determine if this is Result B, D, or X based on the logic
        
        // Enhanced logic to properly distinguish between Result B, D, and X
        // The acclimatisationResult.reason now contains the specific result (B, D, or X)
        if acclimatisationResult.reason.contains("Result B") {
            return "B" // Acclimatised to home base - Result 'B'
        } else if acclimatisationResult.reason.contains("Result D") {
            return "D" // Acclimatised to current departure - Result 'D'
        } else if acclimatisationResult.reason.contains("Result X") {
            return "X" // Unknown acclimatisation state - Result 'X'
        } else {
            // Fallback logic based on the boolean values
            if acclimatisationResult.isAcclimatised && acclimatisationResult.shouldBeAcclimatised {
                return "B" // Acclimatised to home base - Result 'B'
            } else if acclimatisationResult.isAcclimatised && !acclimatisationResult.shouldBeAcclimatised {
                return "D" // Acclimatised to current departure - Result 'D'
            } else {
                return "X" // Unknown acclimatisation state - Result 'X'
            }
        }
    }
    
    // MARK: - Step 2: Determine Base FDP
    
    // FDP Table Selection based on UK CAA Table 1 Results:
    // - Result 'B': Use Table 2 (FDPAcclimatisedTable) with home base local time
    // - Result 'D': Use Table 2 (FDPAcclimatisedTable) with departure local time
    // - Result 'X': Use Table 3 (FDPUnknownAcclimatisedTable) - no time conversion needed
    private static func determineBaseFDP(input: FDPCalculationInput, acclimatisationState: String) -> Double {
        switch acclimatisationState {
        case "B": // Acclimatised to home base - use home base local time for Table 2
            let homeBaseLocalTime = convertToLocalTime(input.reportTime, timeZone: input.previousAcclimatisedTimeZone)
            print("DEBUG: Result B - Using home base local time: \(homeBaseLocalTime) (from \(input.reportTime) in \(input.previousAcclimatisedTimeZone))")
            return RegulatoryTableLookup.lookupFDPAcclimatised(
                reportTime: homeBaseLocalTime,
                sectors: input.sectors
            )
        case "D": // Acclimatised to current departure - use departure local time for Table 2
            let departureLocalTime = convertToLocalTime(input.reportTime, timeZone: input.currentLocationTimeZone)
            print("DEBUG: Result D - Using departure local time: \(departureLocalTime) (from \(input.reportTime) in \(input.currentLocationTimeZone))")
            return RegulatoryTableLookup.lookupFDPAcclimatised(
                reportTime: departureLocalTime,
                sectors: input.sectors
            )
        case "X": // Unknown acclimatisation - use Table 3 (no time conversion needed)
            print("DEBUG: Result X - Using Table 3 (unknown acclimatisation)")
            return RegulatoryTableLookup.lookupFDPUnknownAcclimatised(sectors: input.sectors)
        default:
            return 9.0 // Default minimum
        }
    }
    
    // MARK: - Step 4: Determine Long Flight
    
    private static func determineIfLongFlight(input: FDPCalculationInput) -> Bool {
        guard let flightTimes = input.flightTimes else { return false }
        
        // Long flight = 1 or 2 sectors with one sector > 9 hours
        if flightTimes.count <= 2 {
            return flightTimes.contains { $0 > 9.0 }
        }
        
        return false
    }
    
    // MARK: - Step 5: Delayed Reporting Adjustment
    
    private static func calculateDelayAdjustment(input: FDPCalculationInput, delayedNotifications: [String]) -> Double {
        // Find the largest delay
        var maxDelay: Double = 0
        
        for delayedTime in delayedNotifications {
            let delay = TimeUtilities.calculateHoursBetween(input.reportTime, delayedTime)
            maxDelay = max(maxDelay, delay)
        }
        
        if maxDelay >= 4.0 {
            // Calculate FDP based on original report time
            let originalFDP = RegulatoryTableLookup.lookupFDPAcclimatised(
                reportTime: input.reportTime,
                sectors: input.sectors
            )
            
            // Calculate FDP based on delayed report time
            let delayedFDP = RegulatoryTableLookup.lookupFDPAcclimatised(
                reportTime: delayedNotifications.last ?? input.reportTime,
                sectors: input.sectors
            )
            
            // Return the minimum of the two
            return min(originalFDP, delayedFDP) - originalFDP
        }
        
        return 0 // No adjustment for delays < 4 hours
    }
    
    // MARK: - Helper Functions
    
    private static func convertToLocalTime(_ utcTime: String, timeZone: String) -> String {
        // Ensure time is in Z format for parsing
        let utcTimeZ = utcTime.hasSuffix("z") ? utcTime : utcTime + "z"
        
        guard let utcDate = TimeUtilities.parseTime(utcTimeZ) else {
            print("DEBUG: Failed to parse UTC time: \(utcTimeZ)")
            return utcTime // Return original if parsing fails
        }
        
        // Get time zone offset from time zone string
        let timeZoneOffset = getTimeZoneOffsetFromString(timeZone)
        print("DEBUG: Converting \(utcTimeZ) to \(timeZone) (offset: \(timeZoneOffset)h)")
        
        // Add offset to get local time
        let localDate = utcDate.addingTimeInterval(TimeInterval(timeZoneOffset * 3600))
        
        // Format as HH:mm
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let localTimeString = formatter.string(from: localDate)
        
        print("DEBUG: Converted \(utcTimeZ) to local time: \(localTimeString)")
        return localTimeString
    }
    
    private static func getTimeZoneOffsetFromString(_ timeZoneString: String) -> Int {
        guard let timeZone = TimeZone(identifier: timeZoneString) else {
            print("DEBUG: Invalid time zone string: \(timeZoneString)")
            return 0 // Default to UTC if time zone not found
        }
        
        let now = Date()
        let offsetSeconds = timeZone.secondsFromGMT(for: now)
        return offsetSeconds / 3600 // Convert seconds to hours
    }
    
    // MARK: - Step 6: Commander's Discretion
    
    private static func calculateCommandersDiscretion(input: FDPCalculationInput) -> Double {
        // Commander's discretion: 3 hours for augmented crew with in-flight rest, 2 hours for standard crew
        if input.additionalCrew >= 1 && input.inflightRestFacility != nil {
            return 3.0 // 3 hours for augmented crew with in-flight rest
        } else {
            return 2.0 // 2 hours for standard crew
        }
    }
    
    // MARK: - Step 7: Standby Adjustments
    
    private static func calculateStandbyAdjustment(input: FDPCalculationInput, standbyType: StandbyType, standbyStartTime: String) -> Double {
        switch standbyType {
        case .airportStandby:
            return calculateAirportStandbyAdjustment(input: input, standbyStartTime: standbyStartTime)
        case .homeStandby:
            return calculateHomeStandbyAdjustment(input: input, standbyStartTime: standbyStartTime)
        }
    }
    
    private static func calculateAirportStandbyAdjustment(input: FDPCalculationInput, standbyStartTime: String) -> Double {
        // Airport standby: FDP starts from standby start time
        // Calculate standby duration
        let standbyDuration = TimeUtilities.calculateHoursBetween(standbyStartTime, input.reportTime)
        
        // If standby > 4 hours and converted to duty, reduce FDP
        if standbyDuration > 4.0 {
            return -(standbyDuration - 4.0) // Negative adjustment
        }
        
        return 0
    }
    
    private static func calculateHomeStandbyAdjustment(input: FDPCalculationInput, standbyStartTime: String) -> Double {
        // Home standby: FDP starts from report time, not standby start time
        // Calculate standby duration
        let standbyDuration = TimeUtilities.calculateHoursBetween(standbyStartTime, input.reportTime)
        
        // Determine threshold (6 or 8 hours based on in-flight rest/split duty)
        let threshold = (input.inflightRestFacility != nil || input.hasSplitDuty) ? 8.0 : 6.0
        
        // Apply night exclusion (23:00-07:00)
        let effectiveStandbyTime = applyNightExclusion(standbyDuration: standbyDuration, standbyStartTime: standbyStartTime)
        
        // Apply FDP reduction logic
        if effectiveStandbyTime <= threshold {
            return 0 // No reduction for early call
        } else {
            return -(effectiveStandbyTime - threshold) // Negative adjustment
        }
    }
    
    private static func applyNightExclusion(standbyDuration: Double, standbyStartTime: String) -> Double {
        // This is a simplified implementation
        // In practice, this would need to calculate the exact time spent in 23:00-07:00 period
        // For now, return the full duration
        return standbyDuration
    }
}

 

 