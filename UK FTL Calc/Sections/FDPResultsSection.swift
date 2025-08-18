//
//  FDPResultsSection.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct FDPResultsSection: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("FDP Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Base FDP
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base FDP")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if viewModel.hasCalculated {
                            Text("\(TimeUtilities.formatHoursAndMinutes(viewModel.cachedMaxFDP))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        } else {
                            Text("Press Calculate to see results")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Acclimatisation")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if viewModel.hasCalculated {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.selectedAcclimatisation == "X" ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(viewModel.selectedAcclimatisation == "X" ? .red : (viewModel.selectedAcclimatisation == "D" ? .orange : .green))
                                    .font(.caption)
                                Text(viewModel.selectedAcclimatisation.isEmpty ? "Not Set" : viewModel.selectedAcclimatisation)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(viewModel.selectedAcclimatisation == "X" ? .red : (viewModel.selectedAcclimatisation == "D" ? .orange : .green))
                            }
                        } else {
                            Text("Not calculated")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Home Standby Rules Applied (if applicable)
                if viewModel.isStandbyEnabled && viewModel.selectedStandbyType == "Standby" && viewModel.hasCalculated {
                    let standbyDuration = viewModel.cachedStandbyDuration
                    let thresholdHours = (viewModel.hasInFlightRest && viewModel.restFacilityType != .none) || viewModel.hasSplitDuty ? 8.0 : 6.0
                    let totalAwakeTime = standbyDuration + viewModel.cachedMaxFDP
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text("Home Standby Rules Applied")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Standby Duration: \(TimeUtilities.formatHoursAndMinutes(standbyDuration))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Threshold: \(TimeUtilities.formatHoursAndMinutes(thresholdHours)) (\(viewModel.hasInFlightRest && viewModel.restFacilityType != .none ? "In-Flight Rest" : viewModel.hasSplitDuty ? "Split Duty" : "Standard"))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if standbyDuration > thresholdHours {
                                let reduction = standbyDuration - thresholdHours
                                Text("FDP Reduction: -\(TimeUtilities.formatHoursAndMinutes(reduction))")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .fontWeight(.medium)
                                
                                // Show in-flight rest reduction if applicable
                                if viewModel.hasInFlightRest && viewModel.restFacilityType != .none {
                                    let inFlightRestFDP = viewModel.cachedInFlightRestExtension
                                    let finalFDP = inFlightRestFDP - reduction
                                    Text("In-Flight Rest FDP: \(TimeUtilities.formatHoursAndMinutes(inFlightRestFDP)) - \(TimeUtilities.formatHoursAndMinutes(reduction)) = \(TimeUtilities.formatHoursAndMinutes(finalFDP))")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Text("Total Awake Time: \(TimeUtilities.formatHoursAndMinutes(totalAwakeTime)) / 18h")
                                .font(.caption)
                                .foregroundColor(totalAwakeTime > 18.0 ? .red : .green)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // In-Flight Rest Extension (if applicable)
                if viewModel.hasInFlightRest && viewModel.restFacilityType != .none {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("In-Flight Rest FDP")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("\(TimeUtilities.formatHoursAndMinutes(viewModel.cachedInFlightRestExtension))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Rest Facility")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "bed.double.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text(viewModel.restFacilityType.rawValue)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Split Duty Extension (if applicable)
                if viewModel.hasSplitDuty {
                    let splitDutyDetails = viewModel.getSplitDutyExtensionDetails()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Split Duty FDP")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("\(TimeUtilities.formatHoursAndMinutes(splitDutyDetails.extension))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Accommodation")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "bed.double.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(viewModel.splitDutyAccommodationType)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Split Duty Details
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Split Duty Details")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Break Duration: \(TimeUtilities.formatHoursAndMinutes(viewModel.splitDutyBreakDuration))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if viewModel.splitDutyAccommodationType == "Accommodation" {
                                Text("Break Begin: \(viewModel.formatTimeAsUTC(viewModel.splitDutyBreakBegin))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(splitDutyDetails.explanation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Total FDP
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Max FDP")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        let totalFDP = viewModel.cachedTotalFDP
                        Text("\(TimeUtilities.formatHoursAndMinutes(totalFDP))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        // Show breakdown if extensions are applied
                        if (viewModel.hasInFlightRest && viewModel.restFacilityType != .none) || viewModel.hasSplitDuty {
                            let baseFDP = viewModel.getBaseFDP()
                            let breakdown = getFDPBreakdown(baseFDP: baseFDP)
                            
                            Text(breakdown)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Sectors")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "number.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(viewModel.numberOfSectors == 1 ? "1-2" : "\(viewModel.numberOfSectors)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Functions
    private func getFDPBreakdown(baseFDP: Double) -> String {
        var breakdown = "Base: \(TimeUtilities.formatHoursAndMinutes(baseFDP))"
        
        if viewModel.hasInFlightRest && viewModel.restFacilityType != .none {
            let inFlightRestExtension = viewModel.cachedInFlightRestExtension - baseFDP
            if inFlightRestExtension > 0 {
                breakdown += " + In-Flight Rest: +\(TimeUtilities.formatHoursAndMinutes(inFlightRestExtension))"
            }
        }
        
        if viewModel.hasSplitDuty {
            let splitDutyExtension = viewModel.calculateSplitDutyExtension()
            if splitDutyExtension > 0 {
                breakdown += " + Split Duty: +\(TimeUtilities.formatHoursAndMinutes(splitDutyExtension))"
            }
        }
        
        return breakdown
    }
}

