//
//  FormStepBody.swift
//  playground
//
//  Created by OpenCode on 21/12/2025.
//

import SwiftUI

struct FormStepBody: View {
    let step: OnboardingStep
    @ObservedObject var store: OnboardingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(step.fields ?? []) { field in
                VStack(alignment: .leading, spacing: 12) {
                    Text(field.label)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    switch field.input.type {
                    case .text:
                        TextEntryView(
                            placeholder: field.input.placeholder ?? "",
                            text: Binding(
                                get: {
                                    if case .string(let s) = store.formField(stepID: step.id, fieldID: field.id) { return s }
                                    return ""
                                },
                                set: { store.setFormField(stepID: step.id, fieldID: field.id, value: .string($0)) }
                            )
                        )

                    case .number:
                        // If unitOptions exist, use measurement UI
                        if let unitOptions = field.input.unitOptions, !unitOptions.isEmpty {
                            MeasurementNumberView(
                                placeholder: field.input.placeholder ?? "",
                                unitOptions: unitOptions,
                                defaultUnit: field.input.defaultUnit ?? unitOptions.first ?? "",
                                valueText: {
                                    if let val = store.measurementValueAnswer(stepID: step.id, fieldID: field.id),
                                       case .double(let d) = val { return trimDouble(d) }
                                    return ""
                                }(),
                                selectedUnit: store.measurementUnit(stepID: step.id, fieldID: field.id) ?? (field.input.defaultUnit ?? unitOptions.first ?? ""),
                                onValueChanged: { parsed in
                                    store.setMeasurementValue(stepID: step.id, fieldID: field.id, value: parsed, fallbackUnit: field.input.defaultUnit ?? unitOptions.first ?? "")
                                },
                                onUnitChanged: { newUnit in
                                    store.setMeasurementUnit(stepID: step.id, fieldID: field.id, unit: newUnit)
                                }
                            )
                        } else {
                            NumberEntryView(
                                placeholder: field.input.placeholder ?? "",
                                unitText: field.input.unit,
                                initialText: {
                                    if case .double(let d) = store.formField(stepID: step.id, fieldID: field.id) { return trimDouble(d) }
                                    return ""
                                }(),
                                onChanged: { parsed in
                                    store.setFormField(stepID: step.id, fieldID: field.id, value: parsed)
                                }
                            )
                        }

                    case .date:
                        DatePickerView(
                            date: Binding(
                                get: {
                                    if case .date(let d) = store.formField(stepID: step.id, fieldID: field.id) { return d }
                                    return Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
                                },
                                set: { store.setFormField(stepID: step.id, fieldID: field.id, value: .date($0)) }
                            )
                        )

                    case .single_select:
                        SingleSelectView(
                            title: nil,
                            options: field.input.options ?? [],
                            selection: Binding(
                                get: {
                                    if case .string(let s) = store.formField(stepID: step.id, fieldID: field.id) { return s }
                                    return ""
                                },
                                set: { store.setFormField(stepID: step.id, fieldID: field.id, value: .string($0)) }
                            )
                        )

                    case .multi_select:
                        MultiSelectView(
                            options: field.input.options ?? [],
                            selected: Binding(
                                get: {
                                    if case .array(let arr) = store.formField(stepID: step.id, fieldID: field.id) {
                                        return Set(arr.compactMap {
                                            if case .string(let s) = $0 { return s }
                                            return nil
                                        })
                                    }
                                    return []
                                },
                                set: { newSet in
                                    store.setFormField(stepID: step.id, fieldID: field.id, value: .array(newSet.sorted().map { .string($0) }))
                                }
                            )
                        )

                    case .slider:
                        SliderQuestionView(
                            min: field.input.min ?? 0,
                            max: field.input.max ?? 1,
                            step: field.input.step ?? 0.1,
                            unit: field.input.unit,
                            value: Binding(
                                get: {
                                    if case .double(let d) = store.formField(stepID: step.id, fieldID: field.id) { return d }
                                    let minV = field.input.min ?? 0
                                    let maxV = field.input.max ?? 1
                                    return (minV + maxV) / 2
                                },
                                set: { store.setFormField(stepID: step.id, fieldID: field.id, value: .double($0)) }
                            )
                        )

                    case .toggle:
                        ToggleQuestionView(
                            isOn: Binding(
                                get: {
                                    if case .bool(let b) = store.formField(stepID: step.id, fieldID: field.id) { return b }
                                    return false
                                },
                                set: { store.setFormField(stepID: step.id, fieldID: field.id, value: .bool($0)) }
                            )
                        )
                    }
                }
                .padding(20)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
        }
    }
}

private func trimDouble(_ d: Double) -> String {
    if abs(d.rounded() - d) < 0.000001 { return "\(Int(d.rounded()))" }
    return String(d)
}

#Preview {
    FormStepBody(
        step: OnboardingStep(
            id: "user_info",
            type: .form,
            title: "Tell us about yourself",
            description: "We need some basic information",
            next: nil,
            fields: [
                OnboardingField(
                    id: "name",
                    label: "Full Name",
                    required: true,
                    input: OnboardingInput(
                        type: .text,
                        options: nil,
                        placeholder: "Enter your name",
                        min: nil,
                        max: nil,
                        step: nil,
                        unit: nil,
                        unitOptions: nil,
                        defaultUnit: nil
                    )
                ),
                OnboardingField(
                    id: "age",
                    label: "Age",
                    required: true,
                    input: OnboardingInput(
                        type: .number,
                        options: nil,
                        placeholder: "Enter your age",
                        min: nil,
                        max: nil,
                        step: nil,
                        unit: "years",
                        unitOptions: nil,
                        defaultUnit: nil
                    )
                )
            ],
            input: nil,
            optional: nil,
            permission: nil,
            primaryButton: nil
        ),
        store: OnboardingStore()
    )
    .padding()
}
