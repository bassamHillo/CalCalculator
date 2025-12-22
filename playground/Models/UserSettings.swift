//
//  UserSettings.swift
//  playground
//
//  CalAI Clone - User preferences and settings
//

import Foundation
import SwiftUI

/// User settings and preferences stored in UserDefaults
@Observable
final class UserSettings {
    static let shared = UserSettings()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let calorieGoal = "calorieGoal"
        static let proteinGoal = "proteinGoal"
        static let carbsGoal = "carbsGoal"
        static let fatGoal = "fatGoal"
        static let useMetricUnits = "useMetricUnits"
        static let currentWeight = "currentWeight"
        static let targetWeight = "targetWeight"
        static let height = "height"
        static let lastWeightDate = "lastWeightDate"
    }
    
    // MARK: - Properties
    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }
    
    var calorieGoal: Int {
        didSet { defaults.set(calorieGoal, forKey: Keys.calorieGoal) }
    }
    
    var proteinGoal: Double {
        didSet { defaults.set(proteinGoal, forKey: Keys.proteinGoal) }
    }
    
    var carbsGoal: Double {
        didSet { defaults.set(carbsGoal, forKey: Keys.carbsGoal) }
    }
    
    var fatGoal: Double {
        didSet { defaults.set(fatGoal, forKey: Keys.fatGoal) }
    }
    
    var useMetricUnits: Bool {
        didSet { defaults.set(useMetricUnits, forKey: Keys.useMetricUnits) }
    }
    
    var currentWeight: Double { // in kg
        didSet { defaults.set(currentWeight, forKey: Keys.currentWeight) }
    }
    
    var targetWeight: Double { // in kg
        didSet { defaults.set(targetWeight, forKey: Keys.targetWeight) }
    }
    
    var height: Double { // in cm
        didSet { defaults.set(height, forKey: Keys.height) }
    }
    
    var lastWeightDate: Date? {
        didSet { defaults.set(lastWeightDate, forKey: Keys.lastWeightDate) }
    }
    
    // MARK: - Computed Properties
    var macroGoals: MacroData {
        MacroData(
            calories: calorieGoal,
            proteinG: proteinGoal,
            carbsG: carbsGoal,
            fatG: fatGoal
        )
    }
    
    var remainingCalories: Int {
        calorieGoal
    }
    
    // MARK: - Initialization
    private init() {
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.calorieGoal = defaults.object(forKey: Keys.calorieGoal) as? Int ?? 2000
        self.proteinGoal = defaults.object(forKey: Keys.proteinGoal) as? Double ?? 150
        self.carbsGoal = defaults.object(forKey: Keys.carbsGoal) as? Double ?? 250
        self.fatGoal = defaults.object(forKey: Keys.fatGoal) as? Double ?? 65
        self.useMetricUnits = defaults.object(forKey: Keys.useMetricUnits) as? Bool ?? true
        self.currentWeight = defaults.object(forKey: Keys.currentWeight) as? Double ?? 70
        self.targetWeight = defaults.object(forKey: Keys.targetWeight) as? Double ?? 70
        self.height = defaults.object(forKey: Keys.height) as? Double ?? 170
        self.lastWeightDate = defaults.object(forKey: Keys.lastWeightDate) as? Date
    }
    
    // MARK: - Methods
    func resetToDefaults() {
        calorieGoal = 2000
        proteinGoal = 150
        carbsGoal = 250
        fatGoal = 65
        useMetricUnits = true
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func updateWeight(_ weight: Double) {
        currentWeight = weight
        lastWeightDate = Date()
    }
}
