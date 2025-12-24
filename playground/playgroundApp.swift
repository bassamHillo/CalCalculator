//
//  playgroundApp.swift
//  playground
//
//  Created by Tareq Khalili on 15/12/2025.
//

import SwiftUI
import SwiftData

@main
struct playgroundApp: App {
    let modelContainer: ModelContainer
    @State private var appearanceMode: AppearanceMode
    
    init() {
        do {
            let schema = Schema([
                Meal.self,
                MealItem.self,
                DaySummary.self,
                WeightEntry.self,
                Exercise.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        // Initialize appearance mode from repository
        _appearanceMode = State(initialValue: UserProfileRepository.shared.getAppearanceMode())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .preferredColorScheme(appearanceMode.colorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .appearanceModeChanged)) { notification in
                    if let mode = notification.object as? AppearanceMode {
                        appearanceMode = mode
                    }
                }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let appearanceModeChanged = Notification.Name("appearanceModeChanged")
    static let nutritionGoalsChanged = Notification.Name("nutritionGoalsChanged")
}
