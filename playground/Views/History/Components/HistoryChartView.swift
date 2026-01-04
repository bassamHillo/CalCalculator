//
//  HistoryChartView.swift
//  playground
//
//  Chart view for displaying calorie history
//

import SwiftUI
import Charts

struct HistoryChartView: View {
    let summaries: [DaySummary]
    let timeFilter: HistoryTimeFilter
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var animateChart = false
    
    private var chartData: [ChartDataPoint] {
        summaries.sorted { $0.date < $1.date }.map { summary in
            ChartDataPoint(
                date: summary.date,
                calories: summary.totalCalories
            )
        }
    }
    
    private var averageCalories: Int {
        guard !summaries.isEmpty else { return 0 }
        return summaries.reduce(0) { $0 + $1.totalCalories } / summaries.count
    }
    
    var body: some View {
        let _ = localizationManager.currentLanguage
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.localizedString(for: AppStrings.Progress.calorieTrend))
                            .id("calorie-trend-\(localizationManager.currentLanguage)")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(timeFilter.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Chart
                    if chartData.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No data available")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxHeight: 300)
                        .padding()
                    } else {
                        Chart {
                            // Bar marks for each day
                            ForEach(chartData) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Calories", animateChart ? data.calories : 0)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(4)
                            }
                            
                            // Average line (outside ForEach to avoid duplicate)
                            RuleMark(y: .value("Average", averageCalories))
                                .foregroundStyle(.blue.opacity(0.6))
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: min(7, chartData.count))) { value in
                                AxisGridLine()
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(formatDate(date))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .frame(height: 300)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    
                    // Stats
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Average",
                            value: "\(averageCalories)",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Highest",
                            value: "\(chartData.map { $0.calories }.max() ?? 0)",
                            color: .red
                        )
                        
                        StatCard(
                            title: "Lowest",
                            value: "\(chartData.map { $0.calories }.min() ?? 0)",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle(localizationManager.localizedString(for: AppStrings.Home.summary))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateChart = true
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if chartData.count <= 7 {
            formatter.dateFormat = "MMM d"
        } else if chartData.count <= 30 {
            formatter.dateFormat = "d"
        } else {
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

