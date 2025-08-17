//
//  ManualCalcView.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct ManualCalcView: View {
    @StateObject private var viewModel = ManualCalcViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section - Matching main calculator theme
        VStack(spacing: 16) {
                        // Main Header Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Manual FTL Calculator")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Enter flight information manually for FTL calculations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                                // Icon with background
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 60, height: 60)
                        )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    // Home Bases Section
                    HomeBaseSection(viewModel: viewModel)
                    
                    // Standby Section
                    StandbySection(viewModel: viewModel)
                    
                    // Reporting Section
                    ReportingSection(viewModel: viewModel)
                    
                    // Sectors Section
                    SectorsSection(viewModel: viewModel)
                    
                    // FDP Results Section
                    FDPResultsSection(viewModel: viewModel)
                    
                    // Latest Times Section
                    LatestTimesSection(viewModel: viewModel)
                    
                    // Calculate Button Section
                    VStack(spacing: 16) {
                        // Calculate Button
                        Button(action: {
                            viewModel.performCalculation()
                        }) {
                            HStack {
                                if viewModel.isCalculating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "calculator")
                                        .font(.title2)
                                }
                                
                                Text(viewModel.isCalculating ? "Calculating..." : "Calculate FTL")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.hasCalculated ? Color.green : Color.blue)
                            )
                        }
                        .disabled(viewModel.isCalculating)
                        
                        // Results Status
                        if viewModel.hasCalculated {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("FTL calculations completed")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showingStandbyOptions) {
                standbyOptionsSheet
            }
            .sheet(isPresented: $viewModel.showingLocationPicker) {
                locationPickerSheet
            }
            .sheet(isPresented: $viewModel.showingDateTimePicker) {
                dateTimePickerSheet
            }
            .sheet(isPresented: $viewModel.showingAirportDutyDateTimePicker) {
                airportDutyDateTimePickerSheet
            }
            .sheet(isPresented: $viewModel.showingReportingLocationPicker) {
                reportingLocationPickerSheet
            }
            .sheet(isPresented: $viewModel.showingReportingDateTimePicker) {
                reportingDateTimePickerSheet
            }
            .sheet(isPresented: $viewModel.showingAcclimatisationPicker) {
                acclimatisationPickerSheet
            }
            .sheet(isPresented: $viewModel.showingInFlightRestPicker) {
                inFlightRestPickerSheet
            }
            .sheet(isPresented: $viewModel.showingBlockTimePicker) {
                blockTimePickerSheet
            }
            .sheet(isPresented: $viewModel.showingSplitDutyOptions) {
                splitDutyOptionsSheet
            }
            .sheet(isPresented: $viewModel.showingWithDiscretionDetails) {
                withDiscretionDetailsSheet
            }
            .sheet(isPresented: $viewModel.showingWithoutDiscretionDetails) {
                withoutDiscretionDetailsSheet
            }
            .sheet(isPresented: $viewModel.showingOnBlocksDetails) {
                onBlocksDetailsSheet
            }
            .sheet(isPresented: $viewModel.showingHomeBaseEditor) {
                homeBaseEditorSheet
            }
            .sheet(isPresented: $viewModel.showingHomeBaseLocationPicker) {
                homeBaseLocationPickerSheet
            }
            .sheet(isPresented: $viewModel.showingNightStandbyContactPopup) {
                nightStandbyContactPopupSheet
            }
            .onAppear {
                // Refresh published home bases to ensure they're in sync
                viewModel.refreshPublishedHomeBases()
                
                // Initialize selected hour and minute from current reportingDateTime (in UTC)
                var utcCalendar = Calendar.current
                utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
                let components = utcCalendar.dateComponents([.hour, .minute], from: viewModel.reportingDateTime)
                viewModel.selectedHour = components.hour ?? 12
                viewModel.selectedMinute = components.minute ?? 20
                
                // Initialize selected hour and minute for block time picker
                let blockTimeHours = Int(viewModel.estimatedBlockTime)
                let blockTimeMinutes = Int((viewModel.estimatedBlockTime - Double(blockTimeHours)) * 60)
                viewModel.selectedBlockTimeHour = blockTimeHours
                viewModel.selectedBlockTimeMinute = blockTimeMinutes
                
                // Initialize selected hour and minute for standby time picker
                let standbyComponents = utcCalendar.dateComponents([.hour, .minute], from: viewModel.standbyStartDateTime)
                viewModel.selectedStandbyHour = standbyComponents.hour ?? 9
                viewModel.selectedStandbyMinute = standbyComponents.minute ?? 0
                
                // Initialize selected hour and minute for airport duty start time picker
                // For airport duty, this should start as the same time as standby start time
                let airportDutyComponents = utcCalendar.dateComponents([.hour, .minute], from: viewModel.standbyStartDateTime)
                viewModel.selectedAirportDutyHour = airportDutyComponents.hour ?? 9
                viewModel.selectedAirportDutyMinute = airportDutyComponents.minute ?? 0
                
                // Initialize in-flight rest configuration
                if viewModel.hasInFlightRest && viewModel.restFacilityType == .none {
                    viewModel.hasInFlightRest = false
                    viewModel.inFlightRestSectors = 1
                    viewModel.isLongFlight = false
                    viewModel.additionalCrewMembers = 1
                }
                
                // Initialize split duty time values
                let breakDurationHours = Int(viewModel.splitDutyBreakDuration)
                let breakDurationMinutes = Int((viewModel.splitDutyBreakDuration - Double(breakDurationHours)) * 60)
                viewModel.selectedBreakDurationHour = breakDurationHours
                viewModel.selectedBreakDurationMinute = breakDurationMinutes
                
                let breakBeginComponents = utcCalendar.dateComponents([.hour, .minute], from: viewModel.splitDutyBreakBegin)
                viewModel.selectedBreakBeginHour = breakBeginComponents.hour ?? 14
                viewModel.selectedBreakBeginMinute = breakBeginComponents.minute ?? 0
            }
        }
    }
    
    // MARK: - Sheet Views
    private var standbyOptionsSheet: some View {
        StandbyOptionsSheet(viewModel: viewModel, isPresented: $viewModel.showingStandbyOptions)
    }
    
    private var locationPickerSheet: some View {
        LocationPickerSheet(viewModel: viewModel, isPresented: $viewModel.showingLocationPicker, isHomeBaseEditor: false, onLocationSelected: { location in
            viewModel.selectedStandbyLocation = location
        })
    }
    
    private var dateTimePickerSheet: some View {
        DateTimePickerSheet(viewModel: viewModel, isPresented: $viewModel.showingDateTimePicker, title: "Select Standby Start Date & Time", isStandbyTime: true, isAirportDutyTime: false)
    }
    
    private var airportDutyDateTimePickerSheet: some View {
        DateTimePickerSheet(viewModel: viewModel, isPresented: $viewModel.showingAirportDutyDateTimePicker, title: "Select Airport Duty Start Date & Time", isStandbyTime: false, isAirportDutyTime: true)
    }
    
    private var reportingLocationPickerSheet: some View {
        ReportingLocationPickerSheet(viewModel: viewModel, isPresented: $viewModel.showingReportingLocationPicker)
    }
    
    private var reportingDateTimePickerSheet: some View {
        ReportingDateTimePickerSheet(viewModel: viewModel, isPresented: $viewModel.showingReportingDateTimePicker)
    }
    
    private var acclimatisationPickerSheet: some View {
        AcclimatisationPickerSheet(viewModel: viewModel, isPresented: $viewModel.showingAcclimatisationPicker)
    }
    
    private var inFlightRestPickerSheet: some View {
        InFlightRestPickerSheet(viewModel: viewModel, isPresented: $viewModel.showingInFlightRestPicker)
    }
    
    private var blockTimePickerSheet: some View {
        BlockTimePickerSheet(viewModel: viewModel, isPresented: $viewModel.showingBlockTimePicker)
    }
    
    private var splitDutyOptionsSheet: some View {
        SplitDutyOptionsSheet(viewModel: viewModel, isPresented: $viewModel.showingSplitDutyOptions)
    }
    
    private var withDiscretionDetailsSheet: some View {
        WithDiscretionDetailsSheet(viewModel: viewModel, isPresented: $viewModel.showingWithDiscretionDetails)
    }
    
    private var withoutDiscretionDetailsSheet: some View {
        WithoutDiscretionDetailsSheet(viewModel: viewModel, isPresented: $viewModel.showingWithoutDiscretionDetails)
    }
    
    private var onBlocksDetailsSheet: some View {
        OnBlocksDetailsSheet(viewModel: viewModel, isPresented: $viewModel.showingOnBlocksDetails)
    }
    
    private var homeBaseEditorSheet: some View {
        HomeBaseEditorSheet(viewModel: viewModel)
    }
    
    private var homeBaseLocationPickerSheet: some View {
        HomeBaseLocationPickerSheet(viewModel: viewModel)
    }
    
    private var nightStandbyContactPopupSheet: some View {
        NightStandbyContactPopupSheet(viewModel: viewModel, isPresented: $viewModel.showingNightStandbyContactPopup)
    }
}

#Preview {
    ManualCalcView()
}
