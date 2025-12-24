//
//  HomeViewModel.swift
//  playground
//
//  View model for HomeView
//

import SwiftUI
import SwiftData

/// Represents a day in the week header
struct WeekDay: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String       // "Sun", "Mon", etc.
    let dayNumber: Int        // 1-31
    let isToday: Bool
    let progress: Double      // 0.0 to 1.0+ (calorie progress)
    let summary: DaySummary?
    let caloriesConsumed: Int
    let calorieGoal: Int
    let hasMeals: Bool
    
    /// Calories consumed over the daily goal
    var caloriesOverGoal: Int {
        max(0, caloriesConsumed - calorieGoal)
    }
    
    /// Whether the ring should be dotted (no meals logged)
    var isDotted: Bool {
        !hasMeals
    }
    
    /// Progress color based on calories over goal
    /// - Green: Up to 100 calories over goal
    /// - Yellow: 100-200 calories over goal
    /// - Red: More than 200 calories over goal
    /// - Gray: No meals logged (used with dotted ring)
    var progressColor: Color {
        if !hasMeals {
            return .gray
        }
        
        switch caloriesOverGoal {
        case 0...100:
            return .green
        case 101...200:
            return .yellow
        default:
            return .red
        }
    }
}

/// View model managing home screen state and actions
@MainActor
@Observable
final class HomeViewModel {
    // MARK: - Dependencies
    private let repository: MealRepository
    private let imageStorage: ImageStorage
    
    // MARK: - State
    var todaysSummary: DaySummary?
    var recentMeals: [Meal] = []
    var weekDays: [WeekDay] = []
    var isLoading = false
    var isInitialLoad = true // Track if this is the first load
    var error: Error?
    
    // MARK: - Burned/Rollover Calories State
    var todaysBurnedCalories: Int = 0
    var rolloverCaloriesFromYesterday: Int = 0
    
    // MARK: - Error State
    var showError = false
    var errorMessage: String?
    
    // MARK: - Keys for UserDefaults
    private let rolloverCaloriesKey = "rolloverCalories_lastDate"
    private let rolloverCaloriesAmountKey = "rolloverCalories_amount"
    
    init(
        repository: MealRepository,
        imageStorage: ImageStorage
    ) {
        self.repository = repository
        self.imageStorage = imageStorage
    }
    
    // MARK: - Data Loading
    
    func loadData() async {
        let startTime = Date()
        print("🟢 [HomeViewModel] loadData() started")
        
        // Mark that we're loading (UI can show immediately with empty state)
        isInitialLoad = true
        
        // Load critical data first (today's summary and recent meals) - show UI immediately
        await loadCriticalData()
        
        let criticalDataTime = Date().timeIntervalSince(startTime)
        print("🟢 [HomeViewModel] Critical data loaded in \(String(format: "%.3f", criticalDataTime))s")
        
        // Mark initial load complete
        isInitialLoad = false
        
        // Load less critical data in background (non-blocking)
        Task { @MainActor in
            await self.loadBackgroundData()
        }
    }

    func refreshTodayData() async {
        let startTime = Date()
        print("🟢 [HomeViewModel] refreshTodayData() started")
        await fetchData()
        let elapsed = Date().timeIntervalSince(startTime)
        print("🟢 [HomeViewModel] refreshTodayData() completed in \(String(format: "%.3f", elapsed))s")
    }
    
    /// Load critical data that's needed for initial UI display
    private func loadCriticalData() async {
        let startTime = Date()
        print("🔵 [HomeViewModel] loadCriticalData() started")
        
        // Load rollover calories immediately (fast - UserDefaults, non-blocking)
        loadRolloverCalories()
        
        // Start loading from database in background (non-blocking)
        // UI can show immediately with empty state while data loads
        Task { @MainActor in
            do {
                // Load today's summary and recent meals
                let summaryStart = Date()
                print("  📊 Fetching today's summary...")
                let summary = try repository.fetchTodaySummary()
                let summaryTime = Date().timeIntervalSince(summaryStart)
                print("  ✅ Today's summary loaded in \(String(format: "%.3f", summaryTime))s - Calories: \(summary.totalCalories)")
                
                let mealsStart = Date()
                print("  🍽️ Fetching recent meals...")
                let meals = try repository.fetchRecentMeals()
                let mealsTime = Date().timeIntervalSince(mealsStart)
                print("  ✅ Recent meals loaded in \(String(format: "%.3f", mealsTime))s - Count: \(meals.count)")
                
                // Update with animation
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        self.todaysSummary = summary
                        self.recentMeals = meals
                        self.hasDataLoaded = true
                    }
                }
                
                let totalTime = Date().timeIntervalSince(startTime)
                print("🟢 [HomeViewModel] loadCriticalData() completed in \(String(format: "%.3f", totalTime))s")
            } catch {
                let totalTime = Date().timeIntervalSince(startTime)
                print("🔴 [HomeViewModel] loadCriticalData() failed after \(String(format: "%.3f", totalTime))s: \(error)")
                self.error = error
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
        
        // Return immediately - UI shows with empty state while data loads
        print("🟢 [HomeViewModel] loadCriticalData() returned immediately (loading in background)")
    }
    
    /// Load background data that can be displayed progressively
    private func loadBackgroundData() async {
        let startTime = Date()
        print("🟡 [HomeViewModel] loadBackgroundData() started")
        
        do {
            // Fetch week summaries and build week days (can load after UI is shown)
            let weekStart = Date()
            print("  📅 Fetching week summaries...")
            let weekSummaries = try repository.fetchCurrentWeekSummaries()
            let weekFetchTime = Date().timeIntervalSince(weekStart)
            print("  ✅ Week summaries fetched in \(String(format: "%.3f", weekFetchTime))s - Count: \(weekSummaries.count)")
            
            let buildStart = Date()
            print("  🔨 Building week days...")
            let newWeekDays = buildWeekDays(from: weekSummaries)
            let buildTime = Date().timeIntervalSince(buildStart)
            print("  ✅ Week days built in \(String(format: "%.3f", buildTime))s - Count: \(newWeekDays.count)")
            
            // Update with animation
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self.weekDays = newWeekDays
                }
            }
            
            // Fetch burned calories for today (less critical)
            let burnedStart = Date()
            print("  🔥 Fetching burned calories...")
            await fetchTodaysBurnedCalories()
            let burnedTime = Date().timeIntervalSince(burnedStart)
            print("  ✅ Burned calories loaded in \(String(format: "%.3f", burnedTime))s - Amount: \(todaysBurnedCalories)")
            
            // Calculate and store rollover for tomorrow (based on yesterday's data)
            let rolloverCalcStart = Date()
            calculateAndStoreRollover(weekSummaries: weekSummaries)
            let rolloverCalcTime = Date().timeIntervalSince(rolloverCalcStart)
            print("  ✅ Rollover calculated in \(String(format: "%.6f", rolloverCalcTime))s")
            
            let totalTime = Date().timeIntervalSince(startTime)
            print("🟢 [HomeViewModel] loadBackgroundData() completed in \(String(format: "%.3f", totalTime))s")
        } catch {
            let totalTime = Date().timeIntervalSince(startTime)
            print("🔴 [HomeViewModel] loadBackgroundData() failed after \(String(format: "%.3f", totalTime))s: \(error)")
        }
    }

    private func fetchData() async {
        let startTime = Date()
        print("🟢 [HomeViewModel] fetchData() started")
        
        do {
            let summaryStart = Date()
            todaysSummary = try repository.fetchTodaySummary()
            print("  ✅ Today's summary: \(Date().timeIntervalSince(summaryStart))s")
            
            let mealsStart = Date()
            recentMeals = try repository.fetchRecentMeals()
            print("  ✅ Recent meals: \(Date().timeIntervalSince(mealsStart))s")
            
            // Fetch week summaries and build week days
            let weekStart = Date()
            let weekSummaries = try repository.fetchCurrentWeekSummaries()
            print("  ✅ Week summaries: \(Date().timeIntervalSince(weekStart))s")
            
            let buildStart = Date()
            weekDays = buildWeekDays(from: weekSummaries)
            print("  ✅ Week days built: \(Date().timeIntervalSince(buildStart))s")
            
            // Fetch burned calories for today
            let burnedStart = Date()
            await fetchTodaysBurnedCalories()
            print("  ✅ Burned calories: \(Date().timeIntervalSince(burnedStart))s")
            
            // Load rollover calories
            let rolloverStart = Date()
            loadRolloverCalories()
            print("  ✅ Rollover loaded: \(Date().timeIntervalSince(rolloverStart))s")
            
            // Calculate and store rollover for tomorrow (based on yesterday's data)
            let rolloverCalcStart = Date()
            calculateAndStoreRollover(weekSummaries: weekSummaries)
            print("  ✅ Rollover calculated: \(Date().timeIntervalSince(rolloverCalcStart))s")
            
            let totalTime = Date().timeIntervalSince(startTime)
            print("🟢 [HomeViewModel] fetchData() completed in \(String(format: "%.3f", totalTime))s")
        } catch {
            let totalTime = Date().timeIntervalSince(startTime)
            print("🔴 [HomeViewModel] fetchData() failed after \(String(format: "%.3f", totalTime))s: \(error)")
            self.error = error
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
    
    // MARK: - Burned Calories
    
    private func fetchTodaysBurnedCalories() async {
        let startTime = Date()
        do {
            let exercises = try repository.fetchTodaysExercises()
            let exerciseCount = exercises.count
            todaysBurnedCalories = exercises.reduce(0) { $0 + $1.calories }
            let elapsed = Date().timeIntervalSince(startTime)
            print("  ✅ Fetched \(exerciseCount) exercises, total burned: \(todaysBurnedCalories) cal in \(String(format: "%.3f", elapsed))s")
        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            print("  ⚠️ Failed to fetch exercises after \(String(format: "%.3f", elapsed))s: \(error)")
            todaysBurnedCalories = 0
        }
    }
    
    // MARK: - Rollover Calories
    
    private func loadRolloverCalories() {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if rollover was stored for yesterday (meaning it applies to today)
        if let lastStoredDate = defaults.object(forKey: rolloverCaloriesKey) as? Date {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            
            // If the stored date is yesterday, use the rollover amount
            if calendar.isDate(lastStoredDate, inSameDayAs: yesterday) {
                rolloverCaloriesFromYesterday = defaults.integer(forKey: rolloverCaloriesAmountKey)
            } else {
                // Rollover expired (more than 1 day old)
                rolloverCaloriesFromYesterday = 0
            }
        } else {
            rolloverCaloriesFromYesterday = 0
        }
    }
    
    private func calculateAndStoreRollover(weekSummaries: [Date: DaySummary]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get yesterday's summary
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let yesterdaySummary = weekSummaries[calendar.startOfDay(for: yesterday)] else {
            return
        }
        
        let calorieGoal = UserSettings.shared.calorieGoal
        let yesterdayConsumed = yesterdaySummary.totalCalories
        let unused = calorieGoal - yesterdayConsumed
        
        // Cap rollover at 200 calories max
        let rolloverAmount = min(200, max(0, unused))
        
        // Store for today to use
        let defaults = UserDefaults.standard
        defaults.set(yesterday, forKey: rolloverCaloriesKey)
        defaults.set(rolloverAmount, forKey: rolloverCaloriesAmountKey)
        
        rolloverCaloriesFromYesterday = rolloverAmount
    }
    
    /// Build WeekDay array for the current week (Sun-Sat)
    private func buildWeekDays(from summaries: [Date: DaySummary]) -> [WeekDay] {
        let calendar = Calendar.current
        let today = Date()
        let calorieGoalValue = effectiveCalorieGoal
        let calorieGoalDouble = Double(calorieGoalValue)
        
        // Get the start of the week (Sunday)
        let weekday = calendar.component(.weekday, from: today)
        guard let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: calendar.startOfDay(for: today)) else {
            return []
        }
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        
        var days: [WeekDay] = []
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { continue }
            
            let dayStart = calendar.startOfDay(for: date)
            let summary = summaries[dayStart]
            let caloriesConsumed = summary?.totalCalories ?? 0
            let caloriesDouble = Double(caloriesConsumed)
            let progress = calorieGoalDouble > 0 ? caloriesDouble / calorieGoalDouble : 0
            let hasMeals = (summary?.mealCount ?? 0) > 0
            
            let weekDay = WeekDay(
                date: date,
                dayName: dayFormatter.string(from: date),
                dayNumber: calendar.component(.day, from: date),
                isToday: calendar.isDateInToday(date),
                progress: progress,
                summary: summary,
                caloriesConsumed: caloriesConsumed,
                calorieGoal: calorieGoalValue,
                hasMeals: hasMeals
            )
            
            days.append(weekDay)
        }
        
        return days
    }

    // MARK: - Meal Management

    func deleteMeal(_ meal: Meal) async {
        do {
            // Delete associated image
            if let photoURL = meal.photoURL {
                imageStorage.deleteImage(at: photoURL)
            }

            try repository.deleteMeal(meal)
            await refreshTodayData()

            HapticManager.shared.notification(.success)
        } catch {
            self.error = error
            self.errorMessage = error.localizedDescription
            self.showError = true
            HapticManager.shared.notification(.error)
        }
    }

    // MARK: - Computed Properties
    
    /// Base calorie goal from settings
    var baseCalorieGoal: Int {
        UserSettings.shared.calorieGoal
    }
    
    /// Effective calorie goal accounting for burned and rollover calories
    var effectiveCalorieGoal: Int {
        var goal = baseCalorieGoal
        
        // Add burned calories if setting is enabled
        if UserProfileRepository.shared.getAddBurnedCalories() {
            goal += todaysBurnedCalories
        }
        
        // Add rollover calories if setting is enabled
        if UserProfileRepository.shared.getRolloverCalories() {
            goal += rolloverCaloriesFromYesterday
        }
        
        return goal
    }
    
    /// Calories remaining for the day (using effective goal)
    var remainingCalories: Int {
        let consumed = todaysSummary?.totalCalories ?? 0
        return max(0, effectiveCalorieGoal - consumed)
    }
    
    /// Calorie progress (using effective goal)
    var calorieProgress: Double {
        let goal = Double(effectiveCalorieGoal)
        let consumed = Double(todaysSummary?.totalCalories ?? 0)
        guard goal > 0 else { return 0 }
        return consumed / goal
    }
    
    /// Whether burned calories are being added to goal
    var isBurnedCaloriesEnabled: Bool {
        UserProfileRepository.shared.getAddBurnedCalories()
    }
    
    /// Whether rollover calories are being used
    var isRolloverCaloriesEnabled: Bool {
        UserProfileRepository.shared.getRolloverCalories()
    }
    
    /// Description of goal adjustments for display
    var goalAdjustmentDescription: String? {
        var adjustments: [String] = []
        
        if isBurnedCaloriesEnabled && todaysBurnedCalories > 0 {
            adjustments.append("+\(todaysBurnedCalories) burned")
        }
        
        if isRolloverCaloriesEnabled && rolloverCaloriesFromYesterday > 0 {
            adjustments.append("+\(rolloverCaloriesFromYesterday) rollover")
        }
        
        return adjustments.isEmpty ? nil : adjustments.joined(separator: ", ")
    }
}
