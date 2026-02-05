//
//  AnnotatedTrendCard.swift
//  Terrain
//
//  A trend card with terrain-specific annotation and priority indicator.
//  Reuses SparklineView but adds micro-explanation below.
//

import SwiftUI

struct AnnotatedTrendCard: View {
    let trend: AnnotatedTrendResult

    @Environment(\.terrainTheme) private var theme
    @State private var showDetail = false

    var body: some View {
        Button {
            HapticManager.light()
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                // Main trend row (same as TrendSparklineCard)
                HStack(spacing: theme.spacing.sm) {
                    // Category icon + name with priority indicator
                    HStack(spacing: theme.spacing.xs) {
                        // Priority indicator for top priorities
                        if trend.priority <= 2 {
                            Circle()
                                .fill(trendColor(trend.direction))
                                .frame(width: 6, height: 6)
                        }

                        Image(systemName: trend.icon)
                            .font(.system(size: 14))
                            .foregroundColor(theme.colors.textSecondary)
                            .frame(width: 20, alignment: .center)

                        Text(trend.category)
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    .frame(width: 110, alignment: .leading)

                    // Mini sparkline chart
                    SparklineView(
                        data: trend.dailyRates,
                        lineColor: trendColor(trend.direction)
                    )
                    .frame(height: 24)

                    // Direction arrow + label
                    HStack(spacing: theme.spacing.xxs) {
                        Image(systemName: trend.direction.icon)
                            .font(.system(size: 10, weight: .semibold))

                        Text(trend.direction.rawValue.capitalized)
                            .font(theme.typography.labelSmall)
                    }
                    .foregroundColor(trendColor(trend.direction))
                    .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, theme.spacing.xs)

                // Terrain-specific micro-explanation (only for priority categories or declining)
                if trend.priority <= 3 || trend.direction == .declining {
                    HStack(spacing: theme.spacing.xs) {
                        // Watch-for badge
                        if trend.isWatchFor {
                            HStack(spacing: theme.spacing.xxs) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 8))
                                Text("Watch")
                                    .font(theme.typography.caption)
                            }
                            .foregroundColor(theme.colors.warning)
                            .padding(.horizontal, theme.spacing.xs)
                            .padding(.vertical, 2)
                            .background(theme.colors.warning.opacity(0.1))
                            .cornerRadius(theme.cornerRadius.small)
                        }

                        Text(trend.terrainNote)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                            .lineLimit(2)
                    }
                    .padding(.leading, trend.priority <= 2 ? 6 : 0) // Align with priority indicator
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(trend.category) trend: \(trend.direction.rawValue)")
        .accessibilityHint(trend.isWatchFor ? "Watch for category. Tap for details." : "Tap for details")
        .sheet(isPresented: $showDetail) {
            TrendDetailSheet(trend: trend)
        }
    }

    private func trendColor(_ direction: TrendDirection) -> Color {
        switch direction {
        case .improving: return theme.colors.success
        case .stable: return theme.colors.textSecondary
        case .declining: return theme.colors.warning
        }
    }
}

// MARK: - Trend Detail Sheet

struct TrendDetailSheet: View {
    let trend: AnnotatedTrendResult

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Header with category and status
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack(spacing: theme.spacing.sm) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 24))
                                .foregroundColor(trendColor)

                            Text(trend.category)
                                .font(theme.typography.headlineLarge)
                                .foregroundColor(theme.colors.textPrimary)
                        }

                        HStack(spacing: theme.spacing.xs) {
                            Image(systemName: trend.direction.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(trend.direction.rawValue.capitalized)
                                .font(theme.typography.labelLarge)
                        }
                        .foregroundColor(trendColor)
                    }

                    // Large sparkline
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("14-Day Pattern")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textTertiary)

                        SparklineView(
                            data: trend.dailyRates,
                            lineColor: trendColor
                        )
                        .frame(height: 80)

                        // Day labels
                        HStack {
                            Text("14 days ago")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)
                            Spacer()
                            Text("Today")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)
                        }
                    }
                    .padding(theme.spacing.md)
                    .background(theme.colors.surface)
                    .cornerRadius(theme.cornerRadius.large)

                    // Terrain interpretation
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        HStack(spacing: theme.spacing.xs) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(theme.colors.accent)
                            Text("For Your Terrain")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.textPrimary)
                        }

                        Text(trend.terrainNote)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if trend.isWatchFor {
                            HStack(spacing: theme.spacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text("This is a watch-for category for your terrain type")
                                    .font(theme.typography.bodySmall)
                            }
                            .foregroundColor(theme.colors.warning)
                            .padding(theme.spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(theme.colors.warning.opacity(0.1))
                            .cornerRadius(theme.cornerRadius.medium)
                        }
                    }
                    .padding(theme.spacing.md)
                    .background(theme.colors.surface)
                    .cornerRadius(theme.cornerRadius.large)

                    // Priority explanation
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Priority for You")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textPrimary)

                        HStack(spacing: theme.spacing.sm) {
                            ForEach(1...8, id: \.self) { priority in
                                Circle()
                                    .fill(priority == trend.priority
                                          ? theme.colors.accent
                                          : theme.colors.textTertiary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }

                        Text("Priority \(trend.priority) of 8 — \(priorityDescription)")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                    }
                    .padding(theme.spacing.md)
                    .background(theme.colors.surface)
                    .cornerRadius(theme.cornerRadius.large)

                    Spacer(minLength: theme.spacing.xxl)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.md)
            }
            .background(theme.colors.background)
            .navigationTitle(trend.category)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.colors.accent)
                }
            }
        }
    }

    private var trendColor: Color {
        switch trend.direction {
        case .improving: return theme.colors.success
        case .stable: return theme.colors.textSecondary
        case .declining: return theme.colors.warning
        }
    }

    private var priorityDescription: String {
        switch trend.priority {
        case 1: return "Most important for your terrain"
        case 2: return "Very relevant for your pattern"
        case 3: return "Important to track"
        case 4...5: return "Worth monitoring"
        default: return "Background metric"
        }
    }
}

// MARK: - Preview

#Preview("Declining Sleep - Priority 1") {
    AnnotatedTrendCard(
        trend: AnnotatedTrendResult(
            base: TrendResult(
                category: "Sleep",
                direction: .declining,
                icon: "moon.zzz",
                dailyRates: [0.8, 0.7, 0.75, 0.6, 0.65, 0.5, 0.55, 0.4, 0.45, 0.4, 0.35, 0.3, 0.35, 0.3]
            ),
            priority: 1,
            terrainNote: "For Low Flame types, sleep is when your reserves rebuild. This decline deserves attention.",
            isWatchFor: true
        )
    )
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Improving Energy - Priority 2") {
    AnnotatedTrendCard(
        trend: AnnotatedTrendResult(
            base: TrendResult(
                category: "Energy",
                direction: .improving,
                icon: "bolt",
                dailyRates: [0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.5, 0.6, 0.65, 0.7, 0.65, 0.7, 0.75, 0.8]
            ),
            priority: 2,
            terrainNote: "Low Flame types build energy slowly but surely. This upward trend shows your warming practices are working.",
            isWatchFor: false
        )
    )
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Stable Mood - Priority 5") {
    AnnotatedTrendCard(
        trend: AnnotatedTrendResult(
            base: TrendResult(
                category: "Mood",
                direction: .stable,
                icon: "face.smiling",
                dailyRates: [0.6, 0.65, 0.6, 0.65, 0.6, 0.65, 0.6, 0.65, 0.6, 0.65, 0.6, 0.65, 0.6, 0.65]
            ),
            priority: 5,
            terrainNote: "Holding steady.",
            isWatchFor: false
        )
    )
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
