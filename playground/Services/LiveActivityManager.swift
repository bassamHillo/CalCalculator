//
//  LiveActivityManager.swift
//  CalCalculator
//
//  Manages Live Activity for displaying daily calories and macros on Lock Screen
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Attributes for the Live Activity showing daily nutrition progress
@available(iOS 16.1, *)
struct NutritionActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var caloriesConsumed: Int
        var calorieGoal: Int
        var proteinG: Double
        var carbsG: Double
        var fatG: Double
        var proteinGoal: Double
        var carbsGoal: Double
        var fatGoal: Double
        var timestamp: Date
        
        var caloriesRemaining: Int {
            max(0, calorieGoal - caloriesConsumed)
        }
        
        var calorieProgress: Double {
            guard calorieGoal > 0 else { return 0 }
            return min(1.0, Double(caloriesConsumed) / Double(calorieGoal))
        }
    }
    
    // Fixed non-changing properties about your activity go here!
    var activityName: String = "Daily Nutrition"
}

/// Manager for Live Activity functionality
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private init() {}
    
    /// Check if Live Activity is available on this device
    var isAvailable: Bool {
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }
    
    /// Check if there's an active Live Activity
    @available(iOS 16.1, *)
    var hasActiveActivity: Bool {
        let activities = Activity<NutritionActivityAttributes>.activities
        return !activities.isEmpty
    }
    
    /// Start or update Live Activity with current nutrition data
    @available(iOS 16.1, *)
    func updateActivity(
        caloriesConsumed: Int,
        calorieGoal: Int,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        proteinGoal: Double,
        carbsGoal: Double,
        fatGoal: Double
    ) {
        guard isAvailable else {
            print("⚠️ [LiveActivity] Live Activities are not enabled on this device")
            return
        }
        
        let attributes = NutritionActivityAttributes()
        let contentState = NutritionActivityAttributes.ContentState(
            caloriesConsumed: caloriesConsumed,
            calorieGoal: calorieGoal,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            proteinGoal: proteinGoal,
            carbsGoal: carbsGoal,
            fatGoal: fatGoal,
            timestamp: Date()
        )
        
        // Check if there's an existing activity
        if let existingActivity = Activity<NutritionActivityAttributes>.activities.first {
            // Update existing activity
            Task {
                let content = ActivityContent(state: contentState, staleDate: nil)
                await existingActivity.update(content)
                print("✅ [LiveActivity] Updated existing activity")
            }
        } else {
            // Start new activity
            do {
                let activity = try Activity<NutritionActivityAttributes>.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil),
                    pushType: nil
                )
                print("✅ [LiveActivity] Started new activity: \(activity.id)")
            } catch {
                print("🔴 [LiveActivity] Failed to start activity: \(error.localizedDescription)")
            }
        }
    }
    
    /// End the Live Activity
    @available(iOS 16.1, *)
    func endActivity() {
        guard let activity = Activity<NutritionActivityAttributes>.activities.first else {
            return
        }
        
        Task {
            // Use the current content state from the activity
            let currentContent = ActivityContent(state: activity.content.state, staleDate: nil)
            await activity.end(currentContent, dismissalPolicy: .immediate)
            print("✅ [LiveActivity] Ended activity")
        }
    }
    
    /// End all activities (cleanup)
    @available(iOS 16.1, *)
    func endAllActivities() {
        let activities = Activity<NutritionActivityAttributes>.activities
        for activity in activities {
            Task {
                // Use the current content state from the activity
                let currentContent = ActivityContent(state: activity.content.state, staleDate: nil)
                await activity.end(currentContent, dismissalPolicy: .immediate)
            }
        }
        print("✅ [LiveActivity] Ended all activities")
    }
}

