//
//  CabinCrewInFlightRestTable.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import Foundation

// MARK: - Cabin Crew In-Flight Rest Table (Table 5 from British Airways OM A)
// Based on British Airways OM A Table 5: Minimum Required In-flight Rest for Cabin Crew Members
struct CabinCrewInFlightRestTable {
    
    /// Lookup maximum allowed FDP based on rest facility class and available rest time
    /// Returns the maximum FDP in hours that can be operated with the given rest facility and rest time
    static func lookupMaxFDP(restFacilityType: RestFacilityType, restTimeAvailable: Double) -> Double {
        switch restFacilityType {
        case .class1:
            return getClass1MaxFDP(for: restTimeAvailable)
        case .class2:
            return getClass2MaxFDP(for: restTimeAvailable)
        case .class3:
            return getClass3MaxFDP(for: restTimeAvailable)
        case .none:
            return 0.0
        }
    }
    
    // MARK: - Class 1 Rest Facility FDP Limits (Table 5)
    /// Class 1: Bunk or flat bed in a separate compartment
    /// Maximum FDP: Up to 18:00 hours
    private static func getClass1MaxFDP(for restTime: Double) -> Double {
        // Table 5 Class 1 logic from British Airways OM A
        if restTime <= 1.5 { return 14.5 }      // 1:30 rest = up to 14:30hr
        if restTime <= 1.75 { return 15.0 }     // 1:45 rest = 14:31-15:00hr
        if restTime <= 2.0 { return 15.5 }      // 2:00 rest = 15:01-15:30hr
        if restTime <= 2.25 { return 16.0 }     // 2:15 rest = 15:31-16:00hr
        if restTime <= 2.58 { return 16.5 }     // 2:35 rest = 16:01-16:30hr
        if restTime <= 3.0 { return 17.0 }      // 3:00 rest = 16:31-17:00hr
        if restTime <= 3.42 { return 17.5 }     // 3:25 rest = 17:01-17:30hr
        if restTime <= 3.83 { return 18.0 }     // 3:50 rest = 17:31-18:00hr
        return 18.0 // Maximum allowed
    }
    
    // MARK: - Class 2 Rest Facility FDP Limits (Table 5)
    /// Class 2: Reclining seat with leg support in a separate compartment
    /// Maximum FDP: Up to 17:00 hours
    private static func getClass2MaxFDP(for restTime: Double) -> Double {
        // Table 5 Class 2 logic from British Airways OM A
        if restTime <= 1.5 { return 14.5 }      // 1:30 rest = up to 14:30hr
        if restTime <= 2.0 { return 15.0 }      // 2:00 rest = 14:31-15:00hr
        if restTime <= 2.33 { return 15.5 }     // 2:20 rest = 15:01-15:30hr
        if restTime <= 2.67 { return 16.0 }     // 2:40 rest = 15:31-16:00hr
        if restTime <= 3.0 { return 16.5 }      // 3:00 rest = 16:01-16:30hr
        if restTime <= 3.42 { return 17.0 }     // 3:25 rest = 16:31-17:00hr
        // 17:01-18:00 not allowed for Class 2
        return 17.0 // Maximum allowed for Class 2
    }
    
    // MARK: - Class 3 Rest Facility FDP Limits (Table 5)
    /// Class 3: Reclining seat with leg support in the passenger cabin
    /// Maximum FDP: Up to 16:00 hours
    private static func getClass3MaxFDP(for restTime: Double) -> Double {
        // Table 5 Class 3 logic from British Airways OM A
        if restTime <= 1.5 { return 14.5 }      // 1:30 rest = up to 14:30hr
        if restTime <= 2.33 { return 15.0 }     // 2:20 rest = 14:31-15:00hr
        if restTime <= 2.67 { return 15.5 }     // 2:40 rest = 15:01-15:30hr
        if restTime <= 3.0 { return 16.0 }      // 3:00 rest = 15:31-16:00hr
        // 16:01-18:00 not allowed for Class 3
        return 16.0 // Maximum allowed for Class 3
    }
    
    // MARK: - Helper Methods
    
    /// Get available rest time options for a given rest facility class
    static func getAvailableRestTimeOptions(for restFacilityType: RestFacilityType) -> [Double] {
        switch restFacilityType {
        case .class1:
            return [1.5, 1.75, 2.0, 2.25, 2.58, 3.0, 3.42, 3.83]
        case .class2:
            return [1.5, 2.0, 2.33, 2.67, 3.0, 3.42]
        case .class3:
            return [1.5, 2.33, 2.67, 3.0]
        case .none:
            return []
        }
    }
    
    /// Format rest time for display (e.g., 1.5 -> "1h 30m")
    static func formatRestTime(_ time: Double) -> String {
        let hours = Int(time)
        let minutes = Int((time.truncatingRemainder(dividingBy: 1)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    /// Get the maximum allowed FDP display string for a given rest facility and rest time
    static func getMaxFDPDisplayString(restFacilityType: RestFacilityType, restTimeAvailable: Double) -> String {
        let maxFDP = lookupMaxFDP(restFacilityType: restFacilityType, restTimeAvailable: restTimeAvailable)
        let hours = Int(maxFDP)
        let minutes = Int((maxFDP.truncatingRemainder(dividingBy: 1)) * 60)
        
        if minutes == 0 {
            return "Up to \(hours):00hr"
        } else {
            return "Up to \(hours):\(String(format: "%02d", minutes))hr"
        }
    }
}
