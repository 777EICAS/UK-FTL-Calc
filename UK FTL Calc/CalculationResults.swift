//
//  CalculationResults.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

// MARK: - Duty Limit Card
struct DutyLimitCard: View {
    let currentDuty: Double
    let maxDuty: Double
    let title: String
    let subtitle: String?
    let reportTime: String
    let dutyEndTime: String
    let blockTime: Double
    
    private var percentage: Double {
        guard maxDuty > 0 else { return 0 }
        return (currentDuty / maxDuty) * 100
    }
    
    private var statusColor: Color {
        if percentage >= 100 {
            return .red
        } else if percentage >= 80 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var statusText: String {
        if percentage >= 100 {
            return "EXCEEDED"
        } else if percentage >= 80 {
            return "APPROACHING LIMIT"
        } else {
            return "WITHIN LIMITS"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(6)
            }
            
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(TimeUtilities.formatHoursAndMinutes(currentDuty))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Maximum Allowed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(TimeUtilities.formatHoursAndMinutes(maxDuty))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor)
                    }
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(statusColor)
                            .frame(width: min(CGFloat(percentage / 100) * geometry.size.width, geometry.size.width), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
                
                Text("\(String(format: "%.0f", percentage))% of limit used")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Latest Off Blocks and On Blocks Times
            if percentage < 100 {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "airplane.departure")
                            .foregroundColor(.blue)
                        Text("Latest Off Blocks Time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(calculateLatestOffBlocksTime())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Image(systemName: "airplane.arrival")
                            .foregroundColor(.blue)
                        Text("Latest On Blocks Time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(calculateLatestOnBlocksTime())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Remaining Time
            if percentage < 100 {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("\(TimeUtilities.formatHoursAndMinutes(maxDuty - currentDuty)) remaining")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Spacer()
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("\(TimeUtilities.formatHoursAndMinutes(currentDuty - maxDuty)) over limit")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Helper function to calculate latest off blocks time
    private func calculateLatestOffBlocksTime() -> String {
        // Latest off blocks time = (report time + maximum allowed duty time) - block time
        // This shows the latest time they could push back going off blocks while staying within limits
        let latestOnBlocksTime = TimeUtilities.addHours(reportTime, hours: maxDuty)
        let latestOffBlocksTime = TimeUtilities.addHours(latestOnBlocksTime, hours: -blockTime)
        return latestOffBlocksTime + "Z"
    }
    
    // Helper function to calculate latest on blocks time
    private func calculateLatestOnBlocksTime() -> String {
        // Latest on blocks time = report time + maximum allowed duty time
        // This shows the latest time they could finish duty while staying within limits
        let latestOnBlocksTime = TimeUtilities.addHours(reportTime, hours: maxDuty)
        return latestOnBlocksTime + "Z"
    }
}

// MARK: - Commander's Discretion Card
struct CommandersDiscretionCard: View {
    let currentDuty: Double
    let maxDuty: Double
    let hasStandbyDuty: Bool
    let standbyType: StandbyType?
    let isAugmentedCrew: Bool
    let hasInflightRest: Bool
    let reportTime: String
    let dutyEndTime: String
    let blockTime: Double
    
    private var maxExtension: Double {
        if isAugmentedCrew && hasInflightRest {
            return 3.0 // 3 hours for augmented crew with in-flight rest
        } else {
            return 2.0 // 2 hours for standard crew
        }
    }
    
    private var canExtend: Bool {
        return currentDuty < maxDuty + maxExtension
    }
    
    private var remainingWithExtension: Double {
        return maxDuty + maxExtension - currentDuty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.badge.shield.checkmark")
                    .foregroundColor(.blue)
                Text("Commander's Discretion")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if canExtend {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Maximum Extension")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(TimeUtilities.formatHoursAndMinutes(maxExtension))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(TimeUtilities.formatHoursAndMinutes(maxDuty + maxExtension))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Latest Off Blocks and On Blocks Times with Commander's Discretion
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "airplane.departure")
                                .foregroundColor(.blue)
                            Text("Latest Off Blocks Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(calculateLatestOffBlocksTimeWithDiscretion())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Image(systemName: "airplane.arrival")
                                .foregroundColor(.blue)
                            Text("Latest On Blocks Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(calculateLatestOnBlocksTimeWithDiscretion())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if currentDuty < maxDuty + maxExtension {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.green)
                            Text("\(TimeUtilities.formatHoursAndMinutes(remainingWithExtension)) available with discretion")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Spacer()
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("Commander's discretion not available")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Helper function to calculate latest off blocks time with commander's discretion
    private func calculateLatestOffBlocksTimeWithDiscretion() -> String {
        // Latest off blocks time = (report time + maximum duty time + extension) - block time
        // This shows the latest time they could push back going off blocks while staying within limits including discretion
        let latestOnBlocksTimeWithDiscretion = TimeUtilities.addHours(reportTime, hours: maxDuty + maxExtension)
        return TimeUtilities.addHours(latestOnBlocksTimeWithDiscretion, hours: -blockTime) + "Z"
    }
    
    // Helper function to calculate latest on blocks time with commander's discretion
    private func calculateLatestOnBlocksTimeWithDiscretion() -> String {
        // Latest on blocks time = report time + maximum duty time + extension
        // This shows the latest time they could finish duty while staying within limits including discretion
        return TimeUtilities.addHours(reportTime, hours: maxDuty + maxExtension) + "Z"
    }
}

// MARK: - Rest Requirement Card
struct RestRequirementCard: View {
    let dutyTime: Double
    let requiredRest: String
    let isOutbound: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double")
                    .foregroundColor(.purple)
                Text("Rest Requirements")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                // Sector type indicator
                HStack(spacing: 4) {
                    Image(systemName: isOutbound ? "airplane.departure" : "airplane.arrival")
                        .font(.caption)
                        .foregroundColor(isOutbound ? .orange : .green)
                    Text(isOutbound ? "Outbound" : "Inbound")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isOutbound ? .orange : .green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isOutbound ? Color.orange : Color.green).opacity(0.1))
                .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Required Rest")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        Text(requiredRest)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                    Spacer()
                }
                
                // Rest period explanation
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rest Period Rules:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    if isOutbound {
                        Text("• Outbound sector: 10h minimum rest required")
                            .font(.caption)
                        Text("• Rest must be ≥ duty time or 10h, whichever is greater")
                            .font(.caption)
                    } else {
                        Text("• Inbound sector (home base): 12h minimum rest required")
                            .font(.caption)
                        Text("• Rest must be ≥ duty time or 12h, whichever is greater")
                            .font(.caption)
                    }
                    
                    if dutyTime > 14.0 {
                        Text("• Extended duty (>14h): 16h rest required")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemPurple).opacity(0.1))
        .cornerRadius(12)
    }
}
