//
//  WatchForsView.swift
//  Terrain
//
//  Section E: "When you're off, it often looks like..."
//  Identity-level symptom signatures for the user's terrain type.
//

import SwiftUI

struct WatchForsView: View {
    let items: [WatchForItem]

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("When you're off, it often looks like")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: theme.spacing.sm) {
                    Image(systemName: item.icon)
                        .font(.system(size: 16))
                        .foregroundColor(theme.colors.warning)
                        .frame(width: 24, alignment: .center)

                    Text(item.text)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)
                }
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}
