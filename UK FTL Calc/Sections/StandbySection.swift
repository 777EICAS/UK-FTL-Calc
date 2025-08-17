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
        VStack(alignment: .leading, spacing: 12) {
            // Section Header - Matching Sectors section style
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.purple)
                    .font(.title3)
                
                Text("Standby/Reserve")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 14) {
                // Standby Toggle Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "togglepower")
                            .foregroundColor(.purple)
                            .font(.title3)
                        Text("Standby/Reserve Time")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                        
                        Toggle("", isOn: $viewModel.isStandbyEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                            .onChange(of: viewModel.isStandbyEnabled) { _, newValue in
                                if newValue {
                                    viewModel.showingStandbyOptions = true
                                } else {
                                    viewModel.resetStandbyFields()
                                }
                            }
                            .onChange(of: viewModel.selectedStandbyType) { _, newValue in
                                viewModel.synchronizeStandbyTimes()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Include Standby/Reserve Time")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text("Configure standby or reserve periods")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
                
                // Selected Type Display Card (only show when standby is enabled)
                if viewModel.isStandbyEnabled && !viewModel.selectedStandbyType.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            Text("Selected Type")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        HStack {
                            Text("Selected:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.selectedStandbyType)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
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
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    if viewModel.wasContactedBefore0700 {
                                        Text("• Contacted at \(String(format: "%02d:%02d", viewModel.selectedContactHour, viewModel.selectedContactMinute)) local")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    } else {
                                        Text("• Not contacted before 07:00")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Standby Location Card (only show when standby is enabled)
                if viewModel.isStandbyEnabled {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "mappin.circle")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Standby Location")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
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
                    
                    // Standby Start Date/Time Card (only show when NOT Airport Duty)
                    if viewModel.selectedStandbyType != "Airport Duty" {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                Text("Standby Start Date & Time")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
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
                    
                    // Airport Duty Start Date/Time Card (only show when Airport Duty is selected)
                    if viewModel.selectedStandbyType == "Airport Duty" {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "airplane.departure")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                Text("Airport Duty Start Date & Time")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
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
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

