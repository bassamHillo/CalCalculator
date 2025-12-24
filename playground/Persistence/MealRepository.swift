//
//  MealRepository.swift
//  playground
//
//  CalAI Clone - Repository for meal data operations
//

import Foundation
import SwiftData

/// Repository for managing meal data operations
final class MealRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Meal Operations
    
    func saveMeal(_ meal: Meal) throws {
        context.insert(meal)
        try context.save()
        
        // Update or create day summary
        try updateDaySummary(for: meal.timestamp, adding: meal)
    }
    
    func deleteMeal(_ meal: Meal) throws {
        // Update day summary before deletion
        try updateDaySummary(for: meal.timestamp, removing: meal)
        
        context.delete(meal)
        try context.save()
    }
    
    func fetchMeals(for date: Date? = nil) throws -> [Meal] {
        var descriptor = FetchDescriptor<Meal>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        if let date = date {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            descriptor.predicate = #Predicate<Meal> { meal in
                meal.timestamp >= startOfDay && meal.timestamp < endOfDay
            }
        }
        
        return try context.fetch(descriptor)
    }
    
    func fetchTodaysMeals() throws -> [Meal] {
        return try fetchMeals(for: Date())
    }
    
    func fetchMeal(by id: UUID) throws -> Meal? {
        let descriptor = FetchDescriptor<Meal>(
            predicate: #Predicate<Meal> { meal in
                meal.id == id
            }
        )
        return try context.fetch(descriptor).first
    }
    
    func fetchRecentMeals(limit: Int = 10) throws -> [Meal] {
        let startTime = Date()
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        var descriptor = FetchDescriptor<Meal>(
            predicate: #Predicate<Meal> { meal in
                meal.timestamp >= startOfDay && meal.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        let meals = try context.fetch(descriptor)
        let elapsed = Date().timeIntervalSince(startTime)
        print("  🍽️ [MealRepository] fetchRecentMeals(limit: \(limit)) returned \(meals.count) meals in \(String(format: "%.3f", elapsed))s")
        return meals
    }
    
    // MARK: - Exercise Operations
    
    func fetchTodaysExercises() throws -> [Exercise] {
        let startTime = Date()
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        var descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.date >= startOfDay && exercise.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.includePendingChanges = false
        descriptor.fetchLimit = 100 // Limit results to prevent scanning entire database
        
        let exercises = try context.fetch(descriptor)
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed > 0.1 {
            print("  ⚠️ [MealRepository] fetchTodaysExercises() returned \(exercises.count) exercises in \(String(format: "%.3f", elapsed))s (slow!)")
        } else {
            print("  🔥 [MealRepository] fetchTodaysExercises() returned \(exercises.count) exercises in \(String(format: "%.3f", elapsed))s")
        }
        return exercises
    }
    
    func fetchExercises(for date: Date) throws -> [Exercise] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.date >= startOfDay && exercise.date < endOfDay
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    func saveExercise(_ exercise: Exercise) throws {
        context.insert(exercise)
        try context.save()
    }
    
    func deleteExercise(_ exercise: Exercise) throws {
        context.delete(exercise)
        try context.save()
    }
    
    // MARK: - Day Summary Operations
    
    func fetchDaySummary(for date: Date) throws -> DaySummary? {
        let startTime = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        var descriptor = FetchDescriptor<DaySummary>(
            predicate: #Predicate<DaySummary> { summary in
                summary.date == startOfDay
            }
        )
        descriptor.fetchLimit = 1 // Optimize: only fetch one
        
        let result = try context.fetch(descriptor).first
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed > 0.1 {
            print("  ⚠️ [MealRepository] fetchDaySummary() took \(String(format: "%.3f", elapsed))s (slow!)")
        }
        return result
    }
    
    func fetchTodaySummary() throws -> DaySummary {
        let startTime = Date()
        
        let fetchStart = Date()
        if let summary = try fetchDaySummary(for: Date()) {
            let fetchTime = Date().timeIntervalSince(fetchStart)
            let totalTime = Date().timeIntervalSince(startTime)
            print("  📊 [MealRepository] fetchTodaySummary() found existing - fetch: \(String(format: "%.3f", fetchTime))s, total: \(String(format: "%.3f", totalTime))s")
            return summary
        }
        
        // Create new summary for today
        let createStart = Date()
        let summary = DaySummary(date: Date())
        context.insert(summary)
        try context.save()
        let createTime = Date().timeIntervalSince(createStart)
        let totalTime = Date().timeIntervalSince(startTime)
        print("  📊 [MealRepository] fetchTodaySummary() created new in \(String(format: "%.3f", createTime))s (total: \(String(format: "%.3f", totalTime))s)")
        return summary
    }
    
    func fetchAllDaySummaries() throws -> [DaySummary] {
        let descriptor = FetchDescriptor<DaySummary>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    /// Fetch summaries for the current week (Sunday to Saturday)
    func fetchCurrentWeekSummaries() throws -> [Date: DaySummary] {
        let startTime = Date()
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: calendar.startOfDay(for: today)),
              let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
            print("  ⚠️ [MealRepository] fetchCurrentWeekSummaries() failed to calculate week range")
            return [:]
        }
        
        let fetchStart = Date()
        var descriptor = FetchDescriptor<DaySummary>(
            predicate: #Predicate<DaySummary> { summary in
                summary.date >= startOfWeek && summary.date < endOfWeek
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        descriptor.fetchLimit = 7 // Only need 7 days max
        descriptor.includePendingChanges = false
        
        let summaries = try context.fetch(descriptor)
        let fetchTime = Date().timeIntervalSince(fetchStart)
        if fetchTime > 0.5 {
            print("  ⚠️ [MealRepository] fetchCurrentWeekSummaries() fetched \(summaries.count) summaries in \(String(format: "%.3f", fetchTime))s (slow!)")
        }
        
        // Convert to dictionary keyed by date
        let dictStart = Date()
        var result: [Date: DaySummary] = [:]
        for summary in summaries {
            let dayStart = calendar.startOfDay(for: summary.date)
            result[dayStart] = summary
        }
        let dictTime = Date().timeIntervalSince(dictStart)
        let totalTime = Date().timeIntervalSince(startTime)
        print("  📅 [MealRepository] fetchCurrentWeekSummaries() completed in \(String(format: "%.3f", totalTime))s (dict conversion: \(String(format: "%.6f", dictTime))s)")
        
        return result
    }
    
    private func updateDaySummary(for date: Date, adding meal: Meal) throws {
        let summary = try fetchDaySummary(for: date) ?? {
            let newSummary = DaySummary(date: date)
            context.insert(newSummary)
            return newSummary
        }()
        
        summary.addMeal(meal)
        try context.save()
    }
    
    private func updateDaySummary(for date: Date, removing meal: Meal) throws {
        guard let summary = try fetchDaySummary(for: date) else { return }
        summary.removeMeal(meal)
        try context.save()
    }
    
    // MARK: - Data Management
    
    func deleteAllData() throws {
        try context.delete(model: Meal.self)
        try context.delete(model: MealItem.self)
        try context.delete(model: DaySummary.self)
        try context.save()
    }
    
    func exportAllMeals() throws -> Data {
        let meals = try fetchMeals()
        let exportData = meals.map { meal in
            ExportMeal(
                name: meal.name,
                timestamp: meal.timestamp,
                totalCalories: meal.totalCalories,
                macros: meal.totalMacros,
                items: meal.items.map { item in
                    ExportMealItem(
                        name: item.name,
                        portion: item.portion,
                        unit: item.unit,
                        calories: item.calories,
                        proteinG: item.proteinG,
                        carbsG: item.carbsG,
                        fatG: item.fatG
                    )
                }
            )
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportData)
    }
}

// MARK: - Export Models

struct ExportMeal: Codable {
    let name: String
    let timestamp: Date
    let totalCalories: Int
    let macros: MacroData
    let items: [ExportMealItem]
}

struct ExportMealItem: Codable {
    let name: String
    let portion: Double
    let unit: String
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
}
