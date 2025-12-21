//
//  OnboardingStore.swift
//  playground
//
//  Created by Bassam-Hillo on 20/12/2025.
//

import Foundation
import Combine

enum AnswerValue: Codable, Hashable {
    case string(String)
    case double(Double)
    case bool(Bool)
    case date(Date)
    case array([AnswerValue])
    case object([String: AnswerValue])
    case none

    private enum CodingKeys: String, CodingKey { case type, value }
    private enum Kind: String, Codable { case string, double, bool, date, array, object, none }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .type)
        switch kind {
        case .string: self = .string(try c.decode(String.self, forKey: .value))
        case .double: self = .double(try c.decode(Double.self, forKey: .value))
        case .bool:   self = .bool(try c.decode(Bool.self, forKey: .value))
        case .date:   self = .date(try c.decode(Date.self, forKey: .value))
        case .array:  self = .array(try c.decode([AnswerValue].self, forKey: .value))
        case .object: self = .object(try c.decode([String: AnswerValue].self, forKey: .value))
        case .none:   self = .none
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let v):
            try c.encode(Kind.string, forKey: .type)
            try c.encode(v, forKey: .value)
        case .double(let v):
            try c.encode(Kind.double, forKey: .type)
            try c.encode(v, forKey: .value)
        case .bool(let v):
            try c.encode(Kind.bool, forKey: .type)
            try c.encode(v, forKey: .value)
        case .date(let v):
            try c.encode(Kind.date, forKey: .type)
            try c.encode(v, forKey: .value)
        case .array(let v):
            try c.encode(Kind.array, forKey: .type)
            try c.encode(v, forKey: .value)
        case .object(let v):
            try c.encode(Kind.object, forKey: .type)
            try c.encode(v, forKey: .value)
        case .none:
            try c.encode(Kind.none, forKey: .type)
        }
    }
}

@MainActor
final class OnboardingStore: ObservableObject {
    @Published var answers: [String: AnswerValue] = [:]

    // MARK: - Step answers (question / permission)

    func setStepAnswer(stepID: String, value: AnswerValue) {
        answers[stepID] = value
    }

    func stepAnswer(stepID: String) -> AnswerValue? {
        answers[stepID]
    }

    // MARK: - Form field answers

    func setFormField(stepID: String, fieldID: String, value: AnswerValue) {
        var obj = formObject(stepID: stepID)
        obj[fieldID] = value
        answers[stepID] = .object(obj)
    }

    func formField(stepID: String, fieldID: String) -> AnswerValue? {
        formObject(stepID: stepID)[fieldID]
    }

    private func formObject(stepID: String) -> [String: AnswerValue] {
        if case .object(let obj) = answers[stepID] {
            return obj
        }
        return [:]
    }

    // MARK: - Measurement (number + unit) stored as: fieldID -> { value: Double, unit: String }

    func setMeasurementValue(stepID: String, fieldID: String, value: AnswerValue, fallbackUnit: String) {
        let unit = measurementUnit(stepID: stepID, fieldID: fieldID) ?? fallbackUnit
        let obj: [String: AnswerValue] = [
            "value": value,
            "unit": .string(unit)
        ]
        setFormField(stepID: stepID, fieldID: fieldID, value: .object(obj))
    }

    func setMeasurementUnit(stepID: String, fieldID: String, unit: String, fallbackValue: AnswerValue = .none) {
        let value = measurementValueAnswer(stepID: stepID, fieldID: fieldID) ?? fallbackValue
        let obj: [String: AnswerValue] = [
            "value": value,
            "unit": .string(unit)
        ]
        setFormField(stepID: stepID, fieldID: fieldID, value: .object(obj))
    }

    func measurementUnit(stepID: String, fieldID: String) -> String? {
        guard case .object(let obj) = formField(stepID: stepID, fieldID: fieldID),
              case .string(let unit) = obj["unit"] else { return nil }
        return unit
    }

    func measurementValueAnswer(stepID: String, fieldID: String) -> AnswerValue? {
        guard case .object(let obj) = formField(stepID: stepID, fieldID: fieldID) else { return nil }
        return obj["value"]
    }

    // MARK: - Completion checks

    func isNonEmpty(_ answer: AnswerValue?) -> Bool {
        guard let answer else { return false }
        switch answer {
        case .none:
            return false
        case .string(let s):
            return !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .array(let a):
            return !a.isEmpty
        case .object(let o):
            return !o.isEmpty
        case .double, .bool, .date:
            return true
        }
    }

    // MARK: - Convert to [String: Any] for callback

    func asAnyDictionary(jsonFriendly: Bool = true) -> [String: Any] {
        var out: [String: Any] = [:]
        for (key, value) in answers {
            if case .none = value { continue }
            if let converted = convert(value, jsonFriendly: jsonFriendly) {
                // skip empty objects
                if let dict = converted as? [String: Any], dict.isEmpty { continue }
                out[key] = converted
            }
        }
        return out
    }

    private func convert(_ value: AnswerValue, jsonFriendly: Bool) -> Any? {
        switch value {
        case .none:
            return nil
        case .string(let v):
            return v
        case .double(let v):
            return v
        case .bool(let v):
            return v
        case .date(let d):
            if jsonFriendly {
                // ISO-8601 string
                let fmt = ISO8601DateFormatter()
                fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return fmt.string(from: d)
            } else {
                return d
            }
        case .array(let arr):
            return arr.compactMap { convert($0, jsonFriendly: jsonFriendly) }
        case .object(let obj):
            var dict: [String: Any] = [:]
            for (k, v) in obj {
                if let converted = convert(v, jsonFriendly: jsonFriendly) {
                    dict[k] = converted
                }
            }
            return dict
        }
    }
}
