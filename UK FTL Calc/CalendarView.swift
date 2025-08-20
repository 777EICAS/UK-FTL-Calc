import SwiftUI

enum DeleteAction {
    case removeDuplicates
    case removeIndividual
    case deleteAll
}

struct CalendarView: View {
    @StateObject private var viewModel = FTLViewModel()
    @State private var selectedDate = Date()
    
    // Initialize with April 2025 since that's when the XML flights are
    init() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 4
        components.day = 1
        if let april2025 = calendar.date(from: components) {
            _selectedDate = State(initialValue: april2025)
        }
    }

    @State private var showingFileUpload = false
    @State private var flights: [FlightRecord] = []
    @State private var isLoading = false
    @State private var showingDeleteMenu = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteAction: DeleteAction = .removeDuplicates
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    // Additional formatter for ISO dates (yyyy-MM-dd) from XML files
    private let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Flight Calendar")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("View your upcoming and past trips")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        // File Upload Button
                        Button(action: {
                            showingFileUpload = true
                        }) {
                            Image(systemName: "doc.badge.plus")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        

                        
                        // Delete Menu Button (only show if there are flights)
                        if !flights.isEmpty {
                            Menu {
                                Button(action: {
                                    deleteAction = .removeDuplicates
                                    showingDeleteConfirmation = true
                                }) {
                                    Label("Remove Duplicates", systemImage: "doc.on.doc")
                                }
                                
                                Button(action: {
                                    deleteAction = .removeIndividual
                                    showingDeleteMenu = true
                                }) {
                                    Label("Remove Individual Flight", systemImage: "minus.circle")
                                }
                                
                                Button(action: {
                                    deleteAction = .deleteAll
                                    showingDeleteConfirmation = true
                                }) {
                                    Label("Delete All Flights", systemImage: "trash")
                                }
                                .foregroundColor(.red)
                            } label: {
                                Image(systemName: "trash.circle")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Month Navigation
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text(monthYearString)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Regulatory Disclaimer Banner
                GuidanceDisclaimerBanner()
                    .padding(.horizontal)
                
                // Calendar Grid
                VStack(spacing: 0) {
                    // Day headers
                    HStack(spacing: 0) {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .background(Color(.systemGray6))
                    
                    // Calendar days
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                        ForEach(daysInMonth, id: \.self) { date in
                            CalendarDayView(
                                date: date,
                                flights: flightsForDate(date),
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isCurrentMonth: calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
                            ) {
                                selectedDate = date
                            }
                            .onAppear {
                                let flightsForThisDate = flightsForDate(date)
                                if let flights = flightsForThisDate, !flights.isEmpty {
                                    print("CalendarView: Day \(date) has \(flights.count) flights: \(flights.map { $0.flightNumber })")
                                }
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
                
                // Selected Date Details
                if let selectedFlights = flightsForDate(selectedDate), !selectedFlights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Flights on \(dateString(selectedDate))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(selectedFlights, id: \.id) { flight in
                                    FlightCardView(flight: flight)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.systemGroupedBackground))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No flights scheduled")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Import PDF roster to see your flights")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)

            .sheet(isPresented: $showingFileUpload) {
                FileUploadView { selectedFlights, allFlights in
                    // Add the parsed flights to the calendar, preventing duplicates
                    print("CalendarView: Importing \(selectedFlights.count) selected flights from \(allFlights.count) total flights")
                    print("CalendarView: Sample flight dates: \(selectedFlights.prefix(3).map { $0.date })")
                    self.addFlightsWithoutDuplicates(selectedFlights)
                    print("CalendarView: Total flights after PDF import: \(self.flights.count)")
                    print("CalendarView: All flight dates: \(self.flights.map { $0.date })")
                    
                    // Debug: Check if flights are being found for specific dates
                    if let sampleFlight = selectedFlights.first {
                        print("CalendarView: Checking if sample flight \(sampleFlight.flightNumber) on \(sampleFlight.date) can be found")
                        if let flightDate = self.isoDateFormatter.date(from: sampleFlight.date) {
                            print("CalendarView: Sample flight date parsed as: \(flightDate)")
                            let sampleDate = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: flightDate)) ?? flightDate
                            if let foundFlights = self.flightsForDate(sampleDate) {
                                print("CalendarView: Found \(foundFlights.count) flights for sample date \(sampleDate)")
                            } else {
                                print("CalendarView: No flights found for sample date \(sampleDate)")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingDeleteMenu) {
                IndividualFlightDeleteView(flights: flights) { flightToDelete in
                    if let index = flights.firstIndex(where: { $0.id == flightToDelete.id }) {
                        flights.remove(at: index)
                        print("CalendarView: Removed individual flight: \(flightToDelete.flightNumber)")
                    }
                }
            }
            .alert("Confirm Delete", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button(deleteAction == .deleteAll ? "Delete All" : "Remove Duplicates", role: .destructive) {
                    performDeleteAction()
                }
            } message: {
                Text(deleteAction == .deleteAll ? 
                     "Are you sure you want to delete all flights for this month? This action cannot be undone." :
                     "Are you sure you want to remove duplicate flights? This action cannot be undone.")
            }
            .onAppear {
                print("CalendarView: Appeared with \(flights.count) flights")
                print("CalendarView: Current selected date: \(selectedDate)")
                print("CalendarView: Flight dates: \(flights.map { $0.date })")
                
                // Debug: Check if any flights can be found for the current month
                let currentMonth = calendar.component(.month, from: selectedDate)
                let currentYear = calendar.component(.year, from: selectedDate)
                print("CalendarView: Looking for flights in month \(currentMonth)/\(currentYear)")
                
                for flight in flights {
                    if let flightDate = isoDateFormatter.date(from: flight.date) {
                        let flightMonth = calendar.component(.month, from: flightDate)
                        let flightYear = calendar.component(.year, from: flightDate)
                        if flightMonth == currentMonth && flightYear == currentYear {
                            print("CalendarView: Flight \(flight.flightNumber) is in current month: \(flight.date)")
                        }
                    }
                }
            }

        }
    }
    
    // MARK: - Computed Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let result = formatter.string(from: selectedDate)
        print("CalendarView: Displaying month: \(result)")
        return result
    }
    
    private var daysInMonth: [Date] {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offsetDays = firstWeekday - 1
        
        let startDate = calendar.date(byAdding: .day, value: -offsetDays, to: startOfMonth) ?? startOfMonth
        
        var days: [Date] = []
        for i in 0..<42 { // 6 weeks
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                days.append(date)
            }
        }
        
        print("CalendarView: Generated \(days.count) days for month starting \(startOfMonth)")
        print("CalendarView: First few days: \(days.prefix(5).map { Calendar.current.component(.day, from: $0) })")
        
        return days
    }
    
    // MARK: - Helper Methods
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
            print("CalendarView: Navigated to previous month: \(newDate)")
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
            print("CalendarView: Navigated to next month: \(newDate)")
        }
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func flightsForDate(_ date: Date) -> [FlightRecord]? {
        let filteredFlights = flights.filter { flight in
            // Try parsing with ISO date format first (for XML files)
            if let flightDate = isoDateFormatter.date(from: flight.date) {
                let isMatch = calendar.isDate(flightDate, inSameDayAs: date)
                if isMatch {
                    print("CalendarView: Found flight \(flight.flightNumber) on \(flight.date) (ISO parsed: \(flightDate)) for calendar date \(date)")
                }
                return isMatch
            }
            // Fallback to short date format (for PDF files)
            if let flightDate = dateFormatter.date(from: flight.date) {
                let isMatch = calendar.isDate(flightDate, inSameDayAs: date)
                if isMatch {
                    print("CalendarView: Found flight \(flight.flightNumber) on \(flight.date) (short parsed: \(flightDate)) for calendar date \(date)")
                }
                return isMatch
            }
            print("CalendarView: Could not parse flight date: \(flight.date) for flight \(flight.flightNumber)")
            return false
        }
        if !filteredFlights.isEmpty {
            print("CalendarView: Found \(filteredFlights.count) flights for date \(date)")
        }
        return filteredFlights.isEmpty ? nil : filteredFlights
    }
    

    
    private func addFlightsWithoutDuplicates(_ newFlights: [FlightRecord]) {
        print("CalendarView: Adding \(newFlights.count) new flights to existing \(flights.count) flights")
        
        var existingFlightKeys = Set<String>()
        
        // Create keys for existing flights
        for flight in flights {
            let key = "\(flight.flightNumber)-\(flight.departure)-\(flight.arrival)-\(flight.date)"
            existingFlightKeys.insert(key)
        }
        
        // Only add flights that don't already exist
        for flight in newFlights {
            let key = "\(flight.flightNumber)-\(flight.departure)-\(flight.arrival)-\(flight.date)"
            if !existingFlightKeys.contains(key) {
                flights.append(flight)
                existingFlightKeys.insert(key)
                print("CalendarView: Added flight: \(flight.flightNumber) (\(flight.departure) → \(flight.arrival)) on \(flight.date)")
            } else {
                print("CalendarView: Skipping duplicate flight: \(flight.flightNumber) (\(flight.departure) → \(flight.arrival)) on \(flight.date)")
            }
        }
        
        print("CalendarView: Total flights after adding: \(flights.count)")
    }
    
    private func performDeleteAction() {
        switch deleteAction {
        case .removeDuplicates:
            removeDuplicates()
        case .deleteAll:
            deleteAllFlightsForCurrentMonth()
        case .removeIndividual:
            // This is handled by the sheet
            break
        }
    }
    
    private func removeDuplicates() {
        var uniqueFlights: [FlightRecord] = []
        var seenKeys = Set<String>()
        
        for flight in flights {
            let key = "\(flight.flightNumber)-\(flight.departure)-\(flight.arrival)-\(flight.date)"
            if !seenKeys.contains(key) {
                uniqueFlights.append(flight)
                seenKeys.insert(key)
            } else {
                print("CalendarView: Removing duplicate flight: \(flight.flightNumber) (\(flight.departure) → \(flight.arrival)) on \(flight.date)")
            }
        }
        
        let removedCount = flights.count - uniqueFlights.count
        flights = uniqueFlights
        
        if removedCount > 0 {
            print("CalendarView: Removed \(removedCount) duplicate flights")
        }
    }
    
    private func deleteAllFlightsForCurrentMonth() {
        let currentMonth = calendar.component(.month, from: selectedDate)
        let currentYear = calendar.component(.year, from: selectedDate)
        
        let flightsToRemove = flights.filter { flight in
            // Try parsing with ISO date format first (for XML files)
            if let flightDate = isoDateFormatter.date(from: flight.date) {
                let flightMonth = calendar.component(.month, from: flightDate)
                let flightYear = calendar.component(.year, from: flightDate)
                return flightMonth == currentMonth && flightYear == currentYear
            }
            // Fallback to short date format (for PDF files)
            if let flightDate = dateFormatter.date(from: flight.date) {
                let flightMonth = calendar.component(.month, from: flightDate)
                let flightYear = calendar.component(.year, from: flightDate)
                return flightMonth == currentMonth && flightYear == currentYear
            }
            return false
        }
        
        for flight in flightsToRemove {
            if let index = flights.firstIndex(where: { $0.id == flight.id }) {
                flights.remove(at: index)
            }
        }
        
        print("CalendarView: Deleted \(flightsToRemove.count) flights for current month")
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let date: Date
    let flights: [FlightRecord]?
    let isSelected: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(textColor)
                
                if let flights = flights, !flights.isEmpty {
                    HStack(spacing: 1) {
                        ForEach(flights.prefix(3), id: \.id) { _ in
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if flights != nil && !flights!.isEmpty {
            return Color.blue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Flight Card View

struct FlightCardView: View {
    let flight: FlightRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(flight.departure) → \(flight.arrival)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Flight \(flight.flightNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(flight.takeoffTime)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Takeoff")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Duty Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(TimeUtilities.formatHoursAndMinutes(flight.dutyTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Flight Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(TimeUtilities.formatHoursAndMinutes(flight.flightTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    CalendarView()
}

// MARK: - Individual Flight Delete View

struct IndividualFlightDeleteView: View {
    let flights: [FlightRecord]
    let onDelete: (FlightRecord) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    // Additional formatter for ISO dates (yyyy-MM-dd) from XML files
    private let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("Remove Individual Flight")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select a flight to remove from your calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Flight List
                if flights.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "airplane")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No flights to remove")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(flights.sorted(by: { $0.date < $1.date }), id: \.id) { flight in
                                Button(action: {
                                    onDelete(flight)
                                    dismiss()
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(flight.departure) → \(flight.arrival)")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                
                                                Text("Flight \(flight.flightNumber)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "minus.circle")
                                                .foregroundColor(.red)
                                                .font(.title2)
                                        }
                                        
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Date")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text(formatFlightDate(flight.date))
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("Takeoff")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text(flight.takeoffTime)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Remove Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Helper function to format flight dates
    private func formatFlightDate(_ dateString: String) -> String {
        // Try parsing with ISO date format first (for XML files)
        if let flightDate = isoDateFormatter.date(from: dateString) {
            return dateFormatter.string(from: flightDate)
        }
        // Fallback to short date format (for PDF files)
        if let flightDate = dateFormatter.date(from: dateString) {
            return dateFormatter.string(from: flightDate)
        }
        return dateString // Fallback to raw date string
    }
} 