//
//  CalendarImportView.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct CalendarImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var availableFlights: [FlightRecord] = []
    @State private var selectedFlights: Set<UUID> = []
    @State private var isLoading = true
    @State private var importMessage = ""
    @State private var isImporting = false
    
    let onImport: ([FlightRecord]) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import Flights")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Select flights to add to your calendar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    if !importMessage.isEmpty {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(importMessage)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading available flights...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else if availableFlights.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "airplane.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No flights available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("No flights available to import")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else {
                    // Flight Selection List
                    VStack(spacing: 0) {
                        // Selection Header
                        HStack {
                            Text("Available Flights")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(selectedFlights.count) selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        
                        // Flights List
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(availableFlights, id: \.id) { flight in
                                    CalendarFlightSelectionRow(
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
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import Selected") {
                        importSelectedFlights()
                    }
                    .disabled(selectedFlights.isEmpty || isImporting)
                }
            }
            .onAppear {
                loadAvailableFlights()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadAvailableFlights() {
        // This function is no longer needed since we removed sample data
        // Flights are now loaded through PDF upload
        availableFlights = []
        isLoading = false
    }
    
    private func importSelectedFlights() {
        isImporting = true
        importMessage = "Importing selected flights..."
        
        let selectedFlightRecords = availableFlights.filter { selectedFlights.contains($0.id) }
        
        // Simulate import delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onImport(selectedFlightRecords)
            importMessage = "Successfully imported \(selectedFlightRecords.count) flights!"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}

// MARK: - Calendar Flight Selection Row

struct CalendarFlightSelectionRow: View {
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
    CalendarImportView { selectedFlights in
        print("Importing \(selectedFlights.count) flights")
    }
} 