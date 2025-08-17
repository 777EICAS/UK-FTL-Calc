import SwiftUI

struct PDFFlightSelectionView: View {
    let flights: [FlightRecord]
    let onFlightsSelected: ([FlightRecord]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFlights: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Flights")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Choose which flights to add to your calendar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    // Selection Summary
                    HStack {
                        Text("\(selectedFlights.count) of \(flights.count) flights selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Select All/None buttons
                        HStack(spacing: 12) {
                            Button("Select All") {
                                selectedFlights = Set(flights.map { $0.id })
                            }
                            .disabled(selectedFlights.count == flights.count)
                            
                            Button("Clear All") {
                                selectedFlights.removeAll()
                            }
                            .disabled(selectedFlights.isEmpty)
                        }
                        .font(.caption)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                if flights.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("No Flights Found")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("No flight records were found in the uploaded file. Please check the file format and try again.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    // Flight Selection List
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(flights, id: \.id) { flight in
                                PDFFlightSelectionRow(
                                    flight: flight,
                                    isSelected: selectedFlights.contains(flight.id),
                                    onToggle: {
                                        if selectedFlights.contains(flight.id) {
                                            selectedFlights.remove(flight.id)
                                        } else {
                                            selectedFlights.insert(flight.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select Flights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import Selected") {
                        let selectedFlightRecords = flights.filter { selectedFlights.contains($0.id) }
                        onFlightsSelected(selectedFlightRecords)
                        dismiss()
                    }
                    .disabled(selectedFlights.isEmpty)
                }
            }
            .onAppear {
                // Auto-select all flights by default
                selectedFlights = Set(flights.map { $0.id })
            }
        }
    }
}

struct PDFFlightSelectionRow: View {
    let flight: FlightRecord
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                // Flight Information
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(flight.departure) → \(flight.arrival)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(flight.takeoffTime)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Flight \(flight.flightNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(flight.date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Duty: \(TimeUtilities.formatHoursAndMinutes(flight.dutyTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Flight: \(TimeUtilities.formatHoursAndMinutes(flight.flightTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PDFFlightSelectionView(
        flights: [
            FlightRecord(
                flightNumber: "BA 179",
                departure: "LHR",
                arrival: "JFK",
                reportTime: "15:35z",
                takeoffTime: "17:05z",
                landingTime: "01:00z",
                dutyEndTime: "01:00z",
                flightTime: 8.5,
                dutyTime: 1.5,
                pilotType: .multiPilot,
                date: "8/5/25"
            ),
            FlightRecord(
                flightNumber: "BA 114",
                departure: "JFK",
                arrival: "LHR",
                reportTime: "00:30z",
                takeoffTime: "01:30z",
                landingTime: "08:40z",
                dutyEndTime: "08:40z",
                flightTime: 7.5,
                dutyTime: 1.0,
                pilotType: .multiPilot,
                date: "8/7/25"
            )
        ],
        onFlightsSelected: { _ in }
    )
} 