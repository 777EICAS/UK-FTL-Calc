//
//  RegulatoryDisclaimerBanner.swift
//  UK FTL Calc
//
//  Created by Adam Da Costa on 03/08/2025.
//

import SwiftUI

struct RegulatoryDisclaimerBanner: View {
    let style: DisclaimerStyle
    let showIcon: Bool
    
    init(style: DisclaimerStyle = .standard, showIcon: Bool = true) {
        self.style = style
        self.showIcon = showIcon
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if showIcon {
                Image(systemName: style.iconName)
                    .font(.title3)
                    .foregroundColor(style.iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(style.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(style.titleColor)
                
                Text(style.message)
                    .font(.caption2)
                    .foregroundColor(style.messageColor)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(12)
        .background(style.backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(style.borderColor, lineWidth: 1)
        )
    }
}

enum DisclaimerStyle {
    case critical
    case warning
    case standard
    case info
    
    var iconName: String {
        switch self {
        case .critical:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.triangle"
        case .standard:
            return "info.circle"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .critical:
            return .red
        case .warning:
            return .orange
        case .standard:
            return .blue
        case .info:
            return .blue
        }
    }
    
    var titleColor: Color {
        switch self {
        case .critical:
            return .red
        case .warning:
            return .orange
        case .standard:
            return .blue
        case .info:
            return .blue
        }
    }
    
    var messageColor: Color {
        switch self {
        case .critical:
            return .red
        case .warning:
            return .orange
        case .standard:
            return .secondary
        case .info:
            return .secondary
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .critical:
            return Color.red.opacity(0.1)
        case .warning:
            return Color.orange.opacity(0.1)
        case .standard:
            return Color.blue.opacity(0.1)
        case .info:
            return Color.blue.opacity(0.05)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .critical:
            return Color.red.opacity(0.3)
        case .warning:
            return Color.orange.opacity(0.3)
        case .standard:
            return Color.blue.opacity(0.3)
        case .info:
            return Color.blue.opacity(0.2)
        }
    }
    
    var title: String {
        switch self {
        case .critical:
            return "⚠️ CRITICAL: Not Official Guidance"
        case .warning:
            return "⚠️ For Guidance Only"
        case .standard:
            return "ℹ️ Regulatory Notice"
        case .info:
            return "ℹ️ Information"
        }
    }
    
    var message: String {
        switch self {
        case .critical:
            return "This app is NOT official UK CAA guidance. Always verify calculations independently."
        case .warning:
            return "For planning purposes only. Verify compliance with official UK CAA regulations."
        case .standard:
            return "Based on developer's interpretation of UK CAA regulations. Verify independently."
        case .info:
            return "This calculation is based on current understanding of UK CAA regulations."
        }
    }
}

// MARK: - Predefined Banners for Common Use Cases

struct CriticalDisclaimerBanner: View {
    var body: some View {
        RegulatoryDisclaimerBanner(style: .critical)
    }
}

struct GuidanceDisclaimerBanner: View {
    var body: some View {
        RegulatoryDisclaimerBanner(style: .warning)
    }
}

struct StandardDisclaimerBanner: View {
    var body: some View {
        RegulatoryDisclaimerBanner(style: .standard)
    }
}

struct InfoDisclaimerBanner: View {
    var body: some View {
        RegulatoryDisclaimerBanner(style: .info)
    }
}

#Preview {
    VStack(spacing: 16) {
        CriticalDisclaimerBanner()
        GuidanceDisclaimerBanner()
        StandardDisclaimerBanner()
        InfoDisclaimerBanner()
    }
    .padding()
}
