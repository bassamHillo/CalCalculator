//
//  HistoryNoResultsView.swift
//  playground
//
//  No results view for filtered history
//

import SwiftUI

struct HistoryNoResultsView: View {
    let searchText: String
    let onClearFilters: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(localizationManager.localizedString(for: AppStrings.History.noResults))
                .id("no-results-\(localizationManager.currentLanguage)")
                .font(.title2)
                .fontWeight(.semibold)
            
            if !searchText.isEmpty {
                Text(
                    localizationManager.localizedString(
                        for: "No entries found for \"%@\"", arguments: searchText)
                )
                .id("no-entries-search-\(localizationManager.currentLanguage)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            } else {
                Text(localizationManager.localizedString(for: AppStrings.History.noEntriesFound))
                    .id("no-entries-period-\(localizationManager.currentLanguage)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onClearFilters) {
                Text(localizationManager.localizedString(for: AppStrings.History.clearFilters))
                    .id("clear-filters-\(localizationManager.currentLanguage)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
