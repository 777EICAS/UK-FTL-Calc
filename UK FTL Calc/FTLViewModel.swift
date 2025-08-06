//
//  FTLViewModel.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class FTLViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var flightNumber: String = ""
    @Published var departure: String = "" {
        didSet {
            // Calculate time zone difference when departure changes
            if !departure.isEmpty && !arrival.isEmpty {
                calculateTimeZoneDifference()
            }
        }
    }
    @Published var arrival: String = "" {
        didSet {
            // Calculate time zone difference when arrival changes
            if !departure.isEmpty && !arrival.isEmpty {
                calculateTimeZoneDifference()
            }
        }
    }
    @Published var reportTime: String = "" {
        didSet {
            // Sync FTL factors when report time changes
            if !reportTime.isEmpty {
                ftlFactors.startTime = reportTime
                // Auto-detect night duty when report time changes
                autoDetectNightDuty()
            }
        }
    }
    @Published var takeoffTime: String = ""
    @Published var landingTime: String = ""
    @Published var dutyEndTime: String = "" {
        didSet {
            // Automatically set landing time to 30 minutes before duty end time
            if !dutyEndTime.isEmpty {
                updateLandingTimeFromDutyEnd()
                // Auto-detect night duty when duty end time changes
                autoDetectNightDuty()
            }
        }
    }
    @Published var flightTime: String = ""
    
    @Published var calculationResult: FTLCalculationResult?
    @Published var aiAnalysisResult: AIAnalysisResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - FTL Factors
    @Published var ftlFactors = FTLFactors()
    
    // MARK: - Profile Settings (sync with ProfileView)
    @AppStorage("homeBase") private var homeBase: String = "LHR"
    @AppStorage("secondHomeBase") private var secondHomeBase: String = ""
    
    // MARK: - Computed Properties
    var canCalculate: Bool {
        let hasAllFields = !flightNumber.isEmpty &&
        !departure.isEmpty &&
        !arrival.isEmpty &&
        !reportTime.isEmpty &&
        !takeoffTime.isEmpty &&
        !landingTime.isEmpty &&
        !dutyEndTime.isEmpty
        
        let validTimes = ValidationRules.isValidTimeFormat(reportTime) &&
        ValidationRules.isValidTimeFormat(takeoffTime) &&
        ValidationRules.isValidTimeFormat(landingTime) &&
        ValidationRules.isValidTimeFormat(dutyEndTime)
        
        let validFlightNumber = ValidationRules.isValidFlightNumber(flightNumber)
        let validDeparture = ValidationRules.isValidAirportCode(departure)
        let validArrival = ValidationRules.isValidAirportCode(arrival)
        
        let result = hasAllFields && validTimes && validFlightNumber && validDeparture && validArrival
        
        if !result {
            print("DEBUG: canCalculate validation failed:")
            print("  hasAllFields: \(hasAllFields)")
            print("  validTimes: \(validTimes)")
            print("  validFlightNumber: \(validFlightNumber)")
            print("  validDeparture: \(validDeparture)")
            print("  validArrival: \(validArrival)")
            print("  flightNumber: '\(flightNumber)'")
            print("  departure: '\(departure)'")
            print("  arrival: '\(arrival)'")
            print("  reportTime: '\(reportTime)'")
            print("  takeoffTime: '\(takeoffTime)'")
            print("  landingTime: '\(landingTime)'")
            print("  dutyEndTime: '\(dutyEndTime)'")
        }
        
        return result
    }
    
    var hasCalculatedResults: Bool {
        calculationResult != nil
    }
    
    var currentStatus: String {
        guard let result = calculationResult else {
            return "No calculation performed"
        }
        
        if result.isCompliant {
            return "Compliant"
        } else if !result.violations.isEmpty {
            return "Non-Compliant"
        } else {
            return "Warning"
        }
    }
    
    var statusColor: Color {
        guard let result = calculationResult else {
            return .gray
        }
        
        if result.isCompliant {
            return .green
        } else if !result.violations.isEmpty {
            return .red
        } else {
            return .orange
        }
    }
    
    var isNightDutyAutoDetected: Bool {
        // Check if night duty was auto-detected based on current times
        guard !reportTime.isEmpty && !dutyEndTime.isEmpty else { return false }
        
        let departureUpper = departure.uppercased()
        let localTimeZoneOffset = TimeUtilities.getTimeZoneOffsetFromUTC(for: departureUpper)
        
        guard let reportDate = TimeUtilities.parseTime(reportTime),
              let dutyEndDate = TimeUtilities.parseTime(dutyEndTime) else { return false }
        
        let calendar = Calendar.current
        let reportHour = calendar.component(.hour, from: reportDate)
        let dutyEndHour = calendar.component(.hour, from: dutyEndDate)
        
        let localReportHour = (reportHour + localTimeZoneOffset + 24) % 24
        let localDutyEndHour = (dutyEndHour + localTimeZoneOffset + 24) % 24
        
        return isTimeInNightWindow(localReportHour) || 
               isTimeInNightWindow(localDutyEndHour) ||
               crossesNightWindow(localReportHour, localDutyEndHour)
    }
    
    var dutyTime: String {
        guard let result = calculationResult else { return "0h" }
        return TimeUtilities.formatHoursAndMinutes(result.dutyTime)
    }
    
    var totalFlightTime: String {
        guard let result = calculationResult else { return "0h" }
        return TimeUtilities.formatHoursAndMinutes(result.flightTime)
    }
    
    var requiredRest: String {
        guard let result = calculationResult else { return "0h" }
        return TimeUtilities.formatHoursAndMinutes(result.requiredRest)
    }
    
    var nextDutyAvailable: String {
        guard let result = calculationResult else { return "N/A" }
        return result.nextDutyAvailable
    }
    
    // MARK: - Numeric Values for Analysis
    var dutyTimeValue: Double {
        guard let result = calculationResult else { return 0.0 }
        return result.dutyTime
    }
    
    var flightTimeValue: Double {
        guard let result = calculationResult else { return 0.0 }
        return result.flightTime
    }
    
    var calculatedFlightTimeDisplay: String {
        // Calculate flight time from takeoff to landing
        let flightTimeHours = TimeUtilities.calculateHoursBetween(takeoffTime, landingTime)
        return TimeUtilities.formatHoursAndMinutes(flightTimeHours)
    }
    
    // MARK: - Dynamic FTL Limits
    var dynamicDailyDutyLimit: Double {
        return UKCAALimits.calculateDailyDutyLimit(factors: ftlFactors, pilotType: .multiPilot, departure: departure, arrival: arrival, homeBase: homeBase)
    }
    

    
    var limitExplanations: [String] {
        return UKCAALimits.getLimitExplanations(factors: ftlFactors, pilotType: .multiPilot, departure: departure, arrival: arrival, homeBase: homeBase)
    }
    
    // MARK: - Initialization
    init() {
        // Initialize FTL factors
    }
    
    // MARK: - Public Methods
    func calculateFTL() {
        print("DEBUG: calculateFTL() called")
        print("DEBUG: canCalculate = \(canCalculate)")
        
        guard canCalculate else {
            errorMessage = "Please fill in all required fields with valid data"
            print("DEBUG: Calculation blocked - canCalculate is false")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Sync FTL factors with current data
        syncFTLFactors()
        
        // Calculate flight time from takeoff to landing time
        let flightTimeValue = TimeUtilities.calculateHoursBetween(takeoffTime, landingTime)
        
        // Calculate duty time
        let dutyTimeValue = TimeUtilities.calculateHoursBetween(reportTime, dutyEndTime)
        
        // Perform FTL calculations
        let result = performFTLCalculations(
            dutyTime: dutyTimeValue,
            flightTime: flightTimeValue,
            pilotType: .multiPilot
        )
        
        calculationResult = result
        
        // Save flight record
        let flightRecord = FlightRecord(
            flightNumber: flightNumber,
            departure: departure.uppercased(),
            arrival: arrival.uppercased(),
            reportTime: reportTime,
            takeoffTime: takeoffTime,
            landingTime: landingTime,
            dutyEndTime: dutyEndTime,
            flightTime: flightTimeValue,
            dutyTime: dutyTimeValue,
            pilotType: .multiPilot
        )
        
        // Perform AI analysis
        aiAnalysisResult = AIAnalysisService.analyzeFTLCompliance(
            currentFlight: flightRecord,
            previousFlights: [],
            pilotType: .multiPilot
        )
        isLoading = false
    }
    
    func resetData() {
        // Reset all flight data fields
        flightNumber = ""
        departure = ""
        arrival = ""
        reportTime = ""
        takeoffTime = ""
        landingTime = ""
        dutyEndTime = ""
        flightTime = ""
        
        // Reset calculation results
        calculationResult = nil
        aiAnalysisResult = nil
        errorMessage = nil
        
        // Reset all FTL factors (quick settings) to default off positions
        ftlFactors = FTLFactors()
        
        // Clear time zone difference since there's no departure/arrival data
        ftlFactors.timeZoneDifference = 0
    }
    
    func resetCalculationState() {
        calculationResult = nil
        aiAnalysisResult = nil
        errorMessage = nil
    }
    
    func importFromCalendar() {
        // This will be implemented in CalendarImportView
    }
    
    // MARK: - Private Methods
    private func syncFTLFactors() {
        // Safely sync FTL factors with current data
        ftlFactors.startTime = reportTime
        
        // Set number of sectors (currently 1 for single flights)
        // This could be enhanced to detect multiple sectors from flight data
        ftlFactors.numberOfSectors = 1
    }
    
    private func updateLandingTimeFromDutyEnd() {
        guard let dutyEndDate = TimeUtilities.parseTime(dutyEndTime) else { return }
        
        // Set landing time (ON Block time) to be the same as duty end time
        // Preserve the 'z' suffix if the duty end time has it
        let formattedTime = TimeUtilities.formatTime(dutyEndDate)
        landingTime = dutyEndTime.hasSuffix("z") ? "\(formattedTime)z" : formattedTime
    }
    private func performFTLCalculations(dutyTime: Double, flightTime: Double, pilotType: PilotType) -> FTLCalculationResult {
        print("DEBUG: ViewModel performFTLCalculations - hasStandbyDuty: \(ftlFactors.hasStandbyDuty)")
        print("DEBUG: ViewModel performFTLCalculations - standbyType: \(String(describing: ftlFactors.standbyType))")
        print("DEBUG: ViewModel performFTLCalculations - standbyStartTime: '\(ftlFactors.standbyStartTime)'")
        print("DEBUG: ViewModel performFTLCalculations - dutyEndTime: '\(dutyEndTime)'")
        
        // Use the comprehensive FTL calculation service
        return FTLCalculationService.calculateFTLCompliance(
            dutyTime: dutyTime,
            flightTime: flightTime,
            pilotType: pilotType,
            previousFlights: [],
            hasStandbyDuty: ftlFactors.hasStandbyDuty,
            standbyType: ftlFactors.hasStandbyDuty ? ftlFactors.standbyType : nil,
            standbyStartTime: ftlFactors.standbyStartTime,
            dutyEndTime: dutyEndTime
        )
    }
    
    private func calculateTimeZoneDifference() {
        guard !departure.isEmpty && !arrival.isEmpty else {
            print("DEBUG: Empty departure or arrival in ViewModel")
            return
        }
        
        // Calculate time zone difference from departure airport to arrival airport
        let departureUpper = departure.uppercased()
        let arrivalUpper = arrival.uppercased()
        
        print("DEBUG: ViewModel calculating TZ diff from '\(departureUpper)' to '\(arrivalUpper)'")
        
        let timeZoneDiff = TimeUtilities.getTimeZoneDifference(from: departureUpper, to: arrivalUpper)
        print("DEBUG: ViewModel time zone difference result: \(timeZoneDiff)")
        
        ftlFactors.timeZoneDifference = timeZoneDiff
        
        // Auto-set acclimatised status for LHR departures
        autoSetAcclimatisedStatus()
        
        // Auto-detect night duty
        autoDetectNightDuty()
    }
    
    private func autoSetAcclimatisedStatus() {
        let departureUpper = departure.uppercased()
        let homeBaseUpper = homeBase.uppercased()
        let secondHomeBaseUpper = secondHomeBase.uppercased()
        
        // Auto-set acclimatised for departures from home base or second home base
        if departureUpper == homeBaseUpper || departureUpper == secondHomeBaseUpper {
            ftlFactors.isAcclimatised = true
            print("DEBUG: Auto-set acclimatised for departure from \(departureUpper) (home base: \(homeBaseUpper), second home base: \(secondHomeBaseUpper))")
        }
    }
    
    private func autoDetectNightDuty() {
        guard !reportTime.isEmpty && !dutyEndTime.isEmpty else { return }
        
        // Get the local time zone offset for the departure location (where crew is acclimatised)
        let departureUpper = departure.uppercased()
        let localTimeZoneOffset = TimeUtilities.getTimeZoneOffsetFromUTC(for: departureUpper)
        
        // Parse report and duty end times
        guard let reportDate = TimeUtilities.parseTime(reportTime),
              let dutyEndDate = TimeUtilities.parseTime(dutyEndTime) else { return }
        
        let calendar = Calendar.current
        
        // Convert UTC times to local acclimatised times
        let reportHour = calendar.component(.hour, from: reportDate)
        let dutyEndHour = calendar.component(.hour, from: dutyEndDate)
        
        let localReportHour = (reportHour + localTimeZoneOffset + 24) % 24
        let localDutyEndHour = (dutyEndHour + localTimeZoneOffset + 24) % 24
        
        // Check if any portion of the FDP falls within 23:00-06:00 local time
        let isNightDuty = isTimeInNightWindow(localReportHour) || 
                         isTimeInNightWindow(localDutyEndHour) ||
                         crossesNightWindow(localReportHour, localDutyEndHour)
        
        ftlFactors.isNightDuty = isNightDuty
        
        if isNightDuty {
            print("DEBUG: Auto-detected night duty - Report: \(localReportHour):00, Duty End: \(localDutyEndHour):00")
        }
    }
    
    private func isTimeInNightWindow(_ hour: Int) -> Bool {
        return hour >= 23 || hour < 6
    }
    
    private func crossesNightWindow(_ startHour: Int, _ endHour: Int) -> Bool {
        // Check if the duty period crosses the 23:00-06:00 night window
        if startHour <= endHour {
            // Same day duty
            return startHour < 6 && endHour >= 23
        } else {
            // Overnight duty
            return startHour < 6 || endHour >= 23
        }
    }
    

}

// MARK: - Extensions for PilotType
extension PilotType: Codable {} 