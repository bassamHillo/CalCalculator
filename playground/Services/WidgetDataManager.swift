//
//  WidgetDataManager.swift
//  playground
//
//  Manages data synchronization between the main app and widgets
//

import Foundation
import WidgetKit

/// Manages widget data synchronization using App Groups
final class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let appGroupIdentifier = "group.com.calcalculator.shared"
    private let userDefaults: UserDefaults?
    
    // MARK: - Keys
    private enum Keys {
        static let caloriesConsumed = "widget_calories_consumed"
        static let caloriesGoal = "widget_calories_goal"
        static let proteinConsumed = "widget_protein_consumed"
        static let proteinGoal = "widget_protein_goal"
        static let carbsConsumed = "widget_carbs_consumed"
        static let carbsGoal = "widget_carbs_goal"
        static let fatConsumed = "widget_fat_consumed"
        static let fatGoal = "widget_fat_goal"
        static let mealCount = "widget_meal_count"
        static let lastMealName = "widget_last_meal_name"
        static let lastMealTime = "widget_last_meal_time"
        static let lastUpdateDate = "widget_last_update_date"
        static let weeklyData = "widget_weekly_data"
    }
    
    private init() {
        self.userDefaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Public Methods
    
    /// Updates widget data with current nutrition information
    func updateWidgetData(
        caloriesConsumed: Int,
        caloriesGoal: Int,
        proteinConsumed: Double,
        proteinGoal: Double,
        carbsConsumed: Double,
        carbsGoal: Double,
        fatConsumed: Double,
        fatGoal: Double,
        mealCount: Int,
        lastMealName: String?,
        lastMealTime: Date?
    ) {
        guard let defaults = userDefaults else {
            print("WidgetDataManager: Failed to access App Group UserDefaults")
            return
        }
        
        defaults.set(caloriesConsumed, forKey: Keys.caloriesConsumed)
        defaults.set(caloriesGoal, forKey: Keys.caloriesGoal)
        defaults.set(proteinConsumed, forKey: Keys.proteinConsumed)
        defaults.set(proteinGoal, forKey: Keys.proteinGoal)
        defaults.set(carbsConsumed, forKey: Keys.carbsConsumed)
        defaults.set(carbsGoal, forKey: Keys.carbsGoal)
        defaults.set(fatConsumed, forKey: Keys.fatConsumed)
        defaults.set(fatGoal, forKey: Keys.fatGoal)
        defaults.set(mealCount, forKey: Keys.mealCount)
        defaults.set(lastMealName, forKey: Keys.lastMealName)
        defaults.set(lastMealTime, forKey: Keys.lastMealTime)
        defaults.set(Date(), forKey: Keys.lastUpdateDate)
        
        defaults.synchronize()
        
        // Request widget refresh
        refreshAllWidgets()
    }
    
    /// Convenience method to update widget data from app models
    /// Call this from HomeViewModel after fetching data
    func syncFromAppData(
        caloriesConsumed: Int,
        proteinConsumed: Double,
        carbsConsumed: Double,
        fatConsumed: Double,
        mealCount: Int,
        lastMealName: String?,
        lastMealTime: Date?,
        caloriesGoal: Int,
        proteinGoal: Double,
        carbsGoal: Double,
        fatGoal: Double
    ) {
        updateWidgetData(
            caloriesConsumed: caloriesConsumed,
            caloriesGoal: caloriesGoal,
            proteinConsumed: proteinConsumed,
            proteinGoal: proteinGoal,
            carbsConsumed: carbsConsumed,
            carbsGoal: carbsGoal,
            fatConsumed: fatConsumed,
            fatGoal: fatGoal,
            mealCount: mealCount,
            lastMealName: lastMealName,
            lastMealTime: lastMealTime
        )
    }
    
    /// Updates weekly data for the large widget
    func updateWeeklyData(_ weeklyCalories: [(date: Date, consumed: Int, goal: Int)]) {
        guard let defaults = userDefaults else { return }
        
        let encodableData = weeklyCalories.map { item -> [String: Any] in
            return [
                "date": item.date.timeIntervalSince1970,
                "consumed": item.consumed,
                "goal": item.goal
            ]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: encodableData) {
            defaults.set(jsonData, forKey: Keys.weeklyData)
            defaults.synchronize()
        }
    }
    
    /// Requests all widgets to refresh their timelines
    func refreshAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Requests specific widget to refresh
    func refreshWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
    
    /// Clears all widget data (useful for logout or reset)
    func clearWidgetData() {
        guard let defaults = userDefaults else { return }
        
        defaults.removeObject(forKey: Keys.caloriesConsumed)
        defaults.removeObject(forKey: Keys.caloriesGoal)
        defaults.removeObject(forKey: Keys.proteinConsumed)
        defaults.removeObject(forKey: Keys.proteinGoal)
        defaults.removeObject(forKey: Keys.carbsConsumed)
        defaults.removeObject(forKey: Keys.carbsGoal)
        defaults.removeObject(forKey: Keys.fatConsumed)
        defaults.removeObject(forKey: Keys.fatGoal)
        defaults.removeObject(forKey: Keys.mealCount)
        defaults.removeObject(forKey: Keys.lastMealName)
        defaults.removeObject(forKey: Keys.lastMealTime)
        defaults.removeObject(forKey: Keys.lastUpdateDate)
        defaults.removeObject(forKey: Keys.weeklyData)
        
        defaults.synchronize()
        refreshAllWidgets()
    }
    
    /// Updates just the goals (when settings change)
    func updateGoals(calories: Int, protein: Double, carbs: Double, fat: Double) {
        guard let defaults = userDefaults else { return }
        
        defaults.set(calories, forKey: Keys.caloriesGoal)
        defaults.set(protein, forKey: Keys.proteinGoal)
        defaults.set(carbs, forKey: Keys.carbsGoal)
        defaults.set(fat, forKey: Keys.fatGoal)
        defaults.synchronize()
        
        refreshAllWidgets()
    }
}
