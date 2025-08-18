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
            VStack(spacing: 0) {
                // Enhanced Header
                VStack(spacing: 16) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 80, height: 80)
                        )
                    
                    Text("In-Flight Rest Configuration")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Configure rest facilities and crew for extended flight duty periods")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Enhanced Sector Selection
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "number.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                Text("Number of Sectors")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            Picker("Sectors", selection: $viewModel.inFlightRestSectors) {
                                Text("1-2 sectors").tag(1)
                                Text("3 sectors").tag(3)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .scaleEffect(1.05)
                            
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("Select the number of sectors for this duty")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        
                        // Enhanced Long Flight Option
                        if viewModel.inFlightRestSectors == 1 {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "airplane.departure")
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                    
                                    Text("Long Flight Option")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("One sector with flight time greater than 9 hours")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .fontWeight(.medium)
                                        
                                        Text("This option provides extended FDP limits for long flights")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $viewModel.isLongFlight)
                                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                                        .scaleEffect(1.1)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.isLongFlight ? Color.orange.opacity(0.1) : Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(viewModel.isLongFlight ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                        }
                        
                        // Enhanced Additional Crew Members
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                
                                Text("Additional Flight Crew Members")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            Picker("Additional Crew", selection: $viewModel.additionalCrewMembers) {
                                Text("1 additional crew").tag(1)
                                Text("2 additional crew").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .scaleEffect(1.05)
                            
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Number of additional crew members providing in-flight rest")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        
                        // Enhanced Rest Facility Selection
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "house.fill")
                                    .foregroundColor(.purple)
                                    .font(.title2)
                                
                                Text("Rest Facility Class")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(spacing: 12) {
                                // Enhanced No In-Flight Rest Option
                                Button(action: {
                                    viewModel.hasInFlightRest = false
                                    viewModel.restFacilityType = .none
                                    viewModel.inFlightRestSectors = 1
                                    viewModel.isLongFlight = false
                                    viewModel.additionalCrewMembers = 1
                                    isPresented = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.title3)
                                                Text("No In-Flight Rest")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Text("No dedicated rest facility available")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if !viewModel.hasInFlightRest {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.title2)
                                                .background(
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 28, height: 28)
                                                )
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(!viewModel.hasInFlightRest ? Color.green.opacity(0.1) : Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(!viewModel.hasInFlightRest ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Enhanced Class 1 Rest Facility
                                Button(action: {
                                    viewModel.hasInFlightRest = true
                                    viewModel.restFacilityType = .class1
                                    viewModel.hasSplitDuty = false
                                    viewModel.hasExtendedFDP = false
                                    isPresented = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Image(systemName: "bed.double.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.title3)
                                                Text("Class 1 Rest Facility")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Text("Bunk or flat bed in a separate compartment")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if viewModel.hasInFlightRest && viewModel.restFacilityType == .class1 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.title2)
                                                .background(
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 28, height: 28)
                                                )
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill((viewModel.hasInFlightRest && viewModel.restFacilityType == .class1) ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke((viewModel.hasInFlightRest && viewModel.restFacilityType == .class1) ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Enhanced Class 2 Rest Facility
                                Button(action: {
                                    viewModel.hasInFlightRest = true
                                    viewModel.restFacilityType = .class2
                                    viewModel.hasSplitDuty = false
                                    viewModel.hasExtendedFDP = false
                                    isPresented = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Image(systemName: "chair.lounge.fill")
                                                    .foregroundColor(.indigo)
                                                    .font(.title3)
                                                Text("Class 2 Rest Facility")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Text("Reclining seat with leg support in a separate compartment")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if viewModel.hasInFlightRest && viewModel.restFacilityType == .class2 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.title2)
                                                .background(
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 28, height: 28)
                                                )
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill((viewModel.hasInFlightRest && viewModel.restFacilityType == .class2) ? Color.indigo.opacity(0.1) : Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke((viewModel.hasInFlightRest && viewModel.restFacilityType == .class2) ? Color.indigo.opacity(0.3) : Color.clear, lineWidth: 2)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Enhanced Class 3 Rest Facility
                                Button(action: {
                                    viewModel.hasInFlightRest = true
                                    viewModel.restFacilityType = .class3
                                    viewModel.hasSplitDuty = false
                                    viewModel.hasExtendedFDP = false
                                    isPresented = false
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Image(systemName: "chair.fill")
                                                    .foregroundColor(.teal)
                                                    .font(.title3)
                                                Text("Class 3 Rest Facility")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Text("Reclining seat with leg support in the passenger cabin")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if viewModel.hasInFlightRest && viewModel.restFacilityType == .class3 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.title2)
                                                .background(
                                                    Circle()
                                                        .fill(.white)
                                                        .frame(width: 28, height: 28)
                                                )
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill((viewModel.hasInFlightRest && viewModel.restFacilityType == .class3) ? Color.teal.opacity(0.1) : Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke((viewModel.hasInFlightRest && viewModel.restFacilityType == .class3) ? Color.teal.opacity(0.3) : Color.clear, lineWidth: 2)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        
                        // Enhanced FDP Extension Preview
                        if viewModel.hasInFlightRest && viewModel.restFacilityType != .none {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                    
                                    Text("FDP Extension Preview")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                
                                let extensionHours = viewModel.calculateInFlightRestExtension()
                                let baseFDP = viewModel.calculateMaxFDP()
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Base FDP:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(TimeUtilities.formatHoursAndMinutes(baseFDP))")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack {
                                        Text("In-Flight Rest FDP:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(TimeUtilities.formatHoursAndMinutes(extensionHours))")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Divider()
                                        .background(Color.blue.opacity(0.3))
                                    
                                    HStack {
                                        Text("Max FDP:")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Text("\(TimeUtilities.formatHoursAndMinutes(extensionHours))")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        Text("Configuration Summary")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Sectors: \(viewModel.inFlightRestSectors == 1 ? "1-2" : "3")")
                                        Text("Long Flight: \(viewModel.isLongFlight ? "Yes" : "No")")
                                        Text("Additional Crew: \(viewModel.additionalCrewMembers)")
                                        Text("Rest Facility: \(viewModel.restFacilityType.rawValue)")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("In-Flight Rest")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

