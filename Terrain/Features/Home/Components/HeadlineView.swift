//
//  HeadlineView.swift
//  Terrain
//
//  Big editorial headline statement for the Home tab
//

import SwiftUI

/// Displays the main personalized headline as a bold editorial statement.
/// This is the "Co-Star moment" - the big insight that sets the tone for the day.
struct HeadlineView: View {
    let content: HeadlineContent

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Text(content.text)
            .font(theme.typography.displayMedium)
            .foregroundColor(theme.colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, theme.spacing.lg)
    }
}

#Preview {
    VStack(spacing: 40) {
        HeadlineView(
            content: HeadlineContent(
                text: "Your energy returns when you warm the center first."
            )
        )

        HeadlineView(
            content: HeadlineContent(
                text: "Pause before you push. Calm is today's foundation.",
                isSymptomAdjusted: true
            )
        )
    }
    .padding(.vertical, 40)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
