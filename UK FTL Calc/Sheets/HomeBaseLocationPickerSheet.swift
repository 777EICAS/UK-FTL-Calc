//
//  HomeBaseLocationPickerSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct HomeBaseLocationPickerSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredAirports: [(String, String)] {
        if searchText.isEmpty {
            return Array(AirportsAndAirlines.airports.prefix(100)).map { ($0.0, $0.1) }
        } else {
            let filtered = AirportsAndAirlines.airports
                .filter { airport in
                    airport.0.localizedCaseInsensitiveContains(searchText) ||
                    airport.1.localizedCaseInsensitiveContains(searchText)
                }
            return Array(filtered.prefix(100)).map { ($0.0, $0.1) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search airports...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Airport list
                List(filteredAirports, id: \.0) { airport in
                    Button(action: {
                        if viewModel.editingHomeBaseType == "primary" {
                            viewModel.editingHomeBase = airport.0
                        } else if viewModel.editingHomeBaseType == "secondary" {
                            viewModel.editingSecondHomeBase = airport.0
                        }
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(airport.0)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(airport.1)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Airport")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

