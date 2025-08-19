//
//  UserSettings.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct UserSettings: View {
    @EnvironmentObject var authService: AuthenticationService
    @AppStorage("homeBase") private var homeBase: String = ""
    @AppStorage("secondHomeBase") private var secondHomeBase: String = ""
    @AppStorage("airline") private var airline: String = ""
    @AppStorage("autoSaveFlights") private var autoSaveFlights = true
    @State private var showingHomeBasePicker = false
    @State private var showingSecondHomeBasePicker = false
    @State private var showingAirlinePicker = false
    @State private var showingSettings = false
    @State private var showingDeleteAccountSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        // Welcome message with user's name
                        if let user = authService.currentUser {
                            VStack(spacing: 4) {
                                Text("Welcome back!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                let firstName = user.userMetadata["first_name"]?.stringValue ?? ""
                                let lastName = user.userMetadata["last_name"]?.stringValue ?? ""
                                Text("\(firstName) \(lastName)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        } else {
                            Text("Pilot Profile")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("Configure your home bases and time zones")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Sign Out Button
                        Button(action: {
                            Task {
                                await authService.signOut()
                            }
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
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
                    
                    // Time Zone Display
                    if !homeBase.isEmpty || !secondHomeBase.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Current Local Times")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
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
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                }
                                
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
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Save Profile Button
                    VStack(spacing: 12) {
                        Button(action: {
                            // Profile data is automatically saved via @AppStorage
                            // Show a brief confirmation
                            // You could add a toast notification here if desired
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Profile Saved")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(homeBase.isEmpty)
                        
                        Text("Your profile settings are automatically saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                
                // Delete Account Section
                VStack(spacing: 16) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Danger Zone")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        Text("Once you delete your account, there is no going back. Please be certain.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: {
                        showingDeleteAccountSheet = true
                    }) {
                        Text("Delete Account")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                    }
                }
            }
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
            .sheet(isPresented: $showingSettings) {
                SettingsPopupView(autoSaveFlights: $autoSaveFlights)
            }
            .sheet(isPresented: $showingDeleteAccountSheet) {
                DeleteAccountSheet()
            }
        }
    }
    
    private func getLocalTime(for airportCode: String) -> String {
        return TimeUtilities.getLocalTime(for: airportCode)
    }
}

// Settings Popup View
struct SettingsPopupView: View {
    @Binding var autoSaveFlights: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Data Management
                Section("Data Management") {
                    Toggle("Auto-save Flights", isOn: $autoSaveFlights)
                    
                    Button("Clear All Data") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("UK CAA Website", destination: URL(string: "https://www.caa.co.uk")!)
                    
                    Link("Flight Time Limitations Guide", destination: URL(string: "https://www.caa.co.uk/commercial-industry/airspace/air-traffic-control/air-traffic-services/")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func clearAllData() {
        // Implementation for clearing all data
        // This would show a confirmation alert first
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
