//
//  HistoryListContent.swift
//  playground
//
//  List content for history view
//

import SwiftUI

struct HistoryListContent: View {
    let summaries: [DaySummary]
    let timeFilter: HistoryTimeFilter
    let onSummaryTap: (DaySummary) -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var totalCalories: Int {
        summaries.reduce(0) { $0 + $1.totalCalories }
    }
    
    private var totalMeals: Int {
        summaries.reduce(0) { $0 + $1.mealCount }
    }
    
    private var averageCalories: Int {
        guard !summaries.isEmpty else { return 0 }
        return totalCalories / summaries.count
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !summaries.isEmpty {
                    StatsSummaryCard(
                        daysCount: summaries.count,
                        totalMeals: totalMeals,
                        totalCalories: totalCalories,
                        averageCalories: averageCalories,
                        timeFilter: timeFilter,
                        summaries: summaries
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                ForEach(summaries, id: \.id) { summary in
                    DaySummaryCard(summary: summary)
                        .onTapGesture {
                            HapticManager.shared.impact(.light)
                            onSummaryTap(summary)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
