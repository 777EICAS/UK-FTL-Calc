//
//  LatestTimesSection.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct LatestTimesSection: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "clock.badge.plus")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("Latest OFF/ON Blocks Time")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Estimated Block Time Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Estimated Block Time")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { viewModel.showingBlockTimePicker = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                let hours = Int(viewModel.estimatedBlockTime)
                                let minutes = Int(round((viewModel.estimatedBlockTime - Double(hours)) * 60))
                                Text("Estimated: \(hours)h \(minutes)m")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
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
                
                // Latest Off Blocks Time Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "airplane.departure")
                            .foregroundColor(.purple)
                            .font(.title3)
                        Text("Latest Off Blocks Time")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }
                    
                    // Without Commander's Discretion
                    let latestWithoutDiscretion = viewModel.calculateLatestOffBlocksTime(withCommandersDiscretion: false)
                    Button(action: { viewModel.showingWithoutDiscretionDetails = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Without Commander's Discretion")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text(viewModel.formatTimeForDisplay(latestWithoutDiscretion))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Max FDP")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            
                                Text("\(String(format: "%.1f", viewModel.cachedTotalFDP))h")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Image(systemName: "info.circle")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // With Commander's Discretion
                    let latestWithDiscretion = viewModel.calculateLatestOffBlocksTime(withCommandersDiscretion: true)
                    Button(action: { viewModel.showingWithDiscretionDetails = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("With Commander's Discretion")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text(viewModel.formatTimeForDisplay(latestWithDiscretion))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Max FDP + Extension")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(String(format: "%.1f", viewModel.cachedTotalFDP + viewModel.getCommandersDiscretionExtension()))h")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Latest ON Blocks Time Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "airplane.arrival")
                            .foregroundColor(.blue)
                            .font(.title3)
                        Text("Latest ON Blocks Time")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    // Without Commander's Discretion
                    let latestOnBlocksWithoutDiscretion = viewModel.calculateLatestOnBlocksTime(withCommandersDiscretion: false)
                    Button(action: { viewModel.showingOnBlocksDetails = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Without Commander's Discretion")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text(viewModel.formatTimeForDisplay(latestOnBlocksWithoutDiscretion))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Max FDP")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            
                                Text("\(String(format: "%.1f", viewModel.calculateTotalDutyTime(withCommandersDiscretion: false)))h")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            Image(systemName: "info.circle")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // With Commander's Discretion
                    let latestOnBlocksWithDiscretion = viewModel.calculateLatestOnBlocksTime(withCommandersDiscretion: true)
                    Button(action: { viewModel.showingOnBlocksDetails = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("With Commander's Discretion")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Text(viewModel.formatTimeForDisplay(latestOnBlocksWithDiscretion))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Max FDP + Extension")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            
                                Text("\(String(format: "%.1f", viewModel.calculateTotalDutyTime(withCommandersDiscretion: true)))h")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

