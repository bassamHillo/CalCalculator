//
//  HistoryToolbarContent.swift
//  playground
//
//  Toolbar content for history view
//

import SwiftUI

struct HistoryToolbarContent: ToolbarContent {
    let hasActiveDiet: Bool
    let selectedTimeFilter: HistoryTimeFilter
    let onCreateDiet: () -> Void
    let onFilterChange: (HistoryTimeFilter) -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !hasActiveDiet {
                Button(action: onCreateDiet) {
                    Image(systemName: "calendar.badge.plus")
                }
            } else {
                filterMenuButton
            }
        }
    }
    
    private var filterMenuButton: some View {
        Menu {
            ForEach(HistoryTimeFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onFilterChange(filter)
                    }
                    HapticManager.shared.impact(.light)
                } label: {
                    HStack {
                        Text(filter.displayName)
                        if selectedTimeFilter == filter {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(selectedTimeFilter.shortName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
        }
    }
}
