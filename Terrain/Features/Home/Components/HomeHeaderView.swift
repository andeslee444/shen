//
//  HomeHeaderView.swift
//  Terrain
//
//  Simple header for the Home tab showing date, weather, and steps inline.
//

import SwiftUI

struct HomeHeaderView: View {
    let temperatureCelsius: Double?
    let weatherCondition: String?
    let stepCount: Int?

    @Environment(\.terrainTheme) private var theme

    // MARK: - Date formatting

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Temperature formatting (shows both F and C)

    private var temperatureString: String? {
        guard let tempC = temperatureCelsius else { return nil }
        let tempF = tempC * 9/5 + 32
        return String(format: "%.0f°F", tempF)
    }

    // MARK: - Steps formatting

    private var stepsString: String? {
        guard let steps = stepCount else { return nil }
        if steps >= 1000 {
            return String(format: "%.1fk steps", Double(steps) / 1000.0)
        }
        return "\(steps) steps"
    }

    var body: some View {
        HStack(alignment: .center, spacing: theme.spacing.sm) {
            // Date
            Text(dateString)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textSecondary)

            // Temperature (if available)
            if let temp = temperatureString {
                Text("·")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textTertiary)

                Text(temp)
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }

            // Steps (if available)
            if let steps = stepsString {
                Text("·")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textTertiary)

                HStack(spacing: theme.spacing.xxs) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 11))
                        .foregroundColor(theme.colors.textSecondary)
                    Text(steps)
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, theme.spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today is \(dateString)")
    }
}

#Preview {
    VStack(spacing: 20) {
        // With all data
        HomeHeaderView(
            temperatureCelsius: 22,
            weatherCondition: "clear",
            stepCount: 8500
        )

        // Temperature only
        HomeHeaderView(
            temperatureCelsius: 5,
            weatherCondition: "cold",
            stepCount: nil
        )

        // No data
        HomeHeaderView(
            temperatureCelsius: nil,
            weatherCondition: nil,
            stepCount: nil
        )
    }
    .padding(.vertical)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
