//
//  BlockTimePickerSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct BlockTimePickerSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Estimated Block Time")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    Text("Estimated block time from blocks off to blocks on")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 20) {
                        // Hours picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hours")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Picker("Hours", selection: $viewModel.selectedBlockTimeHour) {
                                ForEach(0..<25, id: \.self) { hour in
                                    Text("\(hour)h").tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: viewModel.selectedBlockTimeHour) { _, newHour in
                                viewModel.updateEstimatedBlockTimeFromCustomInput()
                            }
                        }
                        
                        // Minutes picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Minutes")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Picker("Minutes", selection: $viewModel.selectedBlockTimeMinute) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text("\(minute)m").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: viewModel.selectedBlockTimeMinute) { _, newMinute in
                                viewModel.updateEstimatedBlockTimeFromCustomInput()
                            }
                        }
                    }
                    
                    // Preview of calculation
                    if viewModel.estimatedBlockTime > 0 {
                        VStack(spacing: 8) {
                            Text("Calculation Preview:")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            
                            let latestWithDiscretion = viewModel.calculateLatestOffBlocksTime(withCommandersDiscretion: true)
                            let latestWithoutDiscretion = viewModel.calculateLatestOffBlocksTime(withCommandersDiscretion: false)
                            
                            VStack(spacing: 4) {
                                HStack {
                                    Text("With Commander's Discretion:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(viewModel.formatTimeForDisplay(latestWithDiscretion))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                                
                                HStack {
                                    Text("Without Commander's Discretion:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(viewModel.formatTimeForDisplay(latestWithoutDiscretion))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
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
                    
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .navigationTitle("Estimated Block Time")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

