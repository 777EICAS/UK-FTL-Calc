//
//  ReportingDateTimePickerSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct ReportingDateTimePickerSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Reporting Date & Time")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    // Date picker
                    DatePicker(
                        "Reporting Date",
                        selection: $viewModel.reportingDateTime,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    
                    // Custom time input for UTC
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter UTC Time (Zulu)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            // Hour picker
                            Picker("Hour", selection: $viewModel.selectedHour) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: viewModel.selectedHour) { _, newHour in
                                viewModel.updateReportingTimeFromCustomInput()
                            }
                            
                            Text(":")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            // Minute picker
                            Picker("Minute", selection: $viewModel.selectedMinute) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: viewModel.selectedMinute) { _, newMinute in
                                viewModel.updateReportingTimeFromCustomInput()
                            }
                            
                            Text("z")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Text("Time is entered in UTC (Zulu time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
            .navigationTitle("Reporting Time")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}

