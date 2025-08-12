//
//  AcclimatisationPickerSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct AcclimatisationPickerSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Acclimatisation Calculator")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 8) {
                    // Timezone Difference Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timezone Difference (hours)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Picker("Timezone Difference", selection: $viewModel.timezoneDifference) {
                            ForEach(0...12, id: \.self) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                        
                        Text("The timezone difference between where you reported and where you are currently")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Elapsed Time Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Elapsed Time Since Reporting for First Sector")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Picker("Elapsed Time", selection: $viewModel.elapsedTime) {
                            ForEach(0...168, id: \.self) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                        
                        Text("Elapsed time is the time from reporting at home base on the first sector, to report for the current duty")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Acclimatisation Result
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Acclimatisation Category")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        let acclimatisationResult = viewModel.calculateAcclimatisation()
                        Text(acclimatisationResult)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(acclimatisationResult == "X" ? .red : (acclimatisationResult == "D" ? .orange : .green))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Text(viewModel.getAcclimatisationDescription(for: acclimatisationResult))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Max FDP Display
                        let maxFDP = viewModel.calculateMaxFDP()
                        Text("Max FDP: \(String(format: "%.1f", maxFDP))h")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(.top, 8)
                        
                        // Sectors Info
                        if viewModel.numberOfSectors == 1 {
                            Text("Based on 1-2 sectors")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        } else {
                            Text("Based on \(viewModel.numberOfSectors) sectors")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    
                    Button("Apply") {
                        viewModel.selectedAcclimatisation = viewModel.calculateAcclimatisation()
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .navigationTitle("Acclimatisation")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                viewModel.selectedAcclimatisation = viewModel.calculateAcclimatisation()
                isPresented = false
            })
        }
    }
}

