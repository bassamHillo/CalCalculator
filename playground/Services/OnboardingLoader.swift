//
//  OnboardingLoadError.swift
//  playground
//
//  Created by Bassam-Hillo on 20/12/2025.
//


import Foundation

enum OnboardingLoadError: Error, LocalizedError {
    case fileNotFound(String)
    case decodeFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name): return "Could not find \(name).json in bundle."
        case .decodeFailed(let msg):  return "Failed to decode onboarding JSON: \(msg)"
        }
    }
}

struct OnboardingLoader {
    static func loadSteps(jsonFileName: String) throws -> [OnboardingStep] {
        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: "json") else {
            throw OnboardingLoadError.fileNotFound(jsonFileName)
        }
        let data = try Data(contentsOf: url)

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([OnboardingStep].self, from: data)
        } catch {
            throw OnboardingLoadError.decodeFailed(error.localizedDescription)
        }
    }

    /// Orders steps by following `next` pointers starting from the first element.
    /// Any unreachable steps are appended in original order.
    static func orderedSteps(from steps: [OnboardingStep]) -> [OnboardingStep] {
        guard let first = steps.first else { return [] }
        let byID = Dictionary(uniqueKeysWithValues: steps.map { ($0.id, $0) })

        var ordered: [OnboardingStep] = []
        var visited = Set<String>()

        var current: OnboardingStep? = first
        while let step = current, !visited.contains(step.id) {
            ordered.append(step)
            visited.insert(step.id)
            if let nextID = step.next, let next = byID[nextID] {
                current = next
            } else {
                current = nil
            }
        }

        // append any leftovers
        for s in steps where !visited.contains(s.id) {
            ordered.append(s)
        }

        return ordered
    }
}
