//
//  FieldGuidanceOverlay.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct FieldGuidanceOverlay: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    
    var body: some View {
        if viewModel.showingFieldGuidance {
            VStack(spacing: 0) {
                Spacer()
                
                HStack(spacing: 16) {
                    // Icon based on guidance type
                    Image(systemName: iconForType(viewModel.currentGuidanceType))
                        .font(.title2)
                        .foregroundColor(colorForType(viewModel.currentGuidanceType))
                    
                    // Message
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.currentGuidanceMessage)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if viewModel.nextRequiredField != .none {
                            Text("Tap to complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        viewModel.hideGuidance()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorForType(viewModel.currentGuidanceType).opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.showingFieldGuidance)
        }
    }
    
    private func iconForType(_ type: GuidanceType) -> String {
        switch type {
        case .info:
            return "info.circle.fill"
        case .required:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.octagon.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }
    
    private func colorForType(_ type: GuidanceType) -> Color {
        switch type {
        case .info:
            return .blue
        case .required:
            return .orange
        case .warning:
            return .red
        case .success:
            return .green
        }
    }
}

#Preview {
    FieldGuidanceOverlay(viewModel: ManualCalcViewModel())
        .preferredColorScheme(.light)
}
