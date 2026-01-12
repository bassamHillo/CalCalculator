//
//  HistoryFilterSection.swift
//  playground
//
//  Filter section for history view
//

import SwiftUI

struct HistoryFilterSection: View {
    let hasActiveFilters: Bool
    let selectedTimeFilter: HistoryTimeFilter
    let searchText: String
    let onTimeFilterChange: (HistoryTimeFilter) -> Void
    let onSearchTextChange: (String) -> Void
    let onClearTimeFilter: () -> Void
    let onClearSearch: () -> Void
    
    var body: some View {
        Group {
            if hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if selectedTimeFilter != .all {
                            FilterTag(
                                text: selectedTimeFilter.displayName,
                                onRemove: {
                                    withAnimation {
                                        onClearTimeFilter()
                                    }
                                }
                            )
                        }
                        
                        if !searchText.isEmpty {
                            FilterTag(
                                text: "\"\(searchText)\"",
                                onRemove: {
                                    withAnimation {
                                        onClearSearch()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGroupedBackground))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
