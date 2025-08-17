//
//  SectorsSection.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct SectorsSection: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Sectors and FDP Extensions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Number of Sectors
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "number.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Number of Sectors")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Number of Sectors", selection: $viewModel.numberOfSectors) {
                        ForEach([1, 3, 4, 5, 6, 7, 8, 9, 10], id: \.self) { sector in
                            if sector == 1 {
                                Text("1-2 sectors").tag(1)
                            } else {
                                Text("\(sector) sectors").tag(sector)
                            }
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // In-Flight Rest
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bed.double")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("In-Flight Rest")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            if viewModel.hasInFlightRest {
                                Text(viewModel.restFacilityType.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(viewModel.hasSplitDuty || viewModel.hasExtendedFDP ? .secondary : .primary)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Sectors: \(viewModel.inFlightRestSectors == 1 ? "1-2" : "3")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if viewModel.inFlightRestSectors == 1 && viewModel.isLongFlight {
                                        Text("Long Flight (>9h)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text("Additional Crew: \(viewModel.additionalCrewMembers)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("No In-Flight Rest")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { viewModel.hasInFlightRest },
                            set: { newValue in
                                viewModel.hasInFlightRest = newValue
                                if newValue {
                                    viewModel.showingInFlightRestPicker = true
                                }
                            }
                        ))
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .disabled(viewModel.hasSplitDuty || viewModel.hasExtendedFDP)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background((viewModel.hasSplitDuty || viewModel.hasExtendedFDP) ? Color(.systemGray4) : Color(.systemGray6))
                    .cornerRadius(12)
                    

                }
                
                // Split Duty
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Split Duty")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Split duty (break on the ground)")
                                .font(.subheadline)
                                .foregroundColor(viewModel.hasInFlightRest ? .secondary : .primary)
                            Text("Allows duty to be split by rest periods")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { viewModel.hasSplitDuty },
                            set: { newValue in
                                viewModel.hasSplitDuty = newValue
                                if newValue {
                                    viewModel.showingSplitDutyOptions = true
                                }
                            }
                        ))
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                            .disabled(viewModel.hasInFlightRest || viewModel.hasExtendedFDP)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                                            .background((viewModel.hasInFlightRest || viewModel.hasExtendedFDP) ? Color(.systemGray4) : Color(.systemGray6))
                    .cornerRadius(12)
                    

                    
                    // Warning: Split Duty not allowed with In-Flight Rest
                    if viewModel.hasInFlightRest {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Split Duty not allowed with In-Flight Rest")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    

                }
                
                // Extended FDP
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.badge.plus")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Extended FDP")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Extended flight duty period limits")
                                .font(.subheadline)
                                .foregroundColor(viewModel.hasInFlightRest || viewModel.hasSplitDuty ? .secondary : .primary)
                            Text("Allows extended FDP limits")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { viewModel.hasExtendedFDP },
                            set: { newValue in
                                viewModel.hasExtendedFDP = newValue
                                if newValue {
                                    // TODO: Add Extended FDP configuration sheet when implemented
                                    // viewModel.showingExtendedFDPOptions = true
                                }
                            }
                        ))
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            .disabled(viewModel.hasInFlightRest || viewModel.hasSplitDuty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                                            .background((viewModel.hasInFlightRest || viewModel.hasSplitDuty) ? Color(.systemGray4) : Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Warning: Extended FDP not allowed with In-Flight Rest
                    if viewModel.hasInFlightRest {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Extended FDP not allowed with In-Flight Rest")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Warning: Extended FDP not allowed with Split Duty
                    if viewModel.hasSplitDuty && !viewModel.hasInFlightRest {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Extended FDP not allowed with Split Duty")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

