//
//  HomeBaseLocationPickerSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct HomeBaseLocationPickerSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Select \(viewModel.editingHomeBaseType == "primary" ? "Primary" : "Secondary") Home Base")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Search and Filter
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search airports...", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Airport List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(AirportsAndAirlines.airports.prefix(50)), id: \.0) { airport in
                            Button(action: {
                                // Update the appropriate home base based on type
                                if viewModel.editingHomeBaseType == "primary" {
                                    viewModel.editingHomeBase = airport.0
                                } else if viewModel.editingHomeBaseType == "secondary" {
                                    viewModel.editingSecondHomeBase = airport.0
                                }
                                isPresented = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(airport.0)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Text(airport.1)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Show checkmark for current selection
                                    let currentLocation = viewModel.editingHomeBaseType == "primary" ? viewModel.editingHomeBase : viewModel.editingSecondHomeBase
                                    
                                    if currentLocation == airport.0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

