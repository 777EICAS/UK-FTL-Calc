//
//  ReportingLocationPickerSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct ReportingLocationPickerSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var filteredAirports: [(String, String, String)] {
        if searchText.isEmpty {
            return AirportsAndAirlines.airports
        } else {
            return AirportsAndAirlines.airports.filter { airport in
                airport.0.localizedCaseInsensitiveContains(searchText) ||
                airport.1.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func getUTCOffset(for timeZoneIdentifier: String, on date: Date) -> String {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            return "UTC?"
        }
        
        let offsetSeconds = timeZone.secondsFromGMT(for: date)
        let offsetHours = offsetSeconds / 3600
        
        if offsetHours == 0 {
            return "UTC+0"
        } else if offsetHours > 0 {
            return "UTC+\(offsetHours)"
        } else {
            return "UTC\(offsetHours)"
        }
    }
    
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
                    
                    Text("Select Reporting Location")
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
                    
                    TextField("Search airports...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding()
                
                // Results count
                HStack {
                    Text("\(filteredAirports.count) airports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Airport List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredAirports, id: \.0) { airport in
                            Button(action: {
                                viewModel.selectedReportingLocation = airport.0
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
                                        
                                        Text(getUTCOffset(for: airport.2, on: viewModel.reportingDateTime))
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.selectedReportingLocation == airport.0 {
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

