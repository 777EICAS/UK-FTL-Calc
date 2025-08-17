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
        VStack(alignment: .leading, spacing: 12) {
            // Section Header - More compact
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Sectors and FDP Extensions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 14) {
                // Option 1: Number of Sectors - Reduced padding
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "number.circle")
                            .foregroundColor(.blue)
                            .font(.title3)
                        Text("Number of Sectors")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
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
                    .frame(height: 100)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                
                // Option 2: In-Flight Rest - Reduced padding
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "bed.double")
                            .foregroundColor(.blue)
                            .font(.title3)
                        Text("In-Flight Rest")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
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
                    
                    if viewModel.hasInFlightRest {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.restFacilityType.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(viewModel.hasSplitDuty || viewModel.hasExtendedFDP ? .secondary : .primary)
                            
                            VStack(alignment: .leading, spacing: 3) {
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
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("No In-Flight Rest")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("Allows duty to be extended with augmented crew and inflight rest")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background((viewModel.hasSplitDuty || viewModel.hasExtendedFDP) ? Color(.systemGray4) : Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                
                // Option 3: Split Duty - Reduced padding
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.orange)
                            .font(.title3)
                        Text("Split Duty")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
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
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Split duty (break on the ground)")
                            .font(.subheadline)
                            .foregroundColor(viewModel.hasInFlightRest ? .secondary : .primary)
                        Text("Allows duty to be split by rest periods")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Warning: Split Duty not allowed with In-Flight Rest - Reduced padding
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
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background((viewModel.hasInFlightRest || viewModel.hasExtendedFDP) ? Color(.systemGray4) : Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                
                // Option 4: Extended FDP - Reduced padding
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        Text("Extended FDP")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
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
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Extended flight duty period limits")
                            .font(.subheadline)
                            .foregroundColor(viewModel.hasInFlightRest || viewModel.hasSplitDuty ? .secondary : .primary)
                        Text("Allows extended FDP limits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Warning: Extended FDP not allowed with In-Flight Rest - Reduced padding
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
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Warning: Extended FDP not allowed with Split Duty - Reduced padding
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
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background((viewModel.hasInFlightRest || viewModel.hasSplitDuty) ? Color(.systemGray4) : Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

