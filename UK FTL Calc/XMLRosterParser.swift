import Foundation
import SwiftUI

class XMLRosterParser: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var processingMessage = ""
    @Published var parsedFlights: [FlightRecord] = []
    @Published var errorMessage: String?
    
    func parseXMLRoster(from url: URL) async {
        await MainActor.run {
            isProcessing = true
            processingProgress = 0.0
            processingMessage = "Loading XML file..."
            errorMessage = nil
        }
        
        do {
            let xmlData = try Data(contentsOf: url)
            let xmlString = String(data: xmlData, encoding: .utf8) ?? ""
            
            // Validate XML content
            guard !xmlString.isEmpty else {
                throw XMLParsingError.emptyFile
            }
            
            guard xmlString.contains("[ROSTER]") || xmlString.contains("[TRIP]") else {
                throw XMLParsingError.invalidFormat("File does not appear to be a valid roster XML")
            }
            
            await MainActor.run {
                processingProgress = 0.3
                processingMessage = "Parsing XML structure..."
            }
            
            // Parse the XML content
            let flights = parseXMLContent(xmlString)
            
            await MainActor.run {
                processingProgress = 0.7
                processingMessage = "Converting to flight records..."
            }
            
            // Convert to FlightRecord objects
            let flightRecords = convertToFlightRecords(flights)
            
            await MainActor.run {
                self.parsedFlights = flightRecords
                processingProgress = 1.0
                processingMessage = "Successfully parsed \(flightRecords.count) flights"
                isProcessing = false
            }
            
        } catch {
            await MainActor.run {
                if let xmlError = error as? XMLParsingError {
                    self.errorMessage = xmlError.localizedDescription
                } else {
                    self.errorMessage = "Failed to parse XML file: \(error.localizedDescription)"
                }
                self.isProcessing = false
            }
        }
    }
    
    private func parseXMLContent(_ xmlString: String) -> [XMLFlightData] {
        var flights: [XMLFlightData] = []
        
        print("DEBUG: XML Parser - Starting to parse XML content")
        print("DEBUG: XML Parser - Content length: \(xmlString.count) characters")
        
        // Split the XML content into roster and trip sections
        let sections = xmlString.components(separatedBy: "[TRIP]")
        print("DEBUG: XML Parser - Found \(sections.count) sections")
        
        if sections.count > 1 {
            let tripSection = sections[1]
            print("DEBUG: XML Parser - Trip section length: \(tripSection.count) characters")
            flights = parseTripSection(tripSection)
        } else {
            print("DEBUG: XML Parser - No [TRIP] section found, trying to parse entire content")
            flights = parseTripSection(xmlString)
        }
        
        print("DEBUG: XML Parser - Parsed \(flights.count) flights")
        
        // Validate that we found some flights
        if flights.isEmpty {
            print("DEBUG: XML Parser - Warning: No flights found in XML content")
        }
        
        return flights
    }
    
    private func parseTripSection(_ tripSection: String) -> [XMLFlightData] {
        var flights: [XMLFlightData] = []
        
        // Extract trip blocks
        let tripBlocks = tripSection.components(separatedBy: "<Trip>")
        print("DEBUG: XML Parser - Found \(tripBlocks.count) trip blocks")
        
        if tripBlocks.count <= 1 {
            print("DEBUG: XML Parser - Warning: No trip blocks found in XML")
            return flights
        }
        
        for (index, block) in tripBlocks.dropFirst().enumerated() { // Skip first element as it's header
            print("DEBUG: XML Parser - Parsing trip block \(index + 1)")
            if let flight = parseTripBlock(block) {
                flights.append(flight)
                print("DEBUG: XML Parser - Successfully parsed trip \(flight.tripNumber)")
            } else {
                print("DEBUG: XML Parser - Failed to parse trip block \(index + 1)")
            }
        }
        
        return flights
    }
    
    private func parseTripBlock(_ block: String) -> XMLFlightData? {
        // Extract trip number
        guard let tripNumberMatch = block.range(of: "<TripNumber>(.*?)</TripNumber>", options: .regularExpression),
              let tripNumber = extractValue(from: block, start: tripNumberMatch.lowerBound, end: tripNumberMatch.upperBound) else {
            print("DEBUG: XML Parser - Could not extract trip number from block")
            return nil
        }
        
        // Extract trip start date
        let startDate = extractValue(from: block, pattern: "<StartDate>(.*?)</StartDate>") ?? ""
        print("DEBUG: XML Parser - Trip \(tripNumber) start date: \(startDate)")
        
        // Extract crew complements from trip level
        let crewComplements = extractTripCrewComplements(from: block)
        print("DEBUG: XML Parser - Trip \(tripNumber) crew complements: \(crewComplements)")
        
        // Determine if this is a heavy crew trip based on crew complement pattern
        let isHeavyCrew = crewComplements["heavyCrew"] ?? 0 > 0
        print("DEBUG: XML Parser - Trip \(tripNumber) is heavy crew: \(isHeavyCrew)")
        
        let duties = parseDuties(from: block, isHeavyCrew: isHeavyCrew, tripStartDate: startDate, crewComplements: crewComplements)
        print("DEBUG: XML Parser - Trip \(tripNumber) has \(duties.count) duties")
        
        // Validate that we have at least one duty
        if duties.isEmpty {
            print("DEBUG: XML Parser - Warning: Trip \(tripNumber) has no duties")
        }
        
        // NEW: Create Trip object to group sectors together
        let trip = createTripFromDuties(tripNumber: tripNumber, startDate: startDate, duties: duties, isHeavyCrew: isHeavyCrew)
        
        return XMLFlightData(
            tripNumber: tripNumber,
            startDate: startDate,
            duties: duties,
            isHeavyCrew: isHeavyCrew,
            trip: trip // NEW: Include trip object
        )
    }
    
    // NEW: Function to create Trip object from duties
    private func createTripFromDuties(tripNumber: String, startDate: String, duties: [XMLDuty], isHeavyCrew: Bool) -> Trip {
        var allSectors: [XMLSector] = []
        
        // Collect all sectors from all duties
        for duty in duties {
            allSectors.append(contentsOf: duty.sectors)
        }
        
        // Determine which sectors are outbound vs inbound based on trip context
        // A sector is outbound if it departs from the home base (LHR/LGW)
        // A sector is inbound if it returns to the home base
        
        // Sort sectors by relative departure day to determine order
        let sortedSectors = allSectors.sorted { sector1, sector2 in
            let day1 = Int(sector1.relativeDepartureDay) ?? 0
            let day2 = Int(sector2.relativeDepartureDay) ?? 0
            return day1 < day2
        }
        
        // Determine home base from the trip (usually LHR or LGW)
        let homeBase = determineHomeBase(from: duties)
        print("DEBUG: XML Parser - Trip \(tripNumber) home base determined: \(homeBase)")
        
        // Create new sectors with correct outbound/inbound classification
        var updatedSectors: [XMLSector] = []
        
        for (index, sector) in sortedSectors.enumerated() {
            // A sector is outbound if it departs from the home base
            let isOutbound = sector.departure == homeBase
            
            let updatedSector = XMLSector(
                flightNumber: sector.flightNumber,
                departure: sector.departure,
                arrival: sector.arrival,
                departureTime: sector.departureTime,
                arrivalTime: sector.arrivalTime,
                relativeDepartureDay: sector.relativeDepartureDay,
                pilotCount: sector.pilotCount,
                flyingHours: sector.flyingHours,
                isOutbound: isOutbound,
                tripNumber: tripNumber,
                dutyNumber: sector.dutyNumber,
                isShuttleTrip: false // Will be set later
            )
            
            updatedSectors.append(updatedSector)
            
            print("DEBUG: XML Parser - Trip \(tripNumber) sector \(sector.flightNumber): \(sector.departure)-\(sector.arrival) is \(isOutbound ? "OUTBOUND" : "INBOUND") (day \(sector.relativeDepartureDay), position \(index + 1)/\(sortedSectors.count))")
        }
        
        print("DEBUG: XML Parser - Created Trip \(tripNumber) with \(updatedSectors.count) sectors:")
        for (index, sector) in updatedSectors.enumerated() {
            print("DEBUG: XML Parser -   Sector \(index + 1): \(sector.flightNumber) \(sector.departure)-\(sector.arrival) (\(sector.isOutbound ? "OUTBOUND" : "INBOUND")) on day \(sector.relativeDepartureDay)")
        }
        
        // NEW: Set isShuttleTrip flag for all sectors in this trip
        let isShuttleTrip = duties.contains { duty in
            duty.sectors.count > 1
        }
        print("DEBUG: XML Parser - Trip \(tripNumber) shuttle trip detection: \(isShuttleTrip) (duties with multiple sectors: \(duties.filter { $0.sectors.count > 1 }.count))")
        
        // Update all sectors with the shuttle trip flag
        let finalSectors = updatedSectors.map { sector in
            XMLSector(
                flightNumber: sector.flightNumber,
                departure: sector.departure,
                arrival: sector.arrival,
                departureTime: sector.departureTime,
                arrivalTime: sector.arrivalTime,
                relativeDepartureDay: sector.relativeDepartureDay,
                pilotCount: sector.pilotCount,
                flyingHours: sector.flyingHours,
                isOutbound: sector.isOutbound,
                tripNumber: sector.tripNumber,
                dutyNumber: sector.dutyNumber,
                isShuttleTrip: isShuttleTrip // NEW: Mark as shuttle if any duty has multiple sectors
            )
        }
        
        return Trip(
            tripNumber: tripNumber,
            startDate: startDate,
            sectors: finalSectors,
            isHeavyCrew: isHeavyCrew
        )
    }
    
    // NEW: Helper function to determine home base from duties
    private func determineHomeBase(from duties: [XMLDuty]) -> String {
        // Look for the first duty with a sector departing from LHR or LGW
        for duty in duties {
            for sector in duty.sectors {
                if sector.departure == "LHR" || sector.departure == "LGW" {
                    print("DEBUG: XML Parser - Found home base departure: \(sector.departure) in duty \(duty.dutyNumber)")
                    return sector.departure
                }
            }
        }
        
        // Fallback: if no LHR/LGW departure found, use the first departure station
        if let firstDuty = duties.first, let firstSector = firstDuty.sectors.first {
            print("DEBUG: XML Parser - No LHR/LGW departure found, using first departure: \(firstSector.departure)")
            return firstSector.departure
        }
        
        // Default fallback
        print("DEBUG: XML Parser - No departure stations found, defaulting to LHR")
        return "LHR"
    }
    
    private func parseDuties(from block: String, isHeavyCrew: Bool, tripStartDate: String, crewComplements: [String: Int]) -> [XMLDuty] {
        var duties: [XMLDuty] = []
        
        let dutyBlocks = block.components(separatedBy: "<Duty>")
        print("DEBUG: XML Parser - Found \(dutyBlocks.count) duty blocks")
        
        if dutyBlocks.count <= 1 {
            print("DEBUG: XML Parser - Warning: No duty blocks found in trip")
            return duties
        }
        
        for (index, dutyBlock) in dutyBlocks.dropFirst().enumerated() {
            print("DEBUG: XML Parser - Parsing duty \(index + 1)")
            if let duty = parseDuty(dutyBlock, isHeavyCrew: isHeavyCrew, tripStartDate: tripStartDate, crewComplements: crewComplements) {
                duties.append(duty)
                print("DEBUG: XML Parser - Successfully parsed duty \(duty.dutyNumber)")
            } else {
                print("DEBUG: XML Parser - Failed to parse duty \(index + 1)")
            }
        }
        
        return duties
    }
    
    private func parseDuty(_ dutyBlock: String, isHeavyCrew: Bool, tripStartDate: String, crewComplements: [String: Int]) -> XMLDuty? {
        // Extract duty details
        guard let dutyNumberMatch = dutyBlock.range(of: "<DutyNumber>(.*?)</DutyNumber>", options: .regularExpression),
              let dutyNumber = extractValue(from: dutyBlock, start: dutyNumberMatch.lowerBound, end: dutyNumberMatch.upperBound) else {
            print("DEBUG: XML Parser - Could not extract duty number")
            return nil
        }
        
        // Extract actual report time
        let actualReportTime = extractValue(from: dutyBlock, pattern: "<ActualReportTime>(.*?)</ActualReportTime>") ?? ""
        print("DEBUG: XML Parser - Duty \(dutyNumber) actual report time: \(actualReportTime)")
        
        // Extract duty hours
        let dutyHours = extractValue(from: dutyBlock, pattern: "<DutyHours>(.*?)</DutyHours>") ?? ""
        print("DEBUG: XML Parser - Duty \(dutyNumber) duty hours: \(dutyHours)")
        
        // Extract sectors
        let sectors = parseSectors(from: dutyBlock, isHeavyCrew: isHeavyCrew, tripStartDate: tripStartDate, crewComplements: crewComplements, dutyNumber: dutyNumber)
        print("DEBUG: XML Parser - Duty \(dutyNumber) has \(sectors.count) sectors")
        
        // Validate that we have at least one sector
        if sectors.isEmpty {
            print("DEBUG: XML Parser - Warning: Duty \(dutyNumber) has no sectors")
        }
        
        return XMLDuty(
            dutyNumber: dutyNumber,
            actualReportTime: actualReportTime,
            dutyHours: dutyHours,
            sectors: sectors
        )
    }
    
    private func parseSectors(from dutyBlock: String, isHeavyCrew: Bool, tripStartDate: String, crewComplements: [String: Int], dutyNumber: String) -> [XMLSector] {
        var sectors: [XMLSector] = []
        
        let sectorBlocks = dutyBlock.components(separatedBy: "<Sector>")
        print("DEBUG: XML Parser - Found \(sectorBlocks.count) sector blocks")
        
        if sectorBlocks.count <= 1 {
            print("DEBUG: XML Parser - Warning: No sector blocks found in duty")
            return sectors
        }
        
        for (index, sectorBlock) in sectorBlocks.dropFirst().enumerated() {
            print("DEBUG: XML Parser - Parsing sector \(index + 1)")
            if let sector = parseSector(sectorBlock, isHeavyCrew: isHeavyCrew, tripStartDate: tripStartDate, crewComplements: crewComplements, dutyNumber: dutyNumber) {
                sectors.append(sector)
                print("DEBUG: XML Parser - Successfully parsed sector: \(sector.flightNumber) \(sector.departure)-\(sector.arrival)")
            } else {
                print("DEBUG: XML Parser - Failed to parse sector \(index + 1)")
            }
        }
        
        return sectors
    }
    
        private func parseSector(_ sectorBlock: String, isHeavyCrew: Bool, tripStartDate: String, crewComplements: [String: Int], dutyNumber: String) -> XMLSector? {
        // Extract sector details
        guard let flightNumberMatch = sectorBlock.range(of: "<FlightNumber>(.*?)</FlightNumber>", options: .regularExpression),
              let rawFlightNumber = extractValue(from: sectorBlock, start: flightNumberMatch.lowerBound, end: flightNumberMatch.upperBound),
              let departureMatch = sectorBlock.range(of: "<DepartureStation>(.*?)</DepartureStation>", options: .regularExpression),
              let departure = extractValue(from: sectorBlock, start: departureMatch.lowerBound, end: departureMatch.upperBound),
              let arrivalMatch = sectorBlock.range(of: "<ArrivalStation>(.*?)</ArrivalStation>", options: .regularExpression),
              let arrival = extractValue(from: sectorBlock, start: arrivalMatch.lowerBound, end: arrivalMatch.upperBound) else {
            print("DEBUG: XML Parser - Could not extract basic sector information")
            return nil
        }
        
        // Prepend "BA" to flight numbers since XML contains only numeric part
        let flightNumber = "BA\(rawFlightNumber)"
        
        // Extract PLANNED times (not actual times) for proper scheduling
        let plannedDepartureTime = extractValue(from: sectorBlock, pattern: "<PlannedDepartureTime>(.*?)</PlannedDepartureTime>") ?? ""
        let plannedArrivalTime = extractValue(from: sectorBlock, pattern: "<PlannedArrivalTime>(.*?)</PlannedArrivalTime>") ?? ""
        
        // Fall back to actual times only if planned times are not available
        let departureTime = plannedDepartureTime.isEmpty ? 
            extractValue(from: sectorBlock, pattern: "<DepartureTime>(.*?)</DepartureTime>") ?? "" : 
            plannedDepartureTime
        
        let arrivalTime = plannedArrivalTime.isEmpty ? 
            extractValue(from: sectorBlock, pattern: "<ArrivalTime>(.*?)</ArrivalTime>") ?? "" : 
            plannedArrivalTime
        
        // Extract relative departure day for date calculation
        let relativeDepartureDay = extractValue(from: sectorBlock, pattern: "<RelativeDepartureDay>(.*?)</RelativeDepartureDay>") ?? "0"
        
        // Extract crew complement to determine pilot count
        let pilotCount = extractCrewComplement(from: sectorBlock, crewComplements: crewComplements)
        print("DEBUG: XML Parser - Sector \(flightNumber) pilot count: \(pilotCount) (trip heavy crew: \(isHeavyCrew))")
        
        // Determine if this sector requires augmented crew
        let requiresAugmentedCrew = pilotCount > 2 || isHeavyCrew
        if requiresAugmentedCrew {
            print("DEBUG: XML Parser - Sector \(flightNumber) requires augmented crew (pilot count: \(pilotCount), heavy crew: \(isHeavyCrew))")
        }
        
        // Extract flying hours
        let flyingHours = extractValue(from: sectorBlock, pattern: "<FlyingHours>(.*?)</FlyingHours>") ?? ""
        
        print("DEBUG: XML Parser - Sector details:")
        print("  Flight: \(flightNumber)")
        print("  Route: \(departure)-\(arrival)")
        print("  Planned Times: \(plannedDepartureTime)-\(plannedArrivalTime)")
        print("  Using Times: \(departureTime)-\(arrivalTime)")
        if !plannedDepartureTime.isEmpty && !plannedArrivalTime.isEmpty {
            print("  ✅ Using PLANNED times for scheduling")
        } else {
            print("  ⚠️  Falling back to ACTUAL times (planned times not available)")
        }
        print("  Relative day: \(relativeDepartureDay)")
        print("  Pilot count: \(pilotCount)")
        print("  Flying hours: \(flyingHours)")
        
        return XMLSector(
            flightNumber: flightNumber,
            departure: departure,
            arrival: arrival,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            relativeDepartureDay: relativeDepartureDay,
            pilotCount: pilotCount,
            flyingHours: flyingHours,
            isOutbound: false, // Default to inbound for now, will be set later
            tripNumber: "", // Will be set later
            dutyNumber: dutyNumber, // NEW: Set duty number from parameter
            isShuttleTrip: false // Will be set later based on trip structure
        )
    }
    
    private func extractCrewComplement(from sectorBlock: String, crewComplements: [String: Int]) -> Int {
        // Look for crew complement in the sector block
        let crewComplementPattern = "<CrewComplement>(.*?)</CrewComplement>"
        
        if let match = sectorBlock.range(of: crewComplementPattern, options: .regularExpression),
           let value = extractValue(from: sectorBlock, start: match.lowerBound, end: match.upperBound),
           let intValue = Int(value) {
            print("DEBUG: XML Parser - Found crew complement in sector: \(intValue)")
            return intValue
        }
        
        // If not found in sector, use trip-level crew complement
        if let tripTotal = crewComplements["total"] {
            print("DEBUG: XML Parser - Using trip-level crew complement: \(tripTotal) total crew")
            return tripTotal
        }
        
        print("DEBUG: XML Parser - No crew complement found, defaulting to 1")
        return 1
    }
    
    private func extractValue(from string: String, pattern: String) -> String? {
        guard let range = string.range(of: pattern, options: .regularExpression) else {
            return nil
        }
        return extractValue(from: string, start: range.lowerBound, end: range.upperBound)
    }
    
    private func extractValue(from string: String, start: String.Index, end: String.Index) -> String? {
        let substring = String(string[start..<end])
        // Remove XML tags
        let cleanValue = substring.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return cleanValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractTripCrewComplements(from block: String) -> [String: Int] {
        var crewComplements: [String: Int] = [:]
        
        // Extract all crew complement values from the trip block
        let crewComplementPattern = "<CrewComplement>(.*?)</CrewComplement>"
        
        // Use compatible regex approach instead of matches(of:)
        if let regex = try? NSRegularExpression(pattern: crewComplementPattern, options: []) {
            let range = NSRange(block.startIndex..., in: block)
            let matches = regex.matches(in: block, options: [], range: range)
            
            var crewValues: [Int] = []
            for match in matches {
                let nsRange = match.range
                if let startIndex = block.index(block.startIndex, offsetBy: nsRange.location, limitedBy: block.endIndex),
                   let endIndex = block.index(startIndex, offsetBy: nsRange.length, limitedBy: block.endIndex),
                   let value = extractValue(from: block, start: startIndex, end: endIndex),
                   let intValue = Int(value) {
                    crewValues.append(intValue)
                }
            }
            
            // Interpret crew complement pattern
            if crewValues.count == 2 {
                if crewValues[0] == 1 && crewValues[1] == 1 {
                    // Two "1" values = 2 pilots total
                    crewComplements["total"] = 2
                    crewComplements["pilots"] = 2
                    crewComplements["heavyCrew"] = 0
                    print("DEBUG: XML Parser - Standard crew trip: 2 pilots")
                } else if crewValues[0] == 0 && crewValues[1] == 1 {
                    // "0" + "1" = 1 pilot + 1 heavy crew member = 3 total crew
                    crewComplements["total"] = 3
                    crewComplements["pilots"] = 1
                    crewComplements["heavyCrew"] = 1
                    print("DEBUG: XML Parser - Heavy crew trip: 1 pilot + 1 heavy crew = 3 total crew")
                } else {
                    // Other patterns - sum the values
                    let total = crewValues.reduce(0, +)
                    crewComplements["total"] = total
                    crewComplements["pilots"] = total
                    crewComplements["heavyCrew"] = 0
                    print("DEBUG: XML Parser - Other crew pattern: \(crewValues) = \(total) total")
                }
            } else if crewValues.count == 1 {
                // Single crew complement value
                crewComplements["total"] = crewValues[0]
                crewComplements["pilots"] = crewValues[0]
                crewComplements["heavyCrew"] = 0
                print("DEBUG: XML Parser - Single crew complement: \(crewValues[0])")
            } else {
                // No crew complement found
                crewComplements["total"] = 1
                crewComplements["pilots"] = 1
                crewComplements["heavyCrew"] = 0
                print("DEBUG: XML Parser - No crew complement found, defaulting to 1")
            }
        }
        
        return crewComplements
    }
    
    private func convertToFlightRecords(_ xmlFlights: [XMLFlightData]) -> [FlightRecord] {
        var flightRecords: [FlightRecord] = []
        
        print("DEBUG: XML Parser - Converting \(xmlFlights.count) XML flights to FlightRecord objects")
        
        for (flightIndex, xmlFlight) in xmlFlights.enumerated() {
            print("DEBUG: XML Parser - Processing flight \(flightIndex + 1): Trip \(xmlFlight.tripNumber)")
            
            // Get the trip object for this flight
            let trip = xmlFlight.trip
            print("DEBUG: XML Parser - Trip \(trip.tripNumber) has \(trip.sectors.count) sectors")
            
            // Find outbound and inbound sectors
            let outboundSector = trip.outboundSector
            let inboundSector = trip.inboundSector
            
            if let outbound = outboundSector {
                print("DEBUG: XML Parser - Trip \(trip.tripNumber) outbound: \(outbound.flightNumber) \(outbound.departure)-\(outbound.arrival)")
            }
            if let inbound = inboundSector {
                print("DEBUG: XML Parser - Trip \(trip.tripNumber) inbound: \(inbound.flightNumber) \(inbound.departure)-\(inbound.arrival)")
            }
            
            // Process sectors from the trip object instead of duties to get correct isOutbound values
            for (sectorIndex, sector) in trip.sectors.enumerated() {
                print("DEBUG: XML Parser - Processing sector \(sectorIndex + 1): \(sector.flightNumber)")
                
                // Calculate the actual date for this sector
                let sectorDate = calculateSectorDate(tripStartDate: xmlFlight.startDate, relativeDay: sector.relativeDepartureDay)
                print("DEBUG: XML Parser - Sector date calculated: \(sectorDate)")
                
                // Calculate report time based on NEW SCHEDULING RULES:
                // Home base (LHR/LGW): Planned departure time - 90 minutes
                // Away from home base: Planned departure time - 75 minutes
                let reportTime = calculateReportTime(departure: sector.departure, departureTime: sector.departureTime)
                print("DEBUG: XML Parser - Calculated report time: \(reportTime) (based on \(sector.departure) departure)")
                
                // Calculate flight time from XML data or fall back to calculation
                let flightTime = sector.flyingHours.isEmpty ? 
                    calculateFlightTime(departure: sector.departureTime, arrival: sector.arrivalTime) :
                    parseDuration(sector.flyingHours)
                print("DEBUG: XML Parser - Flight time: \(flightTime) hours")
                
                // Calculate duty time - we need to find the corresponding duty for this sector
                // For now, use a default calculation, but this could be enhanced to find the actual duty
                let dutyTime = flightTime + 2.0 // Add 2 hours for brief/debrief
                print("DEBUG: XML Parser - Duty time: \(dutyTime) hours")
                
                // NEW: Calculate elapsed time for acclimatisation purposes
                // FIXED: This calculation now correctly handles multi-day trips by using
                // the calculateElapsedTimeWithDates function which properly accounts for
                // day differences between outbound and inbound sectors.
                let elapsedTime: Double
                if sector.isOutbound {
                    // Outbound sector: elapsed time is 0 (trip starting point)
                    elapsedTime = 0.0
                    print("DEBUG: XML Parser - Outbound sector \(sector.flightNumber): elapsed time = 0h (trip start)")
                } else if let outbound = outboundSector {
                    // Inbound sector: elapsed time from outbound report time to inbound report time
                    let outboundReportTime = calculateReportTime(departure: outbound.departure, departureTime: outbound.departureTime)
                    let inboundReportTime = calculateReportTime(departure: sector.departure, departureTime: sector.departureTime)
                    
                    // Calculate elapsed time using dates and times
                    // Use the new function to get the correct report time date for the inbound sector
                    let outboundReportDate = calculateSectorDate(tripStartDate: xmlFlight.startDate, relativeDay: outbound.relativeDepartureDay)
                    let inboundReportDate = calculateReportTimeDate(tripStartDate: xmlFlight.startDate, relativeDay: sector.relativeDepartureDay, reportTime: inboundReportTime, offBlockTime: sector.departureTime)
                    
                    elapsedTime = TimeUtilities.calculateElapsedTimeWithDates(
                        startDate: outboundReportDate,
                        startTime: outboundReportTime,
                        endDate: inboundReportDate,
                        endTime: inboundReportTime
                    )
                    
                    print("DEBUG: XML Parser - Inbound sector \(sector.flightNumber): elapsed time = \(elapsedTime)h (from outbound report \(outboundReportTime) on \(outboundReportDate) to inbound report \(inboundReportTime) on \(inboundReportDate))")
                } else {
                    // Fallback: no outbound sector found
                    elapsedTime = 0.0
                    print("DEBUG: XML Parser - Warning: No outbound sector found for inbound \(sector.flightNumber), elapsed time = 0h")
                }
                
                // NEW: Calculate elapsed time from trip start for shuttle trips
                let elapsedTimeFromTripStart: Double
                if sector.isShuttleTrip, let tripStartReportTime = trip.tripStartReportTime {
                    // Calculate elapsed time from trip start report time to this duty's report time
                    let tripStartDate = calculateSectorDate(tripStartDate: xmlFlight.startDate, relativeDay: "0")
                    let dutyReportDate = calculateReportTimeDate(tripStartDate: xmlFlight.startDate, relativeDay: sector.relativeDepartureDay, reportTime: reportTime, offBlockTime: sector.departureTime)
                    
                    elapsedTimeFromTripStart = TimeUtilities.calculateElapsedTimeWithDates(
                        startDate: tripStartDate,
                        startTime: tripStartReportTime,
                        endDate: dutyReportDate,
                        endTime: reportTime
                    )
                    
                    print("DEBUG: XML Parser - Shuttle trip \(trip.tripNumber) duty \(sector.dutyNumber): elapsed time from trip start = \(elapsedTimeFromTripStart)h")
                } else {
                    elapsedTimeFromTripStart = 0.0
                }
                
                let flightRecord = FlightRecord(
                    flightNumber: sector.flightNumber,
                    departure: sector.departure,
                    arrival: sector.arrival,
                    reportTime: reportTime,
                    takeoffTime: sector.departureTime,
                    landingTime: sector.arrivalTime,
                    dutyEndTime: sector.arrivalTime,
                    flightTime: flightTime,
                    dutyTime: dutyTime,
                    pilotType: .copilot, // Default, can be enhanced
                    date: sectorDate,
                    pilotCount: sector.pilotCount,
                    tripNumber: sector.tripNumber, // NEW: Include trip number
                    isOutbound: sector.isOutbound, // NEW: Include outbound/inbound flag
                    elapsedTimeHours: elapsedTime, // NEW: Include calculated elapsed time
                    dutyNumber: sector.dutyNumber, // NEW: Include duty number
                    isShuttleTrip: sector.isShuttleTrip, // NEW: Include shuttle trip flag
                    elapsedTimeFromTripStart: elapsedTimeFromTripStart // NEW: Include elapsed time from trip start
                )
                
                flightRecords.append(flightRecord)
                print("DEBUG: XML Parser - Created FlightRecord: \(flightRecord.flightNumber) \(flightRecord.departure)-\(flightRecord.arrival) on \(flightRecord.date)")
                print("DEBUG: XML Parser - Scheduling: Report \(flightRecord.reportTime), Off Block \(flightRecord.takeoffTime), On Block \(flightRecord.landingTime)")
                print("DEBUG: XML Parser - Trip info: Trip \(flightRecord.tripNumber), \(flightRecord.isOutbound ? "OUTBOUND" : "INBOUND"), Elapsed: \(flightRecord.elapsedTimeHours)h")
            }
        }
        
        print("DEBUG: XML Parser - Successfully created \(flightRecords.count) FlightRecord objects")
        
        // Validate the elapsed time calculations
        print("DEBUG: XML Parser - Validating elapsed time calculations:")
        for record in flightRecords {
            if record.isOutbound && record.elapsedTimeHours != 0.0 {
                print("DEBUG: XML Parser - ERROR: Outbound flight \(record.flightNumber) has non-zero elapsed time: \(record.elapsedTimeHours)h")
            } else if !record.isOutbound && record.elapsedTimeHours == 0.0 {
                print("DEBUG: XML Parser - WARNING: Inbound flight \(record.flightNumber) has zero elapsed time: \(record.elapsedTimeHours)h")
            } else {
                print("DEBUG: XML Parser - ✓ Flight \(record.flightNumber) (\(record.isOutbound ? "OUTBOUND" : "INBOUND")) elapsed time: \(record.elapsedTimeHours)h")
            }
        }
        
        // Additional validation for multi-day trips
        print("DEBUG: XML Parser - Multi-day trip validation:")
        let trips = Dictionary(grouping: flightRecords) { $0.tripNumber }
        for (tripNumber, flights) in trips {
            let outboundFlights = flights.filter { $0.isOutbound }
            let inboundFlights = flights.filter { !$0.isOutbound }
            
            if !outboundFlights.isEmpty && !inboundFlights.isEmpty {
                let outbound = outboundFlights.first!
                let inbound = inboundFlights.first!
                
                // Check if this is a multi-day trip
                let outboundDate = outbound.date
                let inboundDate = inbound.date
                
                if outboundDate != inboundDate {
                    print("DEBUG: XML Parser - Multi-day trip \(tripNumber): \(outboundDate) → \(inboundDate), Elapsed: \(inbound.elapsedTimeHours)h")
                    
                    // Validate that elapsed time makes sense for the date difference
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    if let outboundDateObj = dateFormatter.date(from: outboundDate),
                       let inboundDateObj = dateFormatter.date(from: inboundDate) {
                        let calendar = Calendar.current
                        let dayDifference = calendar.dateComponents([.day], from: outboundDateObj, to: inboundDateObj).day ?? 0
                        
                        if dayDifference > 0 {
                            let expectedMinElapsed = Double(dayDifference) * 24.0
                            if inbound.elapsedTimeHours < expectedMinElapsed {
                                print("DEBUG: XML Parser - WARNING: Trip \(tripNumber) elapsed time (\(inbound.elapsedTimeHours)h) seems too low for \(dayDifference) day difference (expected minimum: \(expectedMinElapsed)h)")
                            } else {
                                print("DEBUG: XML Parser - ✓ Trip \(tripNumber) elapsed time validation passed")
                            }
                        }
                    }
                }
            }
        }
        
        return flightRecords
    }
    
    private func calculateSectorDate(tripStartDate: String, relativeDay: String) -> String {
        print("DEBUG: XML Parser - Calculating sector date from trip start: \(tripStartDate), relative day: \(relativeDay)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let baseDate = dateFormatter.date(from: tripStartDate),
              let relativeDays = Int(relativeDay) else {
            print("DEBUG: XML Parser - Failed to parse date or relative day, returning trip start date")
            return tripStartDate
        }
        
        let sectorDate = Calendar.current.date(byAdding: .day, value: relativeDays, to: baseDate) ?? baseDate
        let resultDate = dateFormatter.string(from: sectorDate)
        
        print("DEBUG: XML Parser - Calculated sector date: \(resultDate)")
        return resultDate
    }
    
    // NEW: Function to calculate the correct date for report time calculation
    // This considers that late report times (like 23:45z) should be on the previous day
    // relative to the off block time for accurate elapsed time calculations
    private func calculateReportTimeDate(tripStartDate: String, relativeDay: String, reportTime: String, offBlockTime: String) -> String {
        print("DEBUG: XML Parser - Calculating report time date from trip start: \(tripStartDate), relative day: \(relativeDay), report time: \(reportTime), off block: \(offBlockTime)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let baseDate = dateFormatter.date(from: tripStartDate),
              let relativeDays = Int(relativeDay) else {
            print("DEBUG: XML Parser - Failed to parse date or relative day, returning trip start date")
            return tripStartDate
        }
        
        // First, calculate the base sector date
        let sectorDate = Calendar.current.date(byAdding: .day, value: relativeDays, to: baseDate) ?? baseDate
        
        // Parse the report time and off block time to determine if we need to adjust the date
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        guard let reportTimeDate = timeFormatter.date(from: reportTime),
              let offBlockTimeDate = timeFormatter.date(from: offBlockTime) else {
            print("DEBUG: XML Parser - Failed to parse times, returning base sector date")
            return dateFormatter.string(from: sectorDate)
        }
        
        // If report time is late in the day (after 18:00) and off block time is early in the day (before 06:00),
        // then the report time should be on the previous day
        let reportHour = Calendar.current.component(.hour, from: reportTimeDate)
        let offBlockHour = Calendar.current.component(.hour, from: offBlockTimeDate)
        
        let needsDateAdjustment = reportHour >= 18 && offBlockHour <= 6
        
        if needsDateAdjustment {
            // Adjust the date back by one day for the report time
            let adjustedDate = Calendar.current.date(byAdding: .day, value: -1, to: sectorDate) ?? sectorDate
            let resultDate = dateFormatter.string(from: adjustedDate)
            print("DEBUG: XML Parser - Adjusted report time date: \(resultDate) (report time \(reportTime) is late, off block \(offBlockTime) is early)")
            return resultDate
        } else {
            let resultDate = dateFormatter.string(from: sectorDate)
            print("DEBUG: XML Parser - Using base sector date for report time: \(resultDate)")
            return resultDate
        }
    }
    
    private func parseDuration(_ duration: String) -> Double {
        // Parse ISO 8601 duration format like "PT08H10M" or "PT15H20M"
        print("DEBUG: XML Parser - Parsing duration: '\(duration)'")
        
        let pattern = "PT(\\d+)H(\\d+)M?"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: duration, range: NSRange(duration.startIndex..., in: duration)) else {
            print("DEBUG: XML Parser - Failed to parse duration format: '\(duration)'")
            return 0.0
        }
        
        let hoursRange = match.range(at: 1)
        let minutesRange = match.range(at: 2)
        
        let hours = Double(duration[Range(hoursRange, in: duration)!]) ?? 0.0
        let minutes = Double(duration[Range(minutesRange, in: duration)!]) ?? 0.0
        
        let totalHours = hours + (minutes / 60.0)
        print("DEBUG: XML Parser - Parsed duration: \(hours)h \(minutes)m = \(totalHours) total hours")
        
        return totalHours
    }
    
    private func calculateReportTime(departure: String, departureTime: String) -> String {
        // NEW SCHEDULING RULES:
        // LHR and LGW (home base): Planned departure time - 90 minutes
        // All other stations (away from home base): Planned departure time - 75 minutes
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        guard let departureDate = timeFormatter.date(from: departureTime) else {
            print("DEBUG: XML Parser - Could not parse departure time: \(departureTime)")
            return departureTime
        }
        
        let isHomeBase = (departure == "LHR" || departure == "LGW")
        let reportOffsetMinutes: Int = isHomeBase ? -90 : -75
        
        let reportDate = departureDate.addingTimeInterval(TimeInterval(reportOffsetMinutes * 60))
        
        let result = timeFormatter.string(from: reportDate)
        print("DEBUG: XML Parser - Report time calculation: \(departureTime) - \(abs(reportOffsetMinutes))min = \(result) (\(departure) is \(isHomeBase ? "home base" : "away from home base"))")
        
        return result
    }
    
    private func calculateFlightTime(departure: String, arrival: String) -> Double {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        guard let departureDate = timeFormatter.date(from: departure),
              let arrivalDate = timeFormatter.date(from: arrival) else {
            return 0.0
        }
        
        var timeDifference = arrivalDate.timeIntervalSince(departureDate)
        
        // Handle overnight flights (arrival time < departure time)
        if timeDifference < 0 {
            timeDifference += 24 * 3600 // Add 24 hours
        }
        
        return timeDifference / 3600.0 // Convert to hours
    }
}

// MARK: - XML Data Models
struct XMLFlightData {
    let tripNumber: String
    let startDate: String
    let duties: [XMLDuty]
    let isHeavyCrew: Bool
    let trip: Trip // NEW: Include trip object
}

struct XMLDuty {
    let dutyNumber: String
    let actualReportTime: String
    let dutyHours: String
    let sectors: [XMLSector]
}

struct XMLSector {
    let flightNumber: String
    let departure: String
    let arrival: String
    let departureTime: String
    let arrivalTime: String
    let relativeDepartureDay: String
    let pilotCount: Int
    let flyingHours: String
    let isOutbound: Bool // NEW: Track if this is outbound or inbound
    let tripNumber: String // NEW: Link sector to trip
    // NEW: Additional fields for shuttle trips
    let dutyNumber: String // NEW: Which duty this sector belongs to
    let isShuttleTrip: Bool // NEW: Whether this sector is part of a shuttle trip
}

// NEW: Trip structure to group sectors together
struct Trip {
    let tripNumber: String
    let startDate: String
    let sectors: [XMLSector]
    let isHeavyCrew: Bool
    
    // NEW: Shuttle trip detection
    var hasShuttleDuties: Bool {
        // Check if any duty has multiple sectors
        let dutySectorCounts = Dictionary(grouping: sectors) { $0.dutyNumber }
        return dutySectorCounts.values.contains { $0.count > 1 }
    }
    
    // NEW: Trip start report time for elapsed time calculations
    var tripStartReportTime: String? {
        // Find the first sector (outbound) and calculate its report time
        guard let outbound = outboundSector else { return nil }
        // Calculate report time: LHR/LGW = -90min, others = -75min
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        guard let departureDate = timeFormatter.date(from: outbound.departureTime) else {
            return nil
        }
        
        let isHomeBase = (outbound.departure == "LHR" || outbound.departure == "LGW")
        let reportOffsetMinutes: Int = isHomeBase ? -90 : -75
        
        let reportDate = departureDate.addingTimeInterval(TimeInterval(reportOffsetMinutes * 60))
        return timeFormatter.string(from: reportDate)
    }
    
    // Helper computed properties
    var outboundSector: XMLSector? {
        return sectors.first { $0.isOutbound }
    }
    
    var inboundSector: XMLSector? {
        return sectors.first { !$0.isOutbound }
    }
    
    var hasOutboundAndInbound: Bool {
        return outboundSector != nil && inboundSector != nil
    }
}

enum XMLParsingError: LocalizedError {
    case emptyFile
    case invalidFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The XML file is empty."
        case .invalidFormat(let message):
            return message
        }
    }
}
