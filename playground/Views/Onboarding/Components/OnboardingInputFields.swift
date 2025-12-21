//
//  OnboardingInputFields.swift
//  playground
//
//  Created by OpenCode on 21/12/2025.
//

import SwiftUI

// MARK: - Text Entry
struct TextEntryView: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.body)
            .padding(16)
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(12)
    }
}

// MARK: - Number Entry
struct NumberEntryView: View {
    let placeholder: String
    let unitText: String?
    let initialText: String
    let onChanged: (AnswerValue) -> Void

    @State private var text: String = ""

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .font(.body)
                .padding(16)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(12)
                .onChange(of: text) { _, newValue in
                    onChanged(parseNumber(newValue))
                }

            if let unitText {
                Text(unitText)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { text = initialText }
    }

    private func parseNumber(_ s: String) -> AnswerValue {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .none }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        if let d = Double(normalized) { return .double(d) }
        return .none
    }
}

// MARK: - Measurement Number View (with unit picker)
struct MeasurementNumberView: View {
    let placeholder: String
    let unitOptions: [String]
    let defaultUnit: String

    let valueText: String
    let selectedUnit: String

    let onValueChanged: (AnswerValue) -> Void
    let onUnitChanged: (String) -> Void

    @State private var text: String = ""
    @State private var unit: String = ""

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .font(.body)
                .padding(16)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(12)
                .onChange(of: text) { _, newValue in
                    onValueChanged(parseNumber(newValue))
                }

            Menu {
                ForEach(unitOptions, id: \.self) { u in
                    Button {
                        unit = u
                        onUnitChanged(u)
                    } label: {
                        HStack {
                            Text(u)
                            if unit == u {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(unit)
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(12)
            }
        }
        .onAppear {
            text = valueText
            unit = selectedUnit.isEmpty ? defaultUnit : selectedUnit
        }
    }

    private func parseNumber(_ s: String) -> AnswerValue {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .none }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        if let d = Double(normalized) { return .double(d) }
        return .none
    }
}

// MARK: - Previews
#Preview("Text Entry") {
    TextEntryView(placeholder: "Enter your name", text: .constant("John"))
        .padding()
}

#Preview("Number Entry") {
    NumberEntryView(
        placeholder: "Enter age",
        unitText: "years",
        initialText: "25",
        onChanged: { _ in }
    )
    .padding()
}

#Preview("Measurement Number") {
    MeasurementNumberView(
        placeholder: "Enter weight",
        unitOptions: ["kg", "lbs"],
        defaultUnit: "kg",
        valueText: "70",
        selectedUnit: "kg",
        onValueChanged: { _ in },
        onUnitChanged: { _ in }
    )
    .padding()
}
