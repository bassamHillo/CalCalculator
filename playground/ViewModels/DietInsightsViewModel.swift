//
//  DietInsightsViewModel.swift
//  playground
//
//  View model for diet insights and nutrition tracking
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class DietInsightsViewModel {
    // MARK: - Dependencies
    private let repository: MealRepository
    private let insightsService = DietInsightsService.shared
    private let alertManager = DietAlertManager.shared
    
    // MARK: - State
    var nutritionStatuses: [NutritionStatus] = []
    var activeAlerts: [NutritionAlert] = []
    var todayConsumed: MacroData = MacroData(calories: 0, proteinG: 0, carbsG: 0, fatG: 0)
    var isLoading = false
    
    // MARK: - Initialization
    init(repository: MealRepository) {
        self.repository = repository
    }
    
    // MARK: - Data Loading
    func loadTodayData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch today's meals
            let today = Calendar.current.startOfDay(for: Date())
            let meals = try repository.fetchMeals(for: today)
            
            // Calculate consumed macros
            var totalCalories = 0
            var totalProtein = 0.0
            var totalCarbs = 0.0
            var totalFat = 0.0
            
            for meal in meals {
                let macros = meal.totalMacros
                totalCalories += macros.calories
                totalProtein += macros.proteinG
                totalCarbs += macros.carbsG
                totalFat += macros.fatG
            }
            
            todayConsumed = MacroData(
                calories: totalCalories,
                proteinG: totalProtein,
                carbsG: totalCarbs,
                fatG: totalFat
            )
            
            // Get goals from UserSettings
            let goals = UserSettings.shared.macroGoals
            
            // Calculate statuses
            nutritionStatuses = insightsService.calculateTodayStatus(
                consumed: todayConsumed,
                goals: goals
            )
            
            // Evaluate alerts
            activeAlerts = alertManager.evaluateAlerts(for: nutritionStatuses)
        } catch {
            print("Failed to load today's data: \(error)")
        }
    }
    
    func dismissAlert(_ alert: NutritionAlert) {
        alertManager.dismissAlert(alert)
        activeAlerts.removeAll { $0.id == alert.id }
    }
    
    func refresh() async {
        await loadTodayData()
    }
}
