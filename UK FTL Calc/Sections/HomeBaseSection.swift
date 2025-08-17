//
//  HomeBaseSection.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct HomeBaseSection: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Your Home Bases")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    viewModel.initializeEditingHomeBases()
                    viewModel.showingHomeBaseEditor = true
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Tap to edit")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            
            VStack(spacing: 6) {
                // Primary Home Base
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Primary")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.currentHomeBase)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if let airport = AirportsAndAirlines.airports.first(where: { $0.0 == viewModel.currentHomeBase }) {
                            Text(airport.1)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("UTC +1")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // Secondary Home Base
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Secondary")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if viewModel.currentSecondHomeBase.isEmpty {
                            Text("Not set")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        } else {
                            Text(viewModel.currentSecondHomeBase)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if let airport = AirportsAndAirlines.airports.first(where: { $0.0 == viewModel.currentSecondHomeBase }) {
                                Text(airport.1)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if !viewModel.currentSecondHomeBase.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text("UTC +1")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                        
                        Button(action: {
                            viewModel.editingSecondHomeBase = ""
                            viewModel.manuallyUpdateHomeBases()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .sheet(isPresented: $viewModel.showingHomeBaseEditor) {
            HomeBaseEditorSheet(viewModel: viewModel)
        }
    }
}

