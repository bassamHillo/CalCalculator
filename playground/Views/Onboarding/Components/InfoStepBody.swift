//
//  InfoStepBody.swift
//  playground
//
//  Created by OpenCode on 21/12/2025.
//

import SwiftUI

struct InfoStepBody: View {
    let step: OnboardingStep

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .padding(.top, 40)
            
            if let description = step.description {
                Text(description)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    InfoStepBody(
        step: OnboardingStep(
            id: "welcome",
            type: .info,
            title: "Welcome!",
            description: "Let's get started with your health journey",
            next: nil,
            fields: nil,
            input: nil,
            optional: nil,
            permission: nil,
            primaryButton: nil
        )
    )
    .padding()
}
