//
//  GoalsRepository.swift
//  playground
//
//  Repository for generating user goals based on onboarding data
//  Uses GoalsGenerationService API for personalized nutrition recommendations
//

import Foundation

// MARK: - Generated Goals Model

/// Generated nutrition goals based on user onboarding data
struct GeneratedGoals: Equatable {
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    
    /// Additional metadata from API (optional)
    let bmi: Double?
    let bmr: Double?
    let tdee: Double?
    let timeToGoalWeeks: Int?
    let notes: String?
    
    init(
        calories: Int,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        bmi: Double? = nil,
        bmr: Double? = nil,
        tdee: Double? = nil,
        timeToGoalWeeks: Int? = nil,
        notes: String? = nil
    ) {
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.bmi = bmi
        self.bmr = bmr
        self.tdee = tdee
        self.timeToGoalWeeks = timeToGoalWeeks
        self.notes = notes
    }
    
    static let `default` = GeneratedGoals(
        calories: 2000,
        proteinG: 150,
        carbsG: 250,
        fatG: 65
    )
    
    static func == (lhs: GeneratedGoals, rhs: GeneratedGoals) -> Bool {
        lhs.calories == rhs.calories &&
        lhs.proteinG == rhs.proteinG &&
        lhs.carbsG == rhs.carbsG &&
        lhs.fatG == rhs.fatG
    }
}

// MARK: - Goals Repository Error

enum GoalsRepositoryError: LocalizedError {
    case apiError(String)
    case networkError(Error)
    case invalidResponse
    case missingUserData(String)
    case fallbackUsed(GeneratedGoals)
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .missingUserData(let field):
            return "Missing required user data: \(field)"
        case .fallbackUsed:
            return "Using calculated goals (API unavailable)"
        }
    }
}

// MARK: - Goals Repository Protocol

protocol GoalsRepositoryProtocol {
    /// Generate goals based on onboarding data using API
    func generateGoals(from onboardingData: [String: Any]) async throws -> GeneratedGoals
    
    /// Save generated goals to UserDefaults
    func saveGoals(_ goals: GeneratedGoals)
    
    /// Check if API-based generation is available
    var isAPIAvailable: Bool { get }
}

// MARK: - Goals Repository Implementation

/// Repository for generating and managing user nutrition goals
@MainActor
final class GoalsRepository: GoalsRepositoryProtocol {
    
    // MARK: - Singleton
    
    static let shared = GoalsRepository()
    
    // MARK: - Dependencies
    
    private let goalsService: GoalsGenerationService
    private let authManager: AuthenticationManager
    
    // MARK: - State
    
    private(set) var isLoading = false
    private(set) var lastError: GoalsRepositoryError?
    
    // MARK: - Initialization
    
    init(
        goalsService: GoalsGenerationService = .shared,
        authManager: AuthenticationManager = .shared
    ) {
        self.goalsService = goalsService
        self.authManager = authManager
    }
    
    // MARK: - Public Properties
    
    var isAPIAvailable: Bool {
        authManager.userId != nil && authManager.jwtToken != nil
    }
    
    // MARK: - Public Methods
    
    /// Generate goals based on onboarding data
    /// - Parameter onboardingData: Dictionary containing user's onboarding responses or profile data
    /// - Returns: Generated nutrition goals
    /// - Note: Attempts to use API first, falls back to local calculation if API fails
    func generateGoals(from onboardingData: [String: Any]) async throws -> GeneratedGoals {
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        // First, try to use the API for personalized goals
        if isAPIAvailable {
            do {
                print("🔵 [GoalsRepository] Attempting API-based goal generation...")
                let goals = try await generateGoalsFromAPI(onboardingData: onboardingData)
                print("✅ [GoalsRepository] API goals generated successfully")
                return goals
            } catch {
                print("⚠️ [GoalsRepository] API failed, falling back to local calculation: \(error.localizedDescription)")
                // Continue to fallback
            }
        } else {
            print("⚠️ [GoalsRepository] API not available (missing credentials), using local calculation")
        }
        
        // Fallback to local calculation
        print("🔵 [GoalsRepository] Using local goal calculation...")
        let fallbackGoals = calculateLocalGoals(from: onboardingData)
        print("✅ [GoalsRepository] Local goals calculated: \(fallbackGoals.calories) cal")
        
        return fallbackGoals
    }
    
    /// Save generated goals to UserDefaults
    func saveGoals(_ goals: GeneratedGoals) {
        let settings = UserSettings.shared
        settings.calorieGoal = goals.calories
        settings.proteinGoal = goals.proteinG
        settings.carbsGoal = goals.carbsG
        settings.fatGoal = goals.fatG
        
        print("💾 [GoalsRepository] Goals saved - Calories: \(goals.calories), P: \(goals.proteinG)g, C: \(goals.carbsG)g, F: \(goals.fatG)g")
    }
    
    // MARK: - Private Methods - API Generation
    
    private func generateGoalsFromAPI(onboardingData: [String: Any]) async throws -> GeneratedGoals {
        // Transform profile data to API format if needed
        let apiFormattedData = transformToAPIFormat(onboardingData)
        
        // Call the GoalsGenerationService
        let result = try await goalsService.generateGoals(from: apiFormattedData)
        
        // Check if user has a specific calorie goal they want to preserve
        // If so, scale macros proportionally to their calorie goal
        // Otherwise, use the API's calculated values directly
        if let userCalorieGoal = onboardingData["calorie_goal"] as? Int, userCalorieGoal > 0 {
            let scaledMacros = scaleMacrosToCalories(
                targetCalories: userCalorieGoal,
                apiCalories: result.calories,
                apiProtein: result.proteinG,
                apiCarbs: result.carbsG,
                apiFat: result.fatG
            )
            
            print("📊 [GoalsRepository] Scaling macros from API calories (\(result.calories)) to user's goal (\(userCalorieGoal))")
            
            return GeneratedGoals(
                calories: userCalorieGoal,
                proteinG: scaledMacros.protein,
                carbsG: scaledMacros.carbs,
                fatG: scaledMacros.fat
            )
        }
        
        // Return API results directly (including calories)
        print("📊 [GoalsRepository] Using API-generated goals directly - Calories: \(result.calories)")
        return GeneratedGoals(
            calories: result.calories,
            proteinG: result.proteinG,
            carbsG: result.carbsG,
            fatG: result.fatG
        )
    }
    
    /// Scale macros proportionally when user has a specific calorie goal
    private func scaleMacrosToCalories(
        targetCalories: Int,
        apiCalories: Int,
        apiProtein: Double,
        apiCarbs: Double,
        apiFat: Double
    ) -> (protein: Double, carbs: Double, fat: Double) {
        guard apiCalories > 0 else {
            // Fallback to standard macro split if API calories is invalid
            return calculateMacros(calories: targetCalories, data: [:])
        }
        
        // Calculate the ratio between user's goal and API's calculation
        let ratio = Double(targetCalories) / Double(apiCalories)
        
        // Scale macros proportionally
        let scaledProtein = round(apiProtein * ratio)
        let scaledCarbs = round(apiCarbs * ratio)
        let scaledFat = round(apiFat * ratio)
        
        return (scaledProtein, scaledCarbs, scaledFat)
    }
    
    /// Transform profile/onboarding data to the format expected by GoalsGenerationService API
    private func transformToAPIFormat(_ data: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        
        // Check if data is already in API format (from onboarding)
        if data["gender"] is [String: Any] || data["height_weight"] is [String: Any] {
            // Already in onboarding format, return as-is
            return data
        }
        
        // Transform from ProfileViewModel format to API format
        
        // Gender
        if let gender = data["gender"] as? String {
            result["gender"] = ["value": gender]
        }
        
        // Height and Weight
        var heightWeight: [String: Any] = [:]
        
        if let heightFeet = data["height_feet"] as? Int,
           let heightInches = data["height_inches"] as? Int {
            // Convert feet/inches to cm for API
            let totalInches = Double(heightFeet * 12 + heightInches)
            let heightCm = totalInches * 2.54
            heightWeight["height"] = heightCm
            heightWeight["height__unit"] = "cm"
        }
        
        if let currentWeight = data["current_weight"] as? Double {
            // ProfileViewModel stores weight in lbs, convert to kg for API
            let weightKg = currentWeight * 0.453592
            heightWeight["weight"] = weightKg
            heightWeight["weight__unit"] = "kg"
        }
        
        if !heightWeight.isEmpty {
            result["height_weight"] = heightWeight
        }
        
        // Desired weight
        if let goalWeight = data["goal_weight"] as? Double {
            // Convert lbs to kg
            let goalWeightKg = goalWeight * 0.453592
            result["desired_weight"] = ["value": goalWeightKg]
        }
        
        // Goal type
        if let goal = data["goal"] as? String {
            result["goal"] = ["value": goal]
        }
        
        // Activity level
        if let activityLevel = data["activity_level"] as? String {
            result["activity_level"] = ["value": activityLevel]
        }
        
        // Goal speed (default to moderate)
        result["goal_speed"] = ["value": 0.5]
        
        // Age -> convert to birthdate
        if let age = data["age"] as? Int {
            let calendar = Calendar.current
            if let birthdate = calendar.date(byAdding: .year, value: -age, to: Date()) {
                let formatter = ISO8601DateFormatter()
                result["birthdate"] = ["birthdate": formatter.string(from: birthdate)]
            }
        }
        
        // Notifications and coach defaults
        result["notifications"] = false
        result["coach"] = ["value": "no"]
        
        return result
    }
    
    // MARK: - Private Methods - Local Calculation
    
    /// Calculate goals locally as a fallback when API is unavailable
    private func calculateLocalGoals(from data: [String: Any]) -> GeneratedGoals {
        // Use calorie_goal from data if provided (user's current goal), otherwise calculate
        var baseCalories: Int
        
        if let userCalorieGoal = data["calorie_goal"] as? Int {
            // Use the user's current calorie goal - preserve their choice
            baseCalories = userCalorieGoal
            print("📊 [GoalsRepository] Using user's calorie goal: \(userCalorieGoal)")
        } else {
            // Calculate from profile data if calorie goal not provided
            baseCalories = calculateBaseCalories(from: data)
        }
        
        // Calculate macros based on the calorie goal
        let macros = calculateMacros(calories: baseCalories, data: data)
        
        return GeneratedGoals(
            calories: baseCalories,
            proteinG: macros.protein,
            carbsG: macros.carbs,
            fatG: macros.fat
        )
    }
    
    private func calculateBaseCalories(from data: [String: Any]) -> Int {
        var baseCalories = 2000
        
        // Adjust based on activity level
        if let activityLevel = data["activity_level"] as? String {
            switch activityLevel.lowercased() {
            case "sedentary":
                baseCalories = 1800
            case "lightly_active", "light":
                baseCalories = 2000
            case "moderately_active", "moderate":
                baseCalories = 2200
            case "very_active", "active":
                baseCalories = 2500
            case "extra_active", "athlete", "extremely_active":
                baseCalories = 2800
            default:
                break
            }
        }
        
        // Adjust based on goal type
        if let goal = data["goal"] as? String {
            switch goal.lowercased() {
            case "lose_weight", "weight_loss", "lose":
                baseCalories = Int(Double(baseCalories) * 0.8)
            case "maintain", "maintain_weight":
                break // Keep as is
            case "gain_weight", "weight_gain", "gain", "build_muscle":
                baseCalories = Int(Double(baseCalories) * 1.15)
            default:
                break
            }
        }
        
        return baseCalories
    }
    
    private func calculateMacros(calories: Int, data: [String: Any]) -> (protein: Double, carbs: Double, fat: Double) {
        var proteinMultiplier = 1.0
        
        // Adjust protein based on goal type
        if let goal = data["goal"] as? String {
            switch goal.lowercased() {
            case "gain_weight", "weight_gain", "gain", "build_muscle":
                proteinMultiplier = 1.2 // Higher protein for muscle gain
            case "lose_weight", "weight_loss", "lose":
                proteinMultiplier = 1.1 // Higher protein to preserve muscle
            default:
                proteinMultiplier = 1.0
            }
        }
        
        // Adjust based on activity level
        if let activityLevel = data["activity_level"] as? String {
            switch activityLevel.lowercased() {
            case "very_active", "active", "extra_active", "athlete", "extremely_active":
                proteinMultiplier *= 1.1
            default:
                break
            }
        }
        
        // Calculate macros based on calories
        // Standard macro split: 30% protein, 40% carbs, 30% fat
        let proteinCalories = Double(calories) * 0.30
        let carbsCalories = Double(calories) * 0.40
        let fatCalories = Double(calories) * 0.30
        
        // Convert to grams
        // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
        let proteinG = (proteinCalories / 4.0) * proteinMultiplier
        let carbsG = carbsCalories / 4.0
        let fatG = fatCalories / 9.0
        
        return (round(proteinG), round(carbsG), round(fatG))
    }
}

// MARK: - Convenience Extensions

extension GoalsRepository {
    
    /// Generate goals using current UserSettings profile data
    func generateGoalsFromCurrentProfile() async throws -> GeneratedGoals {
        let settings = UserSettings.shared
        
        // Build onboarding-style data from current settings
        var data: [String: Any] = [:]
        
        // Gender
        if let gender = settings.gender {
            data["gender"] = ["value": gender]
        }
        
        // Height and weight
        var heightWeight: [String: Any] = [:]
        if settings.height > 0 {
            heightWeight["height"] = settings.height
            heightWeight["height__unit"] = "cm"
        }
        if settings.currentWeight > 0 {
            heightWeight["weight"] = settings.currentWeight
            heightWeight["weight__unit"] = "kg"
        }
        if !heightWeight.isEmpty {
            data["height_weight"] = heightWeight
        }
        
        // Desired weight (targetWeight in UserSettings)
        if settings.targetWeight > 0 {
            data["desired_weight"] = ["value": settings.targetWeight]
        }
        
        // Birthdate
        if let birthdate = settings.birthdate {
            let formatter = ISO8601DateFormatter()
            data["birthdate"] = ["birthdate": formatter.string(from: birthdate)]
        }
        
        // Goal type - infer from current vs target weight
        let currentWeight = settings.currentWeight
        let targetWeight = settings.targetWeight
        let goalType: String
        if targetWeight > 0 && targetWeight < currentWeight {
            goalType = "lose_weight"
        } else if targetWeight > 0 && targetWeight > currentWeight {
            goalType = "gain_weight"
        } else {
            goalType = "maintain"
        }
        data["goal"] = ["value": goalType]
        
        // Activity level - default to moderately_active since UserSettings doesn't store this
        data["activity_level"] = ["value": "moderately_active"]
        
        // Goal speed
        data["goal_speed"] = ["value": 0.5]
        
        // Include current calorie goal if set
        if settings.calorieGoal > 0 {
            data["calorie_goal"] = settings.calorieGoal
        }
        
        // Defaults
        data["notifications"] = false
        data["coach"] = ["value": "no"]
        
        return try await generateGoals(from: data)
    }
}
