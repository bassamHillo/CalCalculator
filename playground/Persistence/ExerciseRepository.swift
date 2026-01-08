//
//  ExerciseRepository.swift
//  playground
//
//  Repository for exercise data operations
//  Prepared for future backend API integration
//

import Foundation
import SwiftData
import SwiftUI

/// Repository for managing exercise data operations
/// This class is prepared for future backend API integration
final class ExerciseRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - CRUD Operations
    
    /// Save a new exercise to the database
    /// - Parameter exercise: The exercise to save
    /// - Throws: SwiftData errors if save fails
    func saveExercise(_ exercise: Exercise) throws {
        // Ensure exercise date is normalized to start of day for consistent querying
        let calendar = Calendar.current
        exercise.date = calendar.startOfDay(for: exercise.date)
        
        context.insert(exercise)
        try context.save()
        
        print("  [ExerciseRepository] Saved exercise: \(exercise.type.displayName), \(exercise.calories) cal")
    }
    
    /// Fetch all exercises for a specific date
    /// - Parameter date: The date to fetch exercises for
    /// - Returns: Array of exercises for that date
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
    
    /// Fetch today's exercises
    /// - Returns: Array of today's exercises
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
        descriptor.fetchLimit = 100
        
        let exercises = try context.fetch(descriptor)
        let elapsed = Date().timeIntervalSince(startTime)
        
        if elapsed > 0.1 {
            print("  [ExerciseRepository] fetchTodaysExercises() returned \(exercises.count) exercises in \(String(format: "%.3f", elapsed))s (slow!)")
        } else {
            print("  [ExerciseRepository] fetchTodaysExercises() returned \(exercises.count) exercises in \(String(format: "%.3f", elapsed))s")
        }
        
        return exercises
    }
    
    /// Fetch a specific exercise by ID
    /// - Parameter id: The UUID of the exercise
    /// - Returns: The exercise if found, nil otherwise
    func fetchExercise(by id: UUID) throws -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.id == id
            }
        )
        return try context.fetch(descriptor).first
    }
    
    /// Delete an exercise
    /// - Parameter exercise: The exercise to delete
    func deleteExercise(_ exercise: Exercise) throws {
        context.delete(exercise)
        try context.save()
        
        print("  [ExerciseRepository] Deleted exercise: \(exercise.type.displayName)")
    }
    
    /// Update an existing exercise
    /// - Parameter exercise: The exercise with updated values
    func updateExercise(_ exercise: Exercise) throws {
        // SwiftData automatically tracks changes to managed objects
        try context.save()
        
        print("  [ExerciseRepository] Updated exercise: \(exercise.type.displayName)")
    }
    
    // MARK: - Aggregation Methods
    
    /// Calculate total calories burned for a specific date
    /// - Parameter date: The date to calculate for
    /// - Returns: Total calories burned
    func totalCaloriesBurned(for date: Date) throws -> Int {
        let exercises = try fetchExercises(for: date)
        return exercises.reduce(0) { $0 + $1.calories }
    }
    
    /// Calculate total calories burned for today
    /// - Returns: Total calories burned today
    func totalCaloriesBurnedToday() throws -> Int {
        return try totalCaloriesBurned(for: Date())
    }
    
    /// Fetch exercises for a date range
    /// - Parameters:
    ///   - startDate: Start of the range
    ///   - endDate: End of the range
    /// - Returns: Array of exercises in the range
    func fetchExercises(from startDate: Date, to endDate: Date) throws -> [Exercise] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.date >= start && exercise.date < end
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    // MARK: - Backend API Integration (Future)
    
    /// Calculate calories for a run exercise
    /// This is a placeholder for future API integration
    /// - Parameters:
    ///   - distance: Distance in km or miles
    ///   - duration: Duration in minutes
    ///   - intensity: Exercise intensity
    ///   - distanceUnit: Unit of distance (km or miles)
    /// - Returns: Estimated calories burned
    func calculateRunCalories(
        distance: Double,
        duration: Int,
        intensity: ExerciseIntensity,
        distanceUnit: DistanceUnit
    ) async throws -> Int {
        // TODO: Replace with actual API call
        // For now, use a simple calculation based on intensity and duration
        
        let baseCaloriesPerMinute: Double
        switch intensity {
        case .high: baseCaloriesPerMinute = 15
        case .medium: baseCaloriesPerMinute = 10
        case .low: baseCaloriesPerMinute = 5
        }
        
        // Add distance factor (more distance = more calories)
        let distanceInKm = distanceUnit == .miles ? distance * 1.60934 : distance
        let distanceFactor = 1.0 + (distanceInKm * 0.05) // 5% increase per km
        
        let calculated = Int(baseCaloriesPerMinute * Double(duration) * distanceFactor)
        return max(1, calculated)
    }
    
    /// Calculate calories for weight lifting exercise
    /// This is a placeholder for future API integration
    /// - Parameters:
    ///   - sets: Array of exercise sets
    /// - Returns: Estimated calories burned
    func calculateWeightLiftingCalories(sets: [ExerciseSet]) async throws -> Int {
        // TODO: Replace with actual API call
        // For now, use a simple calculation based on sets, reps, and weight
        
        var totalCalories = 0
        for set in sets {
            // Base: ~0.05 calories per rep per kg
            let setCalories = Int(Double(set.reps) * set.weight * 0.05)
            totalCalories += max(1, setCalories)
        }
        
        // Minimum of 5 calories per set
        return max(sets.count * 5, totalCalories)
    }
    
    /// Calculate calories for a described exercise
    /// This is a placeholder for future API integration (could use AI)
    /// - Parameters:
    ///   - description: Text description of the exercise
    ///   - duration: Duration in minutes
    /// - Returns: Estimated calories burned
    func calculateDescribedExerciseCalories(
        description: String,
        duration: Int
    ) async throws -> Int {
        // TODO: Replace with actual AI-powered API call
        // For now, use medium intensity estimation
        
        let calculated = Int(10.0 * Double(duration))
        return max(1, calculated)
    }
}
