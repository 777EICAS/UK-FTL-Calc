//
//  DetailsSheets.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

// MARK: - With Discretion Details Sheet
struct WithDiscretionDetailsSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("With Commander's Discretion Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Calculation Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Details:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            let baselineTime = viewModel.getBaselineTimeForCalculations()
                            let baselineLabel = viewModel.isStandbyEnabled && viewModel.selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
                            Text("• \(baselineLabel): \(viewModel.formatTimeForDisplay(baselineTime))")
                            if viewModel.hasInFlightRest && viewModel.restFacilityType != .none {
                                Text("• In-Flight Rest FDP: \(String(format: "%.1f", viewModel.calculateInFlightRestExtension()))h")
                                Text("• Max FDP: \(String(format: "%.1f", viewModel.calculateTotalFDP()))h (In-Flight Rest)")
                            } else {
                                Text("• Max FDP: \(String(format: "%.1f", viewModel.calculateTotalFDP()))h")
                            }
                            Text("• Estimated Block Time: \(String(format: "%.1f", viewModel.estimatedBlockTime))h")
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Calculation Steps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Steps:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        Text(viewModel.formatCalculationBreakdown(withCommandersDiscretion: true))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Commander's Discretion Extension
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Commander's Discretion Extension:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        Text("+\(String(format: "%.1f", viewModel.getCommandersDiscretionExtension()))h")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        if viewModel.hasInFlightRest && viewModel.restFacilityType != .none {
                            Text("With additional crew: +3 hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No additional crew: +2 hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Done") {
                    isPresented = false
                }
                .foregroundColor(.blue)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
            }
            .navigationTitle("With Commander's Discretion")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

// MARK: - Without Discretion Details Sheet
struct WithoutDiscretionDetailsSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Without Commander's Discretion Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Calculation Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Details:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            let baselineTime = viewModel.getBaselineTimeForCalculations()
                            let baselineLabel = viewModel.isStandbyEnabled && viewModel.selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
                            Text("• \(baselineLabel): \(viewModel.formatTimeForDisplay(baselineTime))")
                            if viewModel.hasInFlightRest && viewModel.restFacilityType != .none {
                                Text("• Max FDP: \(String(format: "%.1f", viewModel.calculateInFlightRestExtension()))h")
                                Text("• Max FDP: \(String(format: "%.1f", viewModel.calculateTotalFDP()))h (In-Flight Rest)")
                            } else {
                                Text("• Max FDP: \(String(format: "%.1f", viewModel.calculateTotalFDP()))h")
                            }
                            Text("• Estimated Block Time: \(String(format: "%.1f", viewModel.estimatedBlockTime))h")
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Calculation Steps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Steps:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text(viewModel.formatCalculationBreakdown(withCommandersDiscretion: false))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Max FDP Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximum FDP:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text("\(String(format: "%.1f", viewModel.calculateTotalFDP()))h")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        if viewModel.hasInFlightRest && viewModel.restFacilityType != .none {
                            Text("In-Flight Rest FDP Limit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Standard FDP Limit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Done") {
                    isPresented = false
                }
                .foregroundColor(.blue)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
            }
            .navigationTitle("Without Commander's Discretion")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

// MARK: - ON Blocks Details Sheet
struct OnBlocksDetailsSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Latest ON Blocks Time Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Calculation Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Details:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            let baselineTime = viewModel.getBaselineTimeForCalculations()
                            let baselineLabel = viewModel.isStandbyEnabled && viewModel.selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
                            Text("• \(baselineLabel): \(viewModel.formatTimeForDisplay(baselineTime))")
                            if viewModel.hasInFlightRest && viewModel.restFacilityType != .none {
                                Text("• In-Flight Rest FDP: \(String(format: "%.1f", viewModel.calculateInFlightRestExtension()))h")
                                Text("• Max FDP: \(String(format: "%.1f", viewModel.calculateTotalFDP()))h (In-Flight Rest)")
                            } else {
                                Text("• Max FDP: \(String(format: "%.1f", viewModel.calculateTotalFDP()))h")
                            }
                            Text("• Estimated Block Time: \(String(format: "%.1f", viewModel.estimatedBlockTime))h")
                            Text("• Total Duty Time: \(String(format: "%.1f", viewModel.calculateTotalDutyTime()))h")
                        }
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Calculation Steps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Steps:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Without Commander's Discretion:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            let baselineTime = viewModel.getBaselineTimeForCalculations()
                            let baselineLabel = viewModel.isStandbyEnabled && viewModel.selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
                            Text("\(viewModel.formatTimeForDisplay(baselineTime))z (\(baselineLabel)) + \(String(format: "%.1f", viewModel.calculateTotalDutyTime(withCommandersDiscretion: false)))h = \(viewModel.formatTimeForDisplay(viewModel.calculateLatestOnBlocksTime(withCommandersDiscretion: false)))z")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Text("With Commander's Discretion:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            Text("\(viewModel.formatTimeForDisplay(baselineTime))z (\(baselineLabel)) + \(String(format: "%.1f", viewModel.calculateTotalDutyTime(withCommandersDiscretion: true)))h = \(viewModel.formatTimeForDisplay(viewModel.calculateLatestOnBlocksTime(withCommandersDiscretion: true)))z")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Total Duty Time Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Duty Time:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Without Commander's Discretion:")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Spacer()
                                Text("\(String(format: "%.1f", viewModel.calculateTotalDutyTime(withCommandersDiscretion: false)))h")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("With Commander's Discretion:")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                Spacer()
                                Text("\(String(format: "%.1f", viewModel.calculateTotalDutyTime(withCommandersDiscretion: true)))h")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        let baselineLabel = viewModel.isStandbyEnabled && viewModel.selectedStandbyType == "Airport Duty" ? "Airport Duty Start" : "Reporting Time"
                        Text("Latest ON Blocks = \(baselineLabel) + Max FDP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Done") {
                    isPresented = false
                }
                .foregroundColor(.blue)
                .font(.title3)
                .fontWeight(.semibold)
                .padding()
            }
            .navigationTitle("Latest ON Blocks Time")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

