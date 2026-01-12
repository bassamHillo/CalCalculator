//
//  NutritionAlertBanner.swift
//  playground
//
//  Alert banner for nutrition threshold crossings
//

import SwiftUI

struct NutritionAlertBanner: View {
    let alert: NutritionAlert
    let onDismiss: () -> Void
    let onViewTips: (() -> Void)?
    let onAdjustGoal: (() -> Void)?
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            iconView
            
            // Message
            Text(alert.message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                if let onViewTips = onViewTips {
                    Button(action: onViewTips) {
                        Text("Tips")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
    
    private var iconView: some View {
        Group {
            switch alert.type {
            case .closeToLimit:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            case .exceededLimit:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .font(.title2)
    }
    
    private var backgroundColor: Color {
        switch alert.type {
        case .closeToLimit:
            return Color.orange.opacity(0.1)
        case .exceededLimit:
            return Color.red.opacity(0.1)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        NutritionAlertBanner(
            alert: NutritionAlert(
                metric: .calories,
                type: .exceededLimit,
                message: "You're 120 kcal over your calories goal today.",
                timestamp: Date()
            ),
            onDismiss: {},
            onViewTips: {},
            onAdjustGoal: {}
        )
        
        NutritionAlertBanner(
            alert: NutritionAlert(
                metric: .protein,
                type: .closeToLimit,
                message: "You have 35g protein remaining.",
                timestamp: Date()
            ),
            onDismiss: {},
            onViewTips: nil,
            onAdjustGoal: nil
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
