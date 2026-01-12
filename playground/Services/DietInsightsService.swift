//
//  DietInsightsService.swift
//  playground
//
//  Service for calculating nutrition remaining/over metrics and managing alerts
//

import Foundation

/// Represents the status of a nutrition metric compared to its goal
struct NutritionStatus {
    let metric: NutritionMetric
    let consumed: Double
    let goal: Double
    let remaining: Double
    let over: Double
    let percentage: Double
    
    var isOverGoal: Bool {
        over > 0
    }
    
    var isCloseToLimit: Bool {
        percentage >= 0.8 && percentage < 1.0
    }
    
    var isAtLimit: Bool {
        percentage >= 1.0
    }
}

/// Available nutrition metrics for tracking
enum NutritionMetric: String, CaseIterable, Identifiable {
    case calories
    case protein
    case carbs
    case fat
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fat: return "Fat"
        }
    }
    
    var unit: String {
        switch self {
        case .calories: return "kcal"
        case .protein, .carbs, .fat: return "g"
        }
    }
    
    var color: String {
        switch self {
        case .calories: return "orange"
        case .protein: return "blue"
        case .carbs: return "green"
        case .fat: return "purple"
        }
    }
}

/// Service for calculating nutrition insights and remaining/over metrics
@MainActor
final class DietInsightsService {
    static let shared = DietInsightsService()
    
    private init() {}
    
    /// Calculate nutrition status for all metrics based on today's consumption
    func calculateTodayStatus(consumed: MacroData, goals: MacroData) -> [NutritionStatus] {
        return [
            NutritionStatus(
                metric: .calories,
                consumed: Double(consumed.calories),
                goal: Double(goals.calories),
                remaining: max(0, Double(goals.calories) - Double(consumed.calories)),
                over: max(0, Double(consumed.calories) - Double(goals.calories)),
                percentage: goals.calories > 0 ? Double(consumed.calories) / Double(goals.calories) : 0
            ),
            NutritionStatus(
                metric: .protein,
                consumed: consumed.proteinG,
                goal: goals.proteinG,
                remaining: max(0, goals.proteinG - consumed.proteinG),
                over: max(0, consumed.proteinG - goals.proteinG),
                percentage: goals.proteinG > 0 ? consumed.proteinG / goals.proteinG : 0
            ),
            NutritionStatus(
                metric: .carbs,
                consumed: consumed.carbsG,
                goal: goals.carbsG,
                remaining: max(0, goals.carbsG - consumed.carbsG),
                over: max(0, consumed.carbsG - goals.carbsG),
                percentage: goals.carbsG > 0 ? consumed.carbsG / goals.carbsG : 0
            ),
            NutritionStatus(
                metric: .fat,
                consumed: consumed.fatG,
                goal: goals.fatG,
                remaining: max(0, goals.fatG - consumed.fatG),
                over: max(0, consumed.fatG - goals.fatG),
                percentage: goals.fatG > 0 ? consumed.fatG / goals.fatG : 0
            )
        ]
    }
    
    /// Get status for a specific metric
    func status(for metric: NutritionMetric, consumed: MacroData, goals: MacroData) -> NutritionStatus? {
        return calculateTodayStatus(consumed: consumed, goals: goals)
            .first { $0.metric == metric }
    }
}
