//
//  ManualCalcViewModel+SplitDuty.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

// MARK: - Split Duty Extension
extension ManualCalcViewModel {
    
    func calculateSplitDutyExtension() -> Double {
        // Extended FDP cannot be combined with split duty extensions
        if hasExtendedFDP {
            return 0.0
        }
        
        guard hasSplitDuty else { 
            return 0.0 
        }
        
        // Base extension: 50% of break duration
        let baseExtension = splitDutyBreakDuration * 0.5
        
        if splitDutyAccommodationType == "Suitable Accomm" {
            // Suitable accommodation: full 50% extension
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
            return (baseExtension, "Suitable accommodation: full 50% extension (\(TimeUtilities.formatHoursAndMinutes(baseExtension)))")
        } else {
            var effectiveBreakTime = splitDutyBreakDuration
            var explanation = "Accommodation: "
            
            // 6-hour rule
            if effectiveBreakTime > 6.0 {
                let overLimit = effectiveBreakTime - 6.0
                explanation += "6h limit applied (exceeded by \(TimeUtilities.formatHoursAndMinutes(overLimit))). "
                effectiveBreakTime = 6.0
            }
            
            // WOCL encroachment
            if woclReduction > 0 {
                explanation += "WOCL encroachment: \(TimeUtilities.formatHoursAndMinutes(woclReduction)) excluded. "
            }
            
            let finalExtension = effectiveBreakTime * 0.5
            explanation += "Final extension: \(TimeUtilities.formatHoursAndMinutes(finalExtension)) (50% of \(TimeUtilities.formatHoursAndMinutes(effectiveBreakTime)) effective break time)"
            
            return (finalExtension, explanation)
        }
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
}
