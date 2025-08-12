import Foundation

class AIAnalysisService {
    
    static func analyzeFTLCompliance(
        currentFlight: FlightRecord,
        previousFlights: [FlightRecord],
        pilotType: PilotType,
        isAugmentedCrew: Bool = false,
        hasInflightRest: Bool = false
    ) -> AIAnalysisResult {
        
        // Calculate current usage
        let dailyUsage = calculateDailyUsage(previousFlights: previousFlights, currentFlight: currentFlight)
        let weeklyUsage = calculateWeeklyUsage(previousFlights: previousFlights, currentFlight: currentFlight)
        let monthlyUsage = calculateMonthlyUsage(previousFlights: previousFlights, currentFlight: currentFlight)
        
        // Get limits based on pilot type
        let dailyLimit = UKCAALimits.baseMaxDailyDutyTime
        let weeklyLimit = UKCAALimits.maxWeeklyDutyTime
        let monthlyLimit = UKCAALimits.maxMonthlyDutyTime
        
        // Calculate remaining time
        let dailyRemaining = dailyLimit - dailyUsage
        let weeklyRemaining = weeklyLimit - weeklyUsage
        let monthlyRemaining = monthlyLimit - monthlyUsage
        
        // Analyze fatigue risk
        let fatigueRisk = analyzeFatigueRisk(currentFlight: currentFlight, previousFlights: previousFlights)
        
        // Generate commander's discretion recommendations
        let commanderDiscretion = generateCommanderDiscretion(
            dailyRemaining: dailyRemaining,
            weeklyRemaining: weeklyRemaining,
            monthlyRemaining: monthlyRemaining,
            fatigueRisk: fatigueRisk,
            pilotType: pilotType,
            isAugmentedCrew: isAugmentedCrew,
            hasInflightRest: hasInflightRest
        )
        
        // Generate warnings and recommendations
        let warnings = generateWarnings(
            dailyRemaining: dailyRemaining,
            weeklyRemaining: weeklyRemaining,
            monthlyRemaining: monthlyRemaining,
            fatigueRisk: fatigueRisk
        )
        
        return AIAnalysisResult(
            dailyUsage: dailyUsage,
            weeklyUsage: weeklyUsage,
            monthlyUsage: monthlyUsage,
            dailyRemaining: dailyRemaining,
            weeklyRemaining: weeklyRemaining,
            monthlyRemaining: monthlyRemaining,
            fatigueRisk: fatigueRisk,
            commanderDiscretion: commanderDiscretion,
            warnings: warnings,
            recommendations: generateRecommendations(
                dailyRemaining: dailyRemaining,
                weeklyRemaining: weeklyRemaining,
                monthlyRemaining: monthlyRemaining,
                fatigueRisk: fatigueRisk
            )
        )
    }
    
    private static func calculateDailyUsage(previousFlights: [FlightRecord], currentFlight: FlightRecord) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let todaysFlights = previousFlights.filter { flight in
            guard let flightDate = DateFormatter.shortDate.date(from: flight.date) else { return false }
            let flightStartOfDay = calendar.startOfDay(for: flightDate)
            return calendar.isDate(flightStartOfDay, inSameDayAs: today)
        }
        
        let totalDutyTime = todaysFlights.reduce(0.0) { $0 + $1.dutyTime }
        return totalDutyTime + currentFlight.dutyTime
    }
    
    private static func calculateWeeklyUsage(previousFlights: [FlightRecord], currentFlight: FlightRecord) -> Double {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let weeklyFlights = previousFlights.filter { flight in
            guard let flightDate = DateFormatter.shortDate.date(from: flight.date) else { return false }
            return flightDate >= weekStart
        }
        
        let totalDutyTime = weeklyFlights.reduce(0.0) { $0 + $1.dutyTime }
        return totalDutyTime + currentFlight.dutyTime
    }
    
    private static func calculateMonthlyUsage(previousFlights: [FlightRecord], currentFlight: FlightRecord) -> Double {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        
        let monthlyFlights = previousFlights.filter { flight in
            guard let flightDate = DateFormatter.shortDate.date(from: flight.date) else { return false }
            return flightDate >= monthStart
        }
        
        let totalDutyTime = monthlyFlights.reduce(0.0) { $0 + $1.dutyTime }
        return totalDutyTime + currentFlight.dutyTime
    }
    
    private static func analyzeFatigueRisk(currentFlight: FlightRecord, previousFlights: [FlightRecord]) -> FatigueRisk {
        let consecutiveDays = calculateConsecutiveDutyDays(flights: previousFlights + [currentFlight])
        let dutyTime = currentFlight.dutyTime
        let startTime = TimeUtilities.parseTime(currentFlight.reportTime)
        let endTime = TimeUtilities.parseTime(currentFlight.dutyEndTime)
        
        var riskLevel: FatigueRiskLevel = .low
        var riskFactors: [String] = []
        
        // Check consecutive duty days
        if consecutiveDays >= 7 {
            riskLevel = .high
            riskFactors.append("7+ consecutive duty days")
        } else if consecutiveDays >= 5 {
            riskLevel = .medium
            riskFactors.append("5+ consecutive duty days")
        }
        
        // Check duty time
        if dutyTime > 12 {
            riskLevel = .high
            riskFactors.append("Duty time > 12 hours")
        } else if dutyTime > 10 {
            riskLevel = max(riskLevel, .medium)
            riskFactors.append("Duty time > 10 hours")
        }
        
        // Check time of day
        if let startTime = startTime, let endTime = endTime {
            let startHour = Calendar.current.component(.hour, from: startTime)
            let endHour = Calendar.current.component(.hour, from: endTime)
            if startHour < 6 || endHour > 22 {
                riskLevel = max(riskLevel, .medium)
                riskFactors.append("Early morning or late night duty")
            }
        }
        
        return FatigueRisk(level: riskLevel, factors: riskFactors)
    }
    
    private static func calculateConsecutiveDutyDays(flights: [FlightRecord]) -> Int {
        let calendar = Calendar.current
        let sortedFlights = flights.sorted { $0.date > $1.date }
        
        var consecutiveDays = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for flight in sortedFlights {
            guard let flightDate = DateFormatter.shortDate.date(from: flight.date) else { continue }
            let flightStartOfDay = calendar.startOfDay(for: flightDate)
            if calendar.isDate(flightStartOfDay, inSameDayAs: currentDate) {
                consecutiveDays += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return consecutiveDays
    }
    
    private static func generateCommanderDiscretion(
        dailyRemaining: Double,
        weeklyRemaining: Double,
        monthlyRemaining: Double,
        fatigueRisk: FatigueRisk,
        pilotType: PilotType,
        isAugmentedCrew: Bool = false,
        hasInflightRest: Bool = false
    ) -> CommanderDiscretion {
        
        var canExtend = false
        var maxExtension = 0.0
        var conditions: [String] = []
        var risks: [String] = []
        
        // Check if extension is possible
        if dailyRemaining > 0 && weeklyRemaining > 0 && monthlyRemaining > 0 {
            canExtend = true
            
            // Calculate maximum safe extension - UK CAA Regulation 965/2012
            let maxDailyExtension = (isAugmentedCrew && hasInflightRest) ? 3.0 : 2.0 // 3h for augmented crew with rest, 2h for standard
            let safeDailyExtension = min(dailyRemaining, maxDailyExtension)
            let safeWeeklyExtension = min(weeklyRemaining, 5.0) // Max 5 hours extension
            let safeMonthlyExtension = min(monthlyRemaining, 10.0) // Max 10 hours extension
            
            maxExtension = min(safeDailyExtension, safeWeeklyExtension, safeMonthlyExtension)
            
            // Add conditions
            if fatigueRisk.level == .low {
                conditions.append("Low fatigue risk")
            } else if fatigueRisk.level == .medium {
                conditions.append("Medium fatigue risk - monitor closely")
                maxExtension = min(maxExtension, 1.5) // Reduce extension for medium risk
            } else {
                conditions.append("High fatigue risk - extension not recommended")
                canExtend = false
                maxExtension = 0.0
            }
            
            if pilotType == .multiPilot {
                conditions.append("Multi-pilot operation")
                maxExtension = min(maxExtension, 2.0) // UK CAA: 2 hours max for all operations
            } else {
                conditions.append("Single-pilot operation")
                maxExtension = min(maxExtension, 2.0) // UK CAA: 2 hours max for all operations
            }
        }
        
        // Add risks
        if fatigueRisk.level != .low {
            risks.append("Increased fatigue risk")
        }
        if dailyRemaining < 2.0 {
            risks.append("Limited daily margin")
        }
        if weeklyRemaining < 5.0 {
            risks.append("Limited weekly margin")
        }
        
        return CommanderDiscretion(
            canExtend: canExtend,
            maxExtension: maxExtension,
            conditions: conditions,
            risks: risks
        )
    }
    
    private static func generateWarnings(
        dailyRemaining: Double,
        weeklyRemaining: Double,
        monthlyRemaining: Double,
        fatigueRisk: FatigueRisk
    ) -> [String] {
        var warnings: [String] = []
        
        if dailyRemaining <= 0 {
            warnings.append("⚠️ Daily limit exceeded")
        } else if dailyRemaining < 1.0 {
            warnings.append("⚠️ Very limited daily margin remaining")
        }
        
        if weeklyRemaining <= 0 {
            warnings.append("⚠️ Weekly limit exceeded")
        } else if weeklyRemaining < 3.0 {
            warnings.append("⚠️ Limited weekly margin remaining")
        }
        
        if monthlyRemaining <= 0 {
            warnings.append("⚠️ Monthly limit exceeded")
        } else if monthlyRemaining < 10.0 {
            warnings.append("⚠️ Limited monthly margin remaining")
        }
        
        if fatigueRisk.level == .high {
            warnings.append("🚨 High fatigue risk detected")
        } else if fatigueRisk.level == .medium {
            warnings.append("⚠️ Medium fatigue risk - monitor closely")
        }
        
        return warnings
    }
    
    private static func generateRecommendations(
        dailyRemaining: Double,
        weeklyRemaining: Double,
        monthlyRemaining: Double,
        fatigueRisk: FatigueRisk
    ) -> [String] {
        var recommendations: [String] = []
        
        if dailyRemaining < 2.0 {
            recommendations.append("Consider shorter duty periods for remaining flights today")
        }
        
        if weeklyRemaining < 5.0 {
            recommendations.append("Plan rest days for the remainder of the week")
        }
        
        if monthlyRemaining < 15.0 {
            recommendations.append("Consider taking additional rest days this month")
        }
        
        if fatigueRisk.level == .high {
            recommendations.append("Strongly consider additional rest before next duty")
        } else if fatigueRisk.level == .medium {
            recommendations.append("Monitor fatigue levels and consider additional rest")
        }
        
        if dailyRemaining > 5.0 && weeklyRemaining > 15.0 {
            recommendations.append("Good margin available - current schedule is sustainable")
        }
        
        return recommendations
    }
}

struct AIAnalysisResult {
    let dailyUsage: Double
    let weeklyUsage: Double
    let monthlyUsage: Double
    let dailyRemaining: Double
    let weeklyRemaining: Double
    let monthlyRemaining: Double
    let fatigueRisk: FatigueRisk
    let commanderDiscretion: CommanderDiscretion
    let warnings: [String]
    let recommendations: [String]
}

struct CommanderDiscretion {
    let canExtend: Bool
    let maxExtension: Double
    let conditions: [String]
    let risks: [String]
}

enum FatigueRiskLevel: Comparable {
    case low
    case medium
    case high
    
    var description: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

struct FatigueRisk {
    let level: FatigueRiskLevel
    let factors: [String]
} 