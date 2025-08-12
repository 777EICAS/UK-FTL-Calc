//
//  HomeBaseEditorSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct HomeBaseEditorSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Home Bases")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 24) {
                    // Primary Home Base Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Primary Home Base")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        Button(action: { 
                            viewModel.editingHomeBaseType = "primary"
                            viewModel.showingHomeBaseLocationPicker = true 
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.editingHomeBase.isEmpty ? "Select Primary Home Base" : viewModel.editingHomeBase)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(viewModel.editingHomeBase.isEmpty ? .secondary : .primary)
                                    
                                    if !viewModel.editingHomeBase.isEmpty, let airport = AirportsAndAirlines.airports.first(where: { $0.0 == viewModel.editingHomeBase }) {
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
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Secondary Home Base Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            Text("Secondary Home Base (Optional)")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        Button(action: { 
                            viewModel.editingHomeBaseType = "secondary"
                            viewModel.showingHomeBaseLocationPicker = true 
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.editingSecondHomeBase.isEmpty ? "Select Secondary Home Base" : viewModel.editingSecondHomeBase)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(viewModel.editingSecondHomeBase.isEmpty ? .secondary : .primary)
                                    
                                    if !viewModel.editingSecondHomeBase.isEmpty, let airport = AirportsAndAirlines.airports.first(where: { $0.0 == viewModel.editingSecondHomeBase }) {
                                        Text(airport.1)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Clear secondary home base button
                        if !viewModel.editingSecondHomeBase.isEmpty {
                            Button(action: {
                                viewModel.editingSecondHomeBase = ""
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text("Clear Secondary Home Base")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Help text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("• Your primary home base is used for acclimatisation calculations")
                        Text("• Secondary home base is optional and can be used for multi-base operations")
                        Text("• Both bases are assumed to be in UTC +1 timezone")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 20) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    
                    Button("Save Changes") {
                        // Update the home bases
                        viewModel.homeBase = viewModel.editingHomeBase
                        viewModel.secondHomeBase = viewModel.editingSecondHomeBase
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .disabled(viewModel.editingHomeBase.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Edit Home Bases")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                // Update the home bases
                viewModel.homeBase = viewModel.editingHomeBase
                viewModel.secondHomeBase = viewModel.editingSecondHomeBase
                isPresented = false
            })
        }
    }
}

