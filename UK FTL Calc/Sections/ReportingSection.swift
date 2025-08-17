//
//  ReportingSection.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct ReportingSection: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Reporting")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Reporting Location (hide when airport duty is selected)
                if !(viewModel.isStandbyEnabled && viewModel.selectedStandbyType == "Airport Duty") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mappin.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Reporting Location")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: { viewModel.showingReportingLocationPicker = true }) {
                            HStack {
                                let currentReportingLocation = viewModel.selectedReportingLocation.isEmpty ? viewModel.defaultReportingLocation : viewModel.selectedReportingLocation
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currentReportingLocation)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    if let airport = AirportsAndAirlines.airports.first(where: { $0.0 == currentReportingLocation }) {
                                        Text(airport.1)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
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
                    }
                }
                
                // Reporting Date/Time (hide when airport duty is selected)
                if !(viewModel.isStandbyEnabled && viewModel.selectedStandbyType == "Airport Duty") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Reporting Date & Time")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        // Helpful instruction
                        Text("Enter time in UTC (Zulu time)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        Button(action: { viewModel.showingReportingDateTimePicker = true }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Date: \(viewModel.reportingDateTime, formatter: viewModel.dateFormatter)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    // Always show UTC time
                                    Text("Time: \(viewModel.formatTimeAsUTC(viewModel.reportingDateTime))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Acclimatisation Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.purple)
                            .font(.caption)
                        Text("Acclimatisation")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { viewModel.showingAcclimatisationPicker = true }) {
                        HStack {
                            if !viewModel.selectedAcclimatisation.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(viewModel.selectedAcclimatisation)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text("TZ: \(viewModel.timezoneDifference)h, Elapsed: \(viewModel.elapsedTime)h")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Select Acclimatisation")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.purple)
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

