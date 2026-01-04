//
//  WeightChartCard.swift
//  playground
//
//  Weight Chart card displaying weight trend over time
//

import SwiftUI
import Charts

struct WeightChartCard: View {
    let weightHistory: [WeightDataPoint]
    let useMetricUnits: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var displayWeights: [WeightDataPoint] {
        let convertedHistory: [WeightDataPoint] = useMetricUnits ? weightHistory : weightHistory.map { point in
            WeightDataPoint(date: point.date, weight: point.weight * 2.20462, note: point.note)
        }
        
        guard !convertedHistory.isEmpty else { return [] }
        
        let sortedHistory = convertedHistory.sorted { $0.date < $1.date }
        
        var weightByDay: [Date: WeightDataPoint] = [:]
        for point in sortedHistory {
            let dayStart = Calendar.current.startOfDay(for: point.date)
            if let existing = weightByDay[dayStart] {
                if point.date > existing.date {
                    weightByDay[dayStart] = point
                }
            } else {
                weightByDay[dayStart] = point
            }
        }
        
        var changeEvents = weightByDay.values.sorted { $0.date < $1.date }
        
        if changeEvents.count == 1 {
            let singlePoint = changeEvents[0]
            let today = Calendar.current.startOfDay(for: Date())
            let singlePointDay = Calendar.current.startOfDay(for: singlePoint.date)
            
            if singlePointDay < today {
                changeEvents.append(WeightDataPoint(date: today, weight: singlePoint.weight, note: nil))
            } else if singlePointDay == today {
                if let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today) {
                    changeEvents.insert(WeightDataPoint(date: weekAgo, weight: singlePoint.weight, note: nil), at: 0)
                }
            }
        }
        
        return changeEvents.sorted { $0.date < $1.date }
    }
    
    private var minWeight: Double {
        let weights = displayWeights.map(\.weight)
        guard let minValue = weights.min(), let maxValue = weights.max() else { return 0 }
        let range = maxValue - minValue
        
        // RULE 3: Force biased Y-scale - more aggressive upward bias
        if range == 0 || range < 0.1 {
            // For flat data: value - 2.0 (much more space below, pushes line up)
            return Swift.max(0, minValue - 2.0)
        } else {
            // For varied data, use proportional padding but keep it tight
            let padding = min(range * 0.1, 2.0)
            return Swift.max(0, minValue - padding)
        }
    }
    
    private var maxWeight: Double {
        let weights = displayWeights.map(\.weight)
        guard let minValue = weights.min(), let maxValue = weights.max() else { return 100 }
        let range = maxValue - minValue
        
        // RULE 3: Force biased Y-scale - more aggressive upward bias
        if range == 0 || range < 0.1 {
            // For flat data: value + 0.3 (less space above)
            return maxValue + 0.3
        } else {
            // For varied data, use proportional padding but keep it tight
            let padding = min(range * 0.1, 2.0)
            return maxValue + padding
        }
    }
    
    // Detect if data is stable (all values are the same)
    private var isStable: Bool {
        let weights = displayWeights.map(\.weight)
        guard !weights.isEmpty, let firstWeight = weights.first else { return false }
        return weights.allSatisfy { abs($0 - firstWeight) < 0.1 }
    }
    
    private var stableWeight: Double {
        displayWeights.first?.weight ?? 0
    }
    
    private var titleText: String {
        localizationManager.localizedString(for: AppStrings.Progress.weightChart)
    }
    
    private var noWeightDataText: String {
        localizationManager.localizedString(for: AppStrings.Progress.noWeightData)
    }
    
    private var saveWeightToSeeProgressText: String {
        localizationManager.localizedString(for: AppStrings.Progress.saveWeightToSeeProgress)
    }
    
    var body: some View {
        let weights = displayWeights
        let isEmpty = weights.isEmpty || weights.allSatisfy({ $0.weight == 0 })
        
        return VStack(alignment: .leading, spacing: 12) {
            Text(titleText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            if isEmpty {
                VStack(spacing: 8) {
                    Text(noWeightDataText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(saveWeightToSeeProgressText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if isStable {
                // STABLE STATE: Render a status indicator, NOT a chart
                StableWeightView(
                    value: stableWeight,
                    unit: useMetricUnits ? "kg" : "lbs"
                )
            } else {
                // TREND STATE: Render the actual chart
                TrendChartView(
                    weights: weights,
                    useMetricUnits: useMetricUnits,
                    minWeight: minWeight,
                    maxWeight: maxWeight
                )
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Stable State Mini-Chart (chart language, not progress bar)
struct StableWeightView: View {
    let value: Double
    let unit: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var stableText: String {
        String(format: "%.1f %@ · %@", value, unit, localizationManager.localizedString(for: AppStrings.Progress.stableThisPeriod))
    }
    
    private var startText: String {
        localizationManager.localizedString(for: AppStrings.Progress.start)
    }
    
    private var nowText: String {
        localizationManager.localizedString(for: AppStrings.Progress.now)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(stableText)
                .font(.callout)
                .foregroundStyle(.secondary)
            
            // MINI PLOT AREA (this is what makes it a chart, not a bar)
            ZStack(alignment: .center) {
                // Faint baseline (optional, adds chart context)
                Capsule()
                    .fill(Color.black.opacity(0.04))
                    .frame(height: 2)
                
                // Glow behind the line (halo effect)
                Capsule()
                    .fill(Color.blue.opacity(0.18))
                    .frame(height: 10)
                    .blur(radius: 6)
                    .padding(.horizontal, 10)
                
                // Main line (thin, chart-like)
                Capsule()
                    .fill(Color.blue)
                    .frame(height: 3)
                    .padding(.horizontal, 10)
                
                // Endpoints (dots at start and end)
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Spacer()
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
                .padding(.horizontal, 10)
            }
            .frame(height: 22)
            
            // Tiny time anchors (makes it read as chart with time context)
            HStack {
                Text(startText)
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.7))
                Spacer()
                Text(nowText)
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

// MARK: - Trend Chart (only used when data actually changes)
struct TrendChartView: View {
    let weights: [WeightDataPoint]
    let useMetricUnits: Bool
    let minWeight: Double
    let maxWeight: Double
    
    var body: some View {
        let sortedWeights = weights.sorted { $0.date < $1.date }
        let firstPoint = sortedWeights.first
        let lastPoint = sortedWeights.last
        
        Chart(sortedWeights) { point in
            // Glow line (behind)
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .interpolationMethod(.linear)
            .lineStyle(StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
            .foregroundStyle(Color.blue.opacity(0.18))
            
            // Main line (front)
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .interpolationMethod(.linear)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .foregroundStyle(Color.blue)
            
            // Dots at first and last points
            if point.date == firstPoint?.date || point.date == lastPoint?.date {
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Color.blue.opacity(0.9))
                .symbolSize(30)
            }
        }
        .chartYScale(domain: minWeight...maxWeight)
        .chartPlotStyle { plotContent in
            plotContent
                .padding(.top, 28)
                .padding(.bottom, 36)
                .padding(.horizontal, 12)
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                    .foregroundStyle(Color.clear)
                AxisValueLabel()
                    .foregroundStyle(Color.clear)
            }
        }
        .frame(height: 160)
    }
}

#Preview {
    let sampleData = [
        WeightDataPoint(date: Calendar.current.date(byAdding: .month, value: -8, to: Date())!, weight: 70.0),
        WeightDataPoint(date: Calendar.current.date(byAdding: .month, value: -6, to: Date())!, weight: 65.0),
        WeightDataPoint(date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!, weight: 57.5),
        WeightDataPoint(date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, weight: 55.0),
        WeightDataPoint(date: Date(), weight: 54.7)
    ]
    
    WeightChartCard(
        weightHistory: sampleData,
        useMetricUnits: true
    )
    .padding()
}
