//
//  HomeBaseSection.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct HomeBaseSection: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    
    var body: some View {
        Button(action: {
            // Initialize editing values with current home bases
            viewModel.editingHomeBase = viewModel.homeBase
            viewModel.editingSecondHomeBase = viewModel.secondHomeBase
            viewModel.showingHomeBaseEditor = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Section Header
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text("Your Home Bases")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Edit button
                    HStack(spacing: 4) {
                        Text("Tap to edit")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
                
                VStack(spacing: 8) {
                    // Primary Home Base - Compact
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Primary")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text(viewModel.homeBase)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("UTC +1")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Second Home Base (only show if set) - Compact
                    if !viewModel.secondHomeBase.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Secondary")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Text(viewModel.secondHomeBase)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text("UTC +1")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

