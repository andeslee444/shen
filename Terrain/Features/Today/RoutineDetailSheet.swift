//
//  RoutineDetailSheet.swift
//  Terrain
//
//  Beautifully designed routine detail view with hero image,
//  ambient background, and flowing visual hierarchy.
//

import SwiftUI
import SwiftData

struct RoutineDetailSheet: View {
    let level: RoutineLevel
    let routineModel: Routine
    /// Callback with the start timestamp for duration analytics
    let onComplete: (Date?) -> Void

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
    @State private var scrollOffset: CGFloat = 0
    /// Tracks when the routine was started for duration analytics
    @State private var startedAt: Date = Date()

    // MARK: - Computed Properties

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

    private var currentPhase: DayPhase {
        DayPhase.current()
    }

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

    private var whyForYourTerrain: String? {
        insightEngine.generateWhyForYou(
            routineTags: routineModel.tags,
            terrainType: terrainType,
            modifier: terrainModifier
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient background (phase-aware gradient)
                AmbientBackground(
                    phase: currentPhase,
                    scrollOffset: scrollOffset,
                    showParticles: true
                )

                // Main content
                VStack(spacing: 0) {
                    // Custom scroll view with offset tracking
                    ScrollView {
                        scrollContent
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(
                                            key: ScrollOffsetKey.self,
                                            value: -geo.frame(in: .named("scroll")).minY
                                        )
                                }
                            )
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetKey.self) { value in
                        scrollOffset = value
                    }

                    // Bottom action buttons
                    bottomButtons
                }
            }
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
                onComplete(startedAt)
                dismiss()
            }) {
                PostRoutineFeedbackSheet(
                    routineTitle: routineTitle,
                    whyItHelps: whyForYourTerrain,
                    onDismiss: { }
                )
            }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        VStack(spacing: 0) {
            // Hero image with parallax
            ParallaxHeroImage(
                imageUri: routineModel.heroImageUri,
                fallbackIcon: "cup.and.saucer.fill",
                phase: currentPhase,
                scrollOffset: scrollOffset
            )

            // Content sections with varied spacing
            VStack(spacing: 0) {
                // Title section (overlaps hero slightly)
                titleSection
                    .padding(.top, -theme.spacing.lg)

                // Why section
                whySection
                    .padding(.top, theme.spacing.xl)

                // Ingredients
                ingredientsSection
                    .padding(.top, theme.spacing.xl)

                // All steps overview
                allStepsSection
                    .padding(.top, theme.spacing.lg)

                Spacer(minLength: theme.spacing.xxl)
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: theme.spacing.sm) {
            Text(routineTitle)
                .font(theme.typography.headlineLarge)
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            if !routineSubtitle.isEmpty {
                Text(routineSubtitle)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Duration & difficulty pills
            HStack(spacing: theme.spacing.sm) {
                metadataPill(icon: "clock", text: routineDuration)
                metadataPill(icon: "leaf", text: routineDifficulty)
            }
            .padding(.top, theme.spacing.xs)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.xl)
                .fill(theme.colors.surface)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private func metadataPill(icon: String, text: String) -> some View {
        HStack(spacing: theme.spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(theme.typography.labelSmall)
        }
        .foregroundColor(theme.colors.textTertiary)
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xxs)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.cornerRadius.full)
    }

    // MARK: - Why Section (with left accent border)

    private var whySection: some View {
        HStack(spacing: 0) {
            // Accent border
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.colors.accent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Why this helps")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.accent)

                Text(routineWhyText)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // Terrain-specific "why" callout
                if let terrainWhy = whyForYourTerrain {
                    terrainCallout(terrainWhy)
                }
            }
            .padding(theme.spacing.md)
        }
        .background(theme.colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(theme.cornerRadius.large)
    }

    private func terrainCallout(_ text: String) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.xs) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 12))
                .foregroundColor(theme.colors.accent)

            Text(text)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
                .italic()
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.accent.opacity(0.08))
        .cornerRadius(theme.cornerRadius.medium)
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: "leaf.circle")
                    .foregroundColor(theme.colors.accent)
                Text("Ingredients")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }

            HStack {
                Spacer()
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
                Spacer()
            }
        }
    }

    // MARK: - Current Step Section

    private var currentStepSection: some View {
        VStack(spacing: theme.spacing.md) {
            // Current step header
            HStack {
                Text("Current Step")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textSecondary)

                Spacer()

                // Timer if available
                if routineSteps[currentStep].timerSeconds > 0 {
                    if isTimerRunning {
                        Text(timeString(from: timeRemaining))
                            .font(theme.typography.headlineSmall)
                            .foregroundColor(theme.colors.accent)
                    } else {
                        Button(action: { startTimer(seconds: routineSteps[currentStep].timerSeconds) }) {
                            Label(timeString(from: routineSteps[currentStep].timerSeconds), systemImage: "timer")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.accent)
                        }
                    }
                }
            }

            // Step content (elevated)
            Text(routineSteps[currentStep].text)
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(theme.spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                        .fill(theme.colors.surface)
                        .shadow(color: theme.colors.accent.opacity(0.15), radius: 12, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                        .stroke(theme.colors.accent.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - All Steps Section

    private var allStepsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("All steps")
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textTertiary)

            VStack(spacing: theme.spacing.xs) {
                ForEach(Array(routineSteps.enumerated()), id: \.offset) { index, step in
                    EnhancedStepRow(
                        number: index + 1,
                        text: step.text,
                        isCompleted: index < currentStep,
                        isCurrent: index == currentStep,
                        isLast: index == routineSteps.count - 1
                    )
                }
            }
            .padding(theme.spacing.md)
            .background(theme.colors.backgroundSecondary.opacity(0.5))
            .cornerRadius(theme.cornerRadius.large)
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: theme.spacing.md) {
            if currentStep > 0 {
                TerrainSecondaryButton(title: "Previous") {
                    withAnimation(theme.animation.standard) {
                        currentStep -= 1
                    }
                }
            }

            if currentStep < routineSteps.count - 1 {
                TerrainPrimaryButton(title: "Next Step") {
                    withAnimation(theme.animation.standard) {
                        currentStep += 1
                    }
                }
            } else {
                TerrainPrimaryButton(title: "Complete") {
                    showFeedbackSheet = true
                }
            }
        }
        .padding(theme.spacing.lg)
        .background(
            theme.colors.background
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -4)
        )
    }

    // MARK: - Helpers

    private func findIngredient(named chipName: String) -> Ingredient? {
        let cleaned = chipName.replacingOccurrences(
            of: #"\s*\(.*\)$"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)

        let lowered = cleaned.lowercased()

        if let exact = allIngredients.first(where: { $0.displayName.lowercased() == lowered }) {
            return exact
        }

        return allIngredients.first(where: {
            $0.displayName.lowercased().contains(lowered) || lowered.contains($0.displayName.lowercased())
        })
    }

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
            TerrainLogger.persistence.error("Failed to save cabinet item: \(error)")
        }
    }

    private func removeFromCabinet(_ item: UserCabinet) {
        modelContext.delete(item)
        do {
            try modelContext.save()
            HapticManager.light()
        } catch {
            TerrainLogger.persistence.error("Failed to remove cabinet item: \(error)")
        }
    }

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

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }
        return "\(secs)s"
    }
}

// MARK: - Enhanced Step Row

struct EnhancedStepRow: View {
    let number: Int
    let text: String
    let isCompleted: Bool
    let isCurrent: Bool
    let isLast: Bool

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            // Step indicator with connector
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(circleColor)
                        .frame(width: 28, height: 28)

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

                // Vertical connector line
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? theme.colors.success : theme.colors.textTertiary.opacity(0.2))
                        .frame(width: 2, height: 24)
                }
            }

            // Step text
            Text(text)
                .font(theme.typography.bodyMedium)
                .foregroundColor(textColor)
                .strikethrough(isCompleted, color: theme.colors.textTertiary)
                .padding(.top, 4)

            Spacer()
        }
    }

    private var circleColor: Color {
        if isCompleted {
            return theme.colors.success
        } else if isCurrent {
            return theme.colors.accent
        } else {
            return theme.colors.backgroundSecondary
        }
    }

    private var textColor: Color {
        if isCompleted {
            return theme.colors.textTertiary
        } else if isCurrent {
            return theme.colors.textPrimary
        } else {
            return theme.colors.textSecondary
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

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
            ),
            heroImageUri: "https://images.unsplash.com/photo-1626200419199-391ae4be7a41?w=800"
        ),
        onComplete: { _ in }
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
