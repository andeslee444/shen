//
//  HeadlineView.swift
//  Terrain
//
//  Two-word wisdom + flowing truths for the Home tab
//

import SwiftUI

/// Displays the main personalized headline as bold two-word wisdom
/// followed by flowing one-liner truths about the person's terrain.
struct HeadlineView: View {
    let content: HeadlineContent

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // Punchy headline — big and bold (2-5 words)
            Text(content.headline)
                .font(theme.typography.displayLarge)
                .foregroundColor(theme.colors.textPrimary)

            // Flowing paragraph — personalized truths as continuous prose
            if !content.paragraph.isEmpty {
                Text(content.paragraph)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.spacing.lg)
    }
}

#Preview("Cold Deficient + Stressed") {
    HeadlineView(
        content: HeadlineContent(
            headline: "Breathe first.",
            paragraph: "Stress tightens the Liver and blocks qi flow. Your nervous system is asking for pause, not push. Your Spleen needs warmth to transform food into energy. Cold patterns run deep—rebuild with patience.",
            isSymptomAdjusted: true
        )
    )
    .padding(.vertical, 40)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Warm Excess Baseline") {
    HeadlineView(
        content: HeadlineContent(
            headline: "Cool down.",
            paragraph: "Your Liver holds tension—release before it builds. Intensity without rest depletes even strong reserves. Heat outside compounds heat within. Cool foods and slow pace.",
            isSymptomAdjusted: false
        )
    )
    .padding(.vertical, 40)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Neutral Balanced with Steps") {
    HeadlineView(
        content: HeadlineContent(
            headline: "Stay anchored.",
            paragraph: "Balance is your gift—protect it with rhythm. Your body knows what it needs. Listen. Active day. Your qi is flowing well.",
            isSymptomAdjusted: false
        )
    )
    .padding(.vertical, 40)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
