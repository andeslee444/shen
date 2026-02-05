//
//  HomeView.swift
//  Terrain
//
//  Main Home tab orchestrating insight-driven content.
//  Combines editorial headlines, check-in, do/don'ts, and life areas.
//

import SwiftUI
import SwiftData

/// The Home tab - insight + meaning + direction (Co-Star style).
/// Displays personalized daily guidance based on terrain type and current symptoms.
struct HomeView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationCoordinator.self) private var coordinator

    @Query private var userProfiles: [UserProfile]
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]

    // Local state for symptom selection and mood
    @State private var selectedSymptoms: Set<QuickSymptom> = []
    @State private var moodRating: Int? = nil
    @State private var hasSkippedCheckIn = false
    @State private var saveTask: Task<Void, Never>?

    // TCM diagnostic signals (Phase 13)
    @State private var sleepQuality: SleepQuality?
    @State private var dominantEmotion: DominantEmotion?
    @State private var thermalFeeling: ThermalFeeling?
    @State private var digestiveState: DigestiveState?

    // Life area detail sheet state (Phase 15)
    @State private var selectedLifeAreaReading: LifeAreaReading?
    @State private var selectedModifierReading: ModifierAreaReading?

    // Daily survey sheet state
    @State private var showingSurveySheet = false

    // Weather service — fetches once per calendar day
    @State private var weatherService = WeatherService()

    // Health service — fetches step count once per calendar day
    @State private var healthService = HealthService()

    // Insight engine instance
    private let insightEngine = InsightEngine()

    // MARK: - Computed Properties

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    private var terrainType: TerrainScoringEngine.PrimaryType {
        guard let profile = userProfile,
              let terrainId = profile.terrainProfileId,
              let type = TerrainScoringEngine.PrimaryType(rawValue: terrainId) else {
            return .neutralBalanced // Default fallback
        }
        return type
    }

    private var modifier: TerrainScoringEngine.Modifier {
        userProfile?.resolvedModifier ?? .none
    }

    private var todaysLog: DailyLog? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return dailyLogs.first { calendar.startOfDay(for: $0.date) == today }
    }

    private var hasCheckedInToday: Bool {
        guard let log = todaysLog else { return false }
        return !log.quickSymptoms.isEmpty || log.moodRating != nil || hasSkippedCheckIn
    }

    // MARK: - Generated Content

    private var dailyTone: DailyTone {
        DailyTone.forTerrain(
            terrainType,
            modifier: modifier,
            weatherCondition: todaysLog?.weatherCondition
        )
    }

    private var headline: HeadlineContent {
        insightEngine.generateHeadline(
            for: terrainType,
            modifier: modifier,
            symptoms: selectedSymptoms,
            weatherCondition: todaysLog?.weatherCondition,
            stepCount: healthService.dailyStepCount
        )
    }

    private var typeBlockComponents: TypeBlockComponents {
        TypeBlockComponents.from(terrainType: terrainType, modifier: modifier)
    }

    private var doDont: (dos: [DoDontItem], donts: [DoDontItem]) {
        insightEngine.generateDoDont(
            for: terrainType,
            modifier: modifier,
            symptoms: selectedSymptoms,
            weatherCondition: todaysLog?.weatherCondition,
            alcoholFrequency: userProfile?.alcoholFrequency,
            smokingStatus: userProfile?.smokingStatus,
            stepCount: healthService.dailyStepCount
        )
    }

    private var areas: [AreaOfLifeContent] {
        insightEngine.generateAreas(
            for: terrainType,
            modifier: modifier,
            symptoms: selectedSymptoms,
            sleepQuality: sleepQuality,
            dominantEmotion: dominantEmotion,
            thermalFeeling: thermalFeeling,
            digestiveState: digestiveState
        )
    }

    private var lifeAreaReadings: [LifeAreaReading] {
        insightEngine.generateLifeAreaReadings(
            for: terrainType,
            modifier: modifier,
            symptoms: selectedSymptoms,
            weatherCondition: todaysLog?.weatherCondition,
            stepCount: healthService.dailyStepCount
        )
    }

    private var modifierAreaReadings: [ModifierAreaReading] {
        insightEngine.generateModifierAreaReadings(
            for: terrainType,
            modifier: modifier,
            symptoms: selectedSymptoms
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // 1. Header with date, weather, and steps
                    HomeHeaderView(
                        temperatureCelsius: weatherService.temperatureCelsius,
                        weatherCondition: weatherService.currentCondition,
                        stepCount: healthService.dailyStepCount
                    )
                    .padding(.top, theme.spacing.md)
                    .accessibilityAddTraits(.isHeader)

                    // 2. Headline
                    HeadlineView(content: headline)
                        .accessibilityAddTraits(.isHeader)

                    // 3. Type block
                    TypeBlockView(components: typeBlockComponents)

                    // 4. Action buttons
                    VStack(spacing: theme.spacing.sm) {
                        // Daily Survey button
                        Button(action: {
                            HapticManager.light()
                            showingSurveySheet = true
                        }) {
                            HStack(spacing: theme.spacing.xs) {
                                Image(systemName: "list.clipboard")
                                    .font(.system(size: 18))
                                Text("Daily Survey")
                                    .font(theme.typography.labelLarge)
                            }
                            .foregroundColor(theme.colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.md)
                            .background(theme.colors.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                                    .stroke(theme.colors.accent, lineWidth: 1.5)
                            )
                            .cornerRadius(theme.cornerRadius.large)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityLabel("Daily Survey")
                        .accessibilityHint("Open daily check-in survey")

                        // Start Today's Practice button
                        CapsuleStartCTA(
                            onStart: { navigateToDo() }
                        )
                        .accessibilityLabel("Start your daily practice")
                        .accessibilityHint("Navigate to the Do tab to begin")
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    // Divider: identity zone → guidance zone
                    Divider()
                        .padding(.horizontal, theme.spacing.xl)

                    // 6. Do/Don't
                    DoDontView(dos: doDont.dos, donts: doDont.donts)
                        .accessibilityLabel("Do and Don't recommendations for your terrain")

                    // 7. Life areas (Co-Star style with dot indicators)
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Your day")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .padding(.horizontal, theme.spacing.lg)

                        LifeAreasSection(
                            readings: lifeAreaReadings,
                            selectedReading: $selectedLifeAreaReading
                        )
                    }

                    // 8. Modifier areas (only when modifier-specific conditions are active)
                    ModifierAreasSection(
                        readings: modifierAreaReadings,
                        selectedReading: $selectedModifierReading
                    )

                    Spacer(minLength: theme.spacing.xxl)
                }
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                loadSavedSymptoms()
                HapticManager.success()
            }
            .onAppear {
                loadSavedSymptoms()
            }
            .task {
                await weatherService.fetchWeatherIfNeeded(for: todaysLog)
                await healthService.fetchHealthDataIfNeeded(for: todaysLog)
            }
            .onChange(of: selectedSymptoms) { _, _ in
                scheduleSave()
            }
            .onChange(of: moodRating) { _, _ in
                scheduleSave()
            }
            .onChange(of: sleepQuality) { _, _ in
                scheduleSave()
            }
            .onChange(of: dominantEmotion) { _, _ in
                scheduleSave()
            }
            .onChange(of: thermalFeeling) { _, _ in
                scheduleSave()
            }
            .onChange(of: digestiveState) { _, _ in
                scheduleSave()
            }
            .sheet(item: $selectedLifeAreaReading) { reading in
                LifeAreaDetailSheet(
                    reading: reading,
                    onAccuracyFeedback: { isAccurate in
                        saveAccuracyFeedback(for: reading, isAccurate: isAccurate)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedModifierReading) { reading in
                ModifierAreaDetailSheet(
                    reading: reading,
                    onAccuracyFeedback: { isAccurate in
                        saveModifierAccuracyFeedback(for: reading, isAccurate: isAccurate)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSurveySheet) {
                DailySurveySheet(
                    selectedSymptoms: $selectedSymptoms,
                    moodRating: $moodRating,
                    sleepQuality: $sleepQuality,
                    dominantEmotion: $dominantEmotion,
                    thermalFeeling: $thermalFeeling,
                    digestiveState: $digestiveState,
                    sortedSymptoms: insightEngine.sortSymptomsByRelevance(for: terrainType, modifier: modifier, weatherCondition: todaysLog?.weatherCondition),
                    onDismiss: {
                        showingSurveySheet = false
                        scheduleSave()
                    }
                )
                .presentationDetents([.fraction(0.7), .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Accuracy Feedback

    /// Saves accuracy feedback for a life area reading (for future ML training)
    private func saveAccuracyFeedback(for reading: LifeAreaReading, isAccurate: Bool) {
        TerrainLogger.persistence.info("Accuracy feedback: \(reading.type.rawValue) - \(isAccurate ? "accurate" : "not accurate")")
    }

    /// Saves accuracy feedback for a modifier area reading (for future ML training)
    private func saveModifierAccuracyFeedback(for reading: ModifierAreaReading, isAccurate: Bool) {
        TerrainLogger.persistence.info("Modifier accuracy feedback: \(reading.type.rawValue) - \(isAccurate ? "accurate" : "not accurate")")
    }

    // MARK: - Actions

    /// Coalesces rapid-fire onChange calls into a single save.
    /// When confirmSelection() sets both symptoms and mood in sequence,
    /// the first onChange cancels nothing, the second cancels the first,
    /// and only one save executes with both values settled.
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            saveCheckIn(symptoms: selectedSymptoms, mood: moodRating)
        }
    }

    private func handleSkipCheckIn() {
        hasSkippedCheckIn = true
        saveCheckIn(symptoms: [], mood: nil)
    }

    private func loadSavedSymptoms() {
        if let log = todaysLog {
            if !log.quickSymptoms.isEmpty {
                selectedSymptoms = Set(log.quickSymptoms)
            }
            moodRating = log.moodRating
            // Load TCM diagnostic data
            sleepQuality = log.sleepQuality
            dominantEmotion = log.dominantEmotion
            thermalFeeling = log.thermalFeeling
            digestiveState = log.digestiveState
        }
    }

    private func saveCheckIn(symptoms: Set<QuickSymptom>, mood: Int?) {
        if let log = todaysLog {
            log.quickSymptoms = Array(symptoms)
            log.moodRating = mood
            // Save TCM diagnostic data
            log.sleepQuality = sleepQuality
            log.dominantEmotion = dominantEmotion
            log.thermalFeeling = thermalFeeling
            log.digestiveState = digestiveState
            log.updatedAt = Date()
        } else {
            let log = DailyLog(quickSymptoms: Array(symptoms), moodRating: mood)
            // Set TCM diagnostic data on new log
            log.sleepQuality = sleepQuality
            log.dominantEmotion = dominantEmotion
            log.thermalFeeling = thermalFeeling
            log.digestiveState = digestiveState
            modelContext.insert(log)
        }

        try? modelContext.save()
    }

    private func navigateToDo() {
        coordinator.navigate(to: .do)
    }
}

#Preview {
    HomeView()
        .environment(\.terrainTheme, TerrainTheme.default)
        .environment(NavigationCoordinator())
}
