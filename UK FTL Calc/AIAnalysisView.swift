import SwiftUI

struct AIAnalysisView: View {
    let analysisResult: AIAnalysisResult
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Usage Summary
                usageSummarySection
                
                // Fatigue Risk Analysis
                fatigueRiskSection
                
                // Commander's Discretion
                commanderDiscretionSection
                
                // Warnings
                if !analysisResult.warnings.isEmpty {
                    warningsSection
                }
                
                // Recommendations
                if !analysisResult.recommendations.isEmpty {
                    recommendationsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("UK CAA Compliance Analysis")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("AI-powered analysis of your flight time limitations and fatigue risk")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var usageSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                UsageCard(
                    title: "Daily",
                    used: analysisResult.dailyUsage,
                    remaining: analysisResult.dailyRemaining,
                    limit: analysisResult.dailyUsage + analysisResult.dailyRemaining,
                    color: .blue
                )
                
                UsageCard(
                    title: "Weekly",
                    used: analysisResult.weeklyUsage,
                    remaining: analysisResult.weeklyRemaining,
                    limit: analysisResult.weeklyUsage + analysisResult.weeklyRemaining,
                    color: .green
                )
                
                UsageCard(
                    title: "Monthly",
                    used: analysisResult.monthlyUsage,
                    remaining: analysisResult.monthlyRemaining,
                    limit: analysisResult.monthlyUsage + analysisResult.monthlyRemaining,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var fatigueRiskSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fatigue Risk Assessment")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(fatigueRiskColor)
                            .frame(width: 12, height: 12)
                        
                        Text("Risk Level: \(analysisResult.fatigueRisk.level.description)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    if !analysisResult.fatigueRisk.factors.isEmpty {
                        Text("Risk Factors:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(analysisResult.fatigueRisk.factors, id: \.self) { factor in
                            Text("• \(factor)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: fatigueRiskIcon)
                    .font(.system(size: 30))
                    .foregroundColor(fatigueRiskColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var commanderDiscretionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Commander's Discretion")
                .font(.headline)
                .fontWeight(.semibold)
            
            if analysisResult.commanderDiscretion.canExtend {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Extension Possible")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    Text("Maximum Safe Extension: \(TimeUtilities.formatHoursAndMinutes(analysisResult.commanderDiscretion.maxExtension))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !analysisResult.commanderDiscretion.conditions.isEmpty {
                        Text("Conditions:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(analysisResult.commanderDiscretion.conditions, id: \.self) { condition in
                            Text("• \(condition)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !analysisResult.commanderDiscretion.risks.isEmpty {
                        Text("Risks:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(analysisResult.commanderDiscretion.risks, id: \.self) { risk in
                            Text("• \(risk)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    
                    Text("Extension Not Recommended")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                
                if !analysisResult.commanderDiscretion.risks.isEmpty {
                    Text("Reasons:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(analysisResult.commanderDiscretion.risks, id: \.self) { risk in
                        Text("• \(risk)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Warnings")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(analysisResult.warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text(warning)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(analysisResult.recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(recommendation)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var fatigueRiskColor: Color {
        switch analysisResult.fatigueRisk.level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var fatigueRiskIcon: String {
        switch analysisResult.fatigueRisk.level {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "xmark.shield.fill"
        }
    }
}

struct UsageCard: View {
    let title: String
    let used: Double
    let remaining: Double
    let limit: Double
    let color: Color
    
    private var percentage: Double {
        guard limit > 0 else { return 0 }
        return (used / limit) * 100
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: min(percentage / 100, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", percentage))
                        .font(.caption)
                        .fontWeight(.bold)
                    
                    Text(TimeUtilities.formatHoursAndMinutes(remaining))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 60, height: 60)
            
                            Text("\(TimeUtilities.formatHoursAndMinutes(used))/\(TimeUtilities.formatHoursAndMinutes(limit))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        AIAnalysisView(analysisResult: AIAnalysisResult(
            dailyUsage: 8.5,
            weeklyUsage: 45.0,
            monthlyUsage: 180.0,
            dailyRemaining: 1.5,
            weeklyRemaining: 15.0,
            monthlyRemaining: 20.0,
            fatigueRisk: FatigueRisk(level: .medium, factors: ["5+ consecutive duty days", "Duty time > 10 hours"]),
            commanderDiscretion: CommanderDiscretion(
                canExtend: true,
                maxExtension: 1.5,
                conditions: ["Medium fatigue risk - monitor closely", "Single-pilot operation"],
                risks: ["Increased fatigue risk", "Limited daily margin"]
            ),
            warnings: ["⚠️ Limited daily margin remaining", "⚠️ Medium fatigue risk - monitor closely"],
            recommendations: ["Consider shorter duty periods for remaining flights today", "Monitor fatigue levels and consider additional rest"]
        ))
    }
} 