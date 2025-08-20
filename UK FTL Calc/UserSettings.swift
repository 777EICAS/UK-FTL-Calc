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
    @AppStorage("crewType") private var crewType: String = "Pilot"
    @AppStorage("autoSaveFlights") private var autoSaveFlights = true
    @State private var showingHomeBasePicker = false
    @State private var showingSecondHomeBasePicker = false
    @State private var showingAirlinePicker = false
    @State private var showingSettings = false
    @State private var showingDeleteAccountSheet = false
    @State private var showingEditNameSheet = false
    @State private var showingResetPasswordSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section - Matching manual calc theme
                    VStack(spacing: 16) {
                        // Main Header Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(crewType == "Pilot" ? "Pilot Profile" : "Cabin Crew Profile")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Text("Configure your home bases and time zones")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                // Icon with background
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                    .background(
                                        Circle()
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                    )
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    // Welcome Message Section
                    if let user = authService.currentUser {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "hand.wave.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                
                                Text("Welcome back!")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: 4) {
                                let firstName = user.userMetadata["first_name"]?.stringValue ?? ""
                                let lastName = user.userMetadata["last_name"]?.stringValue ?? ""
                                Text("\(firstName) \(lastName)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    
                    // Crew Type Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            Text("Crew Type")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select your role")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 12) {
                                Button(action: { crewType = "Pilot" }) {
                                    HStack {
                                        Image(systemName: crewType == "Pilot" ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(crewType == "Pilot" ? .blue : .secondary)
                                        Text("Pilot")
                                            .fontWeight(crewType == "Pilot" ? .semibold : .regular)
                                            .foregroundColor(crewType == "Pilot" ? .primary : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(crewType == "Pilot" ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(crewType == "Pilot" ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                }
                                
                                Button(action: { crewType = "Cabin Crew" }) {
                                    HStack {
                                        Image(systemName: crewType == "Cabin Crew" ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(crewType == "Cabin Crew" ? .blue : .secondary)
                                        Text("Cabin Crew")
                                            .fontWeight(crewType == "Cabin Crew" ? .semibold : .regular)
                                            .foregroundColor(crewType == "Cabin Crew" ? .primary : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(crewType == "Cabin Crew" ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(crewType == "Cabin Crew" ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Home Base Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            Text("Home Bases")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
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
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Airline Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "airplane")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            Text("Airline")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
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
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Time Zone Display
                    if !homeBase.isEmpty || !secondHomeBase.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                
                                Text("Current Local Times")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                            }
                            
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
                                    .background(Color(.systemGray6))
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
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
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
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Account Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.badge.key")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            Text("Account Settings")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        // Edit Name Button
                        Button(action: {
                            showingEditNameSheet = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Edit Name")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    if let user = authService.currentUser {
                                        let firstName = user.userMetadata["first_name"]?.stringValue ?? ""
                                        let lastName = user.userMetadata["last_name"]?.stringValue ?? ""
                                        Text("\(firstName) \(lastName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Not set")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Reset Password Button
                        Button(action: {
                            showingResetPasswordSheet = true
                        }) {
                            HStack {
                                Image(systemName: "lock.rotation")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Reset Password")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("Send password reset email")
                                        .font(.caption)
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
                        
                        // Email Display
                        if let user = authService.currentUser,
                           let email = user.email {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Email Address")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Email verification status
                                if user.emailConfirmedAt != nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text("Verified")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(4)
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text("Unverified")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(4)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Account Management Section
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .foregroundColor(.red)
                                .font(.title3)
                            
                            Text("Account Management")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        
                        // Sign Out Button
                        Button(action: {
                            Task {
                                await authService.signOut()
                            }
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .fontWeight(.semibold)
                            }
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
                        
                        // Delete Account Button
                        Button(action: {
                            showingDeleteAccountSheet = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Account")
                                    .fontWeight(.semibold)
                            }
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
                        
                        Text("Once you delete your account, there is no going back. Please be certain.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // Regulatory Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            Text("Regulatory Information")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            // Critical Disclaimer
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text("Critical Notice")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                }
                                
                                Text("This app provides FTL calculations based on the developer's interpretation of UK CAA regulations. It is NOT official UK CAA guidance.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                            
                            // Regulation Sources
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "book.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Official Sources")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• UK CAA: www.caa.co.uk")
                                    Text("• EU OPS Regulations")
                                    Text("• CAP 371 Documentation")
                                    Text("• Your airline's operations manual")
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                            
                            // App Version Info
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("App Information")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Based on UK CAA regulations as of 2025")
                                    Text("• Regulations may change - verify current versions")
                                    Text("• This app may not reflect latest updates")
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
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
            .sheet(isPresented: $showingEditNameSheet) {
                EditNameSheet(currentName: authService.currentUser?.userMetadata["first_name"]?.stringValue ?? "", currentLastName: authService.currentUser?.userMetadata["last_name"]?.stringValue ?? "") { firstName, lastName in
                    Task {
                        await authService.updateUserMetadata(["first_name": firstName, "last_name": lastName])
                    }
                }
            }
            .sheet(isPresented: $showingResetPasswordSheet) {
                ResetPasswordSheet()
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

// Edit Name Sheet
struct EditNameSheet: View {
    let currentName: String
    let currentLastName: String
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String
    @State private var lastName: String
    @State private var isLoading = false
    
    init(currentName: String, currentLastName: String, onSave: @escaping (String, String) -> Void) {
        self.currentName = currentName
        self.currentLastName = currentLastName
        self.onSave = onSave
        self._firstName = State(initialValue: currentName)
        self._lastName = State(initialValue: currentLastName)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Edit Your Name")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Update your first and last name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Form Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter first name", text: $firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter last name", text: $lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    isLoading = true
                    onSave(firstName, lastName)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoading = false
                        dismiss()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        
                        Text(isLoading ? "Saving..." : "Save Changes")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(firstName.isEmpty || lastName.isEmpty ? Color.gray : Color.blue)
                    )
                }
                .disabled(firstName.isEmpty || lastName.isEmpty || isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Edit Name")
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

// Reset Password Sheet
struct ResetPasswordSheet: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var showingSuccess = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your email to receive a password reset link")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Form Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.subheadline)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                .padding(.horizontal)
                
                // Error Message
                if !errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Reset Button
                Button(action: {
                    resetPassword()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        
                        Text(isLoading ? "Sending..." : "Send Reset Link")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(email.isEmpty || isLoading ? Color.gray : Color.blue)
                    )
                }
                .disabled(email.isEmpty || isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Pre-fill email if available from auth service
                if let user = authService.currentUser,
                   let userEmail = user.email {
                    email = userEmail
                }
            }
            .alert("Password Reset Sent", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("If an account with that email exists, you will receive a password reset link shortly.")
            }
        }
    }
    
    private func resetPassword() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.resetPassword(email: email)
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
