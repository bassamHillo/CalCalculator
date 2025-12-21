//
//  OnboardingStep.swift
//  playground
//
//  Created by Bassam-Hillo on 20/12/2025.
//


import Foundation

// MARK: - Models

struct OnboardingStep: Identifiable, Codable, Hashable {
    let id: String
    let type: StepType
    let title: String
    let description: String?
    let next: String?

    // form-only
    let fields: [OnboardingField]?

    // question-only
    let input: OnboardingInput?
    let optional: Bool?

    // permission-only
    let permission: PermissionType?

    // ui
    let primaryButton: ButtonConfig?
}

enum StepType: String, Codable, Hashable {
    case info
    case question
    case form
    case permission
}

struct OnboardingField: Identifiable, Codable, Hashable {
    let id: String
    let label: String
    let required: Bool?
    let input: OnboardingInput
}

struct OnboardingInput: Codable, Hashable {
    let type: InputType

    // for select inputs
    let options: [String]?

    // for text/number
    let placeholder: String?

    // for slider
    let min: Double?
    let max: Double?
    let step: Double?
    let unit: String?

    // for number+unit pickers
    let unitOptions: [String]?
    let defaultUnit: String?
}

enum InputType: String, Codable, Hashable {
    case text
    case number
    case date
    case single_select
    case multi_select
    case slider
    case toggle
}

enum PermissionType: String, Codable, Hashable {
    case notifications
}

struct ButtonConfig: Codable, Hashable {
    let title: String
}
