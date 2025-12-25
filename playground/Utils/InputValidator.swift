//
//  InputValidator.swift
//  playground
//
//  Input validation utilities
//

import Foundation

struct InputValidator {
    /// Validate calorie input
    static func validateCalories(_ value: Int) -> ValidationResult {
        if value < 0 {
            return .invalid("Calories cannot be negative")
        }
        if value > 10000 {
            return .invalid("Calories value seems too high. Please verify.")
        }
        return .valid
    }
    
    /// Validate weight input
    static func validateWeight(_ value: Double, unit: String) -> ValidationResult {
        let minWeight: Double = unit == "kg" ? 20 : 44 // 20kg or 44lbs
        let maxWeight: Double = unit == "kg" ? 300 : 660 // 300kg or 660lbs
        
        if value < minWeight {
            return .invalid("Weight seems too low. Please verify.")
        }
        if value > maxWeight {
            return .invalid("Weight seems too high. Please verify.")
        }
        return .valid
    }
    
    /// Validate height input
    static func validateHeight(_ value: Double, unit: String) -> ValidationResult {
        let minHeight: Double = unit == "cm" ? 50 : 20 // 50cm or 20in
        let maxHeight: Double = unit == "cm" ? 250 : 100 // 250cm or 100in
        
        if value < minHeight {
            return .invalid("Height seems too low. Please verify.")
        }
        if value > maxHeight {
            return .invalid("Height seems too high. Please verify.")
        }
        return .valid
    }
    
    /// Validate age input
    static func validateAge(_ value: Int) -> ValidationResult {
        if value < 13 {
            return .invalid("Age must be at least 13")
        }
        if value > 120 {
            return .invalid("Age seems too high. Please verify.")
        }
        return .valid
    }
    
    /// Validate macro values
    static func validateMacro(_ value: Double, type: MacroType) -> ValidationResult {
        if value < 0 {
            return .invalid("\(type.rawValue) cannot be negative")
        }
        
        let maxValue: Double
        switch type {
        case .protein:
            maxValue = 500 // grams
        case .carbs:
            maxValue = 1000 // grams
        case .fat:
            maxValue = 300 // grams
        }
        
        if value > maxValue {
            return .invalid("\(type.rawValue) value seems too high. Please verify.")
        }
        return .valid
    }
    
    /// Validate text input
    static func validateText(_ text: String, minLength: Int = 1, maxLength: Int = 500) -> ValidationResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.count < minLength {
            return .invalid("Text must be at least \(minLength) character\(minLength == 1 ? "" : "s")")
        }
        if trimmed.count > maxLength {
            return .invalid("Text must be no more than \(maxLength) characters")
        }
        return .valid
    }
}

enum ValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

enum MacroType: String {
    case protein = "Protein"
    case carbs = "Carbs"
    case fat = "Fat"
}

