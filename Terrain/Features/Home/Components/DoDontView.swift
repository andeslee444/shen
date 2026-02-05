//
//  DoDontView.swift
//  Terrain
//
//  Clean list-style Do/Don't recommendations matching "Your Day" section vibe
//

import SwiftUI

/// Clean list display of personalized do's and don'ts based on terrain type.
/// Matches the visual style of the "Your Day" life areas section.
struct DoDontView: View {
    let dos: [DoDontItem]
    let donts: [DoDontItem]

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            // Do section
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Do")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, theme.spacing.lg)

                DoDontListSection(items: dos, isDo: true)
            }

            // Don't section
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Don't")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, theme.spacing.lg)

                DoDontListSection(items: donts, isDo: false)
            }
        }
    }
}

/// List section for Do or Don't items
struct DoDontListSection: View {
    let items: [DoDontItem]
    let isDo: Bool

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                DoDontRow(item: item, isDo: isDo)

                if item.id != items.last?.id {
                    Divider()
                        .padding(.leading, theme.spacing.lg + 20)
                }
            }
        }
        .padding(.horizontal, theme.spacing.lg)
    }
}

/// Individual row - static display, not tappable
struct DoDontRow: View {
    let item: DoDontItem
    let isDo: Bool

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            // Indicator (checkmark or X)
            indicator
                .frame(width: 12, height: 12)
                .padding(.top, 4)

            // Item text and why
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(item.text)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)

                if let why = item.whyForYou {
                    Text(why)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, theme.spacing.sm)
    }

    @ViewBuilder
    private var indicator: some View {
        if isDo {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(theme.colors.success)
        } else {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(theme.colors.error)
        }
    }
}

#Preview("Do/Don't List") {
    ScrollView {
        VStack(spacing: 24) {
            DoDontView(
                dos: [
                    DoDontItem(text: "Moistening foods", priority: 1, whyForYou: "Your warmth dries you out from inside. Moistening foods like pear and honey replenish what heat depletes."),
                    DoDontItem(text: "Early rest", priority: 2, whyForYou: "You burn bright but thin. Evening rest prevents the wired-tired state your type is prone to."),
                    DoDontItem(text: "Gentle hydration", priority: 3, whyForYou: "Sipping throughout the day keeps you nourished. Gulping cold water shocks your system."),
                    DoDontItem(text: "Calming routine", priority: 4, whyForYou: "Your mind races more than most. A structured wind-down gives your spirit a place to settle.")
                ],
                donts: [
                    DoDontItem(text: "Drying foods", priority: 1, whyForYou: "Your warmth already dries you out. Dry, crunchy foods accelerate fluid loss."),
                    DoDontItem(text: "Excess coffee", priority: 2, whyForYou: "Coffee heats and dries — both things your type needs less of."),
                    DoDontItem(text: "Late nights", priority: 3, whyForYou: "Night is your repair window. Your reserves are thinner — use sleep wisely."),
                    DoDontItem(text: "Screen time late", priority: 4, whyForYou: "Screens stimulate an already-active mind. Your shen needs quiet signals to settle for sleep.")
                ]
            )
        }
        .padding(.vertical, 24)
    }
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
