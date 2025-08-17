import SwiftUI
import UniformTypeIdentifiers

struct FileUploadView: View {
    @StateObject private var pdfParser = PDFRosterParser()
    @StateObject private var xmlParser = XMLRosterParser()
    @State private var showingDocumentPicker = false
    @State private var showingProcessingView = false
    @State private var showingFlightSelection = false
    @State private var selectedFileURL: URL?
    @State private var selectedFileType: FileType = .pdf
    
    let onFlightsParsed: ([FlightRecord], [FlightRecord]) -> Void // (selectedFlights, allFlights)
    
    enum FileType {
        case pdf
        case xml
        
        var displayName: String {
            switch self {
            case .pdf: return "PDF"
            case .xml: return "XML"
            }
        }
        
        var icon: String {
            switch self {
            case .pdf: return "doc.text"
            case .xml: return "doc.plaintext"
            }
        }
        
        var description: String {
            switch self {
            case .pdf: return "Roster PDF with flight details"
            case .xml: return "Roster XML with structured flight data"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Upload Roster File")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select your roster file to automatically extract flight information")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // File Type Selector
            Picker("File Type", selection: $selectedFileType) {
                Text("PDF").tag(FileType.pdf)
                Text("XML").tag(FileType.xml)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Upload Button
            Button(action: {
                print("DEBUG: Select \(selectedFileType.displayName) button tapped")
                showingDocumentPicker = true
            }) {
                HStack {
                    Image(systemName: selectedFileType.icon)
                        .font(.title2)
                                    Text("Select Roster File")
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
                Text("Supported Formats:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("PDF: Roster with flight details")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("XML: Structured roster data (more accurate)")
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
            DocumentPicker(selectedURL: $selectedFileURL, onFileSelected: { url in
                print("DEBUG: File selected: \(url)")
                selectedFileURL = url
                showingProcessingView = true
                Task {
                    await parseFile(url: url)
                }
            })
        }
        .sheet(isPresented: $showingProcessingView) {
            ProcessingView(
                isProcessing: selectedFileType == .pdf ? pdfParser.isProcessing : xmlParser.isProcessing,
                progress: selectedFileType == .pdf ? pdfParser.processingProgress : xmlParser.processingProgress,
                message: selectedFileType == .pdf ? pdfParser.processingMessage : xmlParser.processingMessage,
                errorMessage: selectedFileType == .pdf ? pdfParser.errorMessage : xmlParser.errorMessage,
                successMessage: {
                    let flights = selectedFileType == .pdf ? pdfParser.parsedFlights : xmlParser.parsedFlights
                    if flights.isEmpty {
                        return "File processed but no flights found"
                    } else {
                        return "Successfully parsed \(flights.count) flights"
                    }
                }()
            ) {
                showingProcessingView = false
                if let error = selectedFileType == .pdf ? pdfParser.errorMessage : xmlParser.errorMessage {
                    // Handle error
                    print("Error: \(error)")
                } else {
                    let flights = selectedFileType == .pdf ? pdfParser.parsedFlights : xmlParser.parsedFlights
                    if !flights.isEmpty {
                        showingFlightSelection = true
                    } else {
                        // No flights found - show error message
                        print("DEBUG: No flights found in \(selectedFileType.displayName) file")
                        // You could show an alert here if needed
                    }
                }
            }
        }
        .sheet(isPresented: $showingFlightSelection) {
            let flights = selectedFileType == .pdf ? pdfParser.parsedFlights : xmlParser.parsedFlights
            PDFFlightSelectionView(flights: flights, onFlightsSelected: { selectedFlights in
                // Handle multiple flight selection - pass the selected flights as selectedFlights
                // and all flights as allFlights for trip context
                onFlightsParsed(selectedFlights, flights)
            })
        }
        .onAppear {
            print("DEBUG: FileUploadView appeared")
        }
    }
    
    private func parseFile(url: URL) async {
        // Auto-detect file type based on file extension
        let fileExtension = url.pathExtension.lowercased()
        let detectedFileType: FileType
        
        switch fileExtension {
        case "pdf":
            detectedFileType = .pdf
        case "xml":
            detectedFileType = .xml
        default:
            // Default to PDF if unknown extension
            detectedFileType = .pdf
        }
        
        // Update the UI to show the detected file type
        await MainActor.run {
            selectedFileType = detectedFileType
        }
        
        // Parse based on detected type
        switch detectedFileType {
        case .pdf:
            await pdfParser.parsePDFRoster(from: url)
        case .xml:
            await xmlParser.parseXMLRoster(from: url)
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    let onFileSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Use the newer API for better device compatibility
        let picker: UIDocumentPickerViewController
        
        if #available(iOS 14.0, *) {
            // Support both PDF and XML files
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf, UTType.xml], asCopy: true)
        } else {
            // Fallback for older iOS versions
            picker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf", "public.xml"], in: .import)
        }
        
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        
        // Enable these options for better device compatibility
        if #available(iOS 13.0, *) {
            picker.directoryURL = nil // Allow access to all directories
        }
        
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
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            let shouldStopAccessing = url.startAccessingSecurityScopedResource()
            
            // Call the completion handler
            parent.onFileSelected(url)
            
            // Stop accessing the security-scoped resource
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("DEBUG: Document picker was cancelled")
        }
    }
}

// MARK: - Processing View
struct ProcessingView: View {
    let isProcessing: Bool
    let progress: Double
    let message: String
    let errorMessage: String?
    let successMessage: String?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if isProcessing {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1.5, y: 1.5)
                
                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if let error = errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Error")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(error)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("OK") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text("Success!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(successMessage ?? "File processed successfully")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Continue") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: 300)
    }
}
