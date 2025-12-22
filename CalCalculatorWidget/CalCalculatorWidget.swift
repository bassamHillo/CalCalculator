//
//  CalCalculatorWidget.swift
//  CalCalculatorWidget
//
//  Main widget implementations for CalCalculator
//

import WidgetKit
import SwiftUI

// MARK: - Widget Data Entry

/// Main entry for widget timeline containing all nutrition data
struct NutritionEntry: TimelineEntry {
    let date: Date
    let caloriesConsumed: Int
    let caloriesGoal: Int
    let proteinConsumed: Double
    let proteinGoal: Double
    let carbsConsumed: Double
    let carbsGoal: Double
    let fatConsumed: Double
    let fatGoal: Double
    let mealCount: Int
    let lastMealName: String?
    let lastMealTime: Date?
    let weeklyData: [DailyData]
    
    // Computed properties
    var caloriesRemaining: Int {
        max(0, caloriesGoal - caloriesConsumed)
    }
    
    var caloriesProgress: Double {
        guard caloriesGoal > 0 else { return 0 }
        return Double(caloriesConsumed) / Double(caloriesGoal)
    }
    
    var proteinProgress: Double {
        guard proteinGoal > 0 else { return 0 }
        return proteinConsumed / proteinGoal
    }
    
    var carbsProgress: Double {
        guard carbsGoal > 0 else { return 0 }
        return carbsConsumed / carbsGoal
    }
    
    var fatProgress: Double {
        guard fatGoal > 0 else { return 0 }
        return fatConsumed / fatGoal
    }
    
    var isOverGoal: Bool {
        caloriesConsumed > caloriesGoal
    }
    
    var caloriesOverage: Int {
        max(0, caloriesConsumed - caloriesGoal)
    }
    
    // Static placeholder for preview
    static var placeholder: NutritionEntry {
        NutritionEntry(
            date: Date(),
            caloriesConsumed: 1450,
            caloriesGoal: 2000,
            proteinConsumed: 95,
            proteinGoal: 150,
            carbsConsumed: 180,
            carbsGoal: 250,
            fatConsumed: 45,
            fatGoal: 65,
            mealCount: 3,
            lastMealName: "Grilled Chicken Salad",
            lastMealTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
            weeklyData: DailyData.sampleWeek
        )
    }
    
    static var empty: NutritionEntry {
        NutritionEntry(
            date: Date(),
            caloriesConsumed: 0,
            caloriesGoal: 2000,
            proteinConsumed: 0,
            proteinGoal: 150,
            carbsConsumed: 0,
            carbsGoal: 250,
            fatConsumed: 0,
            fatGoal: 65,
            mealCount: 0,
            lastMealName: nil,
            lastMealTime: nil,
            weeklyData: []
        )
    }
}

// MARK: - Daily Data for Weekly View

struct DailyData: Identifiable {
    let id = UUID()
    let date: Date
    let caloriesConsumed: Int
    let caloriesGoal: Int
    
    var progress: Double {
        guard caloriesGoal > 0 else { return 0 }
        return min(Double(caloriesConsumed) / Double(caloriesGoal), 1.5)
    }
    
    var dayAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    static var sampleWeek: [DailyData] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let consumed = daysAgo == 0 ? 1450 : Int.random(in: 1600...2200)
            return DailyData(
                date: date,
                caloriesConsumed: consumed,
                caloriesGoal: 2000
            )
        }
    }
}

// MARK: - Shared UserDefaults Keys for App Group

struct WidgetDataKeys {
    static let appGroupIdentifier = "group.com.calcalculator.shared"
    
    static let caloriesConsumed = "widget_calories_consumed"
    static let caloriesGoal = "widget_calories_goal"
    static let proteinConsumed = "widget_protein_consumed"
    static let proteinGoal = "widget_protein_goal"
    static let carbsConsumed = "widget_carbs_consumed"
    static let carbsGoal = "widget_carbs_goal"
    static let fatConsumed = "widget_fat_consumed"
    static let fatGoal = "widget_fat_goal"
    static let mealCount = "widget_meal_count"
    static let lastMealName = "widget_last_meal_name"
    static let lastMealTime = "widget_last_meal_time"
    static let lastUpdateDate = "widget_last_update_date"
}

// MARK: - Widget Data Provider

struct WidgetDataProvider {
    private let userDefaults: UserDefaults?
    
    init() {
        self.userDefaults = UserDefaults(suiteName: WidgetDataKeys.appGroupIdentifier)
    }
    
    func loadData() -> NutritionEntry {
        guard let defaults = userDefaults else {
            return NutritionEntry.placeholder
        }
        
        // Check if data is from today
        if let lastUpdate = defaults.object(forKey: WidgetDataKeys.lastUpdateDate) as? Date,
           !Calendar.current.isDateInToday(lastUpdate) {
            return NutritionEntry.empty
        }
        
        let caloriesGoal = defaults.integer(forKey: WidgetDataKeys.caloriesGoal)
        let proteinGoal = defaults.double(forKey: WidgetDataKeys.proteinGoal)
        let carbsGoal = defaults.double(forKey: WidgetDataKeys.carbsGoal)
        let fatGoal = defaults.double(forKey: WidgetDataKeys.fatGoal)
        
        return NutritionEntry(
            date: Date(),
            caloriesConsumed: defaults.integer(forKey: WidgetDataKeys.caloriesConsumed),
            caloriesGoal: caloriesGoal > 0 ? caloriesGoal : 2000,
            proteinConsumed: defaults.double(forKey: WidgetDataKeys.proteinConsumed),
            proteinGoal: proteinGoal > 0 ? proteinGoal : 150,
            carbsConsumed: defaults.double(forKey: WidgetDataKeys.carbsConsumed),
            carbsGoal: carbsGoal > 0 ? carbsGoal : 250,
            fatConsumed: defaults.double(forKey: WidgetDataKeys.fatConsumed),
            fatGoal: fatGoal > 0 ? fatGoal : 65,
            mealCount: defaults.integer(forKey: WidgetDataKeys.mealCount),
            lastMealName: defaults.string(forKey: WidgetDataKeys.lastMealName),
            lastMealTime: defaults.object(forKey: WidgetDataKeys.lastMealTime) as? Date,
            weeklyData: DailyData.sampleWeek
        )
    }
}

// MARK: - Timeline Provider

struct NutritionTimelineProvider: TimelineProvider {
    typealias Entry = NutritionEntry
    
    let dataProvider = WidgetDataProvider()
    
    func placeholder(in context: Context) -> NutritionEntry {
        NutritionEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NutritionEntry) -> Void) {
        let entry = context.isPreview ? NutritionEntry.placeholder : dataProvider.loadData()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NutritionEntry>) -> Void) {
        let entry = dataProvider.loadData()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Theme Colors

struct WidgetColors {
    static let primary = Color(red: 0.4, green: 0.8, blue: 0.4) // Fresh green
    static let secondary = Color(red: 0.3, green: 0.7, blue: 0.9) // Sky blue
    static let accent = Color(red: 1.0, green: 0.6, blue: 0.2) // Orange
    static let warning = Color(red: 1.0, green: 0.4, blue: 0.4) // Soft red
    
    static let proteinColor = Color(red: 1.0, green: 0.55, blue: 0.0) // Vibrant orange
    static let carbsColor = Color(red: 0.2, green: 0.6, blue: 1.0) // Bright blue
    static let fatColor = Color(red: 0.7, green: 0.4, blue: 0.9) // Purple
    static let caloriesGradient = LinearGradient(
        colors: [Color(red: 0.4, green: 0.85, blue: 0.5), Color(red: 0.2, green: 0.7, blue: 0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let overGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.5, blue: 0.4), Color(red: 0.9, green: 0.3, blue: 0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Small Widget View (Calories Progress Ring)

struct SmallCaloriesWidgetView: View {
    let entry: NutritionEntry
    
    private var progressGradient: LinearGradient {
        if entry.isOverGoal {
            return WidgetColors.overGradient
        } else if entry.caloriesProgress >= 0.8 {
            return WidgetColors.caloriesGradient
        } else {
            return LinearGradient(
                colors: [WidgetColors.secondary, WidgetColors.secondary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var statusText: String {
        if entry.isOverGoal {
            return "+\(entry.caloriesOverage) over"
        } else {
            return "\(entry.caloriesRemaining) left"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let ringSize = size * 0.7
            let lineWidth = size * 0.09
            
            VStack(spacing: size * 0.03) {
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)
                    
                    // Progress ring with gradient
                    Circle()
                        .trim(from: 0, to: min(entry.caloriesProgress, 1.0))
                        .stroke(
                            progressGradient,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: entry.isOverGoal ? Color.red.opacity(0.3) : Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    // Center content
                    VStack(spacing: 0) {
                        Text("\(entry.caloriesConsumed)")
                            .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.isOverGoal ? WidgetColors.warning : .primary)
                        
                        Text("of \(entry.caloriesGoal)")
                            .font(.system(size: size * 0.07, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: ringSize, height: ringSize)
                
                // Status text with icon
                HStack(spacing: 3) {
                    Image(systemName: entry.isOverGoal ? "exclamationmark.triangle.fill" : "flame.fill")
                        .font(.system(size: size * 0.06))
                        .foregroundStyle(entry.isOverGoal ? WidgetColors.warning : WidgetColors.primary)
                    
                    Text(statusText)
                        .font(.system(size: size * 0.08, weight: .semibold, design: .rounded))
                        .foregroundStyle(entry.isOverGoal ? WidgetColors.warning : .secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Medium Widget View (Macros Overview)

struct MediumMacrosWidgetView: View {
    let entry: NutritionEntry
    
    private var caloriesGradient: LinearGradient {
        entry.isOverGoal ? WidgetColors.overGradient : WidgetColors.caloriesGradient
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 16) {
                // Left side - Calories ring
                VStack(spacing: 6) {
                    ZStack {
                        // Background
                        Circle()
                            .stroke(Color.gray.opacity(0.12), lineWidth: 10)
                        
                        // Progress
                        Circle()
                            .trim(from: 0, to: min(entry.caloriesProgress, 1.0))
                            .stroke(caloriesGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .shadow(color: entry.isOverGoal ? Color.red.opacity(0.25) : Color.green.opacity(0.25), radius: 4)
                        
                        VStack(spacing: 0) {
                            Text("\(entry.caloriesConsumed)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text("kcal")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 85, height: 85)
                    
                    // Status badge
                    HStack(spacing: 3) {
                        Image(systemName: entry.isOverGoal ? "arrow.up.circle.fill" : "flame.fill")
                            .font(.system(size: 8))
                        Text(entry.isOverGoal ? "+\(entry.caloriesOverage)" : "\(entry.caloriesRemaining) left")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(entry.isOverGoal ? WidgetColors.warning : WidgetColors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill((entry.isOverGoal ? WidgetColors.warning : WidgetColors.primary).opacity(0.12))
                    )
                }
                .frame(width: geometry.size.width * 0.38)
                
                // Right side - Macro bars
                VStack(spacing: 10) {
                    ModernMacroBar(
                        title: "Protein",
                        value: entry.proteinConsumed,
                        goal: entry.proteinGoal,
                        color: WidgetColors.proteinColor
                    )
                    ModernMacroBar(
                        title: "Carbs",
                        value: entry.carbsConsumed,
                        goal: entry.carbsGoal,
                        color: WidgetColors.carbsColor
                    )
                    ModernMacroBar(
                        title: "Fat",
                        value: entry.fatConsumed,
                        goal: entry.fatGoal,
                        color: WidgetColors.fatColor
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
}

struct ModernMacroBar: View {
    let title: String
    let value: Double
    let goal: Double
    let color: Color
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("/ \(Int(goal))g")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.12))
                    
                    // Progress with gradient
                    RoundedRectangle(cornerRadius: 4)
                        .fill(gradient)
                        .frame(width: geometry.size.width * progress)
                        .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            .frame(height: 7)
        }
    }
}

// MARK: - Large Widget View (Weekly Summary)

struct LargeWeeklyWidgetView: View {
    let entry: NutritionEntry
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Progress")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(Date(), style: .date)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Today's calories badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.caloriesConsumed)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(entry.isOverGoal ? WidgetColors.warning : WidgetColors.primary)
                    Text("kcal today")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Weekly chart
            HStack(spacing: 6) {
                ForEach(entry.weeklyData) { day in
                    ModernWeeklyDayBar(data: day)
                }
            }
            .padding(.horizontal, 16)
            
            // Divider with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.05), Color.gray.opacity(0.15), Color.gray.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // Macro circles row
            HStack(spacing: 20) {
                ModernMacroCircle(title: "Protein", value: entry.proteinConsumed, goal: entry.proteinGoal, color: WidgetColors.proteinColor)
                ModernMacroCircle(title: "Carbs", value: entry.carbsConsumed, goal: entry.carbsGoal, color: WidgetColors.carbsColor)
                ModernMacroCircle(title: "Fat", value: entry.fatConsumed, goal: entry.fatGoal, color: WidgetColors.fatColor)
                ModernMacroCircle(title: "Calories", value: Double(entry.caloriesConsumed), goal: Double(entry.caloriesGoal), color: entry.isOverGoal ? WidgetColors.warning : WidgetColors.primary)
            }
            .padding(.horizontal, 16)
            
            // Last meal info
            if let mealName = entry.lastMealName, let mealTime = entry.lastMealTime {
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(WidgetColors.accent)
                    
                    Text(mealName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(mealTime, style: .time)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(10)
                .padding(.horizontal, 12)
            }
            
            Spacer(minLength: 8)
        }
    }
}

struct ModernWeeklyDayBar: View {
    let data: DailyData
    
    private var barGradient: LinearGradient {
        let color: Color
        if data.progress > 1.0 {
            color = WidgetColors.warning
        } else if data.progress >= 0.8 {
            color = WidgetColors.primary
        } else if data.progress >= 0.5 {
            color = WidgetColors.accent
        } else {
            color = WidgetColors.secondary.opacity(0.7)
        }
        
        return LinearGradient(
            colors: [color, color.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 5)
                        .fill(barGradient)
                        .frame(height: geometry.size.height * min(data.progress, 1.0))
                        .shadow(color: data.isToday ? Color.black.opacity(0.1) : .clear, radius: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(data.isToday ? Color.primary.opacity(0.3) : .clear, lineWidth: 1.5)
                        )
                }
            }
            .frame(height: 55)
            
            Text(data.dayAbbreviation)
                .font(.system(size: 10, weight: data.isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(data.isToday ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ModernMacroCircle: View {
    let title: String
    let value: Double
    let goal: Double
    let color: Color
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.3), radius: 2)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .frame(width: 42, height: 42)
            
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Quick Log Widget View

struct QuickLogWidgetView: View {
    let entry: NutritionEntry
    
    private var progressGradient: LinearGradient {
        entry.isOverGoal ? WidgetColors.overGradient : WidgetColors.caloriesGradient
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Top section
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(entry.caloriesConsumed)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(entry.isOverGoal ? WidgetColors.warning : .primary)
                    
                    Text("of \(entry.caloriesGoal) kcal")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.12), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: min(entry.caloriesProgress, 1.0))
                        .stroke(progressGradient, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(min(entry.caloriesProgress, 1.0) * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .frame(width: 55, height: 55)
            }
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
            
            // Quick action buttons
            HStack(spacing: 10) {
                ModernQuickActionButton(icon: "camera.fill", title: "Scan", color: WidgetColors.secondary, action: "scan")
                ModernQuickActionButton(icon: "plus.circle.fill", title: "Add", color: WidgetColors.primary, action: "add")
                ModernQuickActionButton(icon: "chart.bar.fill", title: "History", color: WidgetColors.fatColor, action: "history")
            }
        }
        .padding(14)
    }
}

struct ModernQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: String
    
    var body: some View {
        Link(destination: URL(string: "calcalculator://action/\(action)")!) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Compact Macros Widget (Extra Large)

struct CompactMacrosWidgetView: View {
    let entry: NutritionEntry
    
    private var progressGradient: LinearGradient {
        entry.isOverGoal ? WidgetColors.overGradient : WidgetColors.caloriesGradient
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(WidgetColors.accent)
                        Text("Today's Nutrition")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(entry.caloriesConsumed)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.isOverGoal ? WidgetColors.warning : .primary)
                        
                        Text("/ \(entry.caloriesGoal) kcal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: entry.isOverGoal ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 11))
                        Text(entry.isOverGoal ? "\(entry.caloriesOverage) over goal" : "\(entry.caloriesRemaining) remaining")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(entry.isOverGoal ? WidgetColors.warning : WidgetColors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((entry.isOverGoal ? WidgetColors.warning : WidgetColors.primary).opacity(0.12))
                    )
                }
                
                Spacer()
                
                // Large progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: min(entry.caloriesProgress, 1.0))
                        .stroke(progressGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: entry.isOverGoal ? Color.red.opacity(0.2) : Color.green.opacity(0.2), radius: 4)
                    
                    VStack(spacing: 0) {
                        Text("\(Int(min(entry.caloriesProgress, 1.0) * 100))")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 90, height: 90)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            // Macro bars
            VStack(spacing: 8) {
                CompactMacroBar(title: "Protein", value: entry.proteinConsumed, goal: entry.proteinGoal, color: WidgetColors.proteinColor)
                CompactMacroBar(title: "Carbs", value: entry.carbsConsumed, goal: entry.carbsGoal, color: WidgetColors.carbsColor)
                CompactMacroBar(title: "Fat", value: entry.fatConsumed, goal: entry.fatGoal, color: WidgetColors.fatColor)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }
}

struct CompactMacroBar: View {
    let title: String
    let value: Double
    let goal: Double
    let color: Color
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
    
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.9), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(value))g / \(Int(goal))g")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(gradient)
                        .frame(width: geometry.size.width * progress)
                        .shadow(color: color.opacity(0.25), radius: 2, x: 0, y: 1)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Accessory Widgets (Lock Screen) - iOS 16+

#if os(iOS)
@available(iOSApplicationExtension 16.0, *)
struct AccessoryCircularView: View {
    let entry: NutritionEntry
    
    var body: some View {
        Gauge(value: min(entry.caloriesProgress, 1.0)) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(entry.caloriesConsumed)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

@available(iOSApplicationExtension 16.0, *)
struct AccessoryRectangularView: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack(spacing: 10) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: min(entry.caloriesProgress, 1.0))
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
            }
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("\(entry.caloriesConsumed) / \(entry.caloriesGoal)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                
                HStack(spacing: 8) {
                    Label("\(Int(entry.proteinConsumed))g", systemImage: "p.circle.fill")
                    Label("\(Int(entry.carbsConsumed))g", systemImage: "c.circle.fill")
                    Label("\(Int(entry.fatConsumed))g", systemImage: "f.circle.fill")
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
            }
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct AccessoryInlineView: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("\(entry.caloriesConsumed)/\(entry.caloriesGoal) kcal")
                .font(.system(.body, design: .rounded))
        }
    }
}
#endif

// MARK: - Main Widgets

struct CaloriesSmallWidget: Widget {
    let kind: String = "CaloriesSmallWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionTimelineProvider()) { entry in
            SmallCaloriesWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Calories Progress")
        .description("Track your daily calorie intake with a beautiful progress ring.")
        .supportedFamilies([.systemSmall])
    }
}

struct MacrosMediumWidget: Widget {
    let kind: String = "MacrosMediumWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionTimelineProvider()) { entry in
            MediumMacrosWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Macros")
        .description("View your calories and macronutrient progress at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

struct WeeklyLargeWidget: Widget {
    let kind: String = "WeeklyLargeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionTimelineProvider()) { entry in
            LargeWeeklyWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Weekly Summary")
        .description("Track your weekly calorie trends and today's macros.")
        .supportedFamilies([.systemLarge])
    }
}

struct QuickLogWidget: Widget {
    let kind: String = "QuickLogWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionTimelineProvider()) { entry in
            QuickLogWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Log")
        .description("Quickly log meals and view your progress.")
        .supportedFamilies([.systemMedium])
    }
}

struct CompactMacrosWidget: Widget {
    let kind: String = "CompactMacrosWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionTimelineProvider()) { entry in
            CompactMacrosWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Full Nutrition")
        .description("Comprehensive view of your daily nutrition progress.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#if os(iOS)
@available(iOSApplicationExtension 16.0, *)
struct CaloriesAccessoryWidget: Widget {
    let kind: String = "CaloriesAccessoryWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionTimelineProvider()) { entry in
            AccessoryCircularView(entry: entry)
        }
        .configurationDisplayName("Calories Ring")
        .description("Quick calorie progress for your Lock Screen.")
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct MacrosAccessoryWidget: Widget {
    let kind: String = "MacrosAccessoryWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionTimelineProvider()) { entry in
            AccessoryRectangularView(entry: entry)
        }
        .configurationDisplayName("Macros Overview")
        .description("Compact view of your daily macros for Lock Screen.")
        .supportedFamilies([.accessoryRectangular])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct CaloriesInlineWidget: Widget {
    let kind: String = "CaloriesInlineWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionTimelineProvider()) { entry in
            AccessoryInlineView(entry: entry)
        }
        .configurationDisplayName("Calories Inline")
        .description("Inline calorie counter for Lock Screen.")
        .supportedFamilies([.accessoryInline])
    }
}
#endif

// MARK: - Legacy Widget (backward compatibility)

struct CalCalculatorWidget: Widget {
    let kind: String = "CalCalculatorWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutritionTimelineProvider()) { entry in
            SmallCaloriesWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("CalCalculator")
        .description("Track your daily calorie intake.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Previews

#Preview("Small", as: .systemSmall) {
    CaloriesSmallWidget()
} timeline: {
    NutritionEntry.placeholder
}

#Preview("Medium Macros", as: .systemMedium) {
    MacrosMediumWidget()
} timeline: {
    NutritionEntry.placeholder
}

#Preview("Large Weekly", as: .systemLarge) {
    WeeklyLargeWidget()
} timeline: {
    NutritionEntry.placeholder
}

#Preview("Quick Log", as: .systemMedium) {
    QuickLogWidget()
} timeline: {
    NutritionEntry.placeholder
}

#Preview("Compact Macros", as: .systemMedium) {
    CompactMacrosWidget()
} timeline: {
    NutritionEntry.placeholder
}
