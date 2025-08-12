import SwiftUI
import UniformTypeIdentifiers

struct PDFUploadView: View {
    @StateObject private var pdfParser = PDFRosterParser()
    @State private var showingDocumentPicker = false
    @State private var showingProcessingView = false
    @State private var showingFlightSelection = false
    @State private var selectedPDFURL: URL?
    
    let onFlightsParsed: ([FlightRecord], [FlightRecord]) -> Void // (selectedFlights, allFlights)
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Upload Roster PDF")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select your roster PDF to automatically extract flight information")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // Upload Button
            Button(action: {
                print("DEBUG: Select PDF button tapped")
                showingDocumentPicker = true
            }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.title2)
                    Text("Select PDF File")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                Text("Supported Format:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Roster PDF with flight details")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Flight numbers, times, and dates")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Departure and arrival information")
                    }
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(selectedURL: $selectedPDFURL, onFileSelected: { url in
                print("DEBUG: File selected: \(url)")
                selectedPDFURL = url
                showingProcessingView = true
                Task {
                    await pdfParser.parsePDFRoster(from: url)
                }
            })
        }
        .onAppear {
            print("DEBUG: PDFUploadView appeared")
        }
        .sheet(isPresented: $showingProcessingView) {
            PDFProcessingView(
                pdfParser: pdfParser,
                onComplete: { allFlights in
                    showingProcessingView = false
                    showingFlightSelection = true
                },
                onCancel: {
                    showingProcessingView = false
                }
            )
        }
        .sheet(isPresented: $showingFlightSelection) {
            FlightSelectionView(
                allFlights: pdfParser.parsedFlights,
                onFlightSelected: { selectedFlight in
                    showingFlightSelection = false
                    onFlightsParsed([selectedFlight], pdfParser.parsedFlights)
                },
                onCancel: {
                    showingFlightSelection = false
                }
            )
        }
    }
}

// DocumentPicker is now defined in FileUploadView.swift

// MARK: - Processing View
struct PDFProcessingView: View {
    @ObservedObject var pdfParser: PDFRosterParser
    let onComplete: ([FlightRecord]) -> Void // (allFlights)
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Progress Indicator
                VStack(spacing: 20) {
                    if pdfParser.isProcessing {
                        ProgressView(value: pdfParser.processingProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                        
                        Text(pdfParser.processingMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    } else {
                        if let error = pdfParser.errorMessage {
                            // Error State
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                
                                Text("Processing Failed")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        } else if !pdfParser.parsedFlights.isEmpty {
                            // Success State with Flight List
                            VStack(spacing: 20) {
                                // Success Header
                                VStack(spacing: 16) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.green)
                                    
                                    Text("Success!")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("Found \(pdfParser.parsedFlights.count) flights")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Selection Instructions
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "hand.tap.fill")
                                            .foregroundColor(.blue)
                                        Text("Ready to Select Flight:")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("All \(pdfParser.parsedFlights.count) flights have been imported. Now choose which flight to analyze.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                
                                // Continue to Flight Selection Button
                                Button(action: {
                                    onComplete(pdfParser.parsedFlights)
                                }) {
                                    HStack {
                                        Image(systemName: "airplane")
                                            .font(.title2)
                                        Text("Continue to Flight Selection")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal)
                                    .frame(maxHeight: 300)
                                }
                            }
                        }
                    }
                }
                .padding()
                
                // Cancel Button at Bottom
                if !pdfParser.isProcessing {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
            }
            .padding()
            .navigationTitle("Processing PDF")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }

// MARK: - PDF Upload Flight Row
struct PDFUploadFlightRow: View {
    let flight: FlightRecord
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Flight Number and Route
                HStack {
                    Text(flight.flightNumber.uppercased())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .onAppear {
                            print("DEBUG: PDFUploadFlightRow displaying flight number: '\(flight.flightNumber)'")
                        }
                    
                    Spacer()
                    
                    Text("\(flight.departure) → \(flight.arrival)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                // Date and Times
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(flight.date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Report: \(flight.reportTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("OFF: \(flight.takeoffTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("ON: \(flight.landingTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Flight Selection View

// MARK: - Flight Selection Row

#Preview {
    PDFUploadView { selectedFlights, allFlights in
        print("Parsed \(selectedFlights.count) selected flights from \(allFlights.count) total flights")
    }
} 