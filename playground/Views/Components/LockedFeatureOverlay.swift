//
//  LockedFeatureOverlay.swift
//  playground
//
//  Reusable component for premium features
//  NOTE: App is now completely free - all content is shown
//

import SwiftUI

struct LockedFeatureOverlay: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        // App is free - no lock overlay shown
        EmptyView()
    }
}

/// Shows content - app is completely free
struct PremiumLockedContent<Content: View>: View {
    let content: Content
    let isProgressPage: Bool
    
    init(isProgressPage: Bool = false, @ViewBuilder content: () -> Content) {
        self.isProgressPage = isProgressPage
        self.content = content()
    }
    
    var body: some View {
        // App is free - always show content
        content
    }
}

struct LockedButton: View {
    let action: () -> Void
    let label: () -> AnyView
    
    init<Content: View>(@ViewBuilder label: @escaping () -> Content, action: @escaping () -> Void) {
        self.label = { AnyView(label()) }
        self.action = action
    }
    
    var body: some View {
        // App is free - always execute action
        Button {
            action()
        } label: {
            label()
        }
    }
}
