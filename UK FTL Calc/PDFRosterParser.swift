import SwiftUI
import PDFKit
import Vision
import VisionKit

// MARK: - PDF Roster Parser
class PDFRosterParser: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var processingMessage = ""
    @Published var parsedFlights: [FlightRecord] = []
    @Published var errorMessage: String?
    
    func parsePDFRoster(from url: URL) async {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
            processingMessage = "Loading PDF..."
            errorMessage = nil
        }
        
        do {
            // Debug: Print file information
            print("DEBUG: Attempting to load PDF from URL: \(url)")
            print("DEBUG: File exists: \(FileManager.default.fileExists(atPath: url.path))")
            print("DEBUG: File size: \(try? FileManager.default.attributesOfItem(atPath: url.path)[.size] ?? "Unknown")")
            
            // Load PDF document
            guard let pdfDocument = PDFDocument(url: url) else {
                print("DEBUG: Failed to create PDFDocument from URL")
                throw PDFParsingError.invalidPDF
            }
            
            print("DEBUG: Successfully loaded PDF with \(pdfDocument.pageCount) pages")
            
            await MainActor.run {
                processingProgress = 0.2
                processingMessage = "Extracting text from PDF..."
            }
            
            // Extract text from PDF
            let extractedText = extractTextFromPDF(pdfDocument)
            
            // Debug: Print extracted text to console
            print("DEBUG: Extracted text from PDF:")
            print(extractedText)
            
            await MainActor.run {
                processingProgress = 0.4
                processingMessage = "Parsing roster data..."
            }
            
            // Parse the extracted text
            let parsedData = parseRosterText(extractedText)
            
            // Debug: Print parsed data
            print("DEBUG: Parsed \(parsedData.count) duty blocks")
            for (index, block) in parsedData.enumerated() {
                print("DEBUG: Block \(index): \(block.date) - \(block.tripNumber)")
                if let outbound = block.outboundFlight {
                    print("DEBUG:   Outbound: \(outbound.flightNumber) \(outbound.departure)-\(outbound.arrival)")
                }
                if let inbound = block.inboundFlight {
                    print("DEBUG:   Inbound: \(inbound.flightNumber) \(inbound.departure)-\(inbound.arrival)")
                }
            }
            
            await MainActor.run {
                processingProgress = 0.6
                processingMessage = "Converting to flight records..."
            }
            
            // Convert to FlightRecord objects
            let flights = convertToFlightRecords(parsedData)
            
            await MainActor.run {
                processingProgress = 0.8
                processingMessage = "Finalizing..."
            }
            
            // Simulate processing time
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                self.parsedFlights = flights
                processingProgress = 1.0
                processingMessage = "Successfully parsed \(flights.count) flights"
                isProcessing = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
            }
        }
    }
    
    private func extractTextFromPDF(_ document: PDFDocument) -> String {
        var extractedText = ""
        
        print("DEBUG: Starting text extraction from \(document.pageCount) pages")
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                print("DEBUG: Processing page \(i + 1)")
                if let pageContent = page.string {
                    print("DEBUG: Page \(i + 1) content length: \(pageContent.count) characters")
                    extractedText += pageContent + "\n"
                } else {
                    print("DEBUG: Page \(i + 1) has no text content")
                }
            } else {
                print("DEBUG: Could not access page \(i + 1)")
            }
        }
        
        print("DEBUG: Total extracted text length: \(extractedText.count) characters")
        return extractedText
    }
    
    private func parseRosterText(_ text: String) -> [ParsedDutyBlock] {
        var dutyBlocks: [ParsedDutyBlock] = []
        let lines = text.components(separatedBy: .newlines)
        
        var currentDutyBlock: ParsedDutyBlock?
        var currentOutboundFlight: ParsedFlight? = nil
        var currentInboundFlight: ParsedFlight? = nil
        var dutyBlockPilots: Set<String> = []
        var hasFoundInboundFlight = false
        
        func finalizeDutyBlock() {
            guard var block = currentDutyBlock else { return }
            
            // Assign pilots to both flights in the duty block
            let totalPilotCount = max(1, dutyBlockPilots.count + 1) // +1 for user
            
            if let outbound = currentOutboundFlight {
                block.outboundFlight = outbound
                block.outboundPilotCount = totalPilotCount
                print("DEBUG: Finalized outbound flight \(outbound.flightNumber) with \(totalPilotCount) pilots")
            }
            
            if let inbound = currentInboundFlight {
                block.inboundFlight = inbound
                block.inboundPilotCount = totalPilotCount
                print("DEBUG: Finalized inbound flight \(inbound.flightNumber) with \(totalPilotCount) pilots")
            }
            
            dutyBlocks.append(block)
            print("DEBUG: Completed duty block with \(dutyBlockPilots.count) unique pilots: \(dutyBlockPilots)")
        }
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { continue }
            
            // Debug: Print each line being processed
            print("DEBUG: Processing line: '\(trimmedLine)'")
            
            // Duty block header - start new block
            if let dutyHeader = parseDutyHeader(trimmedLine) {
                // Finalize previous block if exists
                if currentDutyBlock != nil {
                    finalizeDutyBlock()
                }
                
                // Start new block
                currentDutyBlock = dutyHeader
                currentOutboundFlight = nil
                currentInboundFlight = nil
                dutyBlockPilots.removeAll()
                hasFoundInboundFlight = false
                print("DEBUG: Starting new duty block: \(dutyHeader.date) - \(dutyHeader.tripNumber)")
                continue
            }
            
            // Flight line
            if let flight = parseFlightLine(trimmedLine) {
                if currentOutboundFlight == nil {
                    // This is the outbound flight
                    currentOutboundFlight = flight
                    print("DEBUG: Found outbound flight: \(flight.flightNumber)")
                } else if !hasFoundInboundFlight {
                    // This is the inbound flight
                    currentInboundFlight = flight
                    hasFoundInboundFlight = true
                    print("DEBUG: Found inbound flight: \(flight.flightNumber)")
                }
                continue
            }
            
            // Pilot line - collect all pilots for this duty block
            if trimmedLine.contains("Captain") || trimmedLine.contains("Co-Pilot") {
                // Check if this line also contains return date information
                if trimmedLine.contains("Return:") {
                    print("DEBUG: Found pilot line with return date: '\(trimmedLine)'")
                    
                    // Split the line into pilot and return date parts
                    let components = trimmedLine.components(separatedBy: " ")
                    var pilotParts: [String] = []
                    var returnDateParts: [String] = []
                    var foundReturn = false
                    
                    for component in components {
                        if component.hasPrefix("Return:") {
                            foundReturn = true
                            // Extract the time part after "Return:"
                            let timePart = String(component.dropFirst(7)) // Remove "Return:"
                            returnDateParts.append(timePart)
                            continue
                        }
                        
                        if foundReturn {
                            returnDateParts.append(component)
                        } else {
                            pilotParts.append(component)
                        }
                    }
                    
                    print("DEBUG: Pilot parts: \(pilotParts)")
                    print("DEBUG: Return date parts: \(returnDateParts)")
                    
                    // Process pilot part
                    let pilotLine = pilotParts.joined(separator: " ")
                    if let pilotName = extractPilotName(pilotLine) {
                        if !dutyBlockPilots.contains(pilotName) {
                            dutyBlockPilots.insert(pilotName)
                            print("DEBUG: Added pilot to duty block: \(pilotName)")
                        } else {
                            print("DEBUG: Duplicate pilot in duty block (ignoring): \(pilotName)")
                        }
                    }
                    
                    // Process return date part
                    let returnDateLine = returnDateParts.joined(separator: " ")
                    print("DEBUG: Attempting to parse return date from: '\(returnDateLine)'")
                    
                    // Reconstruct the proper return date string
                    // We need to get the day and day name from pilot parts
                    // Look for a number (day) and a day name in the pilot parts
                    var day = ""
                    var dayName = ""
                    
                    for part in pilotParts {
                        if part.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil && !part.isEmpty {
                            // This is a number (day)
                            day = part
                        } else if ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"].contains(part) {
                            // This is a day name
                            dayName = part
                        }
                    }
                    
                    if !day.isEmpty && !dayName.isEmpty {
                        let reconstructedReturnDate = "\(day) \(dayName) - Return:\(returnDateLine)"
                        print("DEBUG: Reconstructed return date string: '\(reconstructedReturnDate)'")
                        
                        if let returnDate = parseReturnDate(reconstructedReturnDate) {
                            currentDutyBlock?.returnDate = returnDate
                            print("DEBUG: Set return date from combined line: \(returnDate)")
                        } else {
                            print("DEBUG: Failed to parse return date from reconstructed string")
                        }
                    } else {
                        print("DEBUG: Could not find day (\(day)) and day name (\(dayName)) in pilot parts")
                    }
                } else {
                    // Regular pilot line without return date
                    if let pilotName = extractPilotName(trimmedLine) {
                        if !dutyBlockPilots.contains(pilotName) {
                            dutyBlockPilots.insert(pilotName)
                            print("DEBUG: Added pilot to duty block: \(pilotName)")
                        } else {
                            print("DEBUG: Duplicate pilot in duty block (ignoring): \(pilotName)")
                        }
                    }
                }
                continue
            }
            
            // Return date (standalone date line)
            if let returnDate = parseReturnDate(trimmedLine) {
                currentDutyBlock?.returnDate = returnDate
                continue
            }
            
            // Pilot line with return date (e.g., "Co-Pilot Joshua Head 13 Wednesday - Return:11:50z")
            if let (pilotName, returnDate) = parsePilotWithReturnDate(trimmedLine) {
                // Add pilot to duty block
                if !dutyBlockPilots.contains(pilotName) {
                    dutyBlockPilots.insert(pilotName)
                    print("DEBUG: Added pilot to duty block: \(pilotName)")
                } else {
                    print("DEBUG: Duplicate pilot in duty block (ignoring): \(pilotName)")
                }
                
                // Set return date
                currentDutyBlock?.returnDate = returnDate
                continue
            }
            
            // Layover
            if let layover = parseLayoverInfo(trimmedLine) {
                currentDutyBlock?.layover = layover
                continue
            }
            
            // Debug unmatched lines
            if !trimmedLine.isEmpty && !trimmedLine.contains("Slip in") && 
               !trimmedLine.contains("Hotel") && !trimmedLine.contains("Tel:") &&
               !trimmedLine.contains("Pickup") && !trimmedLine.contains("Return:") &&
               !trimmedLine.contains("ATD:") && !trimmedLine.contains("ATA:") &&
               !trimmedLine.contains("a/c:") && !trimmedLine.contains("______") &&
               !trimmedLine.contains("Captain") && !trimmedLine.contains("Co-Pilot") {
                print("DEBUG: Unmatched line: '\(trimmedLine)'")
            }
        }
        
        // Finalize the last duty block
        if currentDutyBlock != nil {
            finalizeDutyBlock()
        }
        
        return dutyBlocks
    }
    
    private func parseDutyHeader(_ line: String) -> ParsedDutyBlock? {
        // Pattern: "5 Tuesday - T7165 Report:16:36z" (from actual PDF)
        let pattern = #"(\d+)\s+(\w+)\s+-\s+(\w+)\s+Report:(\d{2}:\d{2}z)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        let day = String(line[Range(match.range(at: 1), in: line)!])
        let dayName = String(line[Range(match.range(at: 2), in: line)!])
        let tripNumber = String(line[Range(match.range(at: 3), in: line)!])
        let reportTime = String(line[Range(match.range(at: 4), in: line)!])
        
        return ParsedDutyBlock(
            date: "\(day) \(dayName)",
            tripNumber: tripNumber,
            reportTime: reportTime
        )
    }
    
    private func parseFlightLine(_ line: String) -> ParsedFlight? {
        // Pattern: "BA 179 LHR - JFK, 17:05z - 01:00z" (from actual PDF)
        let pattern = #"([A-Z]{2,3})\s+(\d+)\s+([A-Z]{3})\s+-\s+([A-Z]{3}),\s+(\d{2}:\d{2}z)\s+-\s+(\d{2}:\d{2}z)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            print("DEBUG: Flight line did not match pattern: '\(line)'")
            return nil
        }
        
        let airline = String(line[Range(match.range(at: 1), in: line)!])
        let flightNumber = String(line[Range(match.range(at: 2), in: line)!])
        let departure = String(line[Range(match.range(at: 3), in: line)!])
        let arrival = String(line[Range(match.range(at: 4), in: line)!])
        let departureTime = String(line[Range(match.range(at: 5), in: line)!])
        let arrivalTime = String(line[Range(match.range(at: 6), in: line)!])
        
        // Convert XBA to BA for consistency
        let displayAirline = airline == "XBA" ? "BA" : airline
        
        print("DEBUG: Parsed flight - Airline: '\(airline)', Display Airline: '\(displayAirline)', Flight Number: '\(flightNumber)', Combined: '\(displayAirline) \(flightNumber)'")
        print("DEBUG: Flight times - Departure: '\(departureTime)' from '\(departure)', Arrival: '\(arrivalTime)' at '\(arrival)'")
        
        return ParsedFlight(
            airline: airline,
            flightNumber: "\(displayAirline) \(flightNumber)",
            departure: departure,
            arrival: arrival,
            departureTime: departureTime,
            arrivalTime: arrivalTime
        )
    }
    
    private func parseReturnDate(_ line: String) -> String? {
        // Pattern: "7 Thursday - Return:09:10z" (standalone return date line)
        let pattern = #"(\d+)\s+(\w+)\s+-\s+Return:(\d{2}:\d{2}z)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        let day = String(line[Range(match.range(at: 1), in: line)!])
        let dayName = String(line[Range(match.range(at: 2), in: line)!])
        
        print("DEBUG: Parsed standalone return date: '\(day) \(dayName)' from line: '\(line)'")
        return "\(day) \(dayName)"
    }
    
    private func parsePilotWithReturnDate(_ line: String) -> (pilotName: String, returnDate: String)? {
        // Pattern: "Co-Pilot Joshua Head 13 Wednesday - Return:11:50z" or "Training Captain Martin Abbott 11 Wednesday - Return:08:50z"
        // This line contains both pilot information and return date
        let pattern = #"(Captain|Co-Pilot|Training Captain)\s+([A-Za-z]+)\s+([A-Za-z]+)\s+(\d+)\s+(\w+)\s+-\s+Return:(\d{2}:\d{2}z)"#
        
        print("DEBUG: parsePilotWithReturnDate - testing line: '\(line)'")
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            print("DEBUG: parsePilotWithReturnDate - no match for line: '\(line)'")
            return nil
        }
        
        let pilotType = String(line[Range(match.range(at: 1), in: line)!])
        let firstName = String(line[Range(match.range(at: 2), in: line)!])
        let lastName = String(line[Range(match.range(at: 3), in: line)!])
        let day = String(line[Range(match.range(at: 4), in: line)!])
        let dayName = String(line[Range(match.range(at: 5), in: line)!])
        
        let pilotName = "\(firstName) \(lastName)"
        let returnDate = "\(day) \(dayName)"
        
        print("DEBUG: Parsed pilot with return date - Pilot: '\(pilotName)' (\(pilotType)), Return Date: '\(returnDate)' from line: '\(line)'")
        return (pilotName: pilotName, returnDate: returnDate)
    }
    
    private func parseLayoverInfo(_ line: String) -> ParsedLayover? {
        // Look for layover duration patterns
        if line.contains("Slip in") && line.contains("hours") {
            // Extract location and duration
            let components = line.components(separatedBy: " ")
            if let slipIndex = components.firstIndex(of: "Slip"),
               let inIndex = components.firstIndex(of: "in"),
               slipIndex + 1 < components.count,
               inIndex + 1 < components.count {
                
                let location = components[inIndex + 1]
                let duration = components[slipIndex + 1]
                
                return ParsedLayover(
                    location: location,
                    duration: duration
                )
            }
        }
        
        return nil
    }
    
    private func parsePilotCount(_ line: String) -> Int? {
        // Count the number of pilot entries in the line
        // The user is automatically assumed to be one pilot, so we count additional pilots
        var pilotCount = 1 // Start with 1 (the user)
        
        // Count Captain mentions (including Training Captain)
        let captainCount = line.components(separatedBy: "Captain").count - 1
        pilotCount += captainCount
        
        // Count Co-Pilot mentions
        let coPilotCount = line.components(separatedBy: "Co-Pilot").count - 1
        pilotCount += coPilotCount
        
        // Note: Training Captain is already counted in the Captain count above
        // since "Training Captain" contains "Captain"
        
        print("DEBUG: Pilot count calculation - Line: '\(line)'")
        print("DEBUG:   Captain count (including Training Captain): \(captainCount)")
        print("DEBUG:   Co-Pilot count: \(coPilotCount)")
        print("DEBUG:   Total pilots (including user): \(pilotCount)")
        
        // Return the total count (including the user)
        return pilotCount
    }
    

    
    private func extractPilotName(_ line: String) -> String? {
        // Extract pilot name from line like "Captain Peter Jones", "Co-Pilot Joshua Head", or "Training Captain Martin Abbott"
        let words = line.components(separatedBy: .whitespaces)
        if words.count >= 3 && (words[0] == "Captain" || words[0] == "Co-Pilot") {
            // Return first and last name (e.g., "Peter Jones")
            return "\(words[1]) \(words[2])"
        } else if words.count >= 4 && words[0] == "Training" && words[1] == "Captain" {
            // Handle "Training Captain Martin Abbott"
            return "\(words[2]) \(words[3])"
        }
        return nil
    }
    

    

    
    private func convertToFlightRecords(_ dutyBlocks: [ParsedDutyBlock]) -> [FlightRecord] {
        var flights: [FlightRecord] = []
        
        for dutyBlock in dutyBlocks {
            // Create outbound flight
            if let outbound = dutyBlock.outboundFlight {
                let flightRecord = createFlightRecord(
                    from: dutyBlock,
                    flight: outbound,
                    isOutbound: true
                )
                flights.append(flightRecord)
            }
            
            // Create inbound flight
            if let inbound = dutyBlock.inboundFlight {
                let flightRecord = createFlightRecord(
                    from: dutyBlock,
                    flight: inbound,
                    isOutbound: false
                )
                flights.append(flightRecord)
            }
        }
        
        return flights
    }
    
    private func createFlightRecord(from dutyBlock: ParsedDutyBlock, flight: ParsedFlight, isOutbound: Bool) -> FlightRecord {
        // Parse the date
        let inputDateString = isOutbound ? dutyBlock.date : (dutyBlock.returnDate ?? dutyBlock.date)
        let components = inputDateString.components(separatedBy: " ")
        let dayString = components.first ?? "1"
        let day = Int(dayString) ?? 1
        
        // Create date for August 2025
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 8 // August
        dateComponents.day = day
        
        let flightDate = calendar.date(from: dateComponents) ?? Date()
        let dateFormatter = DateFormatter.shortDate
        let formattedDateString = dateFormatter.string(from: flightDate)
        
        // Calculate report time based on departure airport
        let dutyStartTime = calculateDutyStartTime(from: flight.departureTime, departure: flight.departure)
        
        // Calculate actual flight time from OFF Block to ON Block
        let flightTimeHours = TimeUtilities.calculateHoursBetween(flight.departureTime, flight.arrivalTime)
        
        // Calculate actual duty time from report time to duty end time
        let dutyTimeHours = TimeUtilities.calculateHoursBetween(dutyStartTime, flight.arrivalTime)
        
        let finalFlightRecord = FlightRecord(
            flightNumber: flight.flightNumber,
            departure: flight.departure,
            arrival: flight.arrival,
            reportTime: dutyStartTime,
            takeoffTime: flight.departureTime,
            landingTime: flight.arrivalTime,
            dutyEndTime: flight.arrivalTime,
            flightTime: flightTimeHours,
            dutyTime: dutyTimeHours,
            pilotType: .multiPilot,
            date: formattedDateString,
            pilotCount: isOutbound ? dutyBlock.outboundPilotCount : dutyBlock.inboundPilotCount
        )
        
        print("DEBUG: Created FlightRecord - Flight Number: '\(finalFlightRecord.flightNumber)', Pilot Count: \(finalFlightRecord.pilotCount)")
        
        return finalFlightRecord
    }
    
    private func calculateDutyStartTime(from takeoffTime: String, departure: String) -> String {
        // Determine report time based on departure airport
        // LHR/LGW departures: 90 minutes before departure
        // All other departures: 75 minutes before departure
        let reportTimeMinutes: Int
        if departure.uppercased() == "LHR" || departure.uppercased() == "LGW" {
            reportTimeMinutes = 90
            print("DEBUG: LHR/LGW departure - using 90 minute report time")
        } else {
            reportTimeMinutes = 75
            print("DEBUG: Non-LHR/LGW departure (\(departure)) - using 75 minute report time")
        }
        
        // Convert takeoff time to minutes, subtract report time, convert back
        let timeComponents = takeoffTime.replacingOccurrences(of: "z", with: "").components(separatedBy: ":")
        guard let hour = Int(timeComponents[0]), let minute = Int(timeComponents[1]) else {
            print("DEBUG: Failed to parse time components from '\(takeoffTime)'")
            return "00:00z"
        }
        
        let departureMinutes = hour * 60 + minute
        var totalMinutes = departureMinutes - reportTimeMinutes
        
        print("DEBUG: Time calculation - Departure: \(hour):\(minute)z (\(departureMinutes) minutes) - \(reportTimeMinutes) minutes = \(totalMinutes) minutes")
        
        // Handle negative time (previous day)
        if totalMinutes < 0 {
            totalMinutes += 24 * 60
            print("DEBUG: Adjusted for previous day: \(totalMinutes) minutes")
        }
        
        let dutyHour = totalMinutes / 60
        let dutyMinute = totalMinutes % 60
        
        let reportTime = String(format: "%02d:%02dz", dutyHour, dutyMinute)
        print("DEBUG: Calculated report time: \(reportTime) (departure: \(takeoffTime), airport: \(departure))")
        
        return reportTime
    }
    

}

// MARK: - Data Models
struct ParsedDutyBlock {
    let date: String
    let tripNumber: String
    let reportTime: String
    var outboundFlight: ParsedFlight?
    var inboundFlight: ParsedFlight?
    var returnDate: String?
    var layover: ParsedLayover?
    var outboundPilotCount: Int = 1 // Default to 1 pilot (the user) for outbound
    var inboundPilotCount: Int = 1 // Default to 1 pilot (the user) for inbound
}

struct ParsedFlight {
    let airline: String
    let flightNumber: String
    let departure: String
    let arrival: String
    let departureTime: String
    let arrivalTime: String
}

struct ParsedLayover {
    let location: String
    let duration: String
}

// MARK: - Errors
enum PDFParsingError: Error, LocalizedError {
    case invalidPDF
    case textExtractionFailed
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            return "Invalid PDF file"
        case .textExtractionFailed:
            return "Failed to extract text from PDF"
        case .parsingFailed:
            return "Failed to parse roster data"
        }
    }
} 