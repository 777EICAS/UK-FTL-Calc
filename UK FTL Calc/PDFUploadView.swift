import SwiftUI
import UniformTypeIdentifiers

struct PDFUploadView: View {
    @StateObject private var pdfParser = PDFRosterParser()
    @State private var showingDocumentPicker = false
    @State private var showingProcessingView = false
    @State private var selectedPDFURL: URL?
    
    let onFlightsParsed: ([FlightRecord]) -> Void
    
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
                do {
                    showingDocumentPicker = true
                } catch {
                    print("DEBUG: Error showing document picker: \(error)")
                }
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
                onComplete: { flights in
                    showingProcessingView = false
                    onFlightsParsed(flights)
                },
                onCancel: {
                    showingProcessingView = false
                }
            )
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    let onFileSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Try different approaches for document picker
        let picker: UIDocumentPickerViewController
        
        if #available(iOS 14.0, *) {
            // Use the newer API
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf], asCopy: true)
        } else {
            // Fallback for older iOS versions
            picker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .import)
        }
        
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        
        // Add error handling for system issues
        print("DEBUG: Creating document picker with configuration: \(picker)")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("DEBUG: Document picker did pick documents: \(urls)")
            guard let url = urls.first else { 
                print("DEBUG: No URL selected")
                return 
            }
            parent.selectedURL = url
            parent.onFileSelected(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("DEBUG: Document picker was cancelled")
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
            print("DEBUG: Document picker did pick document at: \(url)")
            parent.selectedURL = url
            parent.onFileSelected(url)
        }
    }
}

// MARK: - Processing View
struct PDFProcessingView: View {
    @ObservedObject var pdfParser: PDFRosterParser
    let onComplete: ([FlightRecord]) -> Void
    let onCancel: () -> Void
    @State private var showingFlightSelection = false
    
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
                                        Text("Import Options:")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("Choose to import all flights or select individual flights")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                
                                // Import All Button
                                Button(action: {
                                    onComplete(pdfParser.parsedFlights)
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.title2)
                                        Text("Import All \(pdfParser.parsedFlights.count) Flights")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal)
                                
                                // Divider
                                HStack {
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(height: 1)
                                    Text("OR")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(height: 1)
                                }
                                .padding(.horizontal)
                                
                                // Individual Flight Selection
                                VStack(spacing: 8) {
                                    Text("Select Individual Flights:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    ScrollView {
                                        LazyVStack(spacing: 12) {
                                            ForEach(pdfParser.parsedFlights) { flight in
                                                PDFUploadFlightRow(flight: flight) {
                                                    onComplete([flight])
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
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

#Preview {
    PDFUploadView { flights in
        print("Parsed \(flights.count) flights")
    }
} 