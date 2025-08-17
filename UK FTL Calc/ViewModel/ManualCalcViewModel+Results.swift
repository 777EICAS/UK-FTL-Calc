//
//  ManualCalcViewModel+Results.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

// MARK: - Results and Main Calculation Extension
extension ManualCalcViewModel {
    
    // MARK: - Calculate Button Method
    func performCalculation() {
        isCalculating = true
        hasCalculated = true
        
        print("DEBUG: performCalculation - Starting calculation")
        
        // Run all calculations once using existing logic
        let maxFDP = calculateMaxFDP()
        let totalFDP = calculateTotalFDP()
        let inFlightRestExtension = calculateInFlightRestExtension()
        let splitDutyExtension = calculateSplitDutyExtension()
        let standbyDuration = calculateStandbyDuration(standbyContactTime: standbyContactTime)
        let acclimatisation = calculateAcclimatisation()
        let latestOffBlocksTime = calculateLatestOffBlocksTime(withCommandersDiscretion: false)
        let latestOnBlocksTime = calculateLatestOnBlocksTime(withCommandersDiscretion: false)
        let totalDutyTime = calculateTotalDutyTime(withCommandersDiscretion: false)
        let calculationBreakdown = formatCalculationBreakdown(withCommandersDiscretion: false)
        
        print("DEBUG: performCalculation - standbyDuration calculated: \(standbyDuration)h")
        print("DEBUG: performCalculation - maxFDP: \(maxFDP)h, totalFDP: \(totalFDP)h")
        
        // Store results
        calculationResults = FTLCalculationResults(
            maxFDP: maxFDP,
            totalFDP: totalFDP,
            inFlightRestExtension: inFlightRestExtension,
            splitDutyExtension: splitDutyExtension,
            standbyDuration: standbyDuration,
            acclimatisation: acclimatisation,
            latestOffBlocksTime: latestOffBlocksTime,
            latestOnBlocksTime: latestOnBlocksTime,
            totalDutyTime: totalDutyTime,
            calculationBreakdown: calculationBreakdown
        )
        
        print("DEBUG: performCalculation - Calculation completed and stored")
        isCalculating = false
    }
    
    // Method to apply split duty settings and force calculation update
    func applySplitDutySettings() {
        // Update the actual split duty properties from the selected values
        updateBreakDurationFromCustomInput()
        updateBreakBeginTimeFromCustomInput()
        
        clearCache()
        // Force UI update by triggering objectWillChange
        objectWillChange.send()
    }
}

// MARK: - FTL Calculation Results
struct FTLCalculationResults {
    let maxFDP: Double
    let totalFDP: Double
    let inFlightRestExtension: Double
    let splitDutyExtension: Double
    let standbyDuration: Double
    let acclimatisation: String
    let latestOffBlocksTime: Date
    let latestOnBlocksTime: Date
    let totalDutyTime: Double
    let calculationBreakdown: String
}
