//
//  FlightPicker.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

// MARK: - Flight Selection View
struct FlightSelectionView: View {
    let allFlights: [FlightRecord]
    let onFlightSelected: (FlightRecord) -> Void
    let onCancel: () -> Void
    @State private var searchText = ""
    
    var filteredFlights: [FlightRecord] {
        if searchText.isEmpty {
            return allFlights
        } else {
            return allFlights.filter { flight in
                flight.flightNumber.localizedCaseInsensitiveContains(searchText) ||
                flight.departure.localizedCaseInsensitiveContains(searchText) ||
                flight.arrival.localizedCaseInsensitiveContains(searchText) ||
                flight.date.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Select Flight from Roster")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Choose which flight you want to analyze for FTL calculations. All flights from your uploaded roster are available below.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Additional helpful message
                    Text("💡 You can access all flights from your roster anytime using the Select Flight button - no need to re-upload!")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Flight Count Badge
                HStack {
                    Text("\(filteredFlights.count) of \(allFlights.count) flights")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(12)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search flights by number, route, or date...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                // Flight List
                if filteredFlights.isEmpty {
                    VStack(spacing: 16) {
                        if searchText.isEmpty {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("No Flights Available")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("No flights were found in your uploaded roster. Please try uploading a different file.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("No Matching Flights")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("No flights match your search for '\(searchText)'. Try a different search term.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFlights) { flight in
                                FlightSelectionRow(flight: flight) {
                                    onFlightSelected(flight)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Flight Selection Row
struct FlightSelectionRow: View {
    let flight: FlightRecord
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    // Flight Icon and Route
                    VStack(spacing: 4) {
                        Image(systemName: "airplane")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        // Route indicator
                        HStack(spacing: 4) {
                            Text(flight.departure)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(flight.isOutbound ? .green : .primary)
                            
                            Image(systemName: flight.isOutbound ? "arrow.up.right" : "arrow.down.left")
                                .font(.caption2)
                                .foregroundColor(flight.isOutbound ? .green : .orange)
                            
                            Text(flight.arrival)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(flight.isOutbound ? .primary : .orange)
                        }
                        
                        // Outbound/Inbound indicator
                        Text(flight.isOutbound ? "OUTBOUND" : "INBOUND")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(flight.isOutbound ? .green : .orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(flight.isOutbound ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    // Flight Details
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(flight.flightNumber)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Date badge
                            Text(flight.date)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .cornerRadius(6)
                        }
                        
                        // Times row
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Report")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(flight.reportTime)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Takeoff")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(flight.takeoffTime)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Landing")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(flight.landingTime)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Flight time and duty time
                        HStack {
                            Text("Flight: \(TimeUtilities.formatHoursAndMinutes(flight.flightTime))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Duty: \(TimeUtilities.formatHoursAndMinutes(flight.dutyTime))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Trip information
                        if !flight.tripNumber.isEmpty {
                            HStack {
                                Text("Trip: \(flight.tripNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Elapsed: \(TimeUtilities.formatHoursAndMinutes(flight.elapsedTimeHours))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Shuttle trip information
                        if flight.isShuttleTrip {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "shuttle")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    
                                    Text("Shuttle Trip \(flight.tripNumber) - Duty \(flight.dutyNumber)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                }
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Elapsed from Trip Start")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(TimeUtilities.formatHoursAndMinutes(flight.elapsedTimeFromTripStart))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Regular Elapsed")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(TimeUtilities.formatHoursAndMinutes(flight.elapsedTimeHours))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    VStack {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Select")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
