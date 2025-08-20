//
//  RegulatoryDisclaimerSheet.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct RegulatoryDisclaimerSheet: View {
    @Binding var isPresented: Bool
    @AppStorage("hasAcceptedRegulatoryDisclaimer") private var hasAcceptedDisclaimer = false
    @State private var hasCheckedAcknowledgment = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Critical Warning Header
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("REGULATORY DISCLAIMER")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        Text("This is a critical safety notice that you must read and understand before using this app.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Main Disclaimer Content
                    VStack(alignment: .leading, spacing: 20) {
                        disclaimerSection(
                            title: "⚠️ NOT Official UK CAA Guidance",
                            content: "This app provides FTL calculations based on the developer's interpretation of UK CAA regulations. It is NOT official UK CAA guidance and should NOT be used as the sole source for regulatory compliance."
                        )
                        
                        disclaimerSection(
                            title: "🔍 Always Verify Independently",
                            content: "• Always verify calculations against official UK CAA regulations\n• Consult your airline's flight operations department\n• This app is for guidance and planning purposes only\n• The developer accepts no responsibility for regulatory compliance"
                        )
                        
                        disclaimerSection(
                            title: "📚 Regulation Sources",
                            content: "For official UK CAA regulations, visit:\n• CAA website: www.caa.co.uk\n• EU OPS regulations\n• Your airline's operations manual\n• Current CAP 371 documentation"
                        )
                        
                        disclaimerSection(
                            title: "⚖️ Legal Limitations",
                            content: "By using this app, you acknowledge that:\n• This is not official regulatory guidance\n• You will verify all calculations independently\n• You understand the app's limitations\n• You accept responsibility for regulatory compliance"
                        )
                    }
                    
                    // Acknowledgment Checkbox
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: {
                                hasCheckedAcknowledgment.toggle()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: hasCheckedAcknowledgment ? "checkmark.square.fill" : "square")
                                        .font(.title2)
                                        .foregroundColor(hasCheckedAcknowledgment ? .blue : .secondary)
                                    
                                    Text("I have read, understood, and accept these limitations")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        if hasCheckedAcknowledgment {
                            Text("✅ Thank you for acknowledging these important limitations")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Accept & Continue Button
                    VStack(spacing: 16) {
                        Button(action: {
                            if hasCheckedAcknowledgment {
                                hasAcceptedDisclaimer = true
                                isPresented = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Accept & Continue")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(hasCheckedAcknowledgment ? Color.blue : Color.gray)
                            )
                        }
                        .disabled(!hasCheckedAcknowledgment)
                        
                        if !hasCheckedAcknowledgment {
                            Text("Please read and acknowledge the limitations above to continue")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Regulatory Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
    
    private func disclaimerSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}

#Preview {
    RegulatoryDisclaimerSheet(isPresented: .constant(true))
}
