//
//  NightStandbyContactPopupSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct NightStandbyContactPopupSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Night Standby Contact")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    Text("Your standby starts between 23:00-07:00 local time to your home base.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                
                    Text("Were you contacted before 07:00 local time?")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                
                    // Contact toggle
                    HStack {
                        Text("Contacted before 07:00")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $viewModel.wasContactedBefore0700)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Contact time input (only show if contacted)
                    if viewModel.wasContactedBefore0700 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What time were you contacted? (Local time)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 20) {
                                // Hour picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Hour")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Picker("Hour", selection: $viewModel.selectedContactHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(String(format: "%02d", hour)).tag(hour)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(width: 80, height: 120)
                                    .onChange(of: viewModel.selectedContactHour) { _, newHour in
                                        viewModel.updateContactTimeFromCustomInput()
                                    }
                                }
                                
                                // Minute picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Minute")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Picker("Minute", selection: $viewModel.selectedContactMinute) {
                                        ForEach(0..<60, id: \.self) { minute in
                                            Text(String(format: "%02d", minute)).tag(minute)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(width: 80, height: 120)
                                    .onChange(of: viewModel.selectedContactMinute) { _, newMinute in
                                        viewModel.updateContactTimeFromCustomInput()
                                    }
                                }
                            }
                            
                            Text("Enter the local time when you were contacted")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                }
                .padding()
            }
            .navigationTitle("Night Standby Contact")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

