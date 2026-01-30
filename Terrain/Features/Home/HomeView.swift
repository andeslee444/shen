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

    // Local state for symptom selection
    @State private var selectedSymptoms: Set<QuickSymptom> = []
    @State private var hasSkippedCheckIn = false

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
        return !log.quickSymptoms.isEmpty || hasSkippedCheckIn
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
            symptoms: selectedSymptoms
        )
    }

    private var typeBlockComponents: TypeBlockComponents {
        TypeBlockComponents.from(terrainType: terrainType, modifier: modifier)
    }

    private var doDont: (dos: [DoDontItem], donts: [DoDontItem]) {
        insightEngine.generateDoDont(
            for: terrainType,
            modifier: modifier,
            symptoms: selectedSymptoms
        )
    }

    private var areas: [AreaOfLifeContent] {
        insightEngine.generateAreas(
            for: terrainType,
            modifier: modifier,
            symptoms: selectedSymptoms
        )
    }

    private var theme_: ThemeTodayContent {
        insightEngine.generateTheme(
            for: terrainType,
            modifier: modifier,
            symptoms: selectedSymptoms
        )
    }

    private var seasonalNote: SeasonalNoteContent {
        insightEngine.generateSeasonalNote(
            for: terrainType,
            modifier: modifier
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // 1. Date bar
                    DateBarView(dailyTone: dailyTone)
                        .padding(.top, theme.spacing.md)
                        .accessibilityAddTraits(.isHeader)

                    // 2. Headline
                    HeadlineView(content: headline)
                        .accessibilityAddTraits(.isHeader)

                    // 3. Inline check-in (if not done today) — symptoms sorted by terrain relevance
                    if !hasCheckedInToday {
                        InlineCheckInView(
                            selectedSymptoms: $selectedSymptoms,
                            onSkip: { handleSkipCheckIn() },
                            sortedSymptoms: insightEngine.sortSymptomsByRelevance(for: terrainType, modifier: modifier)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .accessibilityLabel("Quick symptom check-in")
                    }

                    // 4. Type block
                    TypeBlockView(components: typeBlockComponents)

                    // 5. Do/Don't
                    DoDontView(dos: doDont.dos, donts: doDont.donts)
                        .accessibilityLabel("Do and Don't recommendations for your terrain")

                    // 6. Areas of life
                    AreasOfLifeView(areas: areas)

                    // 7. Seasonal note
                    SeasonalCardView(content: seasonalNote)

                    // 8. Theme today
                    ThemeTodayView(content: theme_)

                    // 9. Capsule CTA
                    CapsuleStartCTA(
                        onStart: { navigateToDo() }
                    )
                    .accessibilityLabel("Start your daily routine")
                    .accessibilityHint("Navigate to the Do tab to begin")

                    Spacer(minLength: theme.spacing.xxl)
                }
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                try? await Task.sleep(nanoseconds: 500_000_000)
                HapticManager.success()
            }
            .onAppear {
                loadSavedSymptoms()
            }
            .onChange(of: selectedSymptoms) { _, newValue in
                saveSymptoms(newValue)
            }
        }
    }

    // MARK: - Actions

    private func handleSkipCheckIn() {
        hasSkippedCheckIn = true
        saveSymptoms([])
    }

    private func loadSavedSymptoms() {
        if let log = todaysLog, !log.quickSymptoms.isEmpty {
            selectedSymptoms = Set(log.quickSymptoms)
        }
    }

    private func saveSymptoms(_ symptoms: Set<QuickSymptom>) {
        if let log = todaysLog {
            log.quickSymptoms = Array(symptoms)
            log.updatedAt = Date()
        } else {
            let log = DailyLog(quickSymptoms: Array(symptoms))
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
