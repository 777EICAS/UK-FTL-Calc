import SwiftUI

struct ProfileCompletionView: View {
    @EnvironmentObject var authService: AuthenticationService
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
                    // Welcome Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Welcome!")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if authService.currentUser != nil {
                                Text("Let's set up your pilot profile")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("Please complete your profile to get started with the UK FTL Calculator")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Profile Setup Form
                    VStack(spacing: 20) {
                        // Home Base Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Home Base")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Primary Home Base *")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
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
                            
                            // Second Home Base (Optional)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Second Home Base (Optional)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
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
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select Airline (Optional)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
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
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        
                        // Save Button
                        Button(action: {
                            // Mark profile setup as complete
                            authService.markProfileSetupComplete()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Complete Profile Setup")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(homeBase.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(homeBase.isEmpty)
                        
                        // Note about required fields
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Primary home base is required. Airline and second home base are optional.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Complete Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
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
}
