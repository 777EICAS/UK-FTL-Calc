//
//  ManualCalcViewModel+FDP.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

// MARK: - FDP Calculation Extension
extension ManualCalcViewModel {
    
    // MARK: - FDP Calculation Functions
    func calculateMaxFDP() -> Double {
        let acclimatisationResult = calculateAcclimatisation()
        
        // Check if extended FDP is enabled first
        if hasExtendedFDP {
            let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
            
            // Use the appropriate baseline time based on standby type
            let referenceDateTime: Date
            if isStandbyEnabled {
                switch selectedStandbyType {
                case "Airport Duty":
                    referenceDateTime = airportDutyStartDateTime
                case "Airport Standby":
                    referenceDateTime = reportingDateTime // Airport standby: FDP starts from report time
                case "Standby":
                    referenceDateTime = reportingDateTime // Home standby: FDP starts from report time
                case "Reserve":
                    referenceDateTime = reportingDateTime // Reserve: FDP starts from report time
                default:
                    referenceDateTime = reportingDateTime
                }
            } else {
                referenceDateTime = reportingDateTime
            }
            
            let timeString = utcTimeFormatter.string(from: referenceDateTime)
            let localTime = TimeUtilities.getLocalTime(for: timeString, airportCode: currentDeparture)
            let sectorsForLookup = numberOfSectors == 1 ? 2 : numberOfSectors
            
            // Use extended FDP table (Table 4)
            if let extendedFDP = RegulatoryTableLookup.lookupExtendedFDP(reportTime: localTime, sectors: sectorsForLookup) {
                // Extended FDP: no split duty or in-flight rest extensions allowed
                return extendedFDP
            } else {
                // Fall back to standard calculation if extended FDP not allowed
            }
        }
        
        let baseFDP: Double
        switch acclimatisationResult {
        case "B", "D":
            let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
            
            // Use the appropriate baseline time based on standby type
            let referenceDateTime: Date
            if isStandbyEnabled {
                switch selectedStandbyType {
                case "Airport Duty":
                    referenceDateTime = airportDutyStartDateTime
                case "Airport Standby":
                    referenceDateTime = reportingDateTime // Airport standby: FDP starts from report time
                case "Standby":
                    referenceDateTime = reportingDateTime // Home standby: FDP starts from report time
                case "Reserve":
                    referenceDateTime = reportingDateTime // Reserve: FDP starts from report time
                default:
                    referenceDateTime = reportingDateTime
                }
            } else {
                referenceDateTime = reportingDateTime
            }
            
            let timeString = utcTimeFormatter.string(from: referenceDateTime)
            let localTime = TimeUtilities.getLocalTime(for: timeString, airportCode: currentDeparture)
            let sectorsForLookup = numberOfSectors == 1 ? 2 : numberOfSectors
            
            baseFDP = RegulatoryTableLookup.lookupFDPAcclimatised(reportTime: localTime, sectors: sectorsForLookup)
            
        case "X":
            let result = RegulatoryTableLookup.lookupFDPUnknownAcclimatised(sectors: numberOfSectors)
            baseFDP = result
            
        default:
            baseFDP = 9.0
        }
        
        // Apply split duty extension if enabled
        var finalFDP = baseFDP
        if hasSplitDuty {
            let splitDutyExtension = calculateSplitDutyExtension()
            finalFDP = baseFDP + splitDutyExtension
        }
        
        // Return final FDP (base + split duty extension if applicable)
        // Standby reduction will be applied in calculateTotalFDP()
        return finalFDP
    }
    
    // Helper method to get base FDP without extensions (for breakdown display)
    func getBaseFDP() -> Double {
        let acclimatisationResult = calculateAcclimatisation()
        
        let baseFDP: Double
        switch acclimatisationResult {
        case "B", "D":
            let currentDeparture = selectedReportingLocation.isEmpty ? homeBase : selectedReportingLocation
            
            // Use the appropriate baseline time based on standby type
            let referenceDateTime: Date
            if isStandbyEnabled {
                switch selectedStandbyType {
                case "Airport Duty":
                    referenceDateTime = airportDutyStartDateTime
                case "Airport Standby":
                    referenceDateTime = reportingDateTime
                case "Standby":
                    referenceDateTime = reportingDateTime
                case "Reserve":
                    referenceDateTime = reportingDateTime
                default:
                    referenceDateTime = reportingDateTime
                }
            } else {
                referenceDateTime = reportingDateTime
            }
            
            let timeString = utcTimeFormatter.string(from: referenceDateTime)
            let localTime = TimeUtilities.getLocalTime(for: timeString, airportCode: currentDeparture)
            let sectorsForLookup = numberOfSectors == 1 ? 2 : numberOfSectors
            
            baseFDP = RegulatoryTableLookup.lookupFDPAcclimatised(reportTime: localTime, sectors: sectorsForLookup)
            
        case "X":
            baseFDP = RegulatoryTableLookup.lookupFDPUnknownAcclimatised(sectors: numberOfSectors)
            
        default:
            baseFDP = 9.0
        }
        
        return baseFDP
    }
    
    func calculateTotalFDP() -> Double {
        let baseFDP = calculateMaxFDP()
        
        // Apply in-flight rest extension if applicable
        var adjustedFDP = baseFDP
        if hasInFlightRest && restFacilityType != .none {
            let inFlightRestFDP = calculateInFlightRestExtension()
            adjustedFDP = inFlightRestFDP  // Replace base limit with in-flight rest limit
        }
        
        // Split duty extension is now included in calculateMaxFDP()
        // No need to add it again here
        
        // Apply standby reduction if applicable
        if isStandbyEnabled {
            if selectedStandbyType == "Standby" {
                // Home Standby: FDP starts from report time, reduced by standby exceeding 6-8 hours
                let standbyDuration = calculateStandbyDuration(standbyContactTime: standbyContactTime)
                let thresholdHours = (hasInFlightRest && restFacilityType != .none) || hasSplitDuty ? 8.0 : 6.0
                
                if standbyDuration > thresholdHours {
                    let reduction = standbyDuration - thresholdHours
                    adjustedFDP = adjustedFDP - reduction
                }
                
            } else if selectedStandbyType == "Airport Standby" {
                // Airport Standby: FDP starts from report time, reduced by standby exceeding 4 hours
                let standbyDuration = calculateStandbyDuration(standbyContactTime: standbyContactTime)
                let thresholdHours = 4.0 // Airport standby threshold is always 4 hours
                
                if standbyDuration > thresholdHours {
                    let reduction = standbyDuration - thresholdHours
                    adjustedFDP = adjustedFDP - reduction
                }
                
            } else if selectedStandbyType == "Airport Duty" {
                // Airport Duty: No FDP reduction, all time counts towards duty
            } else if selectedStandbyType == "Reserve" {
                // Reserve: No FDP reduction, doesn't count towards duty
            }
        }
        
        // Apply minimum FDP limit after all adjustments
        // For home standby and airport standby cases, allow FDP to go below 9.0h as per UK CAA rules
        let minimumFDP = 9.0
        let isStandbyReduction = isStandbyEnabled && 
            ((selectedStandbyType == "Standby" && calculateStandbyDuration(standbyContactTime: standbyContactTime) > ((hasInFlightRest && restFacilityType != .none) || hasSplitDuty ? 8.0 : 6.0)) ||
             (selectedStandbyType == "Airport Standby" && calculateStandbyDuration(standbyContactTime: standbyContactTime) > 4.0))
        
        if adjustedFDP < minimumFDP && !isStandbyReduction {
            adjustedFDP = minimumFDP
        }
        
        // Check 16-hour total duty time rule for airport standby
        if isStandbyEnabled && selectedStandbyType == "Airport Standby" {
            let standbyDuration = calculateStandbyDuration(standbyContactTime: standbyContactTime)
            let totalDutyTime = standbyDuration + adjustedFDP
            let maxAllowedDutyTime = (hasInFlightRest && restFacilityType != .none) || hasSplitDuty ? 18.0 : 16.0
            
            if totalDutyTime > maxAllowedDutyTime {
                // TODO: Add user-facing warning for 16-hour rule violation
            }
        }
        
        return adjustedFDP
    }
    
    func calculateInFlightRestExtension() -> Double {
    // Extended FDP cannot be combined with in-flight rest extensions
    if hasExtendedFDP {
        return 0.0
    }
    
    // NEW: Check if cabin crew with in-flight rest
    print("DEBUG: calculateInFlightRestExtension - crewType: '\(crewType)', hasInFlightRest: \(hasInFlightRest), restFacilityType: \(restFacilityType)")
    
    if crewType == "Cabin Crew" && hasInFlightRest && restFacilityType != .none {
        print("DEBUG: calculateInFlightRestExtension - Cabin crew path selected")
        // Use Table 5 data from separate file for cabin crew
        let maxAllowedFDP = CabinCrewInFlightRestTable.lookupMaxFDP(
            restFacilityType: restFacilityType,
            restTimeAvailable: inFlightRestTimeAvailable
        )
        print("DEBUG: calculateInFlightRestExtension - Table 5 maxAllowedFDP: \(maxAllowedFDP)h")
        
        // For cabin crew, return the maximum allowed FDP from Table 5 (replacement limit)
        print("DEBUG: calculateInFlightRestExtension - Cabin crew maxAllowedFDP: \(maxAllowedFDP)h")
        return maxAllowedFDP
    } else {
        print("DEBUG: calculateInFlightRestExtension - Pilot path selected")
        // EXISTING PILOT LOGIC - COMPLETELY UNCHANGED
        let restClass: String
        switch restFacilityType {
        case .class1:
            restClass = "class_1"
        case .class2:
            restClass = "class_2"
        case .class3:
            restClass = "class_3"
        case .none:
            return 0.0
        }
        
        let pilotExtension = RegulatoryTableLookup.lookupInflightRestExtension(
            restClass: restClass,
            additionalCrew: additionalCrewMembers,
            isLongFlight: isLongFlight
        )
        print("DEBUG: calculateInFlightRestExtension - Pilot extension calculated: \(pilotExtension)h")
        return pilotExtension
    }
}
    
    // MARK: - Latest Off/On Blocks Time Calculations
    func calculateLatestOffBlocksTime(withCommandersDiscretion: Bool) -> Date {
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        
        let baselineTime = getBaselineTimeForCalculations()
        let timeWithFDP = baselineTime.addingTimeInterval(totalFDP * 3600)
        let latestOffBlocks = timeWithFDP.addingTimeInterval(-estimatedBlockTime * 3600)
        
        return latestOffBlocks
    }
    
    func calculateLatestOnBlocksTime(withCommandersDiscretion: Bool = false) -> Date {
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        
        let baselineTime = getBaselineTimeForCalculations()
        return baselineTime.addingTimeInterval(totalFDP * 3600)
    }
    
    func calculateTotalDutyTime(withCommandersDiscretion: Bool = false) -> Double {
        let maxFDP = calculateTotalFDP()
        let totalFDP = withCommandersDiscretion ? maxFDP + getCommandersDiscretionExtension() : maxFDP
        return totalFDP
    }
    
    // MARK: - Helper Functions
    func getCommandersDiscretionExtension() -> Double {
        // If extended FDP is enabled, apply the 2-hour total extension limit
        if hasExtendedFDP {
            return getCommandersDiscretionExtensionWithExtendedFDPLimit()
        }
        
        // Standard commanders discretion logic (unchanged)
        if hasInFlightRest && restFacilityType != .none {
            return 3.0
        } else {
            return 2.0
        }
    }
    
    /// Calculates commanders discretion extension when extended FDP is enabled
    /// The total extension from standard FDP cannot exceed 2 hours
    private func getCommandersDiscretionExtensionWithExtendedFDPLimit() -> Double {
        // Get the baseline FDP from standard tables (Table 2/3)
        let baselineFDP = getBaseFDP()
        
        // Get the extended FDP from Table 4
        let extendedFDP = calculateMaxFDP()
        
        // Calculate how much extension the extended FDP table already provides
        let extendedFDPMargin = extendedFDP - baselineFDP
        
        // Commanders discretion can only be used to reach the 2-hour total extension limit
        let availableCommandersDiscretion = max(0.0, 2.0 - extendedFDPMargin)
        
        return availableCommandersDiscretion
    }
    
    func getBaselineTimeForCalculations() -> Date {
        let baselineTime: Date
        
        if isStandbyEnabled {
            switch selectedStandbyType {
            case "Airport Duty":
                baselineTime = airportDutyStartDateTime // Use airport duty start time for FDP calculations
            case "Airport Standby":
                baselineTime = reportingDateTime // Airport standby: FDP starts from report time
            case "Standby":
                baselineTime = reportingDateTime // Home standby: FDP starts from report time
            case "Reserve":
                baselineTime = reportingDateTime // Reserve: FDP starts from report time
            default:
                baselineTime = reportingDateTime
            }
        } else {
            baselineTime = reportingDateTime
        }
        
        return baselineTime
    }
}
