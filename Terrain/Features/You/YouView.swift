//
//  YouView.swift
//  Terrain
//
//  The You tab — colorful identity-rich profile screen.
//  Hero header pinned above a Co-Star–style sub-tab picker
//  (Your Terrain / Trends / Settings), with content swapping below.
//

import SwiftUI
import SwiftData

// MARK: - Sub-Tab Enum

enum YouSubTab: String, CaseIterable {
    case terrain = "Your Terrain"
    case trends = "Trends"
    case settings = "Settings"
}

// MARK: - YouView

struct YouView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Query private var userProfiles: [UserProfile]
    @Query private var progressRecords: [ProgressRecord]
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @Query(sort: \Routine.id) private var allRoutines: [Routine]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showRetakeQuizConfirmation = false
    @State private var selectedSubTab: YouSubTab = .terrain
    @State private var showPatternMap = false
    @State private var showReference = false
    @Namespace private var tabNamespace

    private let constitutionService = ConstitutionService()
    private let trendEngine = TrendEngine()

    // MARK: - Computed Properties

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    private var progress: ProgressRecord? {
        progressRecords.first
    }

    private var terrainType: TerrainScoringEngine.PrimaryType? {
        guard let profile = userProfile,
              let terrainId = profile.terrainProfileId else {
            return nil
        }
        return TerrainScoringEngine.PrimaryType(rawValue: terrainId)
    }

    private var terrainModifier: TerrainScoringEngine.Modifier {
        userProfile?.resolvedModifier ?? .none
    }

    // Constitution readout (used by Enhanced Pattern Map)
    private var constitutionReadout: ConstitutionReadout? {
        guard let profile = userProfile else { return nil }
        return constitutionService.generateReadout(
            vector: profile.terrainVector,
            modifier: terrainModifier
        )
    }

    // Terrain identity copy (superpower, trap, ritual, truths)
    private var terrainCopy: TerrainCopy? {
        guard let type = terrainType else { return nil }
        return TerrainCopy.forType(type, modifier: terrainModifier)
    }

    // Signal explanations
    private var signals: [SignalExplanation]? {
        guard let profile = userProfile else { return nil }
        return constitutionService.generateSignals(responses: profile.quizResponses)
    }

    // Section D: Defaults
    private var defaults: DefaultsContent? {
        guard let type = terrainType else { return nil }
        return constitutionService.generateDefaults(type: type, modifier: terrainModifier)
    }

    // Section E: Watch-fors
    private var watchFors: [WatchForItem]? {
        guard let type = terrainType else { return nil }
        return constitutionService.generateWatchFors(type: type, modifier: terrainModifier)
    }

    // Section F: Trends
    private var trends: [TrendResult] {
        trendEngine.computeTrends(logs: Array(dailyLogs))
    }

    /// Routine effectiveness scores for routines the user has completed
    private var routineScores: [(name: String, score: Double)] {
        let logs = Array(dailyLogs)
        // Find routines that have feedback entries
        let routineIdsWithFeedback = Set(logs.flatMap { $0.routineFeedback.map(\.routineOrMovementId) })

        return routineIdsWithFeedback.compactMap { routineId in
            guard let score = trendEngine.computeRoutineEffectiveness(logs: logs, routineId: routineId) else {
                return nil
            }
            let name = allRoutines.first(where: { $0.id == routineId })?.displayName ?? routineId
            return (name: name, score: score)
        }
        .sorted { abs($0.score) > abs($1.score) } // most impactful first
    }

    /// Generates 1-2 Daily Brief items from defaults/watch-fors relevant to today's symptoms or recent trends
    private var dailyBriefItems: [(icon: String, text: String)] {
        var items: [(icon: String, text: String)] = []

        // Check today's symptoms from the most recent log
        let todaySymptoms = dailyLogs.first?.quickSymptoms ?? []

        // Pick a relevant watch-for if user has symptoms today
        if let watchFors = watchFors, !todaySymptoms.isEmpty {
            // Find a watch-for that feels relevant to having symptoms
            if let item = watchFors.first {
                items.append((icon: item.icon, text: item.text))
            }
        }

        // Pick a relevant default (best or avoid)
        if let defaults = defaults {
            if !defaults.bestDefaults.isEmpty {
                let tip = defaults.bestDefaults.randomElement() ?? defaults.bestDefaults[0]
                items.append((icon: "checkmark.seal", text: tip))
            }
            if items.count < 2, !defaults.avoidDefaults.isEmpty {
                let avoid = defaults.avoidDefaults.randomElement() ?? defaults.avoidDefaults[0]
                items.append((icon: "exclamationmark.triangle", text: avoid))
            }
        }

        // If we still have nothing, show a generic terrain note
        if items.isEmpty, let copy = terrainCopy {
            items.append((icon: "sparkles", text: copy.superpower))
        }

        return Array(items.prefix(2))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {

                    // Co-Star–style sub-tab picker
                    subTabPicker

                    // Swappable content based on selected tab
                    switch selectedSubTab {
                    case .terrain:
                        terrainTabContent
                    case .trends:
                        trendsTabContent
                    case .settings:
                        settingsTabContent
                    }

                    Spacer(minLength: theme.spacing.xxl)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.md)
            }
            .background(theme.colors.background)
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Retake Quiz?",
                isPresented: $showRetakeQuizConfirmation,
                titleVisibility: .visible
            ) {
                Button("Retake Quiz", role: .destructive) {
                    retakeQuiz()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset your terrain profile. Your progress and logged data will be preserved.")
            }
        }
    }

    // MARK: - Sub-Tab Picker

    private var subTabPicker: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(YouSubTab.allCases, id: \.self) { tab in
                    Button {
                        HapticManager.light()
                        withAnimation(theme.animation.quick) {
                            selectedSubTab = tab
                        }
                    } label: {
                        VStack(spacing: theme.spacing.xs) {
                            Text(tab.rawValue)
                                .font(theme.typography.labelLarge)
                                .fontWeight(selectedSubTab == tab ? .semibold : .regular)
                                .foregroundStyle(
                                    selectedSubTab == tab
                                        ? theme.colors.textPrimary
                                        : theme.colors.textTertiary
                                )

                            // Accent underline — slides via matchedGeometryEffect
                            if selectedSubTab == tab {
                                Capsule()
                                    .fill(theme.colors.accent)
                                    .frame(height: 2)
                                    .matchedGeometryEffect(id: "underline", in: tabNamespace)
                            } else {
                                Capsule()
                                    .fill(Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var terrainTabContent: some View {
        // Daily Brief — dynamic, relevant-today card
        if !dailyBriefItems.isEmpty {
            dailyBriefCard
        }

        // Terrain Hero Header — always visible (identity)
        if let type = terrainType {
            TerrainHeroHeaderView(
                terrainType: type,
                modifier: terrainModifier
            )
        }

        // Superpower + Trap — always visible (most-used info)
        if let copy = terrainCopy {
            TerrainIdentityView(terrainCopy: copy)
        }

        // Collapsible: Your Pattern Map
        if let readout = constitutionReadout,
           let profile = userProfile {
            disclosureSection(
                title: "Your Pattern Map",
                icon: "chart.bar.xaxis",
                isExpanded: $showPatternMap
            ) {
                EnhancedPatternMapView(
                    readout: readout,
                    vector: profile.terrainVector
                )
            }
        }

        // How We Got This (SignalsView has its own expand/collapse)
        SignalsView(
            signals: signals,
            onRetakeQuiz: { showRetakeQuizConfirmation = true }
        )

        // Collapsible: Reference (Defaults + Watch-Fors)
        if defaults != nil || watchFors != nil {
            disclosureSection(
                title: "Reference",
                icon: "book",
                isExpanded: $showReference
            ) {
                VStack(spacing: theme.spacing.md) {
                    if let defaults = defaults {
                        DefaultsView(defaults: defaults)
                    }
                    if let watchFors = watchFors {
                        WatchForsView(items: watchFors)
                    }
                }
            }
        }
    }

    // MARK: - Daily Brief Card

    private var dailyBriefCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "leaf")
                    .foregroundColor(theme.colors.accent)
                    .font(.system(size: 14))
                Text("Daily Brief")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                ForEach(Array(dailyBriefItems.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: theme.spacing.sm) {
                        Image(systemName: item.icon)
                            .foregroundColor(theme.colors.accent)
                            .font(.system(size: 13))
                            .frame(width: 20, alignment: .center)
                        Text(item.text)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Disclosure Section Helper

    private func disclosureSection<Content: View>(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button {
                HapticManager.light()
                withAnimation(theme.animation.standard) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(theme.colors.accent)
                        .font(.system(size: 14))
                    Text(title)
                        .font(theme.typography.labelLarge)
                        .foregroundColor(theme.colors.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .foregroundColor(theme.colors.textTertiary)
                        .font(.system(size: 12))
                }
                .padding(theme.spacing.md)
            }
            .buttonStyle(PlainButtonStyle())
            .background(theme.colors.surface)
            .cornerRadius(isExpanded.wrappedValue ? 0 : theme.cornerRadius.large)
            .accessibilityLabel("\(title), \(isExpanded.wrappedValue ? "expanded" : "collapsed")")
            .accessibilityHint("Double tap to \(isExpanded.wrappedValue ? "collapse" : "expand")")
            .accessibilityAddTraits(.isHeader)

            if isExpanded.wrappedValue {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private var trendsTabContent: some View {
        EvolutionTrendsView(
            trends: trends,
            routineScores: routineScores,
            currentStreak: progress?.currentStreak ?? 0,
            longestStreak: progress?.longestStreak ?? 0,
            totalCompletions: progress?.totalCompletions ?? 0,
            dailyLogs: dailyLogs
        )
    }

    @ViewBuilder
    private var settingsTabContent: some View {
        PreferencesSafetyView(
            showRetakeQuizConfirmation: $showRetakeQuizConfirmation,
            userProfile: userProfile
        )
    }

    // MARK: - Actions

    private func retakeQuiz() {
        if let profiles = try? modelContext.fetch(FetchDescriptor<UserProfile>()) {
            for profile in profiles {
                modelContext.delete(profile)
            }
            try? modelContext.save()
        }
        hasCompletedOnboarding = false
        HapticManager.success()
    }
}

#Preview {
    YouView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
