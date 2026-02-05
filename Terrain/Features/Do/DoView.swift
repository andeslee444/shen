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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
    private let timer = Timer.publish(every: 60, on: .main, in: .common)
    @State private var timerCancellable: (any Cancellable)?

    private let suggestionEngine = SuggestionEngine()

    // Cached computation results (recomputed on log changes, not every render)
    @State private var cachedEffectivenessMap: [String: Double] = [:]
    @State private var cachedSuggestions: [QuickNeed: QuickSuggestion] = [:]

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

    /// Recomputes routine effectiveness scores — call on appear and when logs change
    private func recomputeEffectiveness() {
        let trendEngine = TrendEngine()
        var map: [String: Double] = [:]
        for routine in allRoutines {
            if let score = trendEngine.computeRoutineEffectiveness(logs: dailyLogs, routineId: routine.id) {
                map[routine.id] = score
            }
        }
        cachedEffectivenessMap = map
        cachedSuggestions = [:] // invalidate suggestion cache when data changes
    }

    /// Returns a cached suggestion or computes and caches a new one
    private func cachedSuggestion(for need: QuickNeed) -> QuickSuggestion {
        if let cached = cachedSuggestions[need] {
            return cached
        }
        let result = smartSuggestion(for: need)
        cachedSuggestions[need] = result
        return result
    }

    // MARK: - Day Phase

    /// Current morning/evening phase, derived from the existing 60-second timer.
    /// When the hour crosses 5 PM, SwiftUI re-evaluates and re-renders.
    private var currentPhase: DayPhase {
        DayPhase.current(for: timerTick)
    }

    /// Best routine for current terrain + selected level + day phase.
    ///
    /// Scoring (higher wins):
    ///   - Terrain fit:       +10 (dominant signal — right constitution match)
    ///   - Phase affinity:    +2  per matching tag (e.g., "warming" in morning)
    ///   - Phase anti-affinity: -3 per tag matching the OTHER phase
    ///
    /// Falls back gracefully: best score → any tier match → any routine.
    private var selectedRoutine: Routine? {
        let tier = selectedLevel.rawValue
        let profileId = terrainProfileId ?? ""
        let phase = currentPhase

        let candidates = allRoutines.filter { $0.tier == tier }
        guard !candidates.isEmpty else { return allRoutines.first }

        let scored = candidates.map { routine -> (Routine, Int) in
            var score = 0
            if routine.terrainFit.contains(profileId) { score += 10 }
            score += phase.netPhaseScore(for: routine.tags)
            return (routine, score)
        }
        .sorted { $0.1 > $1.1 }

        return scored.first?.0 ?? allRoutines.first
    }

    /// Best movement for current terrain + selected level + day phase.
    /// Filters by tier first (mirroring routines), then scores by terrain fit,
    /// phase affinity, and intensity match. Falls back to unfiltered if no
    /// tier-matched movements exist (backward compat for content packs
    /// without tier fields).
    private var selectedMovement: Movement? {
        let tier = selectedLevel.rawValue
        let profileId = terrainProfileId ?? ""
        let phase = currentPhase
        let preferredIntensity = phase.preferredIntensity(for: selectedLevel)

        let candidates = allMovements.filter { $0.tier == tier }
        let pool = candidates.isEmpty ? allMovements : candidates

        let scored = pool.map { movement -> (Movement, Int) in
            var score = 0
            if movement.terrainFit.contains(profileId) { score += 10 }
            score += phase.netPhaseScore(for: movement.tags)
            if movement.intensity.rawValue == preferredIntensity { score += 3 }
            return (movement, score)
        }
        .sorted { $0.1 > $1.1 }

        return scored.first?.0 ?? allMovements.first
    }

    /// Quick needs reordered by today's symptoms, with terrain-contradictory needs removed.
    /// A TCM practitioner would never recommend warming herbs to someone running warm.
    private var orderedNeeds: [QuickNeed] {
        let base = suggestionEngine.orderedNeeds(for: todaysSymptoms)
        let profileId = terrainProfileId ?? ""
        let isWarm = profileId.contains("warm")
        let isCold = profileId.contains("cold")

        return base.filter { need in
            if isWarm && need == .warmth { return false }
            if isCold && need == .cooling { return false }
            return true
        }
    }

    /// Dynamic coaching note that rotates by priority:
    /// 1. Completion state → 2. Today's symptoms → 3. TCM organ clock (子午流注)
    /// → 4. Modifier-specific → 5. Evening-specific → 6. Terrain-specific fallback
    private var dynamicCoachingNote: String {
        // 1. Completion state
        if completedCount == 2 {
            return "Both done. Your body is building a new baseline."
        }

        // 2. Today's symptoms
        if todaysSymptoms.contains(.tired) {
            return "Low energy today? Lite level is still real progress."
        }
        if todaysSymptoms.contains(.stressed) {
            return "Stress showing up? Movement first — it unwinds the body faster than food."
        }
        if todaysSymptoms.contains(.poorSleep) {
            return "Rough night? Gentle nourishment over intensity today."
        }

        // 3. TCM organ clock (子午流注)
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 7 && hour < 9 {
            return "Stomach hour (7-9am). Perfect time to nourish your center."
        } else if hour >= 11 && hour < 13 {
            return "Heart time (11am-1pm). A calm practice steadies your afternoon."
        } else if hour >= 17 && hour < 19 {
            return "Kidney hour (5-7pm). Gentle movement replenishes your reserves."
        } else if hour >= 19 {
            return "Evening mode. Gentle movement over intensity tonight."
        }

        // 4. Modifier-specific
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

        // 5. Evening-specific coaching (phase-aware)
        if currentPhase == .evening {
            if profileId.contains("cold") {
                return "Evening warmth matters for you. A gentle routine protects what you built today."
            } else if profileId.contains("warm") {
                return "Evening is your reset. Cooling practices help your body recover."
            } else {
                return "Wind down with intention. Even a small evening practice changes how you sleep."
            }
        }

        // 6. Terrain-specific fallback (morning / no modifier match)
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
            return "Pick the level that fits today. Consistency matters more than intensity."
        }
    }

    // MARK: - Per-Level Completion

    /// Whether the *currently displayed* routine is completed (not any routine across levels).
    private var currentRoutineCompleted: Bool {
        guard let routineId = selectedRoutine?.id else { return false }
        return todaysLog?.completedRoutineIds.contains(routineId) ?? false
    }

    /// Whether the *currently displayed* movement is completed (not any movement across levels).
    private var currentMovementCompleted: Bool {
        guard let movementId = selectedMovement?.id else { return false }
        return todaysLog?.completedMovementIds.contains(movementId) ?? false
    }

    /// Current phase completion count (for the 2 cards shown right now).
    private var completedCount: Int {
        (currentRoutineCompleted ? 1 : 0) + (currentMovementCompleted ? 1 : 0)
    }

    // MARK: - Phase-Aware Progress

    /// Checks if the user completed ANY nourish practice with positive affinity for the given phase.
    /// This lets progress dots aggregate across levels within a phase.
    private func isNourishCompleted(for phase: DayPhase) -> Bool {
        guard let completedIds = todaysLog?.completedRoutineIds else { return false }
        return allRoutines.contains { routine in
            guard completedIds.contains(routine.id) else { return false }
            // Exclude quick-fix IDs (they start with "rightnow-")
            guard !routine.id.hasPrefix("rightnow-") else { return false }
            return phase.netPhaseScore(for: routine.tags) >= 0
        }
    }

    /// Checks if the user completed ANY movement with positive affinity for the given phase.
    private func isMoveCompleted(for phase: DayPhase) -> Bool {
        guard let completedIds = todaysLog?.completedMovementIds else { return false }
        return allMovements.contains { movement in
            completedIds.contains(movement.id) && phase.netPhaseScore(for: movement.tags) >= 0
        }
    }

    /// Whether morning phase had at least one nourish + one movement completed.
    private var morningFullyCompleted: Bool {
        isNourishCompleted(for: .morning) && isMoveCompleted(for: .morning)
    }

    private var dailyProgressText: String {
        let phase = currentPhase
        let phaseNourish = isNourishCompleted(for: phase)
        let phaseMove = isMoveCompleted(for: phase)
        let phaseCount = (phaseNourish ? 1 : 0) + (phaseMove ? 1 : 0)

        // All 4 practices done across both phases
        if morningFullyCompleted && isNourishCompleted(for: .evening) && isMoveCompleted(for: .evening) {
            return "All done. Your body thanks you."
        }

        // Evening: show morning status as prefix
        if phase == .evening && morningFullyCompleted {
            if phaseCount == 2 {
                return "All done. Your body thanks you."
            }
            return "Morning \u{2713} \u{00B7} \(phaseCount) of 2 done"
        }

        switch phaseCount {
        case 2: return "Both done for \(phase == .morning ? "morning" : "evening")."
        case 1: return "1 of 2 done"
        default: return "0 of 2 done"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Manual large title (replaces NavigationStack to prevent pop gesture sliding)
            Text("Do")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.md)
                .padding(.bottom, theme.spacing.xs)

            ZStack {
                ScrollView {
                    VStack(spacing: theme.spacing.xl) {
                        // Level Selector + Progress + Coaching Note
                        VStack(spacing: theme.spacing.sm) {
                            // Daily progress strip — dots track current phase
                            HStack(spacing: theme.spacing.xs) {
                                Circle()
                                    .fill(isNourishCompleted(for: currentPhase) ? theme.colors.success : theme.colors.textTertiary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(isMoveCompleted(for: currentPhase) ? theme.colors.success : theme.colors.textTertiary.opacity(0.3))
                                    .frame(width: 8, height: 8)

                                Text(dailyProgressText)
                                    .font(theme.typography.caption)
                                    .foregroundColor(completedCount == 2 ? theme.colors.success : theme.colors.textSecondary)

                                Spacer()
                            }
                            .padding(.horizontal, theme.spacing.lg)
                            .animation(theme.animation.quick, value: completedCount)

                            levelSelector

                            Text(dynamicCoachingNote)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, theme.spacing.md)
                                .padding(.vertical, theme.spacing.sm)
                                .frame(maxWidth: .infinity)
                                .background(theme.colors.backgroundSecondary)
                                .cornerRadius(theme.cornerRadius.medium)
                                .padding(.horizontal, theme.spacing.lg)
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
        }
        .background(theme.colors.background)
        .sheet(isPresented: $showRoutineDetail) {
            if let routine = selectedRoutine {
                RoutineDetailSheet(
                    level: selectedLevel,
                    routineModel: routine,
                    onComplete: { startedAt in markRoutineComplete(startedAt: startedAt) }
                )
            }
        }
        .sheet(isPresented: $showMovementPlayer) {
            MovementPlayerSheet(
                level: selectedLevel,
                movementModel: selectedMovement,
                onComplete: { startedAt in markMovementComplete(startedAt: startedAt) }
            )
        }
        .onReceive(timer) { _ in
            // Tick the avoid-timer countdown every 60 seconds
            timerTick = Date()
        }
        .onAppear {
            timerCancellable = timer.connect()
            recomputeEffectiveness()
        }
        .onDisappear {
            timerCancellable?.cancel()
            timerCancellable = nil
        }
        .onChange(of: dailyLogs.count) { _, _ in
            recomputeEffectiveness()
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
                    Text("\(level.displayName) · \(level.durationDescription)")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(selectedLevel == level ? theme.colors.textInverted : theme.colors.textSecondary)
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
            // Phase-aware header
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: currentPhase.icon)
                    .font(.system(size: 16))
                    .foregroundColor(currentPhase == .morning ? theme.colors.terrainWarm : theme.colors.terrainCool)
                Text(currentPhase.displayTitle)
                    .font(theme.typography.headlineSmall)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, theme.spacing.lg)
            .animation(theme.animation.standard, value: currentPhase)

            // Routine module — isCompleted checks the SPECIFIC routine shown
            if let routine = selectedRoutine {
                RoutineModuleCard(
                    type: .eatDrink,
                    title: routine.displayName,
                    subtitle: routine.subtitle?.localized ?? "",
                    duration: "\(routine.durationMin) min",
                    isCompleted: currentRoutineCompleted,
                    onTap: { showRoutineDetail = true }
                )
                .padding(.horizontal, theme.spacing.lg)
            } else {
                RoutineModuleCard(
                    type: .eatDrink,
                    title: routineTitle(for: selectedLevel),
                    subtitle: routineSubtitle(for: selectedLevel),
                    duration: routineDuration(for: selectedLevel),
                    isCompleted: currentRoutineCompleted,
                    onTap: { showRoutineDetail = true }
                )
                .padding(.horizontal, theme.spacing.lg)
            }

            // Movement module — isCompleted checks the SPECIFIC movement shown
            if let movement = selectedMovement {
                RoutineModuleCard(
                    type: .movement,
                    title: movement.displayName,
                    subtitle: movement.subtitle?.localized ?? "Wake up your body gently",
                    duration: movement.durationDisplay,
                    isCompleted: currentMovementCompleted,
                    onTap: { showMovementPlayer = true }
                )
                .padding(.horizontal, theme.spacing.lg)
            } else {
                RoutineModuleCard(
                    type: .movement,
                    title: movementTitle(for: selectedLevel),
                    subtitle: movementSubtitle(for: selectedLevel),
                    duration: movementDuration(for: selectedLevel),
                    isCompleted: currentMovementCompleted,
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

            // Quick needs grid — compact 2-column layout
            let columns = [GridItem(.flexible(), spacing: theme.spacing.sm),
                           GridItem(.flexible(), spacing: theme.spacing.sm)]

            LazyVGrid(columns: columns, spacing: theme.spacing.sm) {
                ForEach(orderedNeeds) { need in
                    QuickNeedCompactCard(
                        need: need,
                        isSelected: selectedNeed == need,
                        isCompleted: isNeedCompletedToday(need),
                        onTap: {
                            withAnimation(theme.animation.standard) {
                                selectedNeed = selectedNeed == need ? nil : need
                            }
                            HapticManager.selection()
                        }
                    )
                }
            }
            .padding(.horizontal, theme.spacing.lg)

            // Selected suggestion — powered by SuggestionEngine
            if let need = selectedNeed {
                let suggestion = cachedSuggestion(for: need)
                QuickSuggestionCard(
                    need: need,
                    suggestion: (suggestion.title, suggestion.description, suggestion.avoidHours),
                    isCompleted: isNeedCompletedToday(need),
                    avoidTimeText: avoidTimeText(for: need),
                    whyForYou: generateQuickFixWhy(for: need),
                    onDoThis: {
                        markSuggestionComplete(need: need, avoidHours: suggestion.avoidHours)
                    },
                    onUndo: {
                        undoSuggestionComplete(need: need)
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

                // TCM post-practice micro-guidance
                Text(postPracticeGuidance(for: need))
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, theme.spacing.xxs)
            }
        }
        .padding(theme.spacing.xl)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.xl)
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
        .accessibilityLabel("Completed\(completedNeed.map { ". You completed \($0.displayName.lowercased())" } ?? "")")
        .accessibilityAddTraits(.isStaticText)
    }

    /// TCM post-practice guidance — teaches principles in the moment they matter most
    private func postPracticeGuidance(for need: QuickNeed) -> String {
        switch need {
        case .warmth:
            return "Avoid cold foods and drinks for the next hour."
        case .digestion:
            return "Rest a moment. Let your body focus on processing."
        case .calm:
            return "Hold this stillness. Avoid screens for a few minutes."
        case .energy:
            return "Move gently in the next 20 minutes to circulate the boost."
        case .cooling:
            return "Stay in shade if possible. Avoid heavy meals."
        case .focus:
            return "Channel this clarity now. Start your most important task."
        }
    }

    // MARK: - Suggestion Engine Integration

    /// Calls the SuggestionEngine with full terrain/symptom/time/season/goal/weather context
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
            routineEffectiveness: cachedEffectivenessMap,
            weatherCondition: todaysLog?.weatherCondition,
            alcoholFrequency: userProfile?.alcoholFrequency,
            smokingStatus: userProfile?.smokingStatus,
            stepCount: todaysLog?.stepCount
        )
    }

    // MARK: - Avoid Timer

    /// Calculates remaining avoid window from completion time + avoidHours
    private func avoidTimeRemaining(for need: QuickNeed) -> TimeInterval? {
        guard let log = todaysLog,
              let completionTime = log.quickFixCompletionTimes[need.rawValue] else {
            return nil
        }

        let suggestion = cachedSuggestion(for: need)
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

        let suggestion = cachedSuggestion(for: need)
        let avoidNote = suggestion.avoidNotes ?? "Avoid cold drinks"

        if hours > 0 {
            return "\(avoidNote) for \(hours)h \(minutes)m more"
        } else {
            return "\(avoidNote) for \(minutes)m more"
        }
    }

    // MARK: - Quick Fix Why

    /// Generates a terrain-specific "why" for quick fix suggestions using InsightEngine
    private func generateQuickFixWhy(for need: QuickNeed) -> String? {
        let insightEngine = InsightEngine()
        return insightEngine.generateWhyForYou(
            routineTags: need.relevantTags,
            terrainType: terrainType,
            modifier: terrainModifier
        )
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
            withAnimation(reduceMotion ? nil : theme.animation.spring) {
                showCompletionFeedback = true
            }
            HapticManager.success()

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(reduceMotion ? nil : theme.animation.standard) {
                    showCompletionFeedback = false
                }
            }
        } catch {
            TerrainLogger.persistence.error("Failed to save completion: \(error)")
            HapticManager.error()
        }
    }

    private func undoSuggestionComplete(need: QuickNeed) {
        let suggestionId = "rightnow-\(need.rawValue)"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let todayLog = dailyLogs.first(where: { calendar.startOfDay(for: $0.date) == today }) else { return }

        todayLog.completedRoutineIds.removeAll { $0 == suggestionId }
        todayLog.quickFixCompletionTimes.removeValue(forKey: need.rawValue)
        todayLog.updatedAt = Date()

        do {
            try modelContext.save()
            HapticManager.light()
        } catch {
            TerrainLogger.persistence.error("Failed to undo completion: \(error)")
        }
    }

    private func markRoutineComplete(startedAt: Date? = nil) {
        guard let routineId = selectedRoutine?.id else { return }

        if let log = todaysLog {
            log.markRoutineComplete(routineId, level: selectedLevel, startedAt: startedAt)
        } else {
            let log = DailyLog()
            log.markRoutineComplete(routineId, level: selectedLevel, startedAt: startedAt)
            modelContext.insert(log)
        }

        updateProgress()
        try? modelContext.save()
    }

    private func markMovementComplete(startedAt: Date? = nil) {
        guard let movementId = selectedMovement?.id else { return }

        if let log = todaysLog {
            log.markMovementComplete(movementId, startedAt: startedAt)
        } else {
            let log = DailyLog()
            log.markMovementComplete(movementId, startedAt: startedAt)
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

// MARK: - Module Card (formerly in TodayView.swift)

enum ModuleType {
    case eatDrink
    case movement

    var icon: String {
        switch self {
        case .eatDrink: return "cup.and.saucer.fill"
        case .movement: return "figure.walk"
        }
    }

    var label: String {
        switch self {
        case .eatDrink: return "Nourish"
        case .movement: return "Move"
        }
    }

    func tintColor(theme: TerrainTheme) -> Color {
        switch self {
        case .eatDrink: return theme.colors.terrainWarm
        case .movement: return theme.colors.terrainCool
        }
    }
}

struct RoutineModuleCard: View {
    let type: ModuleType
    let title: String
    let subtitle: String
    let duration: String
    var isCompleted: Bool = false
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    private var tint: Color {
        type.tintColor(theme: theme)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.md) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? theme.colors.success.opacity(0.15) : tint.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: isCompleted ? "checkmark" : type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isCompleted ? theme.colors.success : tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(type.label)
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.textTertiary)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(duration)
                                .font(theme.typography.caption)
                        }
                        .foregroundColor(theme.colors.textTertiary)
                    }

                    Text(title)
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(subtitle)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textTertiary)
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(isCompleted ? theme.colors.success.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DoView()
        .environment(\.terrainTheme, TerrainTheme.default)
        .environment(NavigationCoordinator())
}
