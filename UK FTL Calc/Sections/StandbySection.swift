//
//  StandbySection.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct StandbySection: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("Standby/Reserve")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Toggle Row with enhanced styling
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include Standby/Reserve Time")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text("Configure standby or reserve periods")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.isStandbyEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                        .onChange(of: viewModel.isStandbyEnabled) { _, newValue in
                            if newValue {
                                viewModel.showingStandbyOptions = true
                            }
                        }
                        .onChange(of: viewModel.selectedStandbyType) { _, newValue in
                            viewModel.synchronizeStandbyTimes()
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Selected Type Display
                if viewModel.isStandbyEnabled && !viewModel.selectedStandbyType.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text("Selected:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.selectedStandbyType)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Night Standby Status (if applicable)
                    if viewModel.isStandbyEnabled && (viewModel.selectedStandbyType == "Standby" || viewModel.selectedStandbyType == "Airport Standby") {
                        let standbyStartLocal = TimeUtilities.getLocalTime(for: viewModel.utcTimeFormatter.string(from: viewModel.effectiveStandbyStartTime), airportCode: viewModel.homeBase)
                        let standbyStartHour = Int(standbyStartLocal.prefix(2)) ?? 0
                        let isNightStandby = (standbyStartHour >= 23 || standbyStartHour < 7)
                        
                        if isNightStandby {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                
                                Text("Night Standby Active")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                
                                if viewModel.wasContactedBefore0700 {
                                    Text("• Contacted at \(String(format: "%02d:%02d", viewModel.selectedContactHour, viewModel.selectedContactMinute)) local")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("• Not contacted before 07:00")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                
                // Standby Location Selection (only show when standby is enabled)
                if viewModel.isStandbyEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mappin.circle")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Standby Location")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: { viewModel.showingLocationPicker = true }) {
                            HStack {
                                let currentLocation = viewModel.selectedStandbyLocation.isEmpty ? viewModel.defaultStandbyLocation : viewModel.selectedStandbyLocation
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currentLocation)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    if let airport = AirportsAndAirlines.airports.first(where: { $0.0 == currentLocation }) {
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
                    
                    // Standby Start Date/Time Selection (only show when NOT Airport Duty)
                    if viewModel.selectedStandbyType != "Airport Duty" {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("Standby Start Date & Time")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: { viewModel.showingDateTimePicker = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Date: \(viewModel.standbyStartDateTime, formatter: viewModel.dateFormatter)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Text("Time: \(viewModel.formatTimeAsUTC(viewModel.standbyStartDateTime))")
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
                    
                    // Airport Duty Start Date/Time Selection (only show when Airport Duty is selected)
                    if viewModel.selectedStandbyType == "Airport Duty" {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "airplane.departure")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("Airport Duty Start Date & Time")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: { viewModel.showingAirportDutyDateTimePicker = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Date: \(viewModel.airportDutyStartDateTime, formatter: viewModel.dateFormatter)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Text("Time: \(viewModel.formatTimeAsUTC(viewModel.airportDutyStartDateTime))")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.green)
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
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

