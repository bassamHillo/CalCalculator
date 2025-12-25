//
//  EmptyMealsView.swift
//  playground
//
//  Empty state view for meals
//

import SwiftUI

struct EmptyMealsView: View {
    var onScanTapped: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            emptyIcon
            titleText
            descriptionText
            if onScanTapped != nil {
                actionButton
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Private Views
    
    private var emptyIcon: some View {
        Image(systemName: "fork.knife.circle")
            .font(.system(size: 60))
            .foregroundColor(.gray.opacity(0.5))
    }
    
    private var titleText: some View {
        Text("No meals yet")
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    private var descriptionText: some View {
        Text("Start tracking your nutrition by scanning your first meal")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if let onScanTapped = onScanTapped {
            Button(action: {
                HapticManager.shared.impact(.medium)
                onScanTapped()
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Scan Meal")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}

#Preview("Empty State") {
    EmptyMealsView()
}
