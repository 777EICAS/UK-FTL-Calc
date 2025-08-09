//
//  SettingsView.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultPilotType") private var defaultPilotType: String = PilotType.singlePilot.rawValue
    @AppStorage("showWarnings") private var showWarnings = true
    @AppStorage("autoSaveFlights") private var autoSaveFlights = true
    @AppStorage("use24HourFormat") private var use24HourFormat = true
    
    var body: some View {
        NavigationView {
            List {
                // General Settings
                Section("General") {
                    Picker("Default Pilot Type", selection: $defaultPilotType) {
                        ForEach(PilotType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type.rawValue)
                        }
                    }
                    
                    Toggle("Show Warnings", isOn: $showWarnings)
                    Toggle("Auto-save Flights", isOn: $autoSaveFlights)
                    Toggle("24-Hour Time Format", isOn: $use24HourFormat)
                }
                
                // UK CAA Regulations
                Section("UK CAA Regulations") {
                    NavigationLink("Daily Limits") {
                        DailyLimitsView()
                    }
                    
                    NavigationLink("Weekly Limits") {
                        WeeklyLimitsView()
                    }
                    
                    NavigationLink("Monthly Limits") {
                        MonthlyLimitsView()
                    }
                    
                    NavigationLink("Rest Periods") {
                        RestPeriodsView()
                    }
                }
                
                // Data Management
                Section("Data Management") {
                    Button("Export Flight Data") {
                        exportFlightData()
                    }
                    
                    Button("Clear All Data") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("UK CAA Website", destination: URL(string: "https://www.caa.co.uk")!)
                    
                    Link("Flight Time Limitations Guide", destination: URL(string: "https://www.caa.co.uk/commercial-industry/airspace/air-traffic-control/air-traffic-services/")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportFlightData() {
        // Implementation for exporting flight data
        // This would typically save to Files app or share via email
    }
    
    private func clearAllData() {
        // Implementation for clearing all data
        // This would show a confirmation alert first
    }
}

struct DailyLimitsView: View {
    var body: some View {
        List {
            Section("Duty Time Limits") {
                LimitRow(
                    title: "Maximum Daily Duty Time",
                    value: "13 hours",
                    description: "Maximum duty time in any 24-hour period"
                )
                
                LimitRow(
                    title: "Single Pilot Operations",
                    value: "8 hours",
                    description: "Maximum flight time for single pilot operations"
                )
                
                LimitRow(
                    title: "Multi-Pilot Operations",
                    value: "10 hours",
                    description: "Maximum flight time for multi-pilot operations"
                )
            }
            
            Section("Rest Requirements") {
                LimitRow(
                    title: "At Home Base",
                    value: "12 hours",
                    description: "Minimum rest period when returning to home base"
                )
                
                LimitRow(
                    title: "Away From Base",
                    value: "10 hours",
                    description: "Minimum rest period when away from base"
                )
            }
        }
        .navigationTitle("Daily Limits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WeeklyLimitsView: View {
    var body: some View {
        List {
            Section("Weekly Limits") {
                LimitRow(
                    title: "Maximum Weekly Duty Time",
                    value: "60 hours",
                    description: "Maximum duty time in any 7 consecutive days"
                )
                
                LimitRow(
                    title: "Maximum Weekly Flight Time",
                    value: "56 hours",
                    description: "Maximum flight time in any 7 consecutive days"
                )
            }
            
            Section("Consecutive Duty Days") {
                LimitRow(
                    title: "Maximum Consecutive Days",
                    value: "6 days",
                    description: "Maximum number of consecutive duty days"
                )
            }
        }
        .navigationTitle("Weekly Limits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MonthlyLimitsView: View {
    var body: some View {
        List {
            Section("Monthly Limits") {
                LimitRow(
                    title: "Maximum Monthly Duty Time",
                    value: "190 hours",
                    description: "Maximum duty time in any calendar month"
                )
                
                LimitRow(
                    title: "Maximum Monthly Flight Time",
                    value: "100 hours",
                    description: "Maximum flight time in any calendar month"
                )
            }
            
            Section("Annual Limits") {
                LimitRow(
                    title: "Maximum Annual Duty Time",
                    value: "2,000 hours",
                    description: "Maximum duty time in any 12 consecutive months"
                )
                
                LimitRow(
                    title: "Maximum Annual Flight Time",
                    value: "1,000 hours",
                    description: "Maximum flight time in any 12 consecutive months"
                )
            }
        }
        .navigationTitle("Monthly Limits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RestPeriodsView: View {
    var body: some View {
        List {
            Section("Rest Period Requirements") {
                LimitRow(
                    title: "At Home Base",
                    value: "12 hours",
                    description: "Minimum rest period when returning to home base (or as long as duty, whichever is greater)"
                )
                
                LimitRow(
                    title: "Away From Base",
                    value: "10 hours",
                    description: "Minimum rest period when away from base (or as long as duty, whichever is greater)"
                )
            }
            
            Section("Rest Period Rules") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rest period must be the greater of:")
                        .font(.headline)
                    
                    Text("• The minimum rest period for the location")
                    Text("• The duration of the preceding duty period")
                    Text("• Additional rest may be required for extended duty periods")
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Rest Periods")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LimitRow: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
} 