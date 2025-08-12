//
//  StandbyOptionsSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct StandbyOptionsSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Button("Close") {
                    isPresented = false
                }
                .foregroundColor(.blue)
                .font(.title3)
                
                Spacer()
                
                Text("Standby / Reserve")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Apply") {
                    isPresented = false
                    viewModel.isStandbyEnabled = true
                }
                .foregroundColor(.blue)
                .font(.title3)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Segmented Control Tabs
            HStack(spacing: 3) {
                standbyTab(title: "Standby", isSelected: viewModel.selectedStandbyType == "Standby", action: { viewModel.selectedStandbyType = "Standby" })
                standbyTab(title: "Airport Duty", isSelected: viewModel.selectedStandbyType == "Airport Duty", action: { viewModel.selectedStandbyType = "Airport Duty" })
                standbyTab(title: "Airport Stby", isSelected: viewModel.selectedStandbyType == "Airport Standby", action: { viewModel.selectedStandbyType = "Airport Standby" })
                standbyTab(title: "Reserve", isSelected: viewModel.selectedStandbyType == "Reserve", action: { viewModel.selectedStandbyType = "Reserve" })
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.selectedStandbyType == "Standby" {
                        standbyContent
                    } else if viewModel.selectedStandbyType == "Airport Standby" {
                        airportStandbyContent
                    } else if viewModel.selectedStandbyType == "Airport Duty" {
                        airportDutyContent
                    } else if viewModel.selectedStandbyType == "Reserve" {
                        reserveContent
                    } else {
                        standbyContent
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func standbyTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Content Views
    private var standbyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Home Standby")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Rectangle()
                .fill(Color.blue)
                .frame(height: 3)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("• Home standby (other than at the airport)")
                Text("• Maximum duration 16 hours")
                Text("• Total time awake (standby + Duty) should not exceed 18 hours")
                Text("• Ends at designated reporting point")
            }
            .font(.title3)
            .foregroundColor(.primary)
            
            Text("FDP Calculation Rules:")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("• If reporting within first 6 hours of home standby, FDP starts at report time")
                Text("• If reporting after first 6 hours of home standby, max FDP is reduced by the amount of time exceeding 6 hours")
                Text("• In-flight rest or split duty increases these times to 8 hours")
                Text("• If standby starts between 23:00 and 07:00, the time does not reduce FDP until crew is contacted")
            }
            .font(.title3)
            .foregroundColor(.primary)
        }
    }
    
    private var airportStandbyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Airport Standby")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Rectangle()
                .fill(Color.orange)
                .frame(height: 3)
                
            VStack(alignment: .leading, spacing: 16) {
                Text("• Accommodation away from the airport is provided by the operator")
                Text("• Maximum duration 16 hours (airport standby + FDP) unless split duty or in-flight rest")
                Text("• Counts in full towards daily and weekly duty limits and rest requirements")
                Text("• FDP calculation: maximum FDP is reduced by the amount of airport standby exceeding 4 hours")
            }
            .font(.title3)
            .foregroundColor(.primary)
            
            Text("FDP Calculation Rules:")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("• Airport standby counts towards duty limits and rest requirements")
                Text("• FDP begins at the reporting time for assigned duty")
                Text("• Maximum FDP is reduced by airport standby exceeding 4 hours")
                Text("• Split duty or in-flight rest may extend the 16-hour limit")
            }
            .font(.title3)
            .foregroundColor(.primary)
        }
    }
    
    private var airportDutyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Duties at the Airport")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Rectangle()
                .fill(Color.green)
                .frame(height: 3)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("• Accommodation is not provided (accommodation means somewhere away from the airport, if you are on standby in the airport then it is an airport duty)")
                Text("• Any airport duty counts towards FDP and rest requirements")
                Text("• FDP starts from reporting for airport duty")
                Text("• Max FDP is not reduced by airport duty (unlike home standby when it exceeds 6 hours)")
            }
            .font(.title3)
            .foregroundColor(.primary)
            
            Text("FDP Calculation Rules:")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("• Airport duty counts in full as a duty period")
                Text("• FDP begins at the reporting time for airport duty")
                Text("• Maximum FDP is not reduced by prior airport duty")
                Text("• Airport duty contributes to daily and weekly duty limits")
            }
            .font(.title3)
            .foregroundColor(.primary)
        }
    }
    
    private var reserveContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Reserve")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Rectangle()
                .fill(Color.purple)
                .frame(height: 3)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("• Reserve is a period that a crew member must be available to receive an assignment for a duty, they need to be given at least 10 hours notice for the duty")
                Text("• There must be a period of at least 8 hours for rest (aka sleep)")
                Text("• The 10 hour advanced notification may include the protected 8 hours sleep time")
                Text("• Reserve does not count towards daily and weekly limits or rest requirements")
                Text("• FDP starts from the report time of a duty that has been assigned on reserve")
            }
            .font(.title3)
            .foregroundColor(.primary)
            
            Text("FDP Calculation Rules:")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("• Reserve time does not count towards duty limits or rest requirements")
                Text("• FDP begins only when a duty is assigned and reporting time is set")
                Text("• The 10-hour notice period includes protected 8-hour sleep time")
                Text("• No FDP reduction due to reserve time (unlike standby)")
            }
            .font(.title3)
            .foregroundColor(.primary)
        }
    }
}

