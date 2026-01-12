//
//  NutritionProgressCard.swift
//  playground
//
//  Modern nutrition progress card with remaining/over indicators
//

import SwiftUI

struct NutritionProgressCard: View {
    let status: NutritionStatus
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.metric.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Goal: \(formatValue(status.goal)) \(status.metric.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                statusIndicator
            }
            
            // Progress bar
            progressBar
            
            // Remaining/Over info
            if status.isOverGoal {
                overIndicator
            } else {
                remainingIndicator
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var statusIndicator: some View {
        Group {
            if status.isAtLimit {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            } else if status.isCloseToLimit {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .font(.title3)
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 12)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 8)
                    .fill(progressColor)
                    .frame(
                        width: min(geometry.size.width, geometry.size.width * CGFloat(status.percentage)),
                        height: 12
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: status.percentage)
            }
        }
        .frame(height: 12)
    }
    
    private var progressColor: Color {
        if status.isAtLimit {
            return .red
        } else if status.isCloseToLimit {
            return .orange
        } else {
            return metricColor
        }
    }
    
    private var metricColor: Color {
        switch status.metric {
        case .calories: return .orange
        case .protein: return .blue
        case .carbs: return .green
        case .fat: return .purple
        }
    }
    
    @ViewBuilder
    private var remainingIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            
            Text("\(formatValue(status.remaining)) \(status.metric.unit) remaining")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
    }
    
    @ViewBuilder
    private var overIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.up.circle.fill")
                .foregroundColor(.red)
                .font(.caption)
            
            Text("\(formatValue(status.over)) \(status.metric.unit) over goal")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.red)
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        NutritionProgressCard(
            status: NutritionStatus(
                metric: .calories,
                consumed: 1800,
                goal: 2000,
                remaining: 200,
                over: 0,
                percentage: 0.9
            )
        )
        
        NutritionProgressCard(
            status: NutritionStatus(
                metric: .protein,
                consumed: 160,
                goal: 150,
                remaining: 0,
                over: 10,
                percentage: 1.07
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
