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
        VStack(alignment: .leading, spacing: 12) {
            // Section Header - Matching Sectors section style
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text("Reporting")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 14) {
                // Reporting Location Card (hide when airport duty is selected)
                if !(viewModel.isStandbyEnabled && viewModel.selectedStandbyType == "Airport Duty") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "mappin.circle")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Reporting Location")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
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
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Reporting Date/Time Card (hide when airport duty is selected)
                if !(viewModel.isStandbyEnabled && viewModel.selectedStandbyType == "Airport Duty") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                                .font(.title3)
                            Text("Reporting Date & Time")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        // Helpful instruction
                        Text("Enter time in UTC (Zulu time)")
                            .font(.caption)
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
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Acclimatisation Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.purple)
                            .font(.title3)
                        Text("Acclimatisation")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
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
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

