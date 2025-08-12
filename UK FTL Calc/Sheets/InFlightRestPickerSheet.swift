//
//  InFlightRestPickerSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct InFlightRestPickerSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("In-Flight Rest Configuration")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Sector Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Number of Sectors")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Picker("Sectors", selection: $viewModel.inFlightRestSectors) {
                                Text("1-2 sectors").tag(1)
                                Text("3 sectors").tag(3)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Text("Select the number of sectors for this duty")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Long Flight Option (only for 1-2 sectors)
                        if viewModel.inFlightRestSectors == 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Long Flight Option")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Text("One sector with flight time greater than 9 hours")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $viewModel.isLongFlight)
                                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                
                                Text("This option provides extended FDP limits for long flights")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Additional Crew Members
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Flight Crew Members")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Picker("Additional Crew", selection: $viewModel.additionalCrewMembers) {
                                Text("1 additional crew").tag(1)
                                Text("2 additional crew").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Text("Number of additional crew members providing in-flight rest")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Rest Facility Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Rest Facility Class")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                // No In-Flight Rest Option
                                Button(action: {
                                    viewModel.hasInFlightRest = false
                                    viewModel.restFacilityType = .none
                                    viewModel.inFlightRestSectors = 1
                                    viewModel.isLongFlight = false
                                    viewModel.additionalCrewMembers = 1
                                    isPresented = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("No In-Flight Rest")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Text("No dedicated rest facility available")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if !viewModel.hasInFlightRest {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title2)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Class 1 Rest Facility
                                Button(action: {
                                    viewModel.hasInFlightRest = true
                                    viewModel.restFacilityType = .class1
                                    viewModel.hasSplitDuty = false
                                    viewModel.hasExtendedFDP = false
                                    isPresented = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Class 1 Rest Facility")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Text("Bunk or flat bed in a separate compartment")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if viewModel.hasInFlightRest && viewModel.restFacilityType == .class1 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title2)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Class 2 Rest Facility
                                Button(action: {
                                    viewModel.hasInFlightRest = true
                                    viewModel.restFacilityType = .class2
                                    viewModel.hasSplitDuty = false
                                    viewModel.hasExtendedFDP = false
                                    isPresented = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Class 2 Rest Facility")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Text("Reclining seat with leg support in a separate compartment")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if viewModel.hasInFlightRest && viewModel.restFacilityType == .class2 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title2)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Class 3 Rest Facility
                                Button(action: {
                                    viewModel.hasInFlightRest = true
                                    viewModel.restFacilityType = .class3
                                    viewModel.hasSplitDuty = false
                                    viewModel.hasExtendedFDP = false
                                    isPresented = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Class 3 Rest Facility")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Text("Reclining seat with leg support in the passenger cabin")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if viewModel.hasInFlightRest && viewModel.restFacilityType == .class3 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title2)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // FDP Extension Preview
                        if viewModel.hasInFlightRest && viewModel.restFacilityType != .none {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("FDP Extension Preview")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                let extensionHours = viewModel.calculateInFlightRestExtension()
                                let baseFDP = viewModel.calculateMaxFDP()
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Base FDP:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(String(format: "%.1f", baseFDP))h")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    HStack {
                                        Text("In-Flight Rest FDP:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(String(format: "%.1f", extensionHours))h")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Max FDP:")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Text("\(String(format: "%.1f", extensionHours))h")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sectors: \(viewModel.inFlightRestSectors == 1 ? "1-2" : "3")")
                                    Text("Long Flight: \(viewModel.isLongFlight ? "Yes" : "No")")
                                    Text("Additional Crew: \(viewModel.additionalCrewMembers)")
                                    Text("Rest Facility: \(viewModel.restFacilityType.rawValue)")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("In-Flight Rest")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

