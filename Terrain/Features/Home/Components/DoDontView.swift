//
//  DoDontView.swift
//  Terrain
//
//  Two-column Do/Don't behavioral list for the Home tab
//

import SwiftUI

/// Two-column display of personalized do's and don'ts based on terrain type.
/// Clean, scannable format for quick reference throughout the day.
struct DoDontView: View {
    let dos: [DoDontItem]
    let donts: [DoDontItem]

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Do column
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.success)

                    Text("Do")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textPrimary)
                }

                ForEach(dos) { item in
                    DoDontRow(item: item, isDo: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divider
            Rectangle()
                .fill(theme.colors.backgroundSecondary)
                .frame(width: 1)
                .padding(.vertical, theme.spacing.xs)

            // Don't column
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.error)

                    Text("Don't")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textPrimary)
                }

                ForEach(donts) { item in
                    DoDontRow(item: item, isDo: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, theme.spacing.md)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .padding(.horizontal, theme.spacing.lg)
    }
}

/// Individual row in the Do/Don't list with expandable "why" explanation
struct DoDontRow: View {
    let item: DoDontItem
    let isDo: Bool

    @Environment(\.terrainTheme) private var theme
    @State private var isExpanded = false

    init(item: DoDontItem, isDo: Bool) {
        self.item = item
        self.isDo = isDo
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Button(action: {
                if item.whyForYou != nil {
                    withAnimation(theme.animation.quick) {
                        isExpanded.toggle()
                    }
                    HapticManager.selection()
                }
            }) {
                HStack(alignment: .top, spacing: theme.spacing.xs) {
                    Text("·")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(isDo ? theme.colors.success : theme.colors.error)

                    Text(item.text)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.leading)

                    if item.whyForYou != nil {
                        Spacer(minLength: 2)
                        Image(systemName: isExpanded ? "chevron.up" : "info.circle")
                            .font(.system(size: 10))
                            .foregroundColor(theme.colors.textTertiary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded, let why = item.whyForYou {
                Text(why)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.accent)
                    .italic()
                    .padding(.leading, theme.spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    DoDontView(
        dos: [
            DoDontItem(text: "Warm start", priority: 1),
            DoDontItem(text: "Cooked food", priority: 2),
            DoDontItem(text: "Gentle movement", priority: 3),
            DoDontItem(text: "Rest when tired", priority: 4)
        ],
        donts: [
            DoDontItem(text: "Ice drinks", priority: 1),
            DoDontItem(text: "Raw salads", priority: 2),
            DoDontItem(text: "Skipping meals", priority: 3),
            DoDontItem(text: "Overexertion", priority: 4)
        ]
    )
    .padding(.vertical, 40)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
