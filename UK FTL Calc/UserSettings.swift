//
//  UserSettings.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct UserSettings: View {
    @AppStorage("homeBase") private var homeBase: String = ""
    @AppStorage("secondHomeBase") private var secondHomeBase: String = ""
    @AppStorage("airline") private var airline: String = ""
    @State private var showingHomeBasePicker = false
    @State private var showingSecondHomeBasePicker = false
    @State private var showingAirlinePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Pilot Profile")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Configure your home bases and time zones")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Home Base Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Home Bases")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Primary Home Base
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Home Base")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Button(action: { showingHomeBasePicker = true }) {
                                HStack {
                                    if !homeBase.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(homeBase)
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            if let airport = AirportsAndAirlines.airports.first(where: { $0.0 == homeBase }) {
                                                Text(airport.1)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    } else {
                                        Text("Select Primary Home Base")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        // Second Home Base
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Second Home Base (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Button(action: { showingSecondHomeBasePicker = true }) {
                                HStack {
                                    if !secondHomeBase.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(secondHomeBase)
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            if let airport = AirportsAndAirlines.airports.first(where: { $0.0 == secondHomeBase }) {
                                                Text(airport.1)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    } else {
                                        Text("Select Second Home Base")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Airline Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Airline")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Button(action: { showingAirlinePicker = true }) {
                            HStack {
                                if !airline.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(airline)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        if let airlineInfo = AirportsAndAirlines.airlines.first(where: { $0.0 == airline }) {
                                            Text(airlineInfo.1)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                } else {
                                    Text("Select Airline")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Current Time Display
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Current Local Times")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            // Primary Home Base Time (only show if selected)
                            if !homeBase.isEmpty {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Primary Home Base")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(homeBase)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Local Time")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(getLocalTime(for: homeBase))
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                
                                // Second Home Base Time
                                if !secondHomeBase.isEmpty {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Second Home Base")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(secondHomeBase)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Local Time")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(getLocalTime(for: secondHomeBase))
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)

            .sheet(isPresented: $showingHomeBasePicker) {
                AirportPickerView(
                    selectedAirport: $homeBase,
                    title: "Select Primary Home Base",
                    airports: AirportsAndAirlines.airports
                )
            }
            .sheet(isPresented: $showingSecondHomeBasePicker) {
                AirportPickerView(
                    selectedAirport: $secondHomeBase,
                    title: "Select Second Home Base",
                    airports: AirportsAndAirlines.airports
                )
            }
            .sheet(isPresented: $showingAirlinePicker) {
                AirlinePickerView(
                    selectedAirline: $airline,
                    title: "Select Airline",
                    airlines: AirportsAndAirlines.airlines
                )
            }
        }
    }
    
    private func getLocalTime(for airportCode: String) -> String {
        return TimeUtilities.getLocalTime(for: airportCode)
    }
}

struct AirlinePickerView: View {
    @Binding var selectedAirline: String
    let title: String
    let airlines: [(String, String)]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredAirlines: [(String, String)] {
        if searchText.isEmpty {
            return airlines
        } else {
            return airlines.filter { airline in
                airline.0.localizedCaseInsensitiveContains(searchText) ||
                airline.1.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search airlines...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Airline List
                List(filteredAirlines, id: \.0) { airline in
                    Button(action: {
                        selectedAirline = airline.0
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(airline.0)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(airline.1)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedAirline == airline.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
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

struct AirportPickerView: View {
    @Binding var selectedAirport: String
    let title: String
    let airports: [(String, String, String)]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredAirports: [(String, String, String)] {
        if searchText.isEmpty {
            return airports
        } else {
            return airports.filter { airport in
                airport.0.localizedCaseInsensitiveContains(searchText) ||
                airport.1.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search airports...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Airport List
                List(filteredAirports, id: \.0) { airport in
                    Button(action: {
                        selectedAirport = airport.0
                        dismiss()
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
                            
                            if selectedAirport == airport.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
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
