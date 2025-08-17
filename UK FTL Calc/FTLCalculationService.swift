//
//  FTLCalculationService.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//  Updated to use regulatory table-based calculations
//

import Foundation

class FTLCalculationService {
    
    // MARK: - UK CAA FTL Regulations Implementation (Regulatory Table-Based)
    
    /// Calculates comprehensive FTL compliance for a flight using regulatory tables
    /// Based on UK CAA CAP 371 and EU OPS regulations with table-driven calculations
    static func calculateFTLCompliance(
        dutyTime: Double,
        flightTime: Double,
        pilotType: PilotType,
        previousFlights: [FlightRecord],
        hasStandbyDuty: Bool,
        standbyType: StandbyType?,
        standbyStartTime: String,
        dutyEndTime: String,
        reportTime: String,
        departure: String,
        arrival: String,
        takeoffTime: String,
        landingTime: String,
        ftlFactors: FTLFactors,
        isOutbound: Bool = false
    ) -> FTLCalculationResult {
        
        var warnings: [String] = []
        var violations: [String] = []
        var isCompliant = true
        
        print("DEBUG: Regulatory FTL Calculation - Starting with new system")
        print("DEBUG: Input - reportTime: \(reportTime), departure: \(departure), arrival: \(arrival)")
        print("DEBUG: FTL Factors - hasAugmentedCrew: \(ftlFactors.hasAugmentedCrew), hasInFlightRest: \(ftlFactors.hasInFlightRest)")
        
        // Calculate the actual duty time to use (standby FDP or regular duty time)
        let actualDutyTime: Double
        print("DEBUG: calculateFTLCompliance - hasStandbyDuty: \(hasStandbyDuty), standbyType: \(String(describing: standbyType))")
        print("DEBUG: calculateFTLCompliance - standbyStartTime: '\(standbyStartTime)', dutyEndTime: '\(dutyEndTime)'")
        print("DEBUG: calculateFTLCompliance - original dutyTime: \(dutyTime)")
        
        if hasStandbyDuty, let standbyType = standbyType {
            switch standbyType {
            case .homeStandby:
                // For home standby, duty time starts from report time (not standby start time)
                actualDutyTime = dutyTime
                print("DEBUG: calculateFTLCompliance - homeStandby actualDutyTime: \(actualDutyTime)")
            case .airportStandby:
                if !standbyStartTime.isEmpty && !dutyEndTime.isEmpty {
                    actualDutyTime = calculateAirportStandbyFDP(standbyStartTime: standbyStartTime, dutyEndTime: dutyEndTime)
                    print("DEBUG: calculateFTLCompliance - airportStandby actualDutyTime: \(actualDutyTime)")
                } else {
                    actualDutyTime = dutyTime
                    print("DEBUG: calculateFTLCompliance - airportStandby fallback actualDutyTime: \(actualDutyTime)")
                }
            }
        } else {
            actualDutyTime = dutyTime
            print("DEBUG: calculateFTLCompliance - no standby actualDutyTime: \(actualDutyTime)")
        }
        
        // NEW: Calculate regulatory-based FDP limit using the 7-step algorithm
        let regulatoryFDPResult = calculateRegulatoryFDP(
            reportTime: reportTime,
            departure: departure,
            arrival: arrival,
            takeoffTime: takeoffTime,
            landingTime: landingTime,
            ftlFactors: ftlFactors,
            hasStandbyDuty: hasStandbyDuty,
            standbyType: standbyType,
            standbyStartTime: standbyStartTime
        )
        
        var maxFDP = regulatoryFDPResult.maxFDP
        print("DEBUG: Regulatory FDP Result - maxFDP: \(maxFDP), acclimatisation: \(regulatoryFDPResult.acclimatisationState)")
        
        // Apply home standby FDP reduction if applicable (Rule v(b))
        if hasStandbyDuty, let standbyType = standbyType, standbyType == .homeStandby {
            if !standbyStartTime.isEmpty && !reportTime.isEmpty {
                let homeStandbyResult = RegulatoryTableLookup.calculateHomeStandbyFDPReduction(
                    standbyStartTime: standbyStartTime,
                    reportTime: reportTime,
                    hasInflightRest: ftlFactors.hasInFlightRest,
                    hasSplitDuty: ftlFactors.hasSplitDuty
                )
                
                if homeStandbyResult.fdpReduction > 0 {
                    maxFDP = max(0.0, maxFDP - homeStandbyResult.fdpReduction)
                    print("DEBUG: Home Standby FDP Reduction applied - standbyDuration: \(homeStandbyResult.standbyDuration), threshold: \(homeStandbyResult.threshold), reduction: \(homeStandbyResult.fdpReduction), new maxFDP: \(maxFDP)")
                    print("DEBUG: Home Standby explanation: \(homeStandbyResult.explanation)")
                } else {
                    print("DEBUG: Home Standby - no FDP reduction needed (standbyDuration: \(homeStandbyResult.standbyDuration), threshold: \(homeStandbyResult.threshold))")
                }
            }
        }
        
        // 1. Daily Limits Check (now using regulatory FDP)
        let dailyCheck = checkDailyLimits(
            actualDutyTime: actualDutyTime,
            maxFDP: maxFDP,
            flightTime: flightTime,
            pilotType: pilotType,
            hasStandbyDuty: hasStandbyDuty,
            standbyType: standbyType,
            regulatoryResult: regulatoryFDPResult
        )
        warnings.append(contentsOf: dailyCheck.warnings)
        violations.append(contentsOf: dailyCheck.violations)
        if !dailyCheck.violations.isEmpty {
            isCompliant = false
        }
        
        // 2. Weekly Limits Check (only if there are previous flights)
        if !previousFlights.isEmpty {
            let currentFlight = FlightRecord(
                flightNumber: "CURRENT",
                departure: departure,
                arrival: arrival,
                reportTime: reportTime,
                takeoffTime: "00:00",
                landingTime: "00:00",
                dutyEndTime: dutyEndTime,
                flightTime: flightTime,
                dutyTime: actualDutyTime,
                pilotType: pilotType,
                date: DateFormatter.shortDate.string(from: Date()) // Assuming date is passed as a parameter
            )
            
            let weeklyCheck = checkWeeklyLimits(previousFlights: previousFlights, currentFlight: currentFlight)
            warnings.append(contentsOf: weeklyCheck.warnings)
            violations.append(contentsOf: weeklyCheck.violations)
            if !weeklyCheck.violations.isEmpty {
                isCompliant = false
            }
            
            // 3. Monthly Limits Check
            let monthlyCheck = checkMonthlyLimits(previousFlights: previousFlights, currentFlight: currentFlight)
            warnings.append(contentsOf: monthlyCheck.warnings)
            violations.append(contentsOf: monthlyCheck.violations)
            if !monthlyCheck.violations.isEmpty {
                isCompliant = false
            }
        }
        
        // 4. Rest Period Calculation
        print("DEBUG: calculateFTLCompliance - About to calculate rest period")
        print("DEBUG: calculateFTLCompliance - isOutbound: \(isOutbound), arrival: \(arrival)")
        let requiredRest = calculateRequiredRestPeriod(dutyTime: actualDutyTime, pilotType: pilotType, isOutbound: isOutbound, arrival: arrival, ftlFactors: ftlFactors)
        print("DEBUG: calculateFTLCompliance - Final required rest: \(requiredRest) hours")
        
        // 5. Next Duty Available Time
        let nextDutyAvailable = calculateNextDutyAvailableTime(dutyEndTime: dutyEndTime, requiredRest: requiredRest)
        
        return FTLCalculationResult(
            dutyTime: actualDutyTime,
            flightTime: flightTime,
            requiredRest: requiredRest,
            nextDutyAvailable: nextDutyAvailable,
            isCompliant: isCompliant,
            warnings: warnings,
            violations: violations,
            maxFDP: maxFDP,
            regulatoryExplanations: regulatoryFDPResult.explanations
        )
    }
    
    // MARK: - Regulatory FDP Calculation (7-Step Algorithm)
    
    private static func calculateRegulatoryFDP(
        reportTime: String,
        departure: String,
        arrival: String,
        takeoffTime: String,
        landingTime: String,
        ftlFactors: FTLFactors,
        hasStandbyDuty: Bool,
        standbyType: StandbyType?,
        standbyStartTime: String
    ) -> FDPCalculationResult {
        
        // Use the acclimatisation state that was already determined
        let acclimatisationState = determineAcclimatisationStateFromFTLFactors(ftlFactors: ftlFactors, departure: departure)
        
        // Calculate flight time for long flight detection
        let flightTime = TimeUtilities.calculateHoursBetween(takeoffTime, landingTime)
        
        // Prepare input for the regulatory calculator
        let input = FDPCalculationInput(
            reportTime: reportTime,
            sectors: 1, // Default to 1 sector - could be enhanced to count actual sectors
            lastHomebaseReportTime: ftlFactors.originalHomeBaseReportTime,
            currentLocationTimeZone: getTimeZoneForAirport(departure),
            previousAcclimatisedTimeZone: getTimeZoneForAirport(ftlFactors.homeBase),
            inflightRestFacility: ftlFactors.hasInFlightRest ? getRestFacilityClass(ftlFactors.restFacilityType) : nil,
            additionalCrew: ftlFactors.hasAugmentedCrew ? ftlFactors.numberOfAdditionalPilots : 0,
            delayedReportingNotifications: nil, // Would need to be tracked
            rosteredExtensionUsed: false, // Would need to be tracked
            commanderDiscretionUsed: false, // Would need to be tracked
            standbyStartTime: hasStandbyDuty ? standbyStartTime : nil,
            standbyType: standbyType,
            dutyEndTime: "00:00", // Placeholder
            flightTimes: [flightTime], // Pass the calculated flight time for long flight detection
            preCalculatedElapsedTime: ftlFactors.elapsedTimeHours, // NEW: Pass the pre-calculated elapsed time
            hasSplitDuty: ftlFactors.hasSplitDuty // Pass the split duty flag
        )
        
                // Create a modified calculator that uses the pre-determined acclimatisation state
        return calculateMaxFDPWithPreDeterminedState(input: input, acclimatisationState: acclimatisationState)
    }
    
    private static func determineAcclimatisationStateFromFTLFactors(ftlFactors: FTLFactors, departure: String) -> String {
        // The acclimatisation status has already been determined by UKCAALimits.determineAcclimatisationStatus
        // We need to map the result to the correct state based on the actual Table 1 result
        
        // Use the actual reason from Table 1 to determine the correct acclimatisation state
        if ftlFactors.acclimatisationReason.contains("Result D") {
            return "D" // Acclimatised to current departure - use Table 2 with departure local time
        } else if ftlFactors.acclimatisationReason.contains("Result B") {
            return "B" // Acclimatised to home base - use Table 2 with home base local time
        } else if ftlFactors.acclimatisationReason.contains("Result X") {
            return "X" // Unknown acclimatisation state - use Table 3
        } else {
            // Fallback logic for backward compatibility
            if ftlFactors.isAcclimatised && ftlFactors.shouldBeAcclimatised {
                // Both are true - this could be Result 'D' or Result 'B'
                // Default to 'D' as it's more common for multi-sector duties
                return "D"
            } else if ftlFactors.isAcclimatised {
                return "D" // Acclimatised to current departure - Result 'D'
            } else if ftlFactors.shouldBeAcclimatised {
                return "B" // Acclimatised to home base - Result 'B'
            } else {
                return "X" // Unknown acclimatisation state - Result 'X'
            }
        }
    }
    
        private static func calculateMaxFDPWithPreDeterminedState(input: FDPCalculationInput, acclimatisationState: String) -> FDPCalculationResult {
        // This function duplicates the logic from RegulatoryFDPCalculator.calculateMaxFDP
        // but uses the pre-determined acclimatisation state instead of calculating it
        
        var adjustments: [String: Double] = [:]
        var explanations: [String] = []
        var warnings: [String] = []
        let violations: [String] = []
        
        print("DEBUG: RegulatoryFDPCalculator - Starting FDP calculation with pre-determined acclimatisation state: \(acclimatisationState)")
        print("DEBUG: Input - reportTime: \(input.reportTime), sectors: \(input.sectors)")
        
        // Step 1: Use the pre-determined acclimatisation state
        explanations.append("Acclimatisation state: \(acclimatisationState)")
        print("DEBUG: Step 1 - Pre-determined acclimatisation state: \(acclimatisationState)")
        
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
        
        // Ensure minimum FDP (except for home standby cases per UK CAA Rule v(b))
        let isHomeStandbyReduction = input.standbyType == .homeStandby && 
            input.standbyStartTime != nil && 
            input.standbyStartTime!.isEmpty == false
        
        if !isHomeStandbyReduction {
            baseFDP = max(baseFDP, 9.0)
        } else {
            print("DEBUG: Home standby case - allowing FDP below 9.0h as per UK CAA Rule v(b)")
        }
        
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
    
    // MARK: - Helper Functions for FDP Calculation
    
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
    
    private static func determineIfLongFlight(input: FDPCalculationInput) -> Bool {
        guard let flightTimes = input.flightTimes else { return false }
        
        // Long flight = 1 or 2 sectors with one sector > 9 hours
        if flightTimes.count <= 2 {
            return flightTimes.contains { $0 > 9.0 }
        }
        
        return false
    }
    
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
    
    private static func calculateCommandersDiscretion(input: FDPCalculationInput) -> Double {
        // Commander's discretion: 3 hours for augmented crew with in-flight rest, 2 hours for standard crew
        if input.additionalCrew >= 1 && input.inflightRestFacility != nil {
            return 3.0 // 3 hours for augmented crew with in-flight rest
        } else {
            return 2.0 // 2 hours for standard crew
        }
    }
    
    private static func calculateStandbyAdjustment(input: FDPCalculationInput, standbyType: StandbyType, standbyStartTime: String) -> Double {
        // Standby adjustments depend on the type and duration
        // This is a simplified implementation
        return 0.0
    }
    
    // MARK: - Helper Functions for Regulatory System
    
    private static func getTimeZoneForAirport(_ airport: String) -> String {
        // Simplified time zone mapping - could be enhanced with full airport database
        switch airport.uppercased() {
        case "LHR", "LGW", "STN", "LTN", "LCY":
            return "Europe/London"
        case "JFK", "EWR", "LGA":
            return "America/New_York"
        case "LAX", "SFO":
            return "America/Los_Angeles"
        case "DXB":
            return "Asia/Dubai"
        case "IAH", "HOU":
            return "America/Chicago"
        case "MCO":
            return "America/New_York"
        case "TPA":
            return "America/New_York"
        case "DOH":
            return "Asia/Qatar"
        case "BOS":
            return "America/New_York"
        case "PUJ":
            return "America/Santo_Domingo"
        default:
            return "Europe/London" // Default to London
        }
    }
    
    private static func getRestFacilityClass(_ restType: RestFacilityType) -> String {
        switch restType {
        case .none:
            return "class_3" // Default to class 3 for no rest facility
        case .class1:
            return "class_1"
        case .class2:
            return "class_2"
        case .class3:
            return "class_3"
        }
    }
    
    // MARK: - Updated Daily Limits Check
    
    private static func checkDailyLimits(
        actualDutyTime: Double,
        maxFDP: Double,
        flightTime: Double,
        pilotType: PilotType,
        hasStandbyDuty: Bool,
        standbyType: StandbyType?,
        regulatoryResult: FDPCalculationResult
    ) -> (warnings: [String], violations: [String]) {
        var warnings: [String] = []
        var violations: [String] = []
        
        // Check against regulatory FDP limit
        if actualDutyTime > maxFDP {
            if hasStandbyDuty, let standbyType = standbyType, standbyType == .homeStandby {
                // Home standby has special rules
                let standbyRules = RegulatoryTableLookup.getStandbyRules()
                let maxHomeStandby = standbyRules.homeStandby.maxDurationHours
                
                if actualDutyTime <= maxHomeStandby {
                    violations.append("FDP limit exceeded: \(TimeUtilities.formatHoursAndMinutes(actualDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(maxFDP)). Home standby allows up to \(TimeUtilities.formatHoursAndMinutes(maxHomeStandby)) total duty.")
                } else {
                    violations.append("Home standby hard limit exceeded: \(TimeUtilities.formatHoursAndMinutes(actualDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(maxHomeStandby)). Commanders discretion cannot extend beyond this limit.")
                }
            } else {
                violations.append("FDP limit exceeded: \(TimeUtilities.formatHoursAndMinutes(actualDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(maxFDP))")
            }
        } else if actualDutyTime > maxFDP - 1 {
            warnings.append("Approaching FDP limit: \(TimeUtilities.formatHoursAndMinutes(actualDutyTime)) (max: \(TimeUtilities.formatHoursAndMinutes(maxFDP)))")
        }
        
        // Add regulatory explanations as warnings for information
        for explanation in regulatoryResult.explanations {
            warnings.append("Regulatory: \(explanation)")
        }
        
        return (warnings, violations)
    }
    
    // MARK: - Standby FDP Calculation (Legacy - kept for compatibility)
    
    private static func calculateStandbyFDP(standbyStartTime: String, dutyEndTime: String) -> Double {
        // Ensure times are in Z format for parsing
        let standbyTimeZ = standbyStartTime.hasSuffix("z") ? standbyStartTime : standbyStartTime + "z"
        let dutyEndTimeZ = dutyEndTime.hasSuffix("z") ? dutyEndTime : dutyEndTime + "z"
        
        guard let standbyStart = TimeUtilities.parseTime(standbyTimeZ),
              let dutyEnd = TimeUtilities.parseTime(dutyEndTimeZ) else {
            return 0.0
        }
        
        let _ = Calendar.current
        let timeDifference = dutyEnd.timeIntervalSince(standbyStart)
        let hours = timeDifference / 3600.0
        
        return max(0.0, hours)
    }
    

    
    // MARK: - Airport Standby FDP Calculation
    // FDP starts from standby start time for airport standby
    private static func calculateAirportStandbyFDP(standbyStartTime: String, dutyEndTime: String) -> Double {
        // Ensure times are in Z format for parsing
        let _ = standbyStartTime.hasSuffix("z") ? standbyStartTime : standbyStartTime + "z"
        let _ = dutyEndTime.hasSuffix("z") ? dutyEndTime : dutyEndTime + "z"
        
        // Use the existing calculateHoursBetween function which handles overnight periods correctly
        let fdpStartTime = standbyStartTime.hasSuffix("z") ? standbyStartTime : standbyStartTime + "z"
        
        return TimeUtilities.calculateHoursBetween(fdpStartTime, dutyEndTime)
    }
    
    // MARK: - Weekly Limits (Updated to use regulatory limits)
    
    private static func checkWeeklyLimits(previousFlights: [FlightRecord], currentFlight: FlightRecord) -> (warnings: [String], violations: [String]) {
        var warnings: [String] = []
        var violations: [String] = []
        
        let _ = Calendar.current
        let currentDate = Date()
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
        
        // Filter flights from current week
        let weeklyFlights = previousFlights.filter { flight in
            if let flightDate = DateFormatter.shortDate.date(from: flight.date) {
                return flightDate >= weekStart
            }
            return false
        }
        
        // Calculate weekly totals
        let weeklyDutyTime = weeklyFlights.reduce(0) { $0 + $1.dutyTime } + currentFlight.dutyTime
        let _ = weeklyFlights.reduce(0) { $0 + $1.flightTime } + currentFlight.flightTime
        
        // Use regulatory absolute limits
        let absoluteLimits = RegulatoryTableLookup.getAbsoluteLimits()
        let bufferLimits = RegulatoryTableLookup.getBufferLimits()
        
        // Check weekly duty time limit
        if weeklyDutyTime > absoluteLimits.dutyPeriod.sevenDays {
            violations.append("Weekly duty time limit exceeded: \(TimeUtilities.formatHoursAndMinutes(weeklyDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(absoluteLimits.dutyPeriod.sevenDays))")
        } else if weeklyDutyTime > bufferLimits.dutyHours7Days.tracking {
            warnings.append("Approaching weekly duty time limit (\(TimeUtilities.formatHoursAndMinutes(weeklyDutyTime)))")
        }
        
        // Check consecutive duty days
        let consecutiveDays = calculateConsecutiveDutyDays(flights: weeklyFlights + [currentFlight])
        if consecutiveDays > UKCAALimits.maxConsecutiveDutyDays {
            violations.append("Maximum consecutive duty days exceeded: \(consecutiveDays) > \(UKCAALimits.maxConsecutiveDutyDays)")
        }
        
        return (warnings, violations)
    }
    
    // MARK: - Monthly Limits (Updated to use regulatory limits)
    
    private static func checkMonthlyLimits(previousFlights: [FlightRecord], currentFlight: FlightRecord) -> (warnings: [String], violations: [String]) {
        var warnings: [String] = []
        var violations: [String] = []
        
        let _ = Calendar.current
        let currentDate = Date()
        let monthStart = Calendar.current.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
        
        // Filter flights from current month
        let monthlyFlights = previousFlights.filter { flight in
            if let flightDate = DateFormatter.shortDate.date(from: flight.date) {
                return flightDate >= monthStart
            }
            return false
        }
        
        // Calculate monthly totals
        let monthlyDutyTime = monthlyFlights.reduce(0) { $0 + $1.dutyTime } + currentFlight.dutyTime
        let monthlyFlightTime = monthlyFlights.reduce(0) { $0 + $1.flightTime } + currentFlight.flightTime
        
        // Use regulatory absolute limits
        let absoluteLimits = RegulatoryTableLookup.getAbsoluteLimits()
        let bufferLimits = RegulatoryTableLookup.getBufferLimits()
        
        // Check monthly duty time limit
        if monthlyDutyTime > absoluteLimits.dutyPeriod.twentyEightDays {
            violations.append("Monthly duty time limit exceeded: \(TimeUtilities.formatHoursAndMinutes(monthlyDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(absoluteLimits.dutyPeriod.twentyEightDays))")
        } else if monthlyDutyTime > absoluteLimits.dutyPeriod.twentyEightDays - 10 {
            warnings.append("Approaching monthly duty time limit (\(TimeUtilities.formatHoursAndMinutes(monthlyDutyTime)))")
        }
        
        // Check monthly flight time limit
        if monthlyFlightTime > absoluteLimits.flightTime.twentyEightDays {
            violations.append("Monthly flight time limit exceeded: \(TimeUtilities.formatHoursAndMinutes(monthlyFlightTime)) > \(TimeUtilities.formatHoursAndMinutes(absoluteLimits.flightTime.twentyEightDays))")
        } else if monthlyFlightTime > bufferLimits.flightHours28Days.tracking {
            warnings.append("Approaching monthly flight time limit (\(TimeUtilities.formatHoursAndMinutes(monthlyFlightTime)))")
        }
        
        return (warnings, violations)
    }
    
    // MARK: - Rest Period Calculations
    
    private static func calculateRequiredRestPeriod(dutyTime: Double, pilotType: PilotType, isOutbound: Bool, arrival: String, ftlFactors: FTLFactors) -> Double {
        // UK CAA rule: Rest period depends on location after duty
        // Away from base (after outbound sector): 10 hours minimum OR duty time, whichever is greater
        // At home base (after inbound sector): 12 hours minimum OR duty time, whichever is greater
        
        // Enhanced logic: Check if the arrival airport is at home base
        // This provides access to the FTLFactors to get the home base information
        
        // For rest purposes, we need to determine if the pilot will be at home base after the duty
        // This is based on the arrival airport, not the departure airport
        let isAtHomeBase = (arrival == ftlFactors.homeBase || arrival == ftlFactors.secondHomeBase)
        
        print("DEBUG: calculateRequiredRestPeriod - arrival: \(arrival), homeBase: \(ftlFactors.homeBase), secondHomeBase: \(ftlFactors.secondHomeBase)")
        print("DEBUG: calculateRequiredRestPeriod - isOutbound: \(isOutbound), isAtHomeBase: \(isAtHomeBase)")
        
        let minimumRestPeriod: Double
        if isAtHomeBase {
            minimumRestPeriod = UKCAALimits.minRestPeriodAtHome // 12 hours at home base
            print("DEBUG: calculateRequiredRestPeriod - Using home base rest period: \(minimumRestPeriod) hours")
        } else {
            minimumRestPeriod = UKCAALimits.minRestPeriodAwayFromBase // 10 hours away from base
            print("DEBUG: calculateRequiredRestPeriod - Using away from base rest period: \(minimumRestPeriod) hours")
        }
        
        // Rest period must be at least the minimum OR as long as the preceding duty, whichever is greater
        var restPeriod = max(minimumRestPeriod, dutyTime)
        
        // Extended rest for very long duty periods
        if dutyTime > 14.0 {
            restPeriod = 16.0
        }
        
        return restPeriod
    }
    
    private static func calculateNextDutyAvailableTime(dutyEndTime: String, requiredRest: Double) -> String {
        return TimeUtilities.addHours(dutyEndTime, hours: requiredRest)
    }
    
    // MARK: - Helper Methods
    
    private static func calculateConsecutiveDutyDays(flights: [FlightRecord]) -> Int {
        let calendar = Calendar.current
        let sortedFlights = flights.sorted { flight1, flight2 in
            guard let date1 = DateFormatter.shortDate.date(from: flight1.date),
                  let date2 = DateFormatter.shortDate.date(from: flight2.date) else {
                return false
            }
            return date1 < date2
        }
        
        var consecutiveDays = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for flight in sortedFlights {
            guard let flightDate = DateFormatter.shortDate.date(from: flight.date) else { continue }
            
            if let last = lastDate {
                let daysBetween = calendar.dateComponents([.day], from: last, to: flightDate).day ?? 0
                if daysBetween <= 1 {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            consecutiveDays = max(consecutiveDays, currentStreak)
            lastDate = flightDate
        }
        
        return consecutiveDays
    }
    
    // MARK: - Advanced FTL Calculations
    
    /// Calculates fatigue risk based on duty time and time of day
    static func calculateFatigueRisk(dutyTime: Double, startTime: String, endTime: String) -> FatigueRisk {
        var riskLevel: FatigueRiskLevel = .low
        var factors: [String] = []
        
        // Time of day factors
        if let start = TimeUtilities.parseTime(startTime) {
            let hour = Calendar.current.component(.hour, from: start)
            
            // Night duty (22:00 - 06:00)
            if hour >= 22 || hour <= 6 {
                riskLevel = .high
                factors.append("Night duty")
            }
            // Early morning duty (04:00 - 08:00)
            else if hour >= 4 && hour <= 8 {
                riskLevel = .medium
                factors.append("Early morning duty")
            }
        }
        
        // Duty time factors
        if dutyTime > 12 {
            riskLevel = .high
            factors.append("Extended duty time")
        } else if dutyTime > 10 {
            riskLevel = .medium
            factors.append("Long duty time")
        }
        
        return FatigueRisk(level: riskLevel, factors: factors)
    }
    

} 