//
//  NutritionLiveActivity.swift
//  CalCalculator
//
//  Live Activity widget for Lock Screen and Dynamic Island
//

#if canImport(ActivityKit)
import ActivityKit
#endif
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct NutritionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NutritionActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calories")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(context.state.caloriesConsumed)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("/ \(context.state.calorieGoal)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        LiveActivityCircularProgressView(
                            progress: context.state.calorieProgress,
                            size: 44
                        )
                        Text("\(context.state.caloriesRemaining) left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        LiveActivityMacroPill(
                            name: "P",
                            value: Int(context.state.proteinG),
                            goal: Int(context.state.proteinGoal),
                            color: .blue
                        )
                        LiveActivityMacroPill(
                            name: "C",
                            value: Int(context.state.carbsG),
                            goal: Int(context.state.carbsGoal),
                            color: .orange
                        )
                        LiveActivityMacroPill(
                            name: "F",
                            value: Int(context.state.fatG),
                            goal: Int(context.state.fatGoal),
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                // Compact leading UI
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            } compactTrailing: {
                // Compact trailing UI
                Text("\(context.state.caloriesConsumed)/\(context.state.calorieGoal)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            } minimal: {
                // Minimal UI (Dynamic Island only)
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<NutritionActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Daily Nutrition")
                    .font(.headline)
                Spacer()
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Calories Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(context.state.caloriesConsumed)")
                        .font(.system(size: 32, weight: .bold))
                    Text("/ \(context.state.calorieGoal) cal")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(context.state.caloriesRemaining) left")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(progressColor)
                            .frame(
                                width: geometry.size.width * min(1.0, context.state.calorieProgress),
                                height: 8
                            )
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
            
            // Macros
            HStack(spacing: 12) {
                MacroView(
                    name: "Protein",
                    value: Int(context.state.proteinG),
                    goal: Int(context.state.proteinGoal),
                    color: .blue
                )
                MacroView(
                    name: "Carbs",
                    value: Int(context.state.carbsG),
                    goal: Int(context.state.carbsGoal),
                    color: .orange
                )
                MacroView(
                    name: "Fat",
                    value: Int(context.state.fatG),
                    goal: Int(context.state.fatGoal),
                    color: .green
                )
            }
        }
        .padding()
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: context.state.timestamp)
    }
    
    private var progressColor: Color {
        let progress = context.state.calorieProgress
        if progress <= 1.0 {
            return .green
        } else if progress <= 1.1 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Supporting Views

struct MacroView: View {
    let name: String
    let value: Int
    let goal: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text("/ \(goal)g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LiveActivityMacroPill: View {
    let name: String
    let value: Int
    let goal: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.caption2)
                .fontWeight(.semibold)
            Text("\(value)")
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

private struct LiveActivityCircularProgressView: View {
    let progress: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
    
    private var progressColor: Color {
        if progress <= 1.0 {
            return .green
        } else if progress <= 1.1 {
            return .yellow
        } else {
            return .red
        }
    }
}

