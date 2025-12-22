//
//  ContentView.swift
//  playground
//
//  Created by Tareq Khalili on 15/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var repository: MealRepository?
    @State private var authState: AuthState = .login
    @State private var onboardingResult: [String: Any] = [:]
    
    private var settings = UserSettings.shared
    
    enum AuthState {
        case login
        case onboarding
        case signIn
        case authenticated
    }

    var body: some View {
        if let repository = repository {
            switch authState {
            case .login:
                LoginView(
                    onGetStarted: {
                        authState = .onboarding
                    },
                    onSignIn: {
                        authState = .signIn
                    }
                )
                
            case .onboarding:
                OnboardingFlowView(jsonFileName: "onboarding") { dict in
                    // ✅ This is the final dictionary: [stepId: answer]
                    onboardingResult = dict
                    
                    // Save onboarding data
                    saveOnboardingData(dict)
                    
                    // Mark onboarding as completed
                    settings.completeOnboarding()
                    
                    // Save user as authenticated
                    AuthenticationManager.shared.setUserId(AuthenticationManager.shared.userId ?? "")

                    // Example: convert to JSON for debugging/network
                    if JSONSerialization.isValidJSONObject(dict),
                       let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
                       let json = String(data: data, encoding: .utf8) {
                        print(json)
                    }
                    
                    // Navigate to authenticated state
                    // Paywall check will happen here if SDK is integrated
                    authState = .authenticated
                }
                
            case .signIn:
                // TODO: Implement sign in view
                // For now, just authenticate directly
                Text("Sign In View")
                    .onAppear {
                        // Temporary: auto-authenticate existing users
                        authState = .authenticated
                    }
                
            case .authenticated:
                MainTabView(repository: repository)
            }
        } else {
            ProgressView("Loading...")
                .task {
                    self.repository = MealRepository(context: modelContext)
                    
                    // Check if onboarding is already completed
                    if settings.hasCompletedOnboarding {
                        // Skip login/onboarding and go straight to authenticated
                        authState = .authenticated
                    }
                    // Otherwise, start with login screen
                }
        }
    }
    
    // MARK: - Save Onboarding Data
    
    private func saveOnboardingData(_ dict: [String: Any]) {
        // Extract height and weight from "height_weight" step
        // Structure: height_weight -> { height: { value: Double, unit: String }, weight: { value: Double, unit: String } }
        if let heightWeightData = dict["height_weight"] as? [String: Any] {
            // Height
            if let heightData = heightWeightData["height"] as? [String: Any] {
                if let heightValue = heightData["value"] as? Double,
                   let unit = heightData["unit"] as? String {
                    // Convert to cm
                    let heightInCm = unit == "cm" ? heightValue : heightValue * 30.48 // ft to cm
                    settings.height = heightInCm
                }
            }
            
            // Weight
            if let weightData = heightWeightData["weight"] as? [String: Any] {
                if let weightValue = weightData["value"] as? Double,
                   let unit = weightData["unit"] as? String {
                    // Convert to kg
                    let weightInKg = unit == "kg" ? weightValue : weightValue * 0.453592 // lbs to kg
                    // Use updateWeight to set both weight and lastWeightDate
                    settings.updateWeight(weightInKg)
                }
            }
        }
        
        // Extract desired weight from "desired_weight" step
        // Structure: desired_weight -> Double (already in kg)
        if let desiredWeightValue = dict["desired_weight"] as? Double {
            settings.targetWeight = desiredWeightValue
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [Meal.self, MealItem.self, DaySummary.self, WeightEntry.self],
            inMemory: true
        )
}
