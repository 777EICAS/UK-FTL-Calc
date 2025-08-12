import SwiftUI

struct FTLFactorsView: View {
    @ObservedObject var viewModel: FTLViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAugmentedCrewPopup = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("FTL Factors")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Configure factors that affect your duty limits")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Start Time Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Duty Start Time")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Report Time")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(viewModel.ftlFactors.startTime)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            if viewModel.ftlFactors.isEarlyStart {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("Early start detected - reduced limits apply")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    

                    
                    // Duty Type
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Duty Type")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ToggleRow(
                                title: "Split Duty",
                                subtitle: "Duty period with rest break",
                                isOn: $viewModel.ftlFactors.hasSplitDuty
                            )
                            
                            ToggleRow(
                                title: "Standby Duty",
                                subtitle: "Standby duty considerations",
                                isOn: $viewModel.ftlFactors.hasStandbyDuty
                            )
                        }
                    }
                    
                    // Rest Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rest Configuration")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("Rest Periods")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• At Home Base: 12 hours minimum")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("• Away From Base: 10 hours minimum")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("• Or duty duration, whichever is greater")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Consecutive Duty Days
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Consecutive Duty Days")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Current Day")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(viewModel.ftlFactors.consecutiveDutyDays)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Stepper("", value: $viewModel.ftlFactors.consecutiveDutyDays, in: 1...7)
                                .labelsHidden()
                            
                            if viewModel.ftlFactors.consecutiveDutyDays >= 5 {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("5+ consecutive days - reduced limits apply")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Current Limits Preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Current Limits Preview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            LimitPreviewRow(
                                title: "Daily Duty Limit",
                                value: TimeUtilities.formatHoursAndMinutes(viewModel.dynamicDailyDutyLimit),
                                unit: "",
                                color: .blue
                            )
                        }
                        .padding()
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Limit Explanations
                    if !viewModel.limitExplanations.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Applied Factors")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.limitExplanations, id: \.self) { explanation in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        Text(explanation)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("FTL Factors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAugmentedCrewPopup) {
                AugmentedCrewRestFacilityView(
                    restFacilityType: $viewModel.ftlFactors.restFacilityType,
                    hasAugmentedCrew: $viewModel.ftlFactors.hasAugmentedCrew,
                    hasInFlightRest: $viewModel.ftlFactors.hasInFlightRest,
                    isPresented: $showingAugmentedCrewPopup,
                    numberOfAdditionalPilots: $viewModel.ftlFactors.numberOfAdditionalPilots,
                    takeoffTime: viewModel.takeoffTime,
                    landingTime: viewModel.landingTime
                )
            }
        }
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct LimitPreviewRow: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AugmentedCrewRestFacilityView: View {
    @Binding var restFacilityType: RestFacilityType
    @Binding var hasAugmentedCrew: Bool
    @Binding var hasInFlightRest: Bool
    @Binding var isPresented: Bool
    @Binding var numberOfAdditionalPilots: Int
    let takeoffTime: String
    let landingTime: String
    
    @State private var showingRestFacilitySelection = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.3")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Augmented Crew Configuration")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select the number of additional pilots for your augmented crew operation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Additional Pilots Selection
                VStack(spacing: 16) {
                    ForEach([1, 2], id: \.self) { pilotCount in
                        Button(action: {
                            numberOfAdditionalPilots = pilotCount
                            hasAugmentedCrew = true
                            showingRestFacilitySelection = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(pilotCount) Additional Pilot\(pilotCount == 1 ? "" : "s")")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if numberOfAdditionalPilots == pilotCount {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                
                                Text("Maximum duty limit: \(pilotCount == 1 ? "17" : "18") hours")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(numberOfAdditionalPilots == pilotCount ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(numberOfAdditionalPilots == pilotCount ? Color.blue : Color(.systemGray4), lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rest Facility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingRestFacilitySelection) {
                RestFacilitySelectionView(
                    restFacilityType: $restFacilityType,
                    hasInFlightRest: $hasInFlightRest,
                    isPresented: $showingRestFacilitySelection,
                    parentIsPresented: $isPresented,
                    numberOfAdditionalPilots: numberOfAdditionalPilots,
                    isLongFlight: calculateIsLongFlight()
                )
            }
        }
    }
    
    private func getDutyLimitForRestFacility(for facilityType: RestFacilityType, additionalPilots: Int, isLongFlight: Bool) -> String {
        // Augmented crew duty limits based on rest facility type and number of additional pilots
        // Based on UK CAA EASA FTL Regulations (https://www.caa.co.uk/publication/download/17414)
        
        // Determine which table to use based on flight time
        if isLongFlight {
            // Table 2: One or two sectors, one with flight time greater than 9 hours
            switch facilityType {
            case .class1:
                return additionalPilots == 1 ? "17h" : "18h"
            case .class2:
                return additionalPilots == 1 ? "16h" : "17h"
            case .class3:
                return additionalPilots == 1 ? "15h" : "16h"
            case .none:
                return "13h"
            }
        } else {
            // Table 1: Up to 3 Sectors
            switch facilityType {
            case .class1:
                return additionalPilots == 1 ? "16h" : "17h"
            case .class2:
                return additionalPilots == 1 ? "15h" : "16h"
            case .class3:
                return additionalPilots == 1 ? "14h" : "15h"
            case .none:
                return "13h"
            }
        }
    }
    
    private func calculateIsLongFlight() -> Bool {
        // Calculate flight time from takeoff to landing
        let flightTime = TimeUtilities.calculateHoursBetween(takeoffTime, landingTime)
        // Long flight = 1 or 2 sectors with one sector > 9 hours
        return flightTime > 9.0
    }
    
    private func getDutyLimit(for facilityType: RestFacilityType, additionalPilots: Int, isLongFlight: Bool = false) -> String {
        // Augmented crew duty limits based on rest facility type and number of additional pilots
        // Based on UK CAA EASA FTL Regulations (https://www.caa.co.uk/publication/download/17414)
        
        // Determine which table to use based on flight time
        if isLongFlight {
            // Table 2: One or two sectors, one with flight time greater than 9 hours
            switch facilityType {
            case .class1:
                return additionalPilots == 1 ? "17h" : "18h"
            case .class2:
                return additionalPilots == 1 ? "16h" : "17h"
            case .class3:
                return additionalPilots == 1 ? "15h" : "16h"
            case .none:
                return "13h"
            }
        } else {
            // Table 1: Up to 3 Sectors
            switch facilityType {
            case .class1:
                return additionalPilots == 1 ? "16h" : "17h"
            case .class2:
                return additionalPilots == 1 ? "15h" : "16h"
            case .class3:
                return additionalPilots == 1 ? "14h" : "15h"
            case .none:
                return "13h"
            }
        }
    }
}

struct RestFacilitySelectionView: View {
    @Binding var restFacilityType: RestFacilityType
    @Binding var hasInFlightRest: Bool
    @Binding var isPresented: Bool
    @Binding var parentIsPresented: Bool
    let numberOfAdditionalPilots: Int
    let isLongFlight: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "bed.double")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Rest Facility Type")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select the type of rest facility available for your augmented crew operation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Rest Facility Options
                VStack(spacing: 16) {
                    ForEach([RestFacilityType.class1, RestFacilityType.class2, RestFacilityType.class3, RestFacilityType.none], id: \.self) { facilityType in
                        Button(action: {
                            restFacilityType = facilityType
                            
                            // Auto-tick in-flight rest for Class 1, 2, or 3 rest facilities
                            if facilityType == .class1 || facilityType == .class2 || facilityType == .class3 {
                                hasInFlightRest = true
                            }
                            
                            // Close both popups
                            isPresented = false
                            parentIsPresented = false
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(facilityType.rawValue)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if restFacilityType == facilityType {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                
                                Text(facilityType.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                // Show augmented crew duty limit
                                HStack {
                                    Text("Augmented Crew Duty Limit:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(getDutyLimitForRestFacility(for: facilityType, additionalPilots: numberOfAdditionalPilots, isLongFlight: isLongFlight))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(restFacilityType == facilityType ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(restFacilityType == facilityType ? Color.blue : Color(.systemGray4), lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rest Facility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func getDutyLimitForRestFacility(for facilityType: RestFacilityType, additionalPilots: Int, isLongFlight: Bool) -> String {
        // Augmented crew duty limits based on rest facility type and number of additional pilots
        // Based on UK CAA EASA FTL Regulations (https://www.caa.co.uk/publication/download/17414)
        
        // Determine which table to use based on flight time
        if isLongFlight {
            // Table 2: One or two sectors, one with flight time greater than 9 hours
            switch facilityType {
            case .class1:
                return additionalPilots == 1 ? "17h" : "18h"
            case .class2:
                return additionalPilots == 1 ? "16h" : "17h"
            case .class3:
                return additionalPilots == 1 ? "15h" : "16h"
            case .none:
                return "13h"
            }
        } else {
            // Table 1: Up to 3 Sectors
            switch facilityType {
            case .class1:
                return additionalPilots == 1 ? "16h" : "17h"
            case .class2:
                return additionalPilots == 1 ? "15h" : "16h"
            case .class3:
                return additionalPilots == 1 ? "14h" : "15h"
            case .none:
                return "13h"
            }
        }
    }
}

// MARK: - In-Flight Rest Facility Selection View
struct InFlightRestFacilitySelectionView: View {
    @Binding var restFacilityType: RestFacilityType
    @Binding var hasInFlightRest: Bool
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "bed.double")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("In-Flight Rest Facility")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select the type of rest facility available during your flight.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Rest Facility Options
                VStack(spacing: 16) {
                    ForEach([RestFacilityType.class1, RestFacilityType.class2, RestFacilityType.class3, RestFacilityType.none], id: \.self) { facilityType in
                        Button(action: {
                            restFacilityType = facilityType
                            
                            // Auto-tick in-flight rest for Class 1, 2, or 3 rest facilities
                            if facilityType == .class1 || facilityType == .class2 || facilityType == .class3 {
                                hasInFlightRest = true
                            } else {
                                hasInFlightRest = false
                            }
                            
                            // Close popup
                            isPresented = false
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(facilityType.rawValue)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if restFacilityType == facilityType {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                
                                Text(facilityType.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                // Show FDP extension benefit
                                if facilityType != .none {
                                    HStack {
                                        Image(systemName: "clock.badge.plus")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        
                                        Text("Extends FDP limits")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(restFacilityType == facilityType ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(restFacilityType == facilityType ? Color.blue : Color(.systemGray4), lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Rest Facility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Reset to previous state if cancelled
                        if restFacilityType == .none {
                            hasInFlightRest = false
                        }
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    FTLFactorsView(viewModel: FTLViewModel())
}

struct StandbyTypeSelectionView: View {
    @Binding var standbyType: StandbyType
    @Binding var hasStandbyDuty: Bool
    @Binding var standbyTypeSelected: Bool
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Standby Type")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select the type of standby duty for your operation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Standby Type Options
                VStack(spacing: 16) {
                    ForEach(StandbyType.allCases, id: \.self) { type in
                        Button(action: {
                            standbyType = type
                            hasStandbyDuty = true
                            standbyTypeSelected = true
                            // Show standby start time input popup after type selection
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // This will trigger the standby start time input to appear
                            }
                            isPresented = false
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(type.rawValue)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if standbyType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                
                                Text(type.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                // Show standby duty limit
                                HStack {
                                    Text("Standby Duty Limit:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(getStandbyLimit(for: type))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(standbyType == type ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(standbyType == type ? Color.blue : Color(.systemGray4), lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Standby Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func getStandbyLimit(for standbyType: StandbyType) -> String {
        // Standby duty limits based on UK CAA EASA FTL Regulations
        switch standbyType {
        case .homeStandby:
                            return "FDP reduction based on standby duration" // Home standby - FDP reduction based on standby duration exceeding threshold
        case .airportStandby:
            return "No limit" // Airport standby - no maximum time, but all counts towards FDP
        }
    }
} 