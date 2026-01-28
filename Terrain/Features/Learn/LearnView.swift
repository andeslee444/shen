//
//  LearnView.swift
//  Terrain
//
//  Learn tab with Field Guide lessons
//

import SwiftUI

struct LearnView: View {
    @Environment(\.terrainTheme) private var theme

    private let topics: [(topic: LessonTopic, lessons: [LessonPreview])] = [
        (.coldHeat, [
            LessonPreview(title: "Understanding Cold & Heat", description: "What does it mean to 'run cold' or 'run hot'?"),
            LessonPreview(title: "Signs of Cold", description: "How to recognize cold patterns in your body"),
            LessonPreview(title: "Signs of Heat", description: "How to recognize heat patterns in your body")
        ]),
        (.dampDry, [
            LessonPreview(title: "Damp vs Dry", description: "The moisture balance in TCM"),
            LessonPreview(title: "Signs of Dampness", description: "Heaviness, puffiness, and sluggish digestion"),
            LessonPreview(title: "Signs of Dryness", description: "Thirst, dry skin, and constipation")
        ]),
        (.shen, [
            LessonPreview(title: "What is Shen?", description: "The mind-spirit connection in TCM"),
            LessonPreview(title: "Calming the Shen", description: "Practices for better sleep and mental peace")
        ]),
        (.qiFlow, [
            LessonPreview(title: "Understanding Qi", description: "What Qi means in everyday terms"),
            LessonPreview(title: "Moving Stuck Qi", description: "Simple ways to improve flow")
        ]),
        (.methods, [
            LessonPreview(title: "Warming Methods", description: "How to prepare warming foods"),
            LessonPreview(title: "Cooling Methods", description: "How to prepare cooling foods")
        ])
    ]

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

                    // Topics
                    ForEach(topics, id: \.topic) { topicGroup in
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text(topicGroup.topic.displayName)
                                .font(theme.typography.labelLarge)
                                .foregroundColor(theme.colors.textPrimary)
                                .padding(.horizontal, theme.spacing.lg)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: theme.spacing.md) {
                                    ForEach(topicGroup.lessons, id: \.title) { lesson in
                                        LessonCard(lesson: lesson)
                                    }
                                }
                                .padding(.horizontal, theme.spacing.lg)
                            }
                        }
                    }

                    Spacer(minLength: theme.spacing.xxl)
                }
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct LessonPreview {
    let title: String
    let description: String
}

struct LessonCard: View {
    let lesson: LessonPreview

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Image placeholder
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .fill(theme.colors.backgroundSecondary)
                .frame(width: 200, height: 120)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 32))
                        .foregroundColor(theme.colors.accent.opacity(0.5))
                )

            Text(lesson.title)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(2)

            Text(lesson.description)
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
