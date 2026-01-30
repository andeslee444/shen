//
//  DoView.swift
//  Terrain
//
//  The Do tab - execution-focused view combining routine capsule and quick fixes.
//  This is where users take action on their daily routines.
//

import SwiftUI
import SwiftData
import Combine

/// The Do tab - execution mode for daily routines.
/// Combines the capsule (routine + movement) with quick fix suggestions.
struct DoView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationCoordinator.self) private var coordinator

    @Query private var userProfiles: [UserProfile]
    @Query(sort: \Ingredient.id) private var ingredients: [Ingredient]
    @Query(sort: \Routine.id) private var allRoutines: [Routine]
    @Query(sort: \Movement.id) private var allMovements: [Movement]
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @Query private var cabinetItems: [UserCabinet]
    @Query(sort: \TerrainProfile.id) private var terrainProfiles: [TerrainProfile]

    @State private var showRoutineDetail = false
    @State private var showMovementPlayer = false
    @State private var selectedNeed: QuickNeed?
    @State private var showCompletionFeedback = false
    @State private var completedNeed: QuickNeed?
    @State private var showSuggestionInfo = false

    // Avoid timer: refreshes every 60 seconds to update countdown display
    @State private var timerTick = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private let suggestionEngine = SuggestionEngine()

    // MARK: - Computed Properties

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    private var todaysLog: DailyLog? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return dailyLogs.first { calendar.startOfDay(for: $0.date) == today }
    }

    @State private var selectedLevel: RoutineLevel = .full

    /// The user's terrain profile ID (e.g. "cold_deficient_low_flame")
    private var terrainProfileId: String? {
        userProfile?.terrainProfileId
    }

    /// The user's primary terrain type (parsed from profile ID)
    private var terrainType: TerrainScoringEngine.PrimaryType {
        guard let profileId = terrainProfileId else { return .neutralBalanced }
        return TerrainScoringEngine.PrimaryType(rawValue: profileId) ?? .neutralBalanced
    }

    /// The user's modifier for content boosting
    private var terrainModifier: TerrainScoringEngine.Modifier {
        userProfile?.resolvedModifier ?? .none
    }

    /// Today's quick symptoms from the home tab check-in
    private var todaysSymptoms: Set<QuickSymptom> {
        Set(todaysLog?.quickSymptoms ?? [])
    }

    /// Ingredient IDs the user has saved in their cabinet
    private var cabinetIngredientIds: Set<String> {
        Set(cabinetItems.map(\.ingredientId))
    }

    /// Routine/suggestion IDs completed today (for suppression)
    private var todaysCompletedIds: Set<String> {
        Set(todaysLog?.completedRoutineIds ?? [])
    }

    /// User goal strings (raw values) for goal-alignment scoring
    private var userGoalStrings: [String] {
        userProfile?.goals.map(\.rawValue) ?? []
    }

    /// Avoid tags from the user's terrain profile
    private var terrainAvoidTags: Set<String> {
        guard let profileId = terrainProfileId,
              let profile = terrainProfiles.first(where: { $0.id == profileId }) else {
            return []
        }
        return Set(profile.avoidTags)
    }

    /// Pre-computed routine effectiveness scores from TrendEngine
    private var routineEffectivenessMap: [String: Double] {
        let trendEngine = TrendEngine()
        var map: [String: Double] = [:]
        for routine in allRoutines {
            if let score = trendEngine.computeRoutineEffectiveness(logs: dailyLogs, routineId: routine.id) {
                map[routine.id] = score
            }
        }
        return map
    }

    /// Best routine for current terrain + selected level, falling back gracefully
    private var selectedRoutine: Routine? {
        let tier = selectedLevel.rawValue
        let profileId = terrainProfileId ?? ""

        // 1. Exact terrain match + correct tier
        if let match = allRoutines.first(where: {
            $0.tier == tier && $0.terrainFit.contains(profileId)
        }) {
            return match
        }

        // 2. Any routine with correct tier (fallback)
        if let match = allRoutines.first(where: { $0.tier == tier }) {
            return match
        }

        // 3. Any routine at all
        return allRoutines.first
    }

    /// Best movement for current terrain + selected level
    private var selectedMovement: Movement? {
        let profileId = terrainProfileId ?? ""

        let matched = allMovements.filter { $0.terrainFit.contains(profileId) }

        let preferredIntensity: String = {
            switch selectedLevel {
            case .full: return "moderate"
            case .medium: return "gentle"
            case .lite: return "restorative"
            }
        }()

        if let intensityMatch = matched.first(where: { $0.intensity.rawValue == preferredIntensity }) {
            return intensityMatch
        }
        if let anyMatch = matched.first {
            return anyMatch
        }

        if let fallback = allMovements.first(where: { $0.intensity.rawValue == preferredIntensity }) {
            return fallback
        }
        return allMovements.first
    }

    /// Quick needs reordered by today's symptoms
    private var orderedNeeds: [QuickNeed] {
        suggestionEngine.orderedNeeds(for: todaysSymptoms)
    }

    /// Coaching note below the level selector, personalized to terrain type and modifier
    private var levelCoachingNote: String {
        let profileId = terrainProfileId ?? ""

        switch terrainModifier {
        case .shen:
            return "The movement matters most for you today. Even if you skip the routine, do the movement."
        case .stagnation:
            return "Full level helps move stuck energy. Lean into it when you can."
        case .damp:
            return "Lighter meals help your body clear dampness. Medium or Lite are great starting points."
        case .dry:
            return "Nourishment is your priority. Full routines give your body what it needs most."
        case .none:
            break
        }

        if profileId.contains("cold") && profileId.contains("deficient") {
            return "Start with Lite. Build warmth gently — consistency beats intensity for your pattern."
        } else if profileId.contains("cold") {
            return "Warming routines are your foundation. Even a warm drink shifts things for you."
        } else if profileId.contains("warm") && profileId.contains("excess") {
            return "Full is great for you. Channel that energy into structured practice."
        } else if profileId.contains("warm") && profileId.contains("deficient") {
            return "Medium level balances your warmth without depleting. Steady wins here."
        } else if profileId.contains("warm") {
            return "Cooling, calming routines suit you best. Don't push too hard."
        } else if profileId.contains("neutral") && profileId.contains("deficient") {
            return "Start gentle and build. Your body responds well to consistent, small efforts."
        } else if profileId.contains("neutral") && profileId.contains("excess") {
            return "Full level helps channel your energy. Structure is your friend."
        } else {
            return "Pick the level that fits your morning. Consistency matters more than intensity."
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: theme.spacing.xl) {
                        // Level Selector + Coaching Note
                        VStack(spacing: theme.spacing.sm) {
                            levelSelector

                            Text(levelCoachingNote)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, theme.spacing.xl)
                        }

                        // Capsule Section
                        capsuleSection

                        // Quick Fixes Section
                        quickFixesSection

                        Spacer(minLength: theme.spacing.xxl)
                    }
                    .padding(.top, theme.spacing.md)
                }
                .background(theme.colors.background)

                // Completion feedback overlay
                if showCompletionFeedback {
                    completionOverlay
                }
            }
            .navigationTitle("Do")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showRoutineDetail) {
                if let routine = selectedRoutine {
                    RoutineDetailSheet(
                        level: selectedLevel,
                        routineModel: routine,
                        onComplete: { markRoutineComplete() }
                    )
                }
            }
            .sheet(isPresented: $showMovementPlayer) {
                MovementPlayerSheet(
                    level: selectedLevel,
                    onComplete: { markMovementComplete() }
                )
            }
            .onReceive(timer) { _ in
                // Tick the avoid-timer countdown every 60 seconds
                timerTick = Date()
            }
        }
    }

    // MARK: - Level Selector

    private var levelSelector: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(RoutineLevel.allCases, id: \.self) { level in
                Button(action: {
                    withAnimation(theme.animation.quick) {
                        selectedLevel = level
                    }
                    HapticManager.selection()
                }) {
                    VStack(spacing: 2) {
                        Text(level.displayName)
                            .font(theme.typography.labelMedium)
                            .foregroundColor(selectedLevel == level ? theme.colors.textInverted : theme.colors.textSecondary)

                        Text(level.durationDescription)
                            .font(theme.typography.caption)
                            .foregroundColor(selectedLevel == level ? theme.colors.textInverted.opacity(0.8) : theme.colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.sm)
                    .background(selectedLevel == level ? theme.colors.accent : Color.clear)
                    .cornerRadius(theme.cornerRadius.medium)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(theme.spacing.xxs)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.cornerRadius.large)
        .padding(.horizontal, theme.spacing.lg)
    }

    // MARK: - Capsule Section

    private var capsuleSection: some View {
        VStack(spacing: theme.spacing.md) {
            Text("Your Daily Capsule")
                .font(theme.typography.headlineSmall)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, theme.spacing.lg)

            // Routine module
            if let routine = selectedRoutine {
                RoutineModuleCard(
                    type: .eatDrink,
                    title: routine.displayName,
                    subtitle: routine.subtitle?.localized ?? "",
                    duration: "\(routine.durationMin) min",
                    isCompleted: todaysLog?.completedRoutineIds.isEmpty == false,
                    onTap: { showRoutineDetail = true }
                )
                .padding(.horizontal, theme.spacing.lg)
            } else {
                RoutineModuleCard(
                    type: .eatDrink,
                    title: routineTitle(for: selectedLevel),
                    subtitle: routineSubtitle(for: selectedLevel),
                    duration: routineDuration(for: selectedLevel),
                    isCompleted: todaysLog?.completedRoutineIds.isEmpty == false,
                    onTap: { showRoutineDetail = true }
                )
                .padding(.horizontal, theme.spacing.lg)
            }

            // Movement module
            if let movement = selectedMovement {
                RoutineModuleCard(
                    type: .movement,
                    title: movement.displayName,
                    subtitle: movement.subtitle?.localized ?? "Wake up your body gently",
                    duration: "\(movement.durationMin) min",
                    isCompleted: todaysLog?.completedMovementIds.isEmpty == false,
                    onTap: { showMovementPlayer = true }
                )
                .padding(.horizontal, theme.spacing.lg)
            } else {
                RoutineModuleCard(
                    type: .movement,
                    title: movementTitle(for: selectedLevel),
                    subtitle: movementSubtitle(for: selectedLevel),
                    duration: movementDuration(for: selectedLevel),
                    isCompleted: todaysLog?.completedMovementIds.isEmpty == false,
                    onTap: { showMovementPlayer = true }
                )
                .padding(.horizontal, theme.spacing.lg)
            }
        }
    }

    // MARK: - Quick Fixes Section

    private var quickFixesSection: some View {
        VStack(spacing: theme.spacing.md) {
            HStack(alignment: .center, spacing: theme.spacing.xs) {
                Text("Quick Fixes")
                    .font(theme.typography.headlineSmall)
                    .foregroundColor(theme.colors.textPrimary)

                Button {
                    withAnimation(theme.animation.quick) {
                        showSuggestionInfo.toggle()
                    }
                    HapticManager.light()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("How suggestions are personalized")

                Spacer()
            }
            .padding(.horizontal, theme.spacing.lg)

            if showSuggestionInfo {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("Personalized for you")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Each suggestion is scored based on your terrain type, today's symptoms, time of day, the current season, your goals, what's in your cabinet, and what you've already completed today. Items that conflict with your pattern are deprioritized.")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(theme.spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.cornerRadius.medium)
                .padding(.horizontal, theme.spacing.lg)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }

            Text("Need something right now? Tap to see a suggestion.")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, theme.spacing.lg)

            // Quick needs grid — ordered by symptom relevance
            VStack(spacing: theme.spacing.sm) {
                ForEach(orderedNeeds) { need in
                    QuickNeedCard(
                        need: need,
                        isSelected: selectedNeed == need,
                        isCompleted: isNeedCompletedToday(need),
                        onTap: {
                            withAnimation(theme.animation.standard) {
                                selectedNeed = need
                            }
                            HapticManager.selection()
                        }
                    )
                }
            }
            .padding(.horizontal, theme.spacing.lg)

            // Selected suggestion — powered by SuggestionEngine
            if let need = selectedNeed {
                let suggestion = smartSuggestion(for: need)
                QuickSuggestionCard(
                    need: need,
                    suggestion: (suggestion.title, suggestion.description, suggestion.avoidHours),
                    isCompleted: isNeedCompletedToday(need),
                    avoidTimeText: avoidTimeText(for: need),
                    onDoThis: {
                        markSuggestionComplete(need: need, avoidHours: suggestion.avoidHours)
                    },
                    onSaveGoTo: {
                        HapticManager.light()
                    }
                )
                .padding(.horizontal, theme.spacing.lg)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(theme.colors.success)

            Text("Done!")
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.colors.textPrimary)

            if let need = completedNeed {
                Text("You completed \(need.displayName.lowercased())")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.xl)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.xl)
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Suggestion Engine Integration

    /// Calls the SuggestionEngine with full terrain/symptom/time/season/goal context
    private func smartSuggestion(for need: QuickNeed) -> QuickSuggestion {
        suggestionEngine.suggest(
            for: need,
            terrainType: terrainType,
            modifier: terrainModifier,
            symptoms: todaysSymptoms,
            timeOfDay: TimeOfDay.current(),
            ingredients: ingredients,
            routines: allRoutines,
            season: InsightEngine.TCMSeason.current(),
            userGoals: userGoalStrings,
            avoidTags: terrainAvoidTags,
            completedIds: todaysCompletedIds,
            cabinetIngredientIds: cabinetIngredientIds,
            routineEffectiveness: routineEffectivenessMap
        )
    }

    // MARK: - Avoid Timer

    /// Calculates remaining avoid window from completion time + avoidHours
    private func avoidTimeRemaining(for need: QuickNeed) -> TimeInterval? {
        guard let log = todaysLog,
              let completionTime = log.quickFixCompletionTimes[need.rawValue] else {
            return nil
        }

        let suggestion = smartSuggestion(for: need)
        guard let avoidHours = suggestion.avoidHours, avoidHours > 0 else { return nil }

        let expiryDate = completionTime.addingTimeInterval(TimeInterval(avoidHours * 3600))
        let remaining = expiryDate.timeIntervalSince(timerTick)
        return remaining > 0 ? remaining : nil
    }

    /// Formats the remaining avoid window as human-readable text
    private func avoidTimeText(for need: QuickNeed) -> String? {
        guard let remaining = avoidTimeRemaining(for: need) else { return nil }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        let suggestion = smartSuggestion(for: need)
        let avoidNote = suggestion.avoidNotes ?? "Avoid cold drinks"

        if hours > 0 {
            return "\(avoidNote) for \(hours)h \(minutes)m more"
        } else {
            return "\(avoidNote) for \(minutes)m more"
        }
    }

    // MARK: - Helpers

    private func routineTitle(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "Warm Start Congee"
        case .medium: return "Ginger Honey Tea"
        case .lite: return "Warm Water Ritual"
        }
    }

    private func routineSubtitle(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "Nourishing breakfast to warm your center"
        case .medium: return "Quick warming drink"
        case .lite: return "Simple hydration ritual"
        }
    }

    private func routineDuration(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "10-15 min"
        case .medium: return "5 min"
        case .lite: return "90 sec"
        }
    }

    private func movementTitle(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "Morning Qi Flow"
        case .medium: return "Gentle Stretches"
        case .lite: return "3 Deep Breaths"
        }
    }

    private func movementSubtitle(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "Wake up your body gently"
        case .medium: return "Quick tension release"
        case .lite: return "Reset your nervous system"
        }
    }

    private func movementDuration(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "7 min"
        case .medium: return "3 min"
        case .lite: return "1 min"
        }
    }

    private func isNeedCompletedToday(_ need: QuickNeed) -> Bool {
        let suggestionId = "rightnow-\(need.rawValue)"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return dailyLogs.first { log in
            calendar.startOfDay(for: log.date) == today
        }?.completedRoutineIds.contains(suggestionId) ?? false
    }

    private func markSuggestionComplete(need: QuickNeed, avoidHours: Int?) {
        let suggestionId = "rightnow-\(need.rawValue)"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let todayLog = dailyLogs.first(where: { calendar.startOfDay(for: $0.date) == today }) {
            if !todayLog.completedRoutineIds.contains(suggestionId) {
                todayLog.completedRoutineIds.append(suggestionId)
                todayLog.updatedAt = Date()
            }
            // Record completion time for avoid timer
            todayLog.quickFixCompletionTimes[need.rawValue] = Date()
        } else {
            let newLog = DailyLog()
            newLog.completedRoutineIds.append(suggestionId)
            newLog.quickFixCompletionTimes[need.rawValue] = Date()
            modelContext.insert(newLog)
        }

        do {
            try modelContext.save()
            completedNeed = need
            withAnimation(theme.animation.spring) {
                showCompletionFeedback = true
            }
            HapticManager.success()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(theme.animation.standard) {
                    showCompletionFeedback = false
                }
            }
        } catch {
            print("Failed to save completion: \(error)")
            HapticManager.error()
        }
    }

    private func markRoutineComplete() {
        let routineId = selectedRoutine?.id ?? "warm-start-congee-\(selectedLevel.rawValue)"

        if let log = todaysLog {
            log.markRoutineComplete(routineId, level: selectedLevel)
        } else {
            let log = DailyLog()
            log.markRoutineComplete(routineId, level: selectedLevel)
            modelContext.insert(log)
        }

        updateProgress()
        try? modelContext.save()
    }

    private func markMovementComplete() {
        let movementId = selectedMovement?.id ?? "morning-qi-flow-\(selectedLevel.rawValue)"

        if let log = todaysLog {
            log.markMovementComplete(movementId)
        } else {
            let log = DailyLog()
            log.markMovementComplete(movementId)
            modelContext.insert(log)
        }
        try? modelContext.save()
    }

    private func updateProgress() {
        let fetchDescriptor = FetchDescriptor<ProgressRecord>()
        if let records = try? modelContext.fetch(fetchDescriptor),
           let record = records.first {
            record.recordCompletion()
        }
    }
}

#Preview {
    DoView()
        .environment(\.terrainTheme, TerrainTheme.default)
        .environment(NavigationCoordinator())
}
