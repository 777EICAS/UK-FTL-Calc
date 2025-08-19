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
            let effectiveBreakTimeBeforeWOCL = calculateEffectiveBreakTimeBeforeWOCL()
            
            // Use the more restrictive of the two calculations
            effectiveBreakTime = min(effectiveBreakTime - woclReduction, effectiveBreakTimeBeforeWOCL)
            effectiveBreakTime = max(0.0, effectiveBreakTime)
            
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
        // Only apply if break actually crosses midnight (breakEndHour < breakBeginHour)
        if breakEndHour < breakBeginHour {
            // Break crosses midnight, check if it goes into next day's WOCL
            let nextDayWOCLStart = 2
            let nextDayWOCLEnd = min(6, breakEndHour)
            if nextDayWOCLEnd > nextDayWOCLStart {
                woclEncroachment += Double(nextDayWOCLEnd - nextDayWOCLStart)
            }
        }
        
        return woclEncroachment
    }
    
    /// Calculates the effective break time that occurs before WOCL begins
    /// This ensures that only the portion of the break before 02:00 local time counts
    private func calculateEffectiveBreakTimeBeforeWOCL() -> Double {
        guard splitDutyAccommodationType == "Accommodation" else { return splitDutyBreakDuration }
        
        // Get the local time at the user's acclimatised location
        let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
        let breakBeginTimeString = utcTimeFormatter.string(from: splitDutyBreakBegin)
        let localBreakBeginTime = TimeUtilities.getLocalTime(for: breakBeginTimeString, airportCode: currentDeparture)
        
        // Parse local time to get hour and minute
        let timeComponents = localBreakBeginTime.split(separator: ":")
        let breakBeginHour = Int(timeComponents[0]) ?? 0
        let breakBeginMinute = Int(timeComponents[1]) ?? 0
        
        // Convert to minutes for precise calculation
        let breakBeginMinutes = breakBeginHour * 60 + breakBeginMinute
        let woclStartMinutes = 2 * 60 // 02:00 = 120 minutes
        
        // If break starts at or after WOCL, no effective time before WOCL
        if breakBeginMinutes >= woclStartMinutes {
            return 0.0
        }
        
        // Calculate how much time is available before WOCL
        let timeBeforeWOCL = woclStartMinutes - breakBeginMinutes
        
        // Convert back to hours
        return Double(timeBeforeWOCL) / 60.0
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
            
            // Calculate effective break time using the more restrictive method
            let effectiveBreakTimeBeforeWOCL = calculateEffectiveBreakTimeBeforeWOCL()
            let finalEffectiveBreakTime = min(effectiveBreakTime, effectiveBreakTimeBeforeWOCL)
            
            let finalExtension = finalEffectiveBreakTime * 0.5
            explanation += "Final extension: \(TimeUtilities.formatHoursAndMinutes(finalExtension)) (50% of \(TimeUtilities.formatHoursAndMinutes(finalEffectiveBreakTime)) effective break time)"
            
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
