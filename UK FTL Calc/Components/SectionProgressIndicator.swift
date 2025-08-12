//
//  SectionProgressIndicator.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct SectionProgressIndicator: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Overall Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Calculator Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.getSectionCompletionPercentage() * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: viewModel.getSectionCompletionPercentage())
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 1.5)
            }
            
            // Section Status Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SectionStatusCard(
                    title: "Home Bases",
                    icon: "house.fill",
                    isComplete: viewModel.homeBaseSectionComplete,
                    color: .blue
                )
                
                SectionStatusCard(
                    title: "Standby",
                    icon: "clock.fill",
                    isComplete: viewModel.standbySectionComplete || !viewModel.isStandbyEnabled,
                    color: .orange
                )
                
                SectionStatusCard(
                    title: "Reporting",
                    icon: "location.fill",
                    isComplete: viewModel.reportingSectionComplete,
                    color: .green
                )
                
                SectionStatusCard(
                    title: "Sectors",
                    icon: "airplane",
                    isComplete: viewModel.sectorsSectionComplete,
                    color: .purple
                )
                
                SectionStatusCard(
                    title: "FDP Results",
                    icon: "chart.bar.fill",
                    isComplete: viewModel.fdpResultsSectionComplete,
                    color: .red
                )
                
                SectionStatusCard(
                    title: "Latest Times",
                    icon: "timer",
                    isComplete: viewModel.latestTimesSectionComplete,
                    color: .indigo
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct SectionStatusCard: View {
    let title: String
    let icon: String
    let isComplete: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isComplete ? color : Color(.systemGray4))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isComplete ? "checkmark" : icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isComplete ? .white : .secondary)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isComplete ? .primary : .secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isComplete ? color.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isComplete ? color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    SectionProgressIndicator(viewModel: ManualCalcViewModel())
        .preferredColorScheme(.light)
        .padding()
}
