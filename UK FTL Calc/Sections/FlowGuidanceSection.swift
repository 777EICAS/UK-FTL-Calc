//
//  FlowGuidanceSection.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct FlowGuidanceSection: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Setup Progress")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Complete the required fields to calculate FDP")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: viewModel.overallCompletionPercentage)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: viewModel.overallCompletionPercentage)
                        
                        Text("\(Int(viewModel.overallCompletionPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                // Progress Bar
                ProgressView(value: viewModel.overallCompletionPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Current Step Indicator
            if viewModel.showFieldGuidance {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next Required Field")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if let nextField = viewModel.nextRequiredField {
                                Text(nextField.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Dismiss") {
                            viewModel.dismissFieldGuidance()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    // Action Button
                    if let nextField = viewModel.nextRequiredField {
                        Button(action: {
                            navigateToRequiredField(nextField)
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Go to \(nextField.rawValue)")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Step Navigation
            VStack(spacing: 8) {
                Text("Setup Steps")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(ManualCalcViewModel.FlowStep.allCases, id: \.self) { step in
                    StepRow(
                        step: step,
                        isCurrent: viewModel.currentFlowStep == step,
                        isCompleted: isStepCompleted(step)
                    ) {
                        viewModel.goToStep(step)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private func isStepCompleted(_ step: ManualCalcViewModel.FlowStep) -> Bool {
        switch step {
        case .homeBases:
            return !viewModel.homeBase.isEmpty
        case .standby:
            return viewModel.isStandbyConfigurationComplete
        case .reporting:
            return viewModel.isReportingConfigurationComplete
        case .sectors:
            return viewModel.isSectorsConfigurationComplete
        case .results:
            return viewModel.overallCompletionPercentage >= 1.0
        }
    }
    
    private func navigateToRequiredField(_ field: ManualCalcViewModel.RequiredField) {
        switch field {
        case .standbyType:
            viewModel.showingStandbyOptions = true
        case .standbyStartDateTime:
            viewModel.showingDateTimePicker = true
        case .standbyLocation:
            viewModel.showingLocationPicker = true
        case .standbyContactTime:
            // This will be handled by the standby flow
            break
        case .reportingDateTime:
            viewModel.showingReportingDateTimePicker = true
        case .reportingLocation:
            viewModel.showingReportingLocationPicker = true
        case .acclimatisation:
            viewModel.showingAcclimatisationPicker = true
        case .inFlightRest:
            viewModel.showingInFlightRestPicker = true
        case .estimatedBlockTime:
            viewModel.showingBlockTimePicker = true
        }
    }
}

struct StepRow: View {
    let step: ManualCalcViewModel.FlowStep
    let isCurrent: Bool
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Step Icon
                ZStack {
                    Circle()
                        .fill(stepColor)
                        .frame(width: 32, height: 32)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("\(ManualCalcViewModel.FlowStep.allCases.firstIndex(of: step) ?? 0 + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(step.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isCurrent ? .blue : .primary)
                    
                    Text(step.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isCurrent {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrent ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCurrent ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var stepColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .blue
        } else {
            return .gray
        }
    }
}

#Preview {
    FlowGuidanceSection(viewModel: ManualCalcViewModel())
}
