//
//  DateTimePickerSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct DateTimePickerSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    let title: String
    let isStandbyTime: Bool
    let isAirportDutyTime: Bool // NEW: Parameter to distinguish airport duty time
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    // Date picker
                    DatePicker(
                        getDatePickerLabel(),
                        selection: getDateSelection(),
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .onChange(of: getDateSelection().wrappedValue) { _, _ in
                        // Update the time when date changes to ensure synchronization
                        updateTimeFromInput()
                        if isStandbyTime {
                            viewModel.checkNightStandbyContact()
                        }
                    }
                    
                    // Custom time input for UTC
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter UTC Time (Zulu)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            // Hour picker
                            Picker("Hour", selection: getHourSelection()) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text(String(format: "%02d", hour)).tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: getHourSelection().wrappedValue) { _, _ in
                                updateTimeFromInput()
                            }
                            
                            Text(":")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            // Minute picker
                            Picker("Minute", selection: getMinuteSelection()) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .onChange(of: getMinuteSelection().wrappedValue) { _, _ in
                                updateTimeFromInput()
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
                        // Update the time before dismissing the sheet
                        updateTimeFromInput()
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .onAppear {
                // Initialize hour/minute pickers to match current date/time values
                initializeTimeComponents()
            }
            .navigationTitle(getNavigationTitle())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                // Update the time before dismissing the sheet
                updateTimeFromInput()
                isPresented = false
            })
        }
    }
    
    // MARK: - Helper Functions
    private func getDatePickerLabel() -> String {
        if isAirportDutyTime {
            return "Airport Duty Start Date"
        } else if isStandbyTime {
            return "Standby Start Date"
        } else {
            return "Date"
        }
    }
    
    private func getDateSelection() -> Binding<Date> {
        if isAirportDutyTime {
            return $viewModel.airportDutyStartDateTime
        } else if isStandbyTime {
            return $viewModel.standbyStartDateTime
        } else {
            return $viewModel.reportingDateTime
        }
    }
    
    private func getHourSelection() -> Binding<Int> {
        if isAirportDutyTime {
            return $viewModel.selectedAirportDutyHour
        } else if isStandbyTime {
            return $viewModel.selectedStandbyHour
        } else {
            return $viewModel.selectedHour
        }
    }
    
    private func getMinuteSelection() -> Binding<Int> {
        if isAirportDutyTime {
            return $viewModel.selectedAirportDutyMinute
        } else if isStandbyTime {
            return $viewModel.selectedStandbyMinute
        } else {
            return $viewModel.selectedMinute
        }
    }
    
    private func updateTimeFromInput() {
        if isAirportDutyTime {
            viewModel.updateAirportDutyTimeFromCustomInput()
        } else if isStandbyTime {
            viewModel.updateStandbyTimeFromCustomInput()
            viewModel.checkNightStandbyContact()
        } else {
            viewModel.updateReportingTimeFromCustomInput()
        }
    }
    
    private func getNavigationTitle() -> String {
        if isAirportDutyTime {
            return "Airport Duty Start Time"
        } else if isStandbyTime {
            return "Standby Start Time"
        } else {
            return "Time"
        }
    }
    
    private func initializeTimeComponents() {
        // Extract hour and minute from the current date selection and update the picker values
        let currentDate = getDateSelection().wrappedValue
        let calendar = Calendar.current
        
        if isAirportDutyTime {
            viewModel.selectedAirportDutyHour = calendar.component(.hour, from: currentDate)
            viewModel.selectedAirportDutyMinute = calendar.component(.minute, from: currentDate)
        } else if isStandbyTime {
            viewModel.selectedStandbyHour = calendar.component(.hour, from: currentDate)
            viewModel.selectedStandbyMinute = calendar.component(.minute, from: currentDate)
        } else {
            viewModel.selectedHour = calendar.component(.hour, from: currentDate)
            viewModel.selectedMinute = calendar.component(.minute, from: currentDate)
        }
    }
}

