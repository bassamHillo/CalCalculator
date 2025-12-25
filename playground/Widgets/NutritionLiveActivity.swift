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
        HStack(spacing: 16) {
            // Left: Calories (Primary focus)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(context.state.caloriesConsumed)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("/ \(context.state.calorieGoal)")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // Compact progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [progressColor, progressColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * min(1.0, context.state.calorieProgress),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
                
                // Remaining calories
                Text("\(context.state.caloriesRemaining) cal remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right: Macros (Compact pills)
            VStack(spacing: 6) {
                CompactMacroPill(
                    label: "P",
                    value: Int(context.state.proteinG),
                    goal: Int(context.state.proteinGoal),
                    color: .blue
                )
                CompactMacroPill(
                    label: "C",
                    value: Int(context.state.carbsG),
                    goal: Int(context.state.carbsGoal),
                    color: .orange
                )
                CompactMacroPill(
                    label: "F",
                    value: Int(context.state.fatG),
                    goal: Int(context.state.fatGoal),
                    color: .green
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var progressColor: Color {
        let progress = context.state.calorieProgress
        if progress <= 0.5 {
            return .blue
        } else if progress <= 0.75 {
            return .green
        } else if progress <= 1.0 {
            return .orange
        } else if progress <= 1.1 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Compact Macro Pill

private struct CompactMacroPill: View {
    let label: String
    let value: Int
    let goal: Int
    let color: Color
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(value) / Double(goal))
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Label
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 16)
            
            // Value/Goal
            Text("\(value)/\(goal)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            // Mini progress indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(height: 3)
                    
                    Capsule()
                        .fill(color)
                        .frame(
                            width: geometry.size.width * progress,
                            height: 3
                        )
                }
            }
            .frame(width: 30, height: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(value) / Double(goal))
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                Text("\(value)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(color)
            
            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.2))
                        .frame(height: 2)
                    
                    Capsule()
                        .fill(color)
                        .frame(
                            width: geometry.size.width * progress,
                            height: 2
                        )
                }
            }
            .frame(height: 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

