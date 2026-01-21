//
//  LockedFeatureOverlay.swift
//  playground
//
//  Reusable lock overlay for premium features
//  NOTE: Currently all features are free - no locking applied
//

import SwiftUI

struct LockedFeatureOverlay: View {
    @Environment(\.isSubscribed) private var isSubscribed
    
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        // All features are free - no lock overlay shown
        EmptyView()
    }
}

/// Shows content with empty data for non-subscribers, or full content for subscribers
/// NOTE: Currently all features are free - content is always shown
struct PremiumLockedContent<Content: View>: View {
    @Environment(\.isSubscribed) private var isSubscribed
    
    let content: Content
    let isProgressPage: Bool
    
    init(isProgressPage: Bool = false, @ViewBuilder content: () -> Content) {
        self.isProgressPage = isProgressPage
        self.content = content()
    }
    
    var body: some View {
        // All features are free - always show content
        content
    }
}

struct LockedButton: View {
    @Environment(\.isSubscribed) private var isSubscribed
    
    let action: () -> Void
    let label: () -> AnyView
    
    init<Content: View>(@ViewBuilder label: @escaping () -> Content, action: @escaping () -> Void) {
        self.label = { AnyView(label()) }
        self.action = action
    }
    
    var body: some View {
        // All features are free - always execute action
        Button {
            action()
        } label: {
            label()
        }
    }
}
