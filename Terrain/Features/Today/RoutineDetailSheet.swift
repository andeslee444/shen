//
//  RoutineDetailSheet.swift
//  Terrain
//
//  Detailed view of a routine with steps
//

import SwiftUI
import SwiftData

struct RoutineDetailSheet: View {
    let level: RoutineLevel
    let routineModel: Routine
    let onComplete: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Ingredient.id) private var allIngredients: [Ingredient]
    @Query private var cabinetItems: [UserCabinet]
    @Query private var userProfiles: [UserProfile]

    private let insightEngine = InsightEngine()

    @State private var currentStep = 0
    @State private var isTimerRunning = false
    @State private var timeRemaining = 0
    @State private var selectedIngredient: Ingredient?
    @State private var showFeedbackSheet = false

    /// View-friendly representation of the Routine model
    private var routineTitle: String { routineModel.displayName }
    private var routineSubtitle: String { routineModel.subtitle?.localized ?? "" }
    private var routineDuration: String { "\(routineModel.durationMin) min" }
    private var routineDifficulty: String { routineModel.difficulty.displayName }
    private var routineIngredients: [String] { ingredientDisplayNames(for: routineModel.ingredientRefs) }
    private var routineSteps: [(text: String, timerSeconds: Int)] {
        routineModel.steps.map { (text: $0.text.localized, timerSeconds: $0.timerSeconds ?? 0) }
    }
    private var routineWhyText: String {
        routineModel.why.expanded?.plain.localized ?? routineModel.why.oneLine.localized
    }

    /// Maps ingredient ref IDs (e.g. "ginger") to display names (e.g. "Ginger")
    private func ingredientDisplayNames(for refs: [String]) -> [String] {
        refs.map { ref in
            allIngredients.first(where: { $0.id == ref })?.displayName ?? ref.capitalized
        }
    }

    private var terrainType: TerrainScoringEngine.PrimaryType {
        guard let profile = userProfiles.first,
              let terrainId = profile.terrainProfileId,
              let type = TerrainScoringEngine.PrimaryType(rawValue: terrainId) else {
            return .neutralBalanced
        }
        return type
    }

    private var terrainModifier: TerrainScoringEngine.Modifier {
        userProfiles.first?.resolvedModifier ?? .none
    }

    /// Terrain-specific explanation for why this routine matters for the user
    private var whyForYourTerrain: String? {
        insightEngine.generateWhyForYou(
            routineTags: routineModel.tags,
            terrainType: terrainType,
            modifier: terrainModifier
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress
                ProgressView(value: Double(currentStep) / Double(routineSteps.count))
                    .tint(theme.colors.accent)
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)

                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        // Header
                        VStack(spacing: theme.spacing.sm) {
                            Text(routineTitle)
                                .font(theme.typography.headlineLarge)
                                .foregroundColor(theme.colors.textPrimary)

                            Text(routineSubtitle)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textSecondary)

                            HStack(spacing: theme.spacing.md) {
                                Label(routineDuration, systemImage: "clock")
                                Label(routineDifficulty, systemImage: "speedometer")
                            }
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.top, theme.spacing.md)

                        // Why section
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Why this helps")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.textTertiary)

                            Text(routineWhyText)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textSecondary)

                            // Terrain-specific "why" section
                            if let terrainWhy = whyForYourTerrain {
                                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                    Text("For your terrain")
                                        .font(theme.typography.labelSmall)
                                        .foregroundColor(theme.colors.accent)

                                    Text(terrainWhy)
                                        .font(theme.typography.bodySmall)
                                        .foregroundColor(theme.colors.textSecondary)
                                        .italic()
                                }
                                .padding(theme.spacing.sm)
                                .background(theme.colors.accent.opacity(0.06))
                                .cornerRadius(theme.cornerRadius.medium)
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)

                        // Ingredients
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Ingredients")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.textTertiary)

                            FlowLayout(spacing: theme.spacing.xs) {
                                ForEach(routineIngredients, id: \.self) { ingredientName in
                                    let matched = findIngredient(named: ingredientName)
                                    IngredientChip(
                                        name: ingredientName,
                                        isInCabinet: matched.map { isInCabinet($0.id) } ?? false,
                                        onTap: matched != nil ? {
                                            selectedIngredient = matched
                                            HapticManager.light()
                                        } : nil
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)

                        // Current step
                        if currentStep < routineSteps.count {
                            StepCard(
                                stepNumber: currentStep + 1,
                                totalSteps: routineSteps.count,
                                stepText: routineSteps[currentStep].text,
                                stepTimerSeconds: routineSteps[currentStep].timerSeconds,
                                isTimerRunning: isTimerRunning,
                                timeRemaining: timeRemaining,
                                onStartTimer: startTimer
                            )
                            .padding(.horizontal, theme.spacing.lg)
                        }

                        // All steps overview
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("All steps")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.textTertiary)

                            ForEach(Array(routineSteps.enumerated()), id: \.offset) { index, step in
                                StepRow(
                                    number: index + 1,
                                    text: step.text,
                                    isCompleted: index < currentStep,
                                    isCurrent: index == currentStep
                                )
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)

                        Spacer(minLength: theme.spacing.xxl)
                    }
                }

                // Bottom buttons
                HStack(spacing: theme.spacing.md) {
                    if currentStep > 0 {
                        TerrainSecondaryButton(title: "Previous") {
                            currentStep -= 1
                        }
                    }

                    if currentStep < routineSteps.count - 1 {
                        TerrainPrimaryButton(title: "Next Step") {
                            currentStep += 1
                        }
                    } else {
                        TerrainPrimaryButton(title: "Complete") {
                            showFeedbackSheet = true
                        }
                    }
                }
                .padding(theme.spacing.lg)
                .background(theme.colors.background)
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
            }
            .sheet(item: $selectedIngredient) { ingredient in
                IngredientDetailSheet(
                    ingredient: ingredient,
                    isInCabinet: isInCabinet(ingredient.id),
                    onToggleCabinet: { toggleCabinet(ingredient.id) }
                )
            }
            .sheet(isPresented: $showFeedbackSheet, onDismiss: {
                // After feedback sheet dismisses (either via selection or swipe-down),
                // fire the completion callback and close the routine sheet
                onComplete()
                dismiss()
            }) {
                PostRoutineFeedbackSheet(
                    routineOrMovementId: routineModel.id,
                    onFeedback: { feedback in
                        saveFeedback(feedback)
                    }
                )
            }
        }
    }

    // MARK: - Feedback

    private func saveFeedback(_ feedback: PostRoutineFeedback) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<DailyLog>()
        let allLogs = (try? modelContext.fetch(descriptor)) ?? []
        let todaysLog = allLogs.first { calendar.startOfDay(for: $0.date) == today }

        let entry = RoutineFeedbackEntry(
            routineOrMovementId: routineModel.id,
            feedback: feedback
        )

        if let log = todaysLog {
            log.routineFeedback.append(entry)
            log.updatedAt = Date()
        } else {
            let log = DailyLog(routineFeedback: [entry])
            modelContext.insert(log)
        }

        try? modelContext.save()
    }

    // MARK: - Ingredient Matching

    /// Matches a chip display name (e.g. "Rice", "Fresh Ginger") to a SwiftData Ingredient.
    /// Strips parenthetical suffixes like " (optional)" before matching.
    /// Returns nil if no match — chip stays non-interactive.
    private func findIngredient(named chipName: String) -> Ingredient? {
        // Strip parenthetical suffix: "Chicken (optional)" → "Chicken"
        let cleaned = chipName.replacingOccurrences(
            of: #"\s*\(.*\)$"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)

        let lowered = cleaned.lowercased()

        // Exact case-insensitive match on displayName
        if let exact = allIngredients.first(where: { $0.displayName.lowercased() == lowered }) {
            return exact
        }

        // Fallback: contains match (handles "Fresh Ginger" ↔ "Ginger", "Rice" ↔ "White Rice")
        return allIngredients.first(where: {
            $0.displayName.lowercased().contains(lowered) || lowered.contains($0.displayName.lowercased())
        })
    }

    // MARK: - Cabinet Helpers

    private func isInCabinet(_ ingredientId: String) -> Bool {
        cabinetItems.contains { $0.ingredientId == ingredientId }
    }

    private func toggleCabinet(_ ingredientId: String) {
        if let existingItem = cabinetItems.first(where: { $0.ingredientId == ingredientId }) {
            removeFromCabinet(existingItem)
        } else {
            addToCabinet(ingredientId)
        }
    }

    private func addToCabinet(_ ingredientId: String) {
        guard !isInCabinet(ingredientId) else { return }
        let item = UserCabinet(ingredientId: ingredientId)
        modelContext.insert(item)
        do {
            try modelContext.save()
            HapticManager.success()
        } catch {
            print("Failed to save cabinet item: \(error)")
        }
    }

    private func removeFromCabinet(_ item: UserCabinet) {
        modelContext.delete(item)
        do {
            try modelContext.save()
            HapticManager.light()
        } catch {
            print("Failed to remove cabinet item: \(error)")
        }
    }

    // MARK: - Timer

    private func startTimer(seconds: Int) {
        timeRemaining = seconds
        isTimerRunning = true

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                isTimerRunning = false
            }
        }
    }
}

struct StepCard: View {
    let stepNumber: Int
    let totalSteps: Int
    let stepText: String
    let stepTimerSeconds: Int
    let isTimerRunning: Bool
    let timeRemaining: Int
    let onStartTimer: (Int) -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            HStack {
                Text("Step \(stepNumber) of \(totalSteps)")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.colors.textTertiary)

                Spacer()

                if stepTimerSeconds > 0 {
                    if isTimerRunning {
                        Text(timeString(from: timeRemaining))
                            .font(theme.typography.headlineSmall)
                            .foregroundColor(theme.colors.accent)
                    } else {
                        Button(action: { onStartTimer(stepTimerSeconds) }) {
                            Label(timeString(from: stepTimerSeconds), systemImage: "timer")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.accent)
                        }
                    }
                }
            }

            Text(stepText)
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.accent.opacity(0.08))
        .cornerRadius(theme.cornerRadius.large)
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }
        return "\(secs)s"
    }
}

struct StepRow: View {
    let number: Int
    let text: String
    let isCompleted: Bool
    let isCurrent: Bool

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            ZStack {
                Circle()
                    .fill(isCompleted ? theme.colors.success : (isCurrent ? theme.colors.accent : theme.colors.backgroundSecondary))
                    .frame(width: 24, height: 24)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(isCurrent ? .white : theme.colors.textTertiary)
                }
            }

            Text(text)
                .font(theme.typography.bodyMedium)
                .foregroundColor(isCompleted ? theme.colors.textTertiary : theme.colors.textPrimary)
                .strikethrough(isCompleted)
        }
    }
}

#Preview {
    RoutineDetailSheet(
        level: .full,
        routineModel: Routine(
            id: "preview-warm-start-congee",
            title: LocalizedString(["en-US": "Warm Start Congee"]),
            subtitle: LocalizedString(["en-US": "Nourishing breakfast to warm your center"]),
            durationMin: 15,
            difficulty: .easy,
            tags: ["warming", "supports_digestion"],
            ingredientRefs: ["ginger", "rice"],
            steps: [
                RoutineStep(text: LocalizedString(["en-US": "Bring 4 cups water to a boil"])),
                RoutineStep(text: LocalizedString(["en-US": "Add 1/2 cup rice and 2 slices fresh ginger"])),
                RoutineStep(text: LocalizedString(["en-US": "Reduce heat and simmer, stirring occasionally"]), timerSeconds: 600),
                RoutineStep(text: LocalizedString(["en-US": "Add salt to taste and top with scallions"])),
                RoutineStep(text: LocalizedString(["en-US": "Eat slowly, savoring the warmth"]))
            ],
            why: RoutineWhy(
                oneLine: LocalizedString(["en-US": "Congee is easily digestible and warming to the center."])
            )
        ),
        onComplete: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
