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
    @Published var departure: String = ""
    @Published var arrival: String = ""
    @Published var reportTime: String = "" {
        didSet {
            // Sync FTL factors when report time changes
            if !reportTime.isEmpty {
                ftlFactors.startTime = reportTime
                
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
                
            }
        }
    }
    @Published var flightTime: String = ""
    
    @Published var calculationResult: FTLCalculationResult?
    @Published var aiAnalysisResult: AIAnalysisResult?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var activeFactors: [ActiveFactor] = []
    @Published var allImportedFlights: [FlightRecord] = []
    
    // MARK: - Selected Flight Properties
    @Published var isSelectedFlightOutbound: Bool = false
    
    // MARK: - FTL Factors
    @Published var ftlFactors = FTLFactors()
    
    // MARK: - Profile Settings (sync with UserSettings)
    @AppStorage("homeBase") var homeBase: String = "LHR"
    @AppStorage("secondHomeBase") private var secondHomeBase: String = ""
    
    // MARK: - Computed Properties
    
    var canCalculate: Bool {
        return hasAllFields && validTimes && validFlightNumber && validDeparture && validArrival
    }
    
    var hasAllFields: Bool {
        return !flightNumber.isEmpty && !departure.isEmpty && !arrival.isEmpty &&
               !reportTime.isEmpty && !takeoffTime.isEmpty && !landingTime.isEmpty && !dutyEndTime.isEmpty
    }
    
    var validTimes: Bool {
        return ValidationRules.isValidTimeFormat(reportTime) && ValidationRules.isValidTimeFormat(takeoffTime) &&
               ValidationRules.isValidTimeFormat(landingTime) && ValidationRules.isValidTimeFormat(dutyEndTime)
    }
    
    var validFlightNumber: Bool {
        return ValidationRules.isValidFlightNumber(flightNumber)
    }
    
    var validDeparture: Bool {
        return departure.count == 3
    }
    
    var validArrival: Bool {
        return arrival.count == 3
    }
    
    var isCompliant: Bool {
        guard let result = calculationResult else { return false }
        return result.isCompliant
    }
    
    var warnings: [String] {
        guard let result = calculationResult else { return [] }
        return result.warnings
    }
    
    var currentActiveFactors: [ActiveFactor] {
        guard !departure.isEmpty && !arrival.isEmpty else { return [] }
        // Only calculate active factors if we have a calculation result
        guard let result = calculationResult else { return [] }
        return UKCAALimits.getActiveFactorsWithImpact(
            factors: ftlFactors,
            pilotType: .multiPilot, // This should be configurable
            departure: departure,
            arrival: arrival,
            homeBase: homeBase,
            maxFDP: result.maxFDP
        )
    }
    
    var violations: [String] {
        guard let result = calculationResult else { return [] }
        return result.violations
    }
    
    var complianceColor: Color {
        guard let result = calculationResult else { return .gray }
        if result.violations.isEmpty && result.warnings.isEmpty {
            return .green
        } else if result.violations.isEmpty {
            return .orange
        } else {
            return .red
        }
    }
    
    var hasCalculatedResults: Bool {
        calculationResult != nil
    }
    
    var hasImportedFlights: Bool {
        !allImportedFlights.isEmpty
    }
    
    var availableFlightsCount: Int {
        allImportedFlights.count
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
        // Use the new regulatory calculation result if available, otherwise fall back to old calculation
        if let result = calculationResult {
            return result.maxFDP ?? UKCAALimits.calculateDailyDutyLimit(factors: ftlFactors, pilotType: .multiPilot, departure: departure, arrival: arrival, homeBase: homeBase)
        } else {
            // If no calculation result is available, perform a quick calculation using the new system
            // This ensures we use the correct logic even before the user clicks "Calculate FTL"
            return performQuickFTLCalculation()
        }
    }
    
    // Perform a quick FTL calculation using the new regulatory system
    private func performQuickFTLCalculation() -> Double {
        guard canCalculate else {
            return UKCAALimits.calculateDailyDutyLimit(factors: ftlFactors, pilotType: .multiPilot, departure: departure, arrival: arrival, homeBase: homeBase)
        }
        
        // Calculate flight time and duty time
        let flightTimeValue = TimeUtilities.calculateHoursBetween(takeoffTime, landingTime)
        let dutyTimeValue = TimeUtilities.calculateHoursBetween(reportTime, dutyEndTime)
        
        // Perform FTL calculations using the new system
        let result = performFTLCalculations(
            dutyTime: dutyTimeValue,
            flightTime: flightTimeValue,
            pilotType: .multiPilot
        )
        
        return result.maxFDP ?? UKCAALimits.calculateDailyDutyLimit(factors: ftlFactors, pilotType: .multiPilot, departure: departure, arrival: arrival, homeBase: homeBase)
    }
    

    
    var limitExplanations: [String] {
        // Use the new regulatory calculation explanations if available, otherwise fall back to old calculation
        if let result = calculationResult {
            return result.regulatoryExplanations ?? UKCAALimits.getLimitExplanations(factors: ftlFactors, pilotType: .multiPilot, departure: departure, arrival: arrival, homeBase: homeBase)
        } else {
            return UKCAALimits.getLimitExplanations(factors: ftlFactors, pilotType: .multiPilot, departure: departure, arrival: arrival, homeBase: homeBase)
        }
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
        
        // Elapsed time has already been calculated correctly in ContentView.swift
        // No need to recalculate here as it would override the correct date-aware calculation
        
        // Determine if this is first sector (departure from home base)
        ftlFactors.isFirstSector = departure.uppercased() == homeBase.uppercased()
        
        // Automatically determine acclimatisation status based on UK CAA Table 1 regulations
        let acclimatisationStatus = UKCAALimits.determineAcclimatisationStatus(
            timeZoneDifference: ftlFactors.timeZoneDifference,
            elapsedTimeHours: ftlFactors.elapsedTimeHours,
            isFirstSector: ftlFactors.isFirstSector,
            homeBase: homeBase,
            departure: departure
        )
        ftlFactors.isAcclimatised = acclimatisationStatus.isAcclimatised
        ftlFactors.shouldBeAcclimatised = acclimatisationStatus.shouldBeAcclimatised
        ftlFactors.acclimatisationReason = acclimatisationStatus.reason
        
        print("DEBUG: Acclimatisation - Time zone diff: \(ftlFactors.timeZoneDifference)h, Elapsed: \(ftlFactors.elapsedTimeHours)h, First sector: \(ftlFactors.isFirstSector), Reason: \(acclimatisationStatus.reason)")
        
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
        
        // Update active factors after calculation result is available
        activeFactors = UKCAALimits.getActiveFactorsWithImpact(
            factors: ftlFactors,
            pilotType: .multiPilot,
            departure: departure,
            arrival: arrival,
            homeBase: homeBase,
            maxFDP: result.maxFDP
        )
        
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
            pilotType: .multiPilot,
            isAugmentedCrew: ftlFactors.hasAugmentedCrew,
            hasInflightRest: ftlFactors.hasInFlightRest
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
        activeFactors = []
        
        // Reset all FTL factors (quick settings) to default off positions
        ftlFactors = FTLFactors()
        
        // Clear time zone difference since there's no departure/arrival data
        ftlFactors.timeZoneDifference = 0
        ftlFactors.acclimatisationReason = ""
    }
    
    func resetCalculationState() {
        calculationResult = nil
        aiAnalysisResult = nil
        errorMessage = nil
        activeFactors = []
    }
    
    // Set original home base report time for multi-sector duties
    func setOriginalHomeBaseReportTime(_ reportTime: String) {
        ftlFactors.originalHomeBaseReportTime = reportTime
        ftlFactors.isFirstSector = false // Mark as subsequent sector
        print("DEBUG: Set original home base report time to: \(reportTime)")
    }
    
    func importFromCalendar() {
        // This will be implemented in CalendarImportView
    }
    
    func selectFlight(_ flight: FlightRecord) {
        // Update all flight data fields with the selected flight
        flightNumber = flight.flightNumber
        departure = flight.departure
        arrival = flight.arrival
        reportTime = flight.reportTime
        takeoffTime = flight.takeoffTime
        landingTime = flight.landingTime
        dutyEndTime = flight.dutyEndTime
        flightTime = TimeUtilities.formatHoursAndMinutes(flight.flightTime)
        isSelectedFlightOutbound = flight.isOutbound // Preserve the outbound status
        
        // Reset calculation state since we're switching flights
        resetCalculationState()
        
        // Clear any error messages
        errorMessage = nil
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
        print("DEBUG: ViewModel performFTLCalculations - isSelectedFlightOutbound: \(isSelectedFlightOutbound)")
        
        // Use the comprehensive FTL calculation service with regulatory tables
        return FTLCalculationService.calculateFTLCompliance(
            dutyTime: dutyTime,
            flightTime: flightTime,
            pilotType: pilotType,
            previousFlights: [],
            hasStandbyDuty: ftlFactors.hasStandbyDuty,
            standbyType: ftlFactors.hasStandbyDuty ? ftlFactors.standbyType : nil,
            standbyStartTime: ftlFactors.standbyStartTime,
            dutyEndTime: dutyEndTime,
            reportTime: reportTime,
            departure: departure,
            arrival: arrival,
            takeoffTime: takeoffTime,
            landingTime: landingTime,
            ftlFactors: ftlFactors,
            isOutbound: isSelectedFlightOutbound
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
        

    }
    

    

    

}

// MARK: - Extensions for PilotType
extension PilotType: Codable {} 