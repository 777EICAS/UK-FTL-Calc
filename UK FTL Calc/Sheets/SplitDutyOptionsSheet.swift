//
//  SplitDutyOptionsSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct SplitDutyOptionsSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    @State private var hasUnsavedChanges = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar - Matching app theme
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.blue)
                .font(.subheadline)
                .fontWeight(.medium)
                
                Spacer()
                
                Text("Split Duty")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(hasUnsavedChanges ? "Apply Changes" : "No Changes") {
                    // Trigger calculation update when split duty settings are applied
                    viewModel.applySplitDutySettings()
                    hasUnsavedChanges = false
                    isPresented = false
                }
                .foregroundColor(hasUnsavedChanges ? .blue : .gray)
                .font(.subheadline)
                .fontWeight(.medium)
                .disabled(!hasUnsavedChanges)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Content Area
            ScrollView {
                VStack(spacing: 24) {
                    // Split Duty Toggle Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Split Duty (Break On The Ground)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Duty period split by rest period")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.hasSplitDuty)
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                                .onChange(of: viewModel.hasSplitDuty) { _ in
                                    hasUnsavedChanges = true
                                }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        if viewModel.hasSplitDuty {
                            // Break Duration Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Break Duration")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button(action: { viewModel.showingBreakDurationPicker = true }) {
                                    HStack {
                                        Text("\(String(format: "%.1f", viewModel.splitDutyBreakDuration))h")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                                }
                                
                                Text("The minimum time for a split duty is 3 hours. This does not include: a minimum of 30 mins to complete pre and post flight duties, as well as travel to the accomodation. If the duration exceeds 6 hours then suitable accomodation must be provided, otherwise the time exceeding 6 hours is not allow to be used to extend the duty.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                            }
                            
                            // Accommodation Type Selection
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "bed.double")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("Accommodation Type")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 12) {
                                    Button(action: { 
                                        viewModel.splitDutyAccommodationType = "Accommodation"
                                        hasUnsavedChanges = true
                                    }) {
                                        Text("Accommodation")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(viewModel.splitDutyAccommodationType == "Accommodation" ? .white : .primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(viewModel.splitDutyAccommodationType == "Accommodation" ? Color.blue : Color(.systemGray5))
                                            .cornerRadius(12)
                                    }
                                    
                                    Button(action: { 
                                        viewModel.splitDutyAccommodationType = "Suitable Accomm"
                                        hasUnsavedChanges = true
                                    }) {
                                        Text("Suitable Accomm")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(viewModel.splitDutyAccommodationType == "Suitable Accomm" ? .white : .primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(viewModel.splitDutyAccommodationType == "Suitable Accomm" ? Color.blue : Color(.systemGray5))
                                            .cornerRadius(12)
                                    }
                                }
                                
                                if viewModel.splitDutyAccommodationType == "Accommodation" {
                                    Text("A quiet and comfortable place, not open to the public, with the ability to control light and temp. Equipped with furniture that allows the crew member to sleep (not neccessarily a bed). Must be large enough to accomodate all crew members at the same time. Does not need to be your own private room. Needs access to food and drink.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                }
                                
                                if viewModel.splitDutyAccommodationType == "Suitable Accomm" {
                                    Text("All of the same requirements as accommodation, but needs to contain a seperate room for each crew member and must be equipped with a bed to sleep. (e.g. a hotel room).")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                }
                            }
                            
                            // Break Begin Time (only for Accommodation option)
                            if viewModel.splitDutyAccommodationType == "Accommodation" {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text("Break Begin")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Button(action: { viewModel.showingBreakBeginPicker = true }) {
                                        HStack {
                                            Text(viewModel.formatTimeAsUTC(viewModel.splitDutyBreakBegin))
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.blue)
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(12)
                                    }
                                    
                                    Text("If a break encroaches the WOCL (window of circadian low) then a suitable accomodation must be provided otherwise any of the break time within the WOCL period does not count towards an extension on FDP. WOCL is 02:00-05:59 to where the crew member is acclimatised.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $viewModel.showingBreakDurationPicker) {
            breakDurationPickerSheet
        }
        .sheet(isPresented: $viewModel.showingBreakBeginPicker) {
            breakBeginPickerSheet
        }
    }
    
    // MARK: - Sheet Views
    private var breakDurationPickerSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    viewModel.showingBreakDurationPicker = false
                }
                .foregroundColor(.blue)
                .font(.subheadline)
                .fontWeight(.medium)
                
                Spacer()
                
                Text("Break Duration")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    viewModel.updateBreakDurationFromCustomInput()
                    viewModel.showingBreakDurationPicker = false
                }
                .foregroundColor(.blue)
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Time Picker
            VStack(spacing: 20) {
                Text("Select break duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                HStack(spacing: 20) {
                    // Hours
                    VStack {
                        Text("Hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Hours", selection: $viewModel.selectedBreakDurationHour) {
                            ForEach(3...12, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)
                        .onChange(of: viewModel.selectedBreakDurationHour) { _ in
                            hasUnsavedChanges = true
                        }
                    }
                    
                    // Minutes
                    VStack {
                        Text("Minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Minutes", selection: $viewModel.selectedBreakDurationMinute) {
                            ForEach(0...59, id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)
                        .onChange(of: viewModel.selectedBreakDurationMinute) { _ in
                            hasUnsavedChanges = true
                        }
                    }
                }
                .padding()
                
                // Validation warning removed since picker enforces minimum 3 hours
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var breakBeginPickerSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    viewModel.showingBreakBeginPicker = false
                }
                .foregroundColor(.blue)
                .font(.subheadline)
                .fontWeight(.medium)
                
                Spacer()
                
                Text("Break Begin Time")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    viewModel.updateBreakBeginTimeFromCustomInput()
                    viewModel.showingBreakBeginPicker = false
                }
                .foregroundColor(.blue)
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Time Picker
            VStack(spacing: 20) {
                Text("Select break begin time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                HStack(spacing: 20) {
                    // Hours
                    VStack {
                        Text("Hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Hours", selection: $viewModel.selectedBreakBeginHour) {
                            ForEach(0...23, id: \.self) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)
                        .onChange(of: viewModel.selectedBreakBeginHour) { _ in
                            hasUnsavedChanges = true
                        }
                    }
                    
                    // Minutes
                    VStack {
                        Text("Minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Minutes", selection: $viewModel.selectedBreakBeginMinute) {
                            ForEach(0...59, id: \.self) { minute in
                                Text(String(format: "%02d", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80, height: 120)
                        .onChange(of: viewModel.selectedBreakBeginMinute) { _ in
                            hasUnsavedChanges = true
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    SplitDutyOptionsSheet(viewModel: ManualCalcViewModel(), isPresented: .constant(true))
}
