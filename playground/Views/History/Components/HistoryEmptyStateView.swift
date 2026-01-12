//
//  HistoryEmptyStateView.swift
//  playground
//
//  Empty state view for history
//

import SwiftUI

struct HistoryEmptyStateView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text(localizationManager.localizedString(for: AppStrings.History.noHistoryYet))
                .id("no-history-\(localizationManager.currentLanguage)")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(localizationManager.localizedString(for: AppStrings.History.historyDescription))
                .id("history-desc-\(localizationManager.currentLanguage)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
