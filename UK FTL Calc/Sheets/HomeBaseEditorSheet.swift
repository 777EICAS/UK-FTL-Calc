//
//  HomeBaseEditorSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct HomeBaseEditorSheet: View {
    @ObservedObject var viewModel: ManualCalcViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Edit Home Bases")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Set your primary and secondary home bases")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Primary Home Base Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.blue)
                        Text("Primary Home Base")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Button(action: {
                        viewModel.editingHomeBaseType = "primary"
                        viewModel.showingHomeBaseLocationPicker = true
                    }) {
                        HStack {
                            Text(viewModel.editingHomeBase.isEmpty ? "Select Primary Home Base" : viewModel.editingHomeBase)
                                .foregroundColor(viewModel.editingHomeBase.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                // Secondary Home Base Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.green)
                        Text("Secondary Home Base (Optional)")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Button(action: {
                        viewModel.editingHomeBaseType = "secondary"
                        viewModel.showingHomeBaseLocationPicker = true
                    }) {
                        HStack {
                            Text(viewModel.editingSecondHomeBase.isEmpty ? "Select Secondary Home Base" : viewModel.editingSecondHomeBase)
                                .foregroundColor(viewModel.editingSecondHomeBase.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    if !viewModel.editingSecondHomeBase.isEmpty {
                        Button(action: {
                            viewModel.editingSecondHomeBase = ""
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Clear Secondary Home Base")
                                    .foregroundColor(.red)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.updateHomeBases()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Changes")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        viewModel.initializeEditingHomeBases()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancel")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray4))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.updateHomeBases()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingHomeBaseLocationPicker) {
            HomeBaseLocationPickerSheet(viewModel: viewModel)
        }
        .onAppear {
            viewModel.initializeEditingHomeBases()
        }
    }
}

