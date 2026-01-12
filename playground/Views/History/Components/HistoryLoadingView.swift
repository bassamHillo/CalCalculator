//
//  HistoryLoadingView.swift
//  playground
//
//  Loading state view for history
//

import SwiftUI

struct HistoryLoadingView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(localizationManager.localizedString(for: AppStrings.History.loadingHistory))
                .id("loading-history-\(localizationManager.currentLanguage)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
