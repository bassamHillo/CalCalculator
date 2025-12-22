//
//  SettingsView.swift
//  playground
//
//  CalAI Clone - Settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @Bindable var settings = UserSettings.shared
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingExportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var exportData: Data?
    
    /// Callback to notify parent when data is deleted
    var onDataDeleted: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    macroGoalsSection
                    unitsSection
                    dataManagementSection
                    aboutSection
                }
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Delete All Data",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                deleteConfirmationActions
            } message: {
                deleteConfirmationMessage
            }
            .sheet(isPresented: $showingExportSheet) {
                exportSheet
            }
        }
    }
    
    // MARK: - Private Views
    
    private var macroGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Daily Goals", subtitle: "Adjust your daily nutritional targets")
            
            VStack(spacing: 12) {
                macroGoalCard(
                    title: "Calories",
                    icon: "flame.fill",
                    value: settings.calorieGoal,
                    unit: "",
                    color: .caloriesColor,
                    range: 1000...5000,
                    step: 50,
                    binding: $settings.calorieGoal
                )
                
                macroGoalCard(
                    title: "Protein",
                    icon: "p.circle.fill",
                    value: settings.proteinGoal,
                    unit: "g",
                    color: .proteinColor,
                    range: 10...300,
                    step: 5,
                    binding: $settings.proteinGoal
                )
                
                macroGoalCard(
                    title: "Carbs",
                    icon: "c.circle.fill",
                    value: settings.carbsGoal,
                    unit: "g",
                    color: .carbsColor,
                    range: 10...500,
                    step: 5,
                    binding: $settings.carbsGoal
                )
                
                macroGoalCard(
                    title: "Fat",
                    icon: "f.circle.fill",
                    value: settings.fatGoal,
                    unit: "g",
                    color: .fatColor,
                    range: 10...200,
                    step: 5,
                    binding: $settings.fatGoal
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func macroGoalCard(
        title: String,
        icon: String,
        value: Double,
        unit: String,
        color: Color,
        range: ClosedRange<Double>,
        step: Double,
        binding: Binding<Double>
    ) -> some View {
        HStack(spacing: 16) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Title and value
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value.formattedMacro)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Stepper
            Stepper("", value: binding, in: range, step: step)
                .labelsHidden()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // Overload for Int (calories)
    private func macroGoalCard(
        title: String,
        icon: String,
        value: Int,
        unit: String,
        color: Color,
        range: ClosedRange<Int>,
        step: Int,
        binding: Binding<Int>
    ) -> some View {
        HStack(spacing: 16) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Title and value
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(value)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Stepper
            Stepper("", value: binding, in: range, step: step)
                .labelsHidden()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Units", subtitle: "Use grams and milliliters for portions")
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "ruler")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Metric Units")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(settings.useMetricUnits ? "kg, g, cm, ml" : "lbs, oz, ft, fl oz")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.useMetricUnits)
                    .labelsHidden()
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 16)
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Data Management", subtitle: "Export or delete your data")
            
            VStack(spacing: 12) {
                actionButton(
                    title: "Export Data",
                    subtitle: "Save your data as JSON",
                    icon: "square.and.arrow.up",
                    iconColor: .blue,
                    action: exportDataAction
                )
                
                actionButton(
                    title: "Delete All Data",
                    subtitle: "Permanently remove all meals and history",
                    icon: "trash",
                    iconColor: .red,
                    isDestructive: true,
                    action: { showingDeleteConfirmation = true }
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "About", subtitle: "CalAI Clone - Photo-based calorie tracking")
            
            VStack(spacing: 12) {
                infoRow(
                    title: "Version",
                    value: "1.0.0",
                    icon: "info.circle",
                    iconColor: .blue
                )
                
                infoRow(
                    title: "Mode",
                    value: "Real API",
                    icon: "network",
                    iconColor: .green
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func infoRow(
        title: String,
        value: String,
        icon: String,
        iconColor: Color
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var deleteConfirmationActions: some View {
        Button("Delete All", role: .destructive) {
            Task {
                await viewModel.deleteAllData()
                onDataDeleted?()
            }
        }
        Button("Cancel", role: .cancel) {}
    }
    
    private var deleteConfirmationMessage: some View {
        Text("This will permanently delete all your meals, history, and saved photos. This action cannot be undone.")
    }
    
    @ViewBuilder
    private var exportSheet: some View {
        if let exportData = exportData {
            ShareSheet(items: [exportData])
        }
    }
    
    private func exportDataAction() {
        Task {
            if let data = await viewModel.exportData() {
                exportData = data
                showingExportSheet = true
            }
        }
    }
}

#Preview {
    let persistence = PersistenceController.shared
    let repository = MealRepository(context: persistence.mainContext)
    let viewModel = SettingsViewModel(repository: repository, imageStorage: .shared)
    
    SettingsView(viewModel: viewModel)
}
