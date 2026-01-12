//
//  DietInsightsSection.swift
//  playground
//
//  Section showing nutrition progress and insights
//

import SwiftUI

struct DietInsightsSection: View {
    @Bindable var viewModel: DietInsightsViewModel
    let onViewTips: (() -> Void)?
    let onAdjustGoal: (() -> Void)?
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text("Today's Nutrition")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            
            // Alert banners
            if !viewModel.activeAlerts.isEmpty {
                VStack(spacing: 8) {
                    ForEach(viewModel.activeAlerts) { alert in
                        NutritionAlertBanner(
                            alert: alert,
                            onDismiss: {
                                viewModel.dismissAlert(alert)
                            },
                            onViewTips: onViewTips,
                            onAdjustGoal: onAdjustGoal
                        )
                    }
                }
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Nutrition progress cards
            if !viewModel.nutritionStatuses.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.nutritionStatuses, id: \.metric.id) { status in
                            NutritionProgressCard(status: status)
                                .frame(width: 280)
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollTargetBehavior(.paging)
            } else if !viewModel.isLoading {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No nutrition data yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Log meals to see your progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.activeAlerts.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.nutritionStatuses.count)
    }
}

#Preview {
    let persistence = PersistenceController.shared
    let repository = MealRepository(context: persistence.mainContext)
    let viewModel = DietInsightsViewModel(repository: repository)
    
    return DietInsightsSection(
        viewModel: viewModel,
        onViewTips: {},
        onAdjustGoal: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
