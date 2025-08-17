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
            // Header Bar - Updated to match app theme
            HStack {
                Button("Close") {
                    isPresented = false
                }
                .foregroundColor(.blue)
                .font(.subheadline)
                .fontWeight(.medium)
                
                Spacer()
                
                Text("Standby / Reserve")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Apply") {
                    isPresented = false
                    viewModel.isStandbyEnabled = true
                }
                .foregroundColor(.blue)
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Segmented Control Tabs - Updated with app theme colors
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
            .padding(.horizontal)
            
            // Content Area - Updated with consistent spacing and card design
            ScrollView {
                VStack(spacing: 14) {
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color(.systemGroupedBackground))
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
                .background(isSelected ? Color.purple : Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: isSelected ? .purple.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Content Views - Updated with consistent styling
    
    private var standbyContent: some View {
        VStack(spacing: 14) {
            // Header Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(.purple)
                        .font(.title3)
                    
                    Text("Home Standby")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Home standby (other than at the airport)")
                    Text("• Maximum duration 16 hours")
                    Text("• Total time awake (standby + Duty) should not exceed 18 hours")
                    Text("• Ends at designated reporting point")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
            
            // FDP Rules Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text("FDP Calculation Rules")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• If reporting within first 6 hours of home standby, FDP starts at report time")
                    Text("• If reporting after first 6 hours of home standby, max FDP is reduced by the amount of time exceeding 6 hours")
                    Text("• In-flight rest or split duty increases these times to 8 hours")
                    Text("• If standby starts between 23:00 and 07:00, the time does not reduce FDP until crew is contacted")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var airportStandbyContent: some View {
        VStack(spacing: 14) {
            // Header Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "airplane.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    Text("Airport Standby")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Accommodation away from the airport is provided by the operator")
                    Text("• Maximum duration 16 hours (airport standby + FDP) unless split duty or in-flight rest")
                    Text("• Counts in full towards daily and weekly duty limits and rest requirements")
                    Text("• FDP calculation: maximum FDP is reduced by the amount of airport standby exceeding 4 hours")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            
            // FDP Rules Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text("FDP Calculation Rules")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Airport standby counts towards duty limits and rest requirements")
                    Text("• FDP begins at the reporting time for assigned duty")
                    Text("• Maximum FDP is reduced by airport standby exceeding 4 hours")
                    Text("• Split duty or in-flight rest may extend the 16-hour limit")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var airportDutyContent: some View {
        VStack(spacing: 14) {
            // Header Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    Text("Duties at the Airport")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Accommodation is not provided (accommodation means somewhere away from the airport, if you are on standby in the airport then it is an airport duty)")
                    Text("• Any airport duty counts towards FDP and rest requirements")
                    Text("• FDP starts from reporting for airport duty")
                    Text("• Max FDP is not reduced by airport duty (unlike home standby when it exceeds 6 hours)")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            
            // FDP Rules Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text("FDP Calculation Rules")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Airport duty counts in full as a duty period")
                    Text("• FDP begins at the reporting time for airport duty")
                    Text("• Maximum FDP is not reduced by prior airport duty")
                    Text("• Airport duty contributes to daily and weekly duty limits")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var reserveContent: some View {
        VStack(spacing: 14) {
            // Header Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.purple)
                        .font(.title3)
                    
                    Text("Reserve")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Reserve is a period that a crew member must be available to receive an assignment for a duty, they need to be given at least 10 hours notice for the duty")
                    Text("• There must be a period of at least 8 hours for rest (aka sleep)")
                    Text("• The 10 hour advanced notification may include the protected 8 hours sleep time")
                    Text("• Reserve does not count towards daily and weekly limits or rest requirements")
                    Text("• FDP starts from the report time of a duty that has been assigned on reserve")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
            
            // FDP Rules Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text("FDP Calculation Rules")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Reserve time does not count towards duty limits or rest requirements")
                    Text("• FDP begins only when a duty is assigned and reporting time is set")
                    Text("• The 10-hour notice period includes protected 8-hour sleep time")
                    Text("• No FDP reduction due to reserve time (unlike standby)")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

