//
//  ManualCalcViewModel+Standby.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

// MARK: - Standby and Reserve Extension
extension ManualCalcViewModel {
    
    // MARK: - Standby Duration Calculation
    func calculateStandbyDuration(standbyContactTime: String = "") -> Double {
        print("DEBUG: calculateStandbyDuration - standbyStartDateTime: \(standbyStartDateTime)")
        print("DEBUG: calculateStandbyDuration - reportingDateTime: \(reportingDateTime)")
        print("DEBUG: calculateStandbyDuration - standbyContactTime: \(standbyContactTime)")
        
        // Check if this is night standby (starts between 23:00-07:00 local time)
        let isNightStandby = isStandbyStartingInNightHours()
        
        let duration: Double
        if isNightStandby {
            // Night standby: FDP reduction calculated from contact time to report time
            if !standbyContactTime.isEmpty {
                let contactDateTime = createDateTimeFromContactTime(standbyContactTime)
                duration = reportingDateTime.timeIntervalSince(contactDateTime)
                print("DEBUG: calculateStandbyDuration - Night standby detected, using contact time for FDP reduction")
                print("DEBUG: calculateStandbyDuration - Contact time: \(standbyContactTime), Contact datetime: \(contactDateTime)")
            } else {
                // Fallback to standby start time if no contact time provided
                duration = reportingDateTime.timeIntervalSince(standbyStartDateTime)
                print("DEBUG: calculateStandbyDuration - Night standby detected but no contact time provided - falling back to standby start time")
            }
        } else {
            // Normal standby: FDP reduction calculated from standby start time to report time
            duration = reportingDateTime.timeIntervalSince(standbyStartDateTime)
            print("DEBUG: calculateStandbyDuration - Normal standby - using standby start time for FDP reduction")
        }
        
        let hours = duration / 3600.0 // Convert seconds to hours
        
        print("DEBUG: calculateStandbyDuration - raw duration in seconds: \(duration)")
        print("DEBUG: calculateStandbyDuration - calculated hours: \(hours)")
        
        return hours
    }
    
    // Helper function to determine if standby starts during night hours (23:00-07:00 local time)
    private func isStandbyStartingInNightHours() -> Bool {
        let utcTimeString = utcTimeFormatter.string(from: standbyStartDateTime)
        let standbyStartLocal = TimeUtilities.getLocalTime(for: utcTimeString, airportCode: homeBase)
        
        // Parse the local time to get hour
        let standbyStartHour = Int(standbyStartLocal.prefix(2)) ?? 0
        
        // Night hours: 23:00-07:00 (23, 0, 1, 2, 3, 4, 5, 6)
        let isNightHour = standbyStartHour >= 23 || standbyStartHour < 7
        
        print("DEBUG: isStandbyStartingInNightHours - Standby start time: \(utcTimeString) -> Local: \(standbyStartLocal) -> Hour: \(standbyStartHour) -> Night hours: \(isNightHour)")
        
        return isNightHour
    }
    
    // Helper function to create a Date from contact time string
    private func createDateTimeFromContactTime(_ contactTime: String) -> Date {
        // Parse the contact time (HH:MM format) and apply it to the standby start date
        let components = contactTime.split(separator: ":")
        let hour = Int(components.first ?? "0") ?? 0
        let minute = Int(components.last ?? "0") ?? 0
        
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Use the date from standbyStartDateTime but the time from contactTime
        let dateComponents = utcCalendar.dateComponents([.year, .month, .day], from: standbyStartDateTime)
        
        var newComponents = DateComponents()
        newComponents.year = dateComponents.year
        newComponents.month = dateComponents.month
        newComponents.day = dateComponents.day
        newComponents.hour = hour
        newComponents.minute = minute
        newComponents.second = 0
        
        return utcCalendar.date(from: newComponents) ?? standbyStartDateTime
    }
    
    func checkTotalAwakeTimeLimit() -> Bool {
        let standbyDuration = calculateStandbyDuration(standbyContactTime: standbyContactTime)
        let maxFDP = calculateMaxFDP()
        let totalAwakeTime = standbyDuration + maxFDP
        return totalAwakeTime <= 18.0
    }
    
    func checkNightStandbyContact() {
        if isStandbyEnabled && (selectedStandbyType == "Standby" || selectedStandbyType == "Airport Standby") {
            print("DEBUG: checkNightStandbyContact - standbyStartDateTime: \(standbyStartDateTime)")
            let utcTimeString = utcTimeFormatter.string(from: standbyStartDateTime)
            print("DEBUG: checkNightStandbyContact - utcTimeString: \(utcTimeString)")
            let standbyStartLocal = TimeUtilities.getLocalTime(for: utcTimeString, airportCode: homeBase)
            print("DEBUG: checkNightStandbyContact - standbyStartLocal: \(standbyStartLocal)")
            let standbyStartHour = Int(standbyStartLocal.prefix(2)) ?? 0
            print("DEBUG: checkNightStandbyContact - standbyStartHour: \(standbyStartHour)")
            
            if (standbyStartHour >= 23 || standbyStartHour < 7) {
                print("DEBUG: checkNightStandbyContact - Night standby detected, showing popup")
                showingNightStandbyContactPopup = true
            }
        }
    }
    
    // MARK: - Standby Time Update Functions
    func updateStandbyTimeFromCustomInput() {
        // The DatePicker has already updated standbyStartDateTime with the selected date
        // We just need to update the time components while preserving the selected date
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Extract the date components from the current standbyStartDateTime (which has the selected date)
        let dateComponents = utcCalendar.dateComponents([.year, .month, .day], from: standbyStartDateTime)
        
        // Create new date with the selected date and the new time components
        var newComponents = DateComponents()
        newComponents.year = dateComponents.year
        newComponents.month = dateComponents.month
        newComponents.day = dateComponents.day
        newComponents.hour = selectedStandbyHour
        newComponents.minute = selectedStandbyMinute
        newComponents.second = 0
        
        if let utcDate = utcCalendar.date(from: newComponents) {
            print("DEBUG: updateStandbyTimeFromCustomInput - Updating standby start time")
            print("DEBUG: updateStandbyTimeFromCustomInput - Selected date: \(standbyStartDateTime)")
            print("DEBUG: updateStandbyTimeFromCustomInput - New time: \(selectedStandbyHour):\(selectedStandbyMinute)")
            print("DEBUG: updateStandbyTimeFromCustomInput - Final datetime: \(utcDate)")
            standbyStartDateTime = utcDate
            clearCache() // Clear cache when standby time changes
        } else {
            print("DEBUG: updateStandbyTimeFromCustomInput - Failed to create date from components")
        }
    }
    
    func updateStandbyTimeFromCustomInputWithDate(_ selectedDate: Date) {
        // Use the provided date instead of the current standbyStartDateTime
        // This prevents direct binding issues with the DatePicker
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Extract the date components from the provided date
        let dateComponents = utcCalendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Create new date with the provided date and the new time components
        var newComponents = DateComponents()
        newComponents.year = dateComponents.year
        newComponents.month = dateComponents.month
        newComponents.day = dateComponents.day
        newComponents.hour = selectedStandbyHour
        newComponents.minute = selectedStandbyMinute
        newComponents.second = 0
        
        if let utcDate = utcCalendar.date(from: newComponents) {
            print("DEBUG: updateStandbyTimeFromCustomInputWithDate - Updating standby start time")
            print("DEBUG: updateStandbyTimeFromCustomInputWithDate - Provided date: \(selectedDate)")
            print("DEBUG: updateStandbyTimeFromCustomInputWithDate - New time: \(selectedStandbyHour):\(selectedStandbyMinute)")
            print("DEBUG: updateStandbyTimeFromCustomInputWithDate - Final datetime: \(utcDate)")
            standbyStartDateTime = utcDate
            clearCache() // Clear cache when standby time changes
        } else {
            print("DEBUG: updateStandbyTimeFromCustomInputWithDate - Failed to create date from components")
        }
    }
    
    func updateAirportDutyTimeFromCustomInput() {
        // Get the currently selected date from the date picker
        let selectedDate = airportDutyStartDateTime
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
        
        // Extract date components from the selected date
        let dateComponents = utcCalendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Create new date with selected date and time components
        var newComponents = DateComponents()
        newComponents.year = dateComponents.year
        newComponents.month = dateComponents.month
        newComponents.day = dateComponents.day
        newComponents.hour = selectedAirportDutyHour
        newComponents.minute = selectedAirportDutyMinute
        newComponents.second = 0
        
        if let utcDate = utcCalendar.date(from: newComponents) {
            airportDutyStartDateTime = utcDate
            clearCache() // Clear cache when airport duty time changes
        }
    }
    
    // Synchronize times when standby type changes
    func synchronizeStandbyTimes() {
        switch selectedStandbyType {
        case "Airport Duty":
            // For airport duty, synchronize with standby start time
            airportDutyStartDateTime = standbyStartDateTime
            selectedAirportDutyHour = selectedStandbyHour
            selectedAirportDutyMinute = selectedStandbyMinute
        case "Airport Standby":
            // For airport standby, no synchronization needed - uses standby start time directly
            break
        case "Standby":
            // For home standby, no synchronization needed - uses standby start time directly
            break
        case "Reserve":
            // For reserve, no synchronization needed - uses standby start time directly
            break
        default:
            break
        }
        clearCache() // Clear cache when times are synchronized
    }
    
    func updateContactTimeFromCustomInput() {
        // Update the contact time based on selected hour and minute
        // Convert local time to Z time and store in standbyContactTime
        
        if wasContactedBefore0700 {
            // Format the local time as HH:MM
            let localTimeString = String(format: "%02d:%02d", selectedContactHour, selectedContactMinute)
            
            // Convert local time to Z time using the home base timezone
            let zTimeString = TimeUtilities.getUTCTime(for: localTimeString, airportCode: homeBase)
            
            // Store in standbyContactTime field
            standbyContactTime = zTimeString
            
            print("DEBUG: updateContactTimeFromCustomInput - Local time: \(localTimeString), Z time: \(zTimeString)")
        } else {
            // If not contacted, clear the contact time
            standbyContactTime = ""
            print("DEBUG: updateContactTimeFromCustomInput - Not contacted, cleared contact time")
        }
        
        clearCache() // Clear cache when contact time changes
    }
}
