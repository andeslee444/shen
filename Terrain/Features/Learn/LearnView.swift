//
//  LearnView.swift
//  Terrain
//
//  Learn tab with Field Guide lessons and search
//

import SwiftUI
import SwiftData

struct LearnView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(NavigationCoordinator.self) private var coordinator: NavigationCoordinator?
    @Query(sort: \Lesson.id) private var lessons: [Lesson]
    @Query private var userProfiles: [UserProfile]

    @State private var searchText = ""
    @State private var selectedLesson: Lesson?

    private let insightEngine = InsightEngine()

    /// Groups lessons by their topic, returning only topics that have lessons
    private var topicGroups: [(topic: LessonTopic, lessons: [Lesson])] {
        LessonTopic.allCases.compactMap { topic in
            let topicLessons = lessons.filter { $0.topic == topic.rawValue }
            guard !topicLessons.isEmpty else { return nil }
            return (topic: topic, lessons: topicLessons)
        }
    }

    /// Top 3 lessons recommended for the user's terrain type
    private var recommendedLessons: [Lesson] {
        guard let profile = userProfiles.first,
              let terrainId = profile.terrainProfileId,
              let terrainType = TerrainScoringEngine.PrimaryType(rawValue: terrainId) else {
            return []
        }
        let modifier = profile.resolvedModifier
        let goals = profile.goals.map { $0.rawValue }
        return Array(insightEngine.rankLessons(lessons, for: terrainType, modifier: modifier, goals: goals).prefix(3))
    }

    /// Filters topic groups based on search text
    private var filteredTopicGroups: [(topic: LessonTopic, lessons: [Lesson])] {
        if searchText.isEmpty {
            return topicGroups
        }
        return topicGroups.compactMap { group in
            let filteredLessons = group.lessons.filter { lesson in
                lesson.displayName.localizedCaseInsensitiveContains(searchText) ||
                lesson.takeaway.oneLine.localized.localizedCaseInsensitiveContains(searchText)
            }
            guard !filteredLessons.isEmpty else { return nil }
            return (topic: group.topic, lessons: filteredLessons)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Header
                    VStack(spacing: theme.spacing.sm) {
                        Text("Field Guide")
                            .font(theme.typography.headlineLarge)
                            .foregroundColor(theme.colors.textPrimary)

                        Text("Learn the fundamentals of TCM in everyday terms")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)

                    // Search bar
                    searchBar

                    // Recommended for You (terrain-personalized)
                    if !recommendedLessons.isEmpty && searchText.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Recommended for You")
                                .font(theme.typography.labelLarge)
                                .foregroundColor(theme.colors.accent)
                                .padding(.horizontal, theme.spacing.lg)
                                .accessibilityAddTraits(.isHeader)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: theme.spacing.md) {
                                    ForEach(recommendedLessons) { lesson in
                                        Button {
                                            selectedLesson = lesson
                                            HapticManager.light()
                                        } label: {
                                            LessonCard(lesson: lesson)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, theme.spacing.lg)
                            }
                        }
                    }

                    // Topics
                    if topicGroups.isEmpty {
                        VStack(spacing: theme.spacing.md) {
                            ProgressView()
                            Text("Loading lessons...")
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, theme.spacing.xl)
                    } else if filteredTopicGroups.isEmpty {
                        noResultsView
                    } else {
                        ForEach(filteredTopicGroups, id: \.topic) { topicGroup in
                            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                                Text(topicGroup.topic.displayName)
                                    .font(theme.typography.labelLarge)
                                    .foregroundColor(theme.colors.textPrimary)
                                    .padding(.horizontal, theme.spacing.lg)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: theme.spacing.md) {
                                        ForEach(topicGroup.lessons) { lesson in
                                            Button {
                                                selectedLesson = lesson
                                                HapticManager.light()
                                            } label: {
                                                LessonCard(lesson: lesson)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, theme.spacing.lg)
                                }
                            }
                        }
                    }

                    Spacer(minLength: theme.spacing.xxl)
                }
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedLesson) { lesson in
                LessonDetailSheet(
                    lesson: lesson,
                    onCTATapped: handleCTAAction
                )
            }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.textTertiary)

            TextField("Search lessons", text: $searchText)
                .font(theme.typography.bodyMedium)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    HapticManager.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.medium)
        .padding(.horizontal, theme.spacing.lg)
    }

    private var noResultsView: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(theme.colors.textTertiary)

            Text("No lessons found")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            Text("Try a different search term")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xxl)
    }

    // MARK: - Actions

    private func handleCTAAction(_ action: String) {
        coordinator?.handleCTAAction(action)
    }
}

// MARK: - Lesson Card

struct LessonCard: View {
    let lesson: Lesson

    @Environment(\.terrainTheme) private var theme

    private var topicIcon: String {
        guard let topic = LessonTopic(rawValue: lesson.topic) else { return "book.fill" }
        switch topic {
        case .coldHeat: return "thermometer.medium"
        case .dampDry: return "drop.fill"
        case .shen: return "brain.head.profile"
        case .qiFlow: return "wind"
        case .seasonality: return "leaf.fill"
        case .methods: return "cup.and.saucer.fill"
        case .safety: return "shield.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Image placeholder with topic icon
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .fill(theme.colors.backgroundSecondary)
                .frame(width: 200, height: 120)
                .overlay(
                    Image(systemName: topicIcon)
                        .font(.system(size: 32))
                        .foregroundColor(theme.colors.accent.opacity(0.5))
                )

            Text(lesson.displayName)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(2)

            Text(lesson.takeaway.oneLine.localized)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(2)
        }
        .frame(width: 200)
        .padding(theme.spacing.sm)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }
}

#Preview {
    LearnView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
