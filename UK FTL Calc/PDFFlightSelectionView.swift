import SwiftUI

struct PDFFlightSelectionView: View {
    let flights: [FlightRecord]
    let onFlightSelected: (FlightRecord) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if flights.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("No Flights Found")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("No flight records were found in the uploaded PDF. Please check the file format and try again.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(flights, id: \.id) { flight in
                            PDFFlightSelectionRow(flight: flight) {
                                onFlightSelected(flight)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PDFFlightSelectionRow: View {
    let flight: FlightRecord
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(flight.flightNumber)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(flight.date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(flight.departure)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(flight.arrival)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                
                HStack {
                    Text("Report: \(flight.reportTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Takeoff: \(flight.takeoffTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Landing: \(flight.landingTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
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
        onFlightSelected: { _ in }
    )
} 