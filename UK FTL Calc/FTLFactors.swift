//
//  FTLFactors.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

// MARK: - Active Factor Card
struct ActiveFactorCard: View {
    let factor: ActiveFactor
    let hasAugmentedCrew: Bool
    @State private var showingDetailPopup = false
    
    var body: some View {
        // Special handling for Report Time card when augmented crew is active
        if factor.title == "Report Time" && hasAugmentedCrew {
            DisclosureGroup(
                content: {
                    // Expanded content - show the full card
                    Button(action: {
                        showingDetailPopup = true
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: factor.impactType.icon)
                                    .foregroundColor(factor.impactType.color)
                                    .font(.caption)
                                
                                Text(factor.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Impact indicator
                                Text(factor.impactType.rawValue.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(factor.impactType.color.opacity(0.2))
                                    .foregroundColor(factor.impactType.color)
                                    .cornerRadius(4)
                                
                                // Add chevron to indicate it's tappable
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(factor.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            // Show factor value preview
                            Text(factor.factorValue)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(factor.impactType.color)
                                .lineLimit(1)
                            
                            if !factor.details.isEmpty {
                                Text(factor.details)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .lineLimit(1)
                            }
                            
                            Text(factor.impact)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(factor.impactType.color)
                            
                            // Show priority and dependencies preview
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemName: "list.number")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(factor.priority)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !factor.dependencies.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "link")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                        Text("\(factor.dependencies.count)")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Spacer()
                                
                                // Tap hint
                                Text("Tap for details")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .italic()
                            }
                            
                            // Note about not being used for augmented crew
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                    .font(.caption2)
                                Text("Note: Report time is not used for augmented crew FTL calculations")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .italic()
                            }
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(factor.impactType.color.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(showingDetailPopup ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: showingDetailPopup)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                            .opacity(showingDetailPopup ? 1 : 0)
                    )
                },
                label: {
                    // Collapsed label - show minimal info
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("Report time data (not used for augmented crew)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Impact indicator
                        Text(factor.impactType.rawValue.uppercased())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(factor.impactType.color.opacity(0.2))
                            .foregroundColor(factor.impactType.color)
                            .cornerRadius(4)
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(factor.impactType.color.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            )
            .sheet(isPresented: $showingDetailPopup) {
                FactorDetailPopupView(factor: factor)
            }
        } else {
            // Standard card display for all other factors
            Button(action: {
                showingDetailPopup = true
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: factor.impactType.icon)
                            .foregroundColor(factor.impactType.color)
                            .font(.caption)
                        
                        Text(factor.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Impact indicator
                        Text(factor.impactType.rawValue.uppercased())
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(factor.impactType.color.opacity(0.2))
                            .foregroundColor(factor.impactType.color)
                            .cornerRadius(4)
                        
                        // Add chevron to indicate it's tappable
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(factor.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Show factor value preview
                    Text(factor.factorValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(factor.impactType.color)
                        .lineLimit(1)
                    
                    if !factor.details.isEmpty {
                        Text(factor.details)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .lineLimit(1)
                    }
                    
                    Text(factor.impact)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(factor.impactType.color)
                    
                    // Show priority and dependencies preview
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.number")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(factor.priority)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if !factor.dependencies.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text("\(factor.dependencies.count)")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        // Tap hint
                        Text("Tap for details")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .italic()
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(factor.impactType.color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(showingDetailPopup ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: showingDetailPopup)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                    .opacity(showingDetailPopup ? 1 : 0)
            )
            .sheet(isPresented: $showingDetailPopup) {
                FactorDetailPopupView(factor: factor)
            }
        }
    }
}

// MARK: - Factor Detail Popup View
struct FactorDetailPopupView: View {
    let factor: ActiveFactor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with icon and title
                    VStack(spacing: 16) {
                        Image(systemName: factor.impactType.icon)
                            .font(.system(size: 50))
                            .foregroundColor(factor.impactType.color)
                        
                        Text(factor.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // Impact type badge
                        Text(factor.impactType.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(factor.impactType.color.opacity(0.2))
                            .foregroundColor(factor.impactType.color)
                            .cornerRadius(8)
                        
                        // Priority indicator
                        HStack {
                            Image(systemName: "list.number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Calculation Priority: \(factor.priority)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Factor Value Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Factor Value")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(factor.factorValue)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(factor.impactType.color)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(factor.impactType.color.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    // Before/After Comparison (if available)
                    if let beforeAfter = factor.beforeAfter {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Limit Change")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .center, spacing: 8) {
                                    Text("Before")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(beforeAfter.before)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                Image(systemName: "arrow.right")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .center, spacing: 8) {
                                    Text("After")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(beforeAfter.after)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(factor.impactType.color)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(factor.impactType.color.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Calculation Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How This Factor Was Calculated")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(factor.calculationDetails)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Dependencies Section
                    if !factor.dependencies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dependencies")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(factor.dependencies, id: \.self) { dependency in
                                    HStack {
                                        Image(systemName: "link")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text(dependency)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Main description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(factor.description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Additional details
                    if !factor.details.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(factor.details)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Impact explanation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Impact on Duty Limits")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: factor.impactType.icon)
                                .foregroundColor(factor.impactType.color)
                                .font(.title2)
                            
                            Text(factor.impact)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(factor.impactType.color)
                            
                            Spacer()
                        }
                        .padding()
                        .background(factor.impactType.color.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Regulatory context based on factor type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Regulatory Context")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(getRegulatoryContext(for: factor))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Additional regulatory details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Regulatory Reference")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(factor.regulatoryBasis)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Factor interactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Factor Interactions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(getFactorInteractions(for: factor))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Factor Details")
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
    
    private func getRegulatoryContext(for factor: ActiveFactor) -> String {
        switch factor.title {
        case "Acclimatisation":
            return "UK CAA Table 1 determines acclimatisation status based on time zone difference and elapsed time since departure from home base. Acclimatised crews can use extended duty limits from Table 2, while non-acclimatised crews must use reduced limits."
            
        case "Report Time":
            return "FDP limits are determined by local report time at the departure location. The base limit is found in UK CAA Table 2 (acclimatised) or Table 3 (unknown acclimatisation), then modified by other factors."
            
        case "Augmented Crew":
            return "Additional pilots allow extended duty times up to 17-18 hours depending on rest facility type. This is based on UK CAA regulations for augmented crew operations with proper rest facilities."
            
        case "In-Flight Rest":
            return "Rest facilities during flight allow extended duty times. Class 1 facilities provide the most rest time, followed by Class 2 and Class 3. The specific limits depend on the number of additional pilots and facility type."
            
        case "Split Duty":
            return "Split duty periods with rest breaks require reduced duty limits to ensure adequate recovery time. The rest period must meet minimum duration requirements and be properly documented."
            
        case "Consecutive Duty Days":
            return "After 5 or more consecutive duty days, reduced limits apply to prevent cumulative fatigue. This is a key safety measure in the UK CAA FTL regulations."
            
        case "Standby Duty":
            return "Standby duty affects FDP limits and duty time calculations. Home standby FDP starts from report time with reduction based on standby duration exceeding 6-8 hours. Airport standby counts all time toward FDP limits."
            
        default:
            return "This factor affects duty limits according to UK CAA Flight Time Limitations regulations. The specific impact depends on the combination of factors present in your duty."
        }
    }
    
    private func getRegulatoryReference(for factor: ActiveFactor) -> String {
        switch factor.title {
        case "Acclimatisation":
            return "UK CAA Table 1: Acclimatisation Status"
        case "Report Time":
            return "UK CAA Table 2: Acclimatised Duty Limits"
        case "Augmented Crew":
            return "UK CAA Regulations: Augmented Crew Operations"
        case "In-Flight Rest":
            return "UK CAA Regulations: In-Flight Rest Facilities"
        case "Split Duty":
            return "UK CAA Regulations: Split Duty Periods"
        case "Consecutive Duty Days":
            return "UK CAA Regulations: Consecutive Duty Days"
        case "Standby Duty":
            return "UK CAA Regulations: Standby Duty"
        default:
            return "UK CAA Regulations: General Duty Limits"
        }
    }
    
    private func getFactorInteractions(for factor: ActiveFactor) -> String {
        switch factor.title {
        case "Acclimatisation":
            return "Acclimatisation status affects which regulatory table is used for base FDP limits. Acclimatised crews use Table 2, while non-acclimatised crews use Table 3. This factor interacts with Report Time to determine the starting point for all other modifications."
            
        case "Report Time":
            return "Report time establishes the base FDP limit from the appropriate regulatory table. This base limit is then modified by all other active factors. Early start times (before 06:00) can further reduce limits regardless of acclimatisation status."
            
        case "Augmented Crew":
            return "Augmented crew allows extended duty times but requires proper rest facilities. The number of additional pilots and rest facility type determine the maximum duty limit. This factor works with In-Flight Rest to provide the maximum possible extension."
            
        case "In-Flight Rest":
            return "In-flight rest facilities extend duty limits beyond standard limits. The extension depends on the rest facility class and whether augmented crew is present. This factor cannot exceed the maximum limits set by Augmented Crew regulations."
            
        case "Split Duty":
            return "Split duty reduces the maximum duty time to ensure adequate recovery during the duty period. This reduction applies regardless of other factors and cannot be overridden by extensions from augmented crew or rest facilities."
            
        case "Consecutive Duty Days":
            return "Consecutive duty day limits are cumulative and apply to the entire duty period. These limits work in combination with daily limits and cannot be extended by other factors. They represent a fundamental safety boundary."
            
        case "Standby Duty":
            return "Standby duty affects when FDP begins and how total duty time is calculated. Home standby delays FDP start, while airport standby counts all time. This factor modifies the duty start time, which then affects all subsequent calculations."
            
        default:
            return "This factor works in combination with other active factors to determine your final duty limits. The most restrictive limit always applies, ensuring compliance with UK CAA safety regulations."
        }
    }
    
    private func getCalculationPriority(for factor: ActiveFactor) -> String {
        switch factor.title {
        case "Acclimatisation":
            return "1st - Determines base regulatory table"
        case "Report Time":
            return "2nd - Establishes base FDP limit"
        case "Augmented Crew":
            return "3rd - Allows duty time extensions"
        case "In-Flight Rest":
            return "4th - Extends duty time based on facilities"
        case "Split Duty":
            return "5th - Applies reduction if applicable"
        case "Consecutive Duty Days":
            return "6th - Applies cumulative limits"
        case "Standby Duty":
            return "7th - Modifies duty start time"
        default:
            return "Variable - Applied as needed"
        }
    }
}

// MARK: - Acclimatised Explanation View
struct AcclimatisedExplanationView: View {
    @Binding var isAcclimatised: Bool
    @Binding var isPresented: Bool
    @Binding var timeZoneDifference: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Acclimatised Crew")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Understanding acclimatisation conditions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Current Time Zone Difference
                VStack(spacing: 8) {
                    Text("Current Time Zone Difference: \(timeZoneDifference) hours")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    if timeZoneDifference < 4 {
                        Text("You are automatically considered acclimatised")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("You must meet acclimatisation requirements")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Explanation
                VStack(alignment: .leading, spacing: 16) {
                    Text("Acclimatisation Rules:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Less than 4 hours time zone change")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("You are ALWAYS considered acclimatised")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.orange)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("4-6 hours time zone difference")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Non-acclimatised on arrival. Become acclimatised after 3 local nights")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.red)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("7+ hours time zone difference")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Non-acclimatised on arrival. Become acclimatised after 4 local nights")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Important Note")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Only select 'Acclimatised' if you meet the above conditions. Extended duty limits apply when acclimatised.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        isAcclimatised = true
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Apply Acclimatised Settings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Acclimatisation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
