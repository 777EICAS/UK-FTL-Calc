//
//  ManualCalcViewModel+TimeManagement.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

// MARK: - Time Management Extension
extension ManualCalcViewModel {
    
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
        
        return "\(baselineTimeString)z (\(baselineLabel)) + \(TimeUtilities.formatHoursAndMinutes(totalFDP)) = \(timeString)z - \(TimeUtilities.formatHoursAndMinutes(estimatedBlockTime))"
    }
    
    func formatTimeAsUTC(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")!
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date) + "z"
    }
}
