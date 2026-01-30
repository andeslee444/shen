//
//  DateBarView.swift
//  Terrain
//
//  Date display with daily tone pill for the Home tab header
//

import SwiftUI

/// Displays the current date and daily tone indicator.
/// Example: "Wednesday · Jan 28" with a tappable "Balance Day · Dry air" pill.
struct DateBarView: View {
    let dailyTone: DailyTone
    var onToneTap: (() -> Void)? = nil

    @Environment(\.terrainTheme) private var theme

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            Text(dateString)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textSecondary)

            Spacer()

            // Daily tone pill
            Button(action: { onToneTap?() }) {
                HStack(spacing: theme.spacing.xxs) {
                    Text(toneText)
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textSecondary)

                    if onToneTap != nil {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(theme.colors.textTertiary)
                    }
                }
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xxs)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.cornerRadius.full)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(onToneTap == nil)
        }
        .padding(.horizontal, theme.spacing.lg)
    }

    private var toneText: String {
        if let env = dailyTone.environmentalNote {
            return "\(dailyTone.label) · \(env)"
        }
        return dailyTone.label
    }
}

#Preview {
    VStack(spacing: 20) {
        DateBarView(
            dailyTone: DailyTone(label: "Balance Day", environmentalNote: "Dry air")
        )

        DateBarView(
            dailyTone: DailyTone(label: "Low Flame Day")
        )
    }
    .padding(.vertical)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
