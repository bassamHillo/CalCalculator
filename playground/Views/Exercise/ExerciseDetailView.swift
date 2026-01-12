//
//  ExerciseDetailView.swift
//
//  Exercise detail screen (Run, Weight Lifting, Describe, Manual)
//

import SwiftUI

struct ExerciseDetailView: View {
    let exerciseType: ExerciseType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var localizationManager = LocalizationManager.shared
    private let userSettings = UserSettings.shared
    
    @State private var selectedIntensity: ExerciseIntensity?
    @State private var selectedDuration: Int = 0
    @State private var customDuration: String = ""
    @State private var showingBurnedCalories = false
    @State private var calculatedCalories: Int = 0
    
    @State private var exerciseDescription: String = ""
    @State private var manualCalories: String = ""
    
    // Run specific
    @State private var distance: Double = 5.0
    @State private var distanceUnit: DistanceUnit = .kilometers
    @State private var runHours: Int = 0
    @State private var runMinutes: Int = 30
    
    // Weight lifting specific - sets-based
    @State private var exerciseSets: [ExerciseSet] = [ExerciseSet()]
    
    var body: some View {
        // Explicitly reference currentLanguage to ensure SwiftUI tracks the dependency
        let _ = localizationManager.currentLanguage
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Different UI based on exercise type
                if exerciseType == .describe {
                    describeExerciseView
                } else if exerciseType == .manual {
                    manualExerciseView
                } else if exerciseType == .weightLifting {
                    weightLiftingView
                } else {
                    // Run uses intensity, distance, and time picker
                    runExerciseView
                }
            }
            .padding(.bottom, exerciseType == .weightLifting ? 0 : 100) // Only add padding for non-weight-lifting (they have fixed button)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Fixed Continue button at bottom for weight lifting
            if exerciseType == .weightLifting {
                if !exerciseSets.isEmpty && exerciseSets.allSatisfy({ $0.reps > 0 && $0.weight > 0 }) {
                    continueButton {
                        calculateWeightLiftingCalories()
                        showingBurnedCalories = true
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .background(Color(.systemBackground))
                }
            }
        }
        .navigationTitle(exerciseType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if exerciseType == .weightLifting {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(localizationManager.localizedString(for: AppStrings.Common.done)) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .id("done-keyboard-\(localizationManager.currentLanguage)")
                }
            }
        }
        .sheet(isPresented: $showingBurnedCalories) {
            BurnedCaloriesView(
                calories: calculatedCalories,
                exerciseType: exerciseType,
                duration: exerciseType == .run ? (runHours * 60 + runMinutes) : selectedDuration,
                intensity: exerciseType == .describe || exerciseType == .manual || exerciseType == .weightLifting ? nil : selectedIntensity,
                notes: exerciseType == .describe ? exerciseDescription.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                reps: nil,
                sets: nil,
                weight: nil,
                exerciseSets: exerciseType == .weightLifting ? exerciseSets : nil,
                distance: exerciseType == .run ? distance : nil,
                distanceUnit: exerciseType == .run ? distanceUnit : nil
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .exerciseFlowShouldDismiss)) { _ in
            dismiss()
        }
        .onAppear {
            resetState()
        }
    }
    
    private func resetState() {
        selectedIntensity = nil
        selectedDuration = 0
        customDuration = ""
        calculatedCalories = 0
        exerciseDescription = ""
        manualCalories = ""
        distance = 5.0
        distanceUnit = userSettings.preferredDistanceUnit
        runHours = 0
        runMinutes = 30
        exerciseSets = [ExerciseSet()]
    }
    
    // MARK: - Run Exercise View (Redesigned)
    
    private var runExerciseView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Distance Section with slider and unit toggle
            distanceSection
            
            // Time Picker Section
            timePickerSection
            
            // Pace and Auto-Intensity Display
            if runHours > 0 || runMinutes > 0 {
                paceAndIntensityView
            }
            
            Spacer(minLength: 20)
            
            // Continue Button - only require distance and time
            if distance > 0 && (runHours > 0 || runMinutes > 0) {
                continueButton {
                    calculateRunCalories()
                    showingBurnedCalories = true
                }
            }
        }
        .padding(.horizontal)
    }
    
    /// Auto-calculate intensity based on pace (min/km or min/mi)
    private var autoCalculatedIntensity: ExerciseIntensity {
        let totalMinutes = runHours * 60 + runMinutes
        guard distance > 0, totalMinutes > 0 else { return .medium }
        
        // Convert to pace in min/km for consistent calculation
        let distanceInKm = distanceUnit == .miles ? distance * 1.60934 : distance
        let pacePerKm = Double(totalMinutes) / distanceInKm
        
        // Pace thresholds (min/km):
        // High intensity: < 5 min/km (running fast, ~12 km/h+)
        // Medium intensity: 5-7 min/km (jogging, ~8.5-12 km/h)
        // Low intensity: > 7 min/km (walking/slow jog, < 8.5 km/h)
        if pacePerKm < 5.0 {
            return .high
        } else if pacePerKm < 7.0 {
            return .medium
        } else {
            return .low
        }
    }
    
    private var paceAndIntensityView: some View {
        VStack(spacing: 12) {
            // Pace Display
            if let pace = calculatePace() {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(.purple)
                    Text("\(localizationManager.localizedString(for: AppStrings.Exercise.pace)): \(pace)")
                        .font(.headline)
                    Spacer()
                }
            }
            
            // Auto-detected Intensity
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(intensityColor)
                Text("\(localizationManager.localizedString(for: AppStrings.Exercise.intensity)): \(autoCalculatedIntensity.displayName)")
                    .font(.headline)
                Spacer()
                
                // Intensity indicator pill
                Text(intensityLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(intensityColor)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var intensityColor: Color {
        switch autoCalculatedIntensity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    private var intensityLabel: String {
        switch autoCalculatedIntensity {
        case .high: return localizationManager.localizedString(for: AppStrings.Exercise.high)
        case .medium: return localizationManager.localizedString(for: AppStrings.Exercise.medium)
        case .low: return localizationManager.localizedString(for: AppStrings.Exercise.low)
        }
    }
    
    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                    .foregroundColor(.blue)
                Text(localizationManager.localizedString(for: AppStrings.Progress.distance))
                    .font(.headline)
                
                Spacer()
                
                // Unit Toggle
                Picker("", selection: $distanceUnit) {
                    Text("km").tag(DistanceUnit.kilometers)
                    Text("mi").tag(DistanceUnit.miles)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
            
            // Distance Value Display
            HStack {
                Text(String(format: "%.1f", distance))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text(distanceUnit.displayName)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            // Distance Slider
            Slider(value: $distance, in: 0.5...50, step: 0.5)
                .tint(.blue)
            
            // Quick distance buttons
            HStack(spacing: 8) {
                ForEach([1.0, 5.0, 10.0, 21.1, 42.2], id: \.self) { dist in
                    QuickDistanceButton(
                        distance: dist,
                        unit: distanceUnit,
                        isSelected: abs(distance - dist) < 0.1
                    ) {
                        distance = dist
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.green)
                Text(localizationManager.localizedString(for: AppStrings.Progress.duration))
                    .font(.headline)
                    .id("duration-label-\(localizationManager.currentLanguage)")
            }
            
            // Time Picker (Hours : Minutes)
            HStack(spacing: 0) {
                // Hours Picker
                Picker("Hours", selection: $runHours) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour)h").tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100, height: 120)
                .clipped()
                
                Text(":")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Minutes Picker
                Picker("Minutes", selection: $runMinutes) {
                    ForEach(0..<60, id: \.self) { minute in
                        Text("\(minute)m").tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100, height: 120)
                .clipped()
            }
            .frame(maxWidth: .infinity)
            
            // Quick time buttons
            HStack(spacing: 8) {
                QuickTimeButton(hours: 0, minutes: 15, isSelected: runHours == 0 && runMinutes == 15) {
                    runHours = 0
                    runMinutes = 15
                }
                QuickTimeButton(hours: 0, minutes: 30, isSelected: runHours == 0 && runMinutes == 30) {
                    runHours = 0
                    runMinutes = 30
                }
                QuickTimeButton(hours: 1, minutes: 0, isSelected: runHours == 1 && runMinutes == 0) {
                    runHours = 1
                    runMinutes = 0
                }
                QuickTimeButton(hours: 1, minutes: 30, isSelected: runHours == 1 && runMinutes == 30) {
                    runHours = 1
                    runMinutes = 30
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func calculatePace() -> String? {
        let totalMinutes = runHours * 60 + runMinutes
        guard distance > 0, totalMinutes > 0 else { return nil }
        
        let pacePerUnit = Double(totalMinutes) / distance
        let minutes = Int(pacePerUnit)
        let seconds = Int((pacePerUnit - Double(minutes)) * 60)
        return String(format: "%d:%02d /\(distanceUnit.displayName)", minutes, seconds)
    }
    
    private func calculateRunCalories() {
        let intensity = autoCalculatedIntensity
        let totalMinutes = runHours * 60 + runMinutes
        
        // Also set selectedIntensity so it's passed to BurnedCaloriesView
        selectedIntensity = intensity
        
        let baseCaloriesPerMinute: Double
        switch intensity {
        case .high: baseCaloriesPerMinute = 15
        case .medium: baseCaloriesPerMinute = 10
        case .low: baseCaloriesPerMinute = 5
        }
        
        // Add distance factor
        let distanceInKm = distanceUnit == .miles ? distance * 1.60934 : distance
        let distanceFactor = 1.0 + (distanceInKm * 0.03)
        
        let calculated = Int(baseCaloriesPerMinute * Double(totalMinutes) * distanceFactor)
        calculatedCalories = max(1, calculated)
    }
    
    // MARK: - Weight Lifting View (Sets-based)
    
    private var weightLiftingView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.orange)
                Text(localizationManager.localizedString(for: AppStrings.Exercise.weightLifting))
                    .font(.headline)
                Spacer()
                
                // Total Volume
                VStack(alignment: .trailing) {
                    Text(localizationManager.localizedString(for: AppStrings.Exercise.totalVolume))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(totalVolume)) \(userSettings.weightUnit)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Sets List
            VStack(spacing: 16) {
                ForEach(Array(exerciseSets.enumerated()), id: \.element.id) { index, set in
                    SetRowView(
                        setNumber: index + 1,
                        set: Binding(
                            get: { exerciseSets[index] },
                            set: { exerciseSets[index] = $0 }
                        ),
                        onDelete: {
                            if exerciseSets.count > 1 {
                                exerciseSets.remove(at: index)
                            }
                        },
                        canDelete: exerciseSets.count > 1
                    )
                }
            }
            
            // Add Set Button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    exerciseSets.append(ExerciseSet())
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(localizationManager.localizedString(for: AppStrings.Exercise.addSet))
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20) // Add some bottom padding for spacing
    }
    
    private var totalVolume: Double {
        exerciseSets.reduce(0) { $0 + (Double($1.reps) * $1.weight) }
    }
    
    private func calculateWeightLiftingCalories() {
        // ~0.05 calories per rep per kg, minimum 5 calories per set
        var total = 0
        for set in exerciseSets {
            let setCalories = Int(Double(set.reps) * set.weight * 0.05)
            total += max(5, setCalories)
        }
        calculatedCalories = max(exerciseSets.count * 5, total)
    }
    
    // MARK: - Describe Exercise View
    
    private var describeExerciseView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString(for: AppStrings.Exercise.describeYourWorkout))
                .id("describe-workout-\(localizationManager.currentLanguage)")
                .font(.headline)
                .padding(.horizontal)
            
            TextEditor(text: $exerciseDescription)
                .frame(height: 200)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
            
            // Duration Section for describe
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                    Text(localizationManager.localizedString(for: AppStrings.Exercise.durationMinutes))
                        .id("duration-minutes-\(localizationManager.currentLanguage)")
                        .font(.headline)
                }
                
                // Quick duration buttons
                HStack(spacing: 12) {
                    DurationButton(minutes: 15, isSelected: selectedDuration == 15) {
                        selectedDuration = 15
                        customDuration = "15"
                    }
                    DurationButton(minutes: 30, isSelected: selectedDuration == 30) {
                        selectedDuration = 30
                        customDuration = "30"
                    }
                    DurationButton(minutes: 60, isSelected: selectedDuration == 60) {
                        selectedDuration = 60
                        customDuration = "60"
                    }
                    DurationButton(minutes: 90, isSelected: selectedDuration == 90) {
                        selectedDuration = 90
                        customDuration = "90"
                    }
                }
                
                // Custom duration input
                TextField("Custom", text: $customDuration)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .keyboardDoneButton()
                    .onChange(of: customDuration) { oldValue, newValue in
                        if let minutes = Int(newValue), minutes > 0 {
                            selectedDuration = minutes
                        } else {
                            selectedDuration = 0
                        }
                    }
            }
            .padding()
            
            Spacer()
            
            // Continue Button
            if !exerciseDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedDuration > 0 {
                continueButton {
                    calculateCaloriesForDescribe()
                    showingBurnedCalories = true
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Manual Exercise View
    
    private var manualExerciseView: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text(localizationManager.localizedString(for: AppStrings.Exercise.enterCaloriesBurned))
                    .id("enter-calories-\(localizationManager.currentLanguage)")
                    .font(.headline)
                    .padding(.horizontal)
                
                TextField("Calories", text: $manualCalories)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .keyboardDoneButton()
                    .padding(.horizontal)
                    .onChange(of: manualCalories) { oldValue, newValue in
                        if let calories = Int(newValue), calories > 0 {
                            calculatedCalories = calories
                        }
                    }
            }
            
            Spacer()
            
            // Continue Button
            if let calories = Int(manualCalories), calories > 0 {
                continueButton {
                    calculatedCalories = calories
                    showingBurnedCalories = true
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Continue Button
    
    private func continueButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(localizationManager.localizedString(for: AppStrings.Common.continue_))
                .id("continue-\(localizationManager.currentLanguage)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(12)
        }
    }
    
    private func calculateCaloriesForDescribe() {
        guard selectedDuration > 0 else {
            calculatedCalories = 0
            return
        }
        
        // Try to calculate from API
        Task {
            do {
                if let calculated = try await WorkoutCaloriesAPIService.shared.calculateCalories(
                    workoutType: "general",
                    durationMinutes: selectedDuration,
                    intensity: "moderate"
                ) {
                    await MainActor.run {
                        calculatedCalories = calculated
                    }
                } else {
                    // Fallback calculation
                    await MainActor.run {
                        let calculated = Int(10.0 * Double(selectedDuration))
                        calculatedCalories = max(1, calculated)
                    }
                }
            } catch {
                // Fallback calculation
                await MainActor.run {
                    let calculated = Int(10.0 * Double(selectedDuration))
                    calculatedCalories = max(1, calculated)
                }
            }
        }
    }
}

// MARK: - Set Row View

struct SetRowView: View {
    let setNumber: Int
    @Binding var set: ExerciseSet
    let onDelete: () -> Void
    let canDelete: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    private let userSettings = UserSettings.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Set Header
            HStack {
                Text(String(format: localizationManager.localizedString(for: AppStrings.Exercise.setNumber), setNumber))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            HStack(spacing: 16) {
                // Reps Picker
                VStack(spacing: 4) {
                    Text(localizationManager.localizedString(for: AppStrings.Exercise.reps))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Reps", selection: $set.reps) {
                        ForEach(1...50, id: \.self) { reps in
                            Text("\(reps)").tag(reps)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .clipped()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                .cornerRadius(12)
                
                // Weight Picker
                VStack(spacing: 4) {
                    Text(String(format: localizationManager.localizedString(for: AppStrings.Exercise.weightWithUnit), userSettings.weightUnit))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 0) {
                        // Integer part
                        Picker("Weight", selection: Binding(
                            get: { Int(set.weight) },
                            set: { set.weight = Double($0) + (set.weight - floor(set.weight)) }
                        )) {
                            ForEach(0...200, id: \.self) { weight in
                                Text("\(weight)").tag(weight)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 60, height: 100)
                        .clipped()
                        
                        Text(".")
                            .font(.title2)
                        
                        // Decimal part (0 or 5)
                        Picker("Decimal", selection: Binding(
                            get: { Int((set.weight - floor(set.weight)) * 10) >= 5 ? 5 : 0 },
                            set: { set.weight = floor(set.weight) + Double($0) / 10 }
                        )) {
                            Text("0").tag(0)
                            Text("5").tag(5)
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 40, height: 100)
                        .clipped()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                .cornerRadius(12)
            }
            
            // Volume for this set
            Text("\(localizationManager.localizedString(for: AppStrings.Exercise.volume)): \(Int(Double(set.reps) * set.weight)) \(userSettings.weightUnit)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Quick Distance Button

struct QuickDistanceButton: View {
    let distance: Double
    let unit: DistanceUnit
    let isSelected: Bool
    let action: () -> Void
    
    var displayText: String {
        if distance == 21.1 {
            return "Half"
        } else if distance == 42.2 {
            return "Full"
        } else {
            return String(format: "%.0f", distance)
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(8)
        }
    }
}

// MARK: - Quick Time Button

struct QuickTimeButton: View {
    let hours: Int
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var displayText: String {
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(.systemGray5))
                .cornerRadius(8)
        }
    }
}

// MARK: - Supporting Views

struct IntensityOption: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                        )
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            .padding()
            .background(isSelected ? Color.gray.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
}

struct DurationButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        Button(action: action) {
            Text("\(minutes) \(localizationManager.localizedString(for: AppStrings.Exercise.mins))")
                .id("minutes-label-\(localizationManager.currentLanguage)")
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exerciseType: .run)
    }
}
