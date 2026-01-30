//
//  LessonDetailSheet.swift
//  Terrain
//
//  Full lesson detail modal with body blocks and takeaways
//

import SwiftUI

/// Displays comprehensive lesson content from the Field Guide.
/// Think of this as a mini-article that unfolds to teach one concept at a time,
/// with actionable takeaways and optional calls to action.
struct LessonDetailSheet: View {
    let lesson: Lesson
    var onCTATapped: ((String) -> Void)?

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Header
                    headerSection

                    // Body blocks
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        ForEach(lesson.body) { block in
                            LessonBlockView(block: block)
                        }
                    }

                    // Takeaway card
                    takeawayCard

                    // Call to action (if present)
                    if let cta = lesson.cta {
                        ctaSection(cta)
                    }

                    Spacer(minLength: theme.spacing.xxl)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.md)
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(theme.colors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // Topic chip
            if let topic = LessonTopic(rawValue: lesson.topic) {
                TerrainChip(title: topic.displayName, isSelected: true)
            }

            // Title
            Text(lesson.displayName)
                .font(theme.typography.headlineLarge)
                .foregroundColor(theme.colors.textPrimary)

            // Takeaway preview
            Text(lesson.takeaway.oneLine.localized)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
    }

    // MARK: - Takeaway Card

    private var takeawayCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.accent)

                Text("Key Takeaway")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
            }

            Text(lesson.takeaway.oneLine.localized)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.accent.opacity(0.08))
        .cornerRadius(theme.cornerRadius.large)
    }

    // MARK: - CTA Section

    private func ctaSection(_ cta: LessonCTA) -> some View {
        Button {
            HapticManager.light()
            onCTATapped?(cta.action)
            dismiss()
        } label: {
            HStack(spacing: theme.spacing.sm) {
                Text(cta.label.localized)
                    .font(theme.typography.labelLarge)

                Image(systemName: ctaIcon(for: cta.action))
                    .font(.system(size: 14))
            }
            .foregroundColor(theme.colors.textInverted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.accent)
            .cornerRadius(theme.cornerRadius.large)
        }
    }

    private func ctaIcon(for action: String) -> String {
        switch action {
        case "open_today": return "sun.max"
        case "open_right_now": return "bolt"
        case "open_ingredients": return "leaf"
        case "open_routine": return "list.bullet"
        case "open_movement": return "figure.walk"
        default: return "arrow.right"
        }
    }
}

// MARK: - Lesson Block View

/// Renders a single content block within a lesson.
/// Blocks can be paragraphs, bullet lists, callouts, or images.
struct LessonBlockView: View {
    let block: LessonBlock

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        switch block.type {
        case .paragraph:
            paragraphView

        case .bullets:
            bulletsView

        case .callout:
            calloutView

        case .image:
            imageView
        }
    }

    // MARK: - Block Type Views

    private var paragraphView: some View {
        Group {
            if let text = block.text {
                Text(text.localized)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var bulletsView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if let bullets = block.bullets {
                ForEach(Array(bullets.enumerated()), id: \.offset) { index, bullet in
                    HStack(alignment: .top, spacing: theme.spacing.sm) {
                        Circle()
                            .fill(theme.colors.accent)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)

                        Text(bullet.localized)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var calloutView: some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            Image(systemName: "quote.opening")
                .font(.system(size: 16))
                .foregroundColor(theme.colors.accent)

            if let text = block.text {
                Text(text.localized)
                    .font(theme.typography.bodyMedium)
                    .italic()
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }

    private var imageView: some View {
        Group {
            if let asset = block.asset {
                VStack(spacing: theme.spacing.xs) {
                    // Image placeholder (actual image loading would go here)
                    RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                        .fill(theme.colors.backgroundSecondary)
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(theme.colors.textTertiary)
                        )

                    // Alt text / caption
                    if let alt = asset.alt {
                        Text(alt.localized)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                            .italic()
                    }

                    // Credit
                    if let credit = asset.credit {
                        Text("Credit: \(credit.localized)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LessonDetailSheet(
        lesson: Lesson(
            id: "understanding_cold_heat",
            title: "Understanding Cold & Heat",
            topic: "cold_heat",
            body: [
                .paragraph("In TCM, temperature isn't just about what the thermometer says. It's about how your body tends to run internally."),
                .bullets([
                    "Cold types often feel chilly, even in warm rooms",
                    "Warm types may run hot and prefer cooler environments",
                    "Neutral types adapt easily to temperature changes"
                ]),
                .callout("Your internal temperature tendency influences which foods and practices work best for you."),
                .paragraph("Understanding your thermal nature helps you make better choices about what to eat, drink, and how to care for yourself through the seasons.")
            ],
            takeaway: Takeaway(oneLine: "Your body's temperature tendency is a key to personalizing your daily rituals."),
            cta: LessonCTA(label: "See your personalized routine", action: "open_today")
        ),
        onCTATapped: { action in
            print("CTA tapped: \(action)")
        }
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
