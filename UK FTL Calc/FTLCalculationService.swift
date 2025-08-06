//
//  FTLCalculationService.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import Foundation

class FTLCalculationService {
    
    // MARK: - UK CAA FTL Regulations Implementation
    
    /// Calculates comprehensive FTL compliance for a flight
    /// Based on UK CAA CAP 371 and EU OPS regulations
    static func calculateFTLCompliance(
        dutyTime: Double,
        flightTime: Double,
        pilotType: PilotType,
        previousFlights: [FlightRecord] = [],
        date: Date = Date(),
        hasStandbyDuty: Bool = false,
        standbyType: StandbyType? = nil,
        standbyStartTime: String = "",
        dutyEndTime: String = ""
    ) -> FTLCalculationResult {
        
        var warnings: [String] = []
        var violations: [String] = []
        var isCompliant = true
        
        // Calculate the actual duty time to use (standby FDP or regular duty time)
        let actualDutyTime: Double
        print("DEBUG: calculateFTLCompliance - hasStandbyDuty: \(hasStandbyDuty), standbyType: \(String(describing: standbyType))")
        print("DEBUG: calculateFTLCompliance - standbyStartTime: '\(standbyStartTime)', dutyEndTime: '\(dutyEndTime)'")
        print("DEBUG: calculateFTLCompliance - original dutyTime: \(dutyTime)")
        
        if hasStandbyDuty, let standbyType = standbyType {
            switch standbyType {
            case .homeStandby:
                if !standbyStartTime.isEmpty && !dutyEndTime.isEmpty {
                    actualDutyTime = calculateHomeStandbyFDP(standbyStartTime: standbyStartTime, dutyEndTime: dutyEndTime)
                    print("DEBUG: calculateFTLCompliance - homeStandby actualDutyTime: \(actualDutyTime)")
                } else {
                    actualDutyTime = dutyTime
                    print("DEBUG: calculateFTLCompliance - homeStandby fallback actualDutyTime: \(actualDutyTime)")
                }
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
        
        // 1. Daily Limits Check
        let dailyCheck = checkDailyLimits(dutyTime: actualDutyTime, flightTime: flightTime, pilotType: pilotType, hasStandbyDuty: hasStandbyDuty, standbyType: standbyType, standbyStartTime: standbyStartTime, dutyEndTime: dutyEndTime)
        warnings.append(contentsOf: dailyCheck.warnings)
        violations.append(contentsOf: dailyCheck.violations)
        if !dailyCheck.violations.isEmpty {
            isCompliant = false
        }
        
        // 2. Weekly Limits Check (only if there are previous flights)
        if !previousFlights.isEmpty {
            let currentFlight = FlightRecord(
                flightNumber: "CURRENT",
                departure: "XXX",
                arrival: "XXX",
                reportTime: "00:00",
                takeoffTime: "00:00",
                landingTime: "00:00",
                dutyEndTime: "00:00",
                flightTime: flightTime,
                dutyTime: actualDutyTime,
                pilotType: pilotType,
                date: DateFormatter.shortDate.string(from: date)
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
        let requiredRest = calculateRequiredRestPeriod(dutyTime: actualDutyTime, pilotType: pilotType)
        
        // 5. Next Duty Available Time
        let nextDutyAvailable = calculateNextDutyAvailableTime(dutyEndTime: "00:00", requiredRest: requiredRest)
        
        return FTLCalculationResult(
            dutyTime: actualDutyTime,
            flightTime: flightTime,
            requiredRest: requiredRest,
            nextDutyAvailable: nextDutyAvailable,
            isCompliant: isCompliant,
            warnings: warnings,
            violations: violations
        )
    }
    
    // MARK: - Daily Limits
    
    private static func checkDailyLimits(dutyTime: Double, flightTime: Double, pilotType: PilotType, hasStandbyDuty: Bool = false, standbyType: StandbyType? = nil, standbyStartTime: String = "", dutyEndTime: String = "") -> (warnings: [String], violations: [String]) {
        var warnings: [String] = []
        var violations: [String] = []
        
        // Daily Duty Time Limit - Handle standby duty
        let maxDutyTime: Double
        let actualDutyTime = dutyTime // Use the dutyTime parameter which is now the calculated standby FDP time
        
        if hasStandbyDuty, let standbyType = standbyType {
            switch standbyType {
            case .homeStandby:
                maxDutyTime = 16.0 // Home standby: maximum 16 hours total duty (standby + FDP)
            case .airportStandby:
                maxDutyTime = UKCAALimits.baseMaxDailyDutyTime // Standard FDP limits apply
            }
        } else {
            maxDutyTime = UKCAALimits.baseMaxDailyDutyTime // Standard 13 hours
        }
        
        if actualDutyTime > maxDutyTime {
            if hasStandbyDuty, let standbyType = standbyType, standbyType == .homeStandby {
                if maxDutyTime < 16.0 {
                    // More restrictive limit applies (e.g., 13h for 2-crew)
                    // Check if commanders discretion can help (can extend by 2 hours, but not beyond 16h)
                    let commandersDiscretionLimit = min(maxDutyTime + 2.0, 16.0)
                    if actualDutyTime <= commandersDiscretionLimit {
                        violations.append("Daily duty time limit exceeded: \(TimeUtilities.formatHoursAndMinutes(actualDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(maxDutyTime)) - More restrictive limit applies. Commanders discretion available to extend by 2 hours (max \(TimeUtilities.formatHoursAndMinutes(commandersDiscretionLimit))).")
                    } else {
                        violations.append("Daily duty time limit exceeded: \(TimeUtilities.formatHoursAndMinutes(actualDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(maxDutyTime)) - More restrictive limit applies. Commanders discretion cannot extend beyond 16h home standby hard limit.")
                    }
                } else {
                    violations.append("Daily duty time limit exceeded: \(TimeUtilities.formatHoursAndMinutes(actualDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(maxDutyTime)) - Home standby has a hard limit of 16 hours total duty (standby + FDP). Commanders discretion cannot be applied to increase this limit.")
                }
            } else {
                violations.append("Daily duty time limit exceeded: \(TimeUtilities.formatHoursAndMinutes(actualDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(maxDutyTime))")
            }
        } else if actualDutyTime > maxDutyTime - 1 {
            if hasStandbyDuty, let standbyType = standbyType, standbyType == .homeStandby {
                if maxDutyTime < 16.0 {
                    // More restrictive limit applies - commanders discretion may be available
                    let commandersDiscretionLimit = min(maxDutyTime + 2.0, 16.0)
                    warnings.append("Approaching duty limit (\(TimeUtilities.formatHoursAndMinutes(actualDutyTime))) - More restrictive limit applies. Commanders discretion available to extend by 2 hours (max \(TimeUtilities.formatHoursAndMinutes(commandersDiscretionLimit))).")
                } else {
                    warnings.append("Approaching home standby duty limit (\(TimeUtilities.formatHoursAndMinutes(actualDutyTime))) - Maximum 16 hours total duty applies. Commanders discretion not available for home standby.")
                }
            } else {
                warnings.append("Approaching daily duty time limit (\(TimeUtilities.formatHoursAndMinutes(actualDutyTime)))")
            }
        }
        

        
        return (warnings, violations)
    }
    
    // MARK: - Standby FDP Calculation
    
    private static func calculateStandbyFDP(standbyStartTime: String, dutyEndTime: String) -> Double {
        // Ensure times are in Z format for parsing
        let standbyTimeZ = standbyStartTime.hasSuffix("z") ? standbyStartTime : standbyStartTime + "z"
        let dutyEndTimeZ = dutyEndTime.hasSuffix("z") ? dutyEndTime : dutyEndTime + "z"
        
        guard let standbyStart = TimeUtilities.parseTime(standbyTimeZ),
              let dutyEnd = TimeUtilities.parseTime(dutyEndTimeZ) else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let timeDifference = dutyEnd.timeIntervalSince(standbyStart)
        let hours = timeDifference / 3600.0
        
        return max(0.0, hours)
    }
    
    // MARK: - Home Standby FDP Calculation
    // FDP starts 2 hours after standby start time for home standby
    private static func calculateHomeStandbyFDP(standbyStartTime: String, dutyEndTime: String) -> Double {
        // Ensure times are in Z format for parsing
        let standbyTimeZ = standbyStartTime.hasSuffix("z") ? standbyStartTime : standbyStartTime + "z"
        let dutyEndTimeZ = dutyEndTime.hasSuffix("z") ? dutyEndTime : dutyEndTime + "z"
        
        print("DEBUG: calculateHomeStandbyFDP - standbyStartTime: '\(standbyStartTime)', dutyEndTime: '\(dutyEndTime)'")
        print("DEBUG: calculateHomeStandbyFDP - standbyTimeZ: '\(standbyTimeZ)', dutyEndTimeZ: '\(dutyEndTimeZ)'")
        
        // Use the existing calculateHoursBetween function which handles overnight periods correctly
        let fdpStartTime = standbyStartTime.hasSuffix("z") ? standbyStartTime : standbyStartTime + "z"
        let fdpStartTimePlus2 = TimeUtilities.addHours(fdpStartTime, hours: 2.0)
        
        print("DEBUG: calculateHomeStandbyFDP - fdpStartTime: '\(fdpStartTime)', fdpStartTimePlus2: '\(fdpStartTimePlus2)'")
        
        let result = TimeUtilities.calculateHoursBetween(fdpStartTimePlus2, dutyEndTime)
        
        print("DEBUG: calculateHomeStandbyFDP - result: \(result)")
        
        return result
    }
    
    // MARK: - Airport Standby FDP Calculation
    // FDP starts from standby start time for airport standby
    private static func calculateAirportStandbyFDP(standbyStartTime: String, dutyEndTime: String) -> Double {
        // Ensure times are in Z format for parsing
        let standbyTimeZ = standbyStartTime.hasSuffix("z") ? standbyStartTime : standbyStartTime + "z"
        let dutyEndTimeZ = dutyEndTime.hasSuffix("z") ? dutyEndTime : dutyEndTime + "z"
        
        // Use the existing calculateHoursBetween function which handles overnight periods correctly
        let fdpStartTime = standbyStartTime.hasSuffix("z") ? standbyStartTime : standbyStartTime + "z"
        
        return TimeUtilities.calculateHoursBetween(fdpStartTime, dutyEndTime)
    }
    
    // MARK: - Weekly Limits
    
    private static func checkWeeklyLimits(previousFlights: [FlightRecord], currentFlight: FlightRecord) -> (warnings: [String], violations: [String]) {
        var warnings: [String] = []
        var violations: [String] = []
        
        let calendar = Calendar.current
        let currentDate = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
        
        // Filter flights from current week
        let weeklyFlights = previousFlights.filter { flight in
            if let flightDate = DateFormatter.shortDate.date(from: flight.date) {
                return flightDate >= weekStart
            }
            return false
        }
        
        // Calculate weekly totals
        let weeklyDutyTime = weeklyFlights.reduce(0) { $0 + $1.dutyTime } + currentFlight.dutyTime
        let weeklyFlightTime = weeklyFlights.reduce(0) { $0 + $1.flightTime } + currentFlight.flightTime
        
        // Check weekly duty time limit (60 hours)
        if weeklyDutyTime > UKCAALimits.maxWeeklyDutyTime {
            violations.append("Weekly duty time limit exceeded: \(TimeUtilities.formatHoursAndMinutes(weeklyDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(UKCAALimits.maxWeeklyDutyTime))")
        } else if weeklyDutyTime > UKCAALimits.maxWeeklyDutyTime - 5 {
            warnings.append("Approaching weekly duty time limit (\(TimeUtilities.formatHoursAndMinutes(weeklyDutyTime)))")
        }
        

        
        // Check consecutive duty days
        let consecutiveDays = calculateConsecutiveDutyDays(flights: weeklyFlights + [currentFlight])
        if consecutiveDays > UKCAALimits.maxConsecutiveDutyDays {
            violations.append("Maximum consecutive duty days exceeded: \(consecutiveDays) > \(UKCAALimits.maxConsecutiveDutyDays)")
        }
        
        return (warnings, violations)
    }
    
    // MARK: - Monthly Limits
    
    private static func checkMonthlyLimits(previousFlights: [FlightRecord], currentFlight: FlightRecord) -> (warnings: [String], violations: [String]) {
        var warnings: [String] = []
        var violations: [String] = []
        
        let calendar = Calendar.current
        let currentDate = Date()
        let monthStart = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
        
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
        
        // Check monthly duty time limit (190 hours)
        if monthlyDutyTime > UKCAALimits.maxMonthlyDutyTime {
            violations.append("Monthly duty time limit exceeded: \(TimeUtilities.formatHoursAndMinutes(monthlyDutyTime)) > \(TimeUtilities.formatHoursAndMinutes(UKCAALimits.maxMonthlyDutyTime))")
        } else if monthlyDutyTime > UKCAALimits.maxMonthlyDutyTime - 10 {
            warnings.append("Approaching monthly duty time limit (\(TimeUtilities.formatHoursAndMinutes(monthlyDutyTime)))")
        }
        

        
        return (warnings, violations)
    }
    
    // MARK: - Rest Period Calculations
    
    private static func calculateRequiredRestPeriod(dutyTime: Double, pilotType: PilotType) -> Double {
        // Standard rest period is 11 hours
        var restPeriod = UKCAALimits.minRestPeriod
        
        // Reduced rest period (10 hours) can be used under specific conditions
        if dutyTime <= 10.0 {
            restPeriod = UKCAALimits.minRestPeriodReduced
        }
        
        // Additional considerations for long-haul flights
        if dutyTime > 12.0 {
            restPeriod += 1.0 // Additional rest for extended duty
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

// FatigueRisk is now defined in AIAnalysisService.swift 