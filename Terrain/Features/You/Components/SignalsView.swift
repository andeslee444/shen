//
//  SignalsView.swift
//  Terrain
//
//  Section C: "How we determined this" — collapsible top-3 quiz signals.
//  Shows a retake prompt if the user completed the quiz before response tracking existed.
//

import SwiftUI

struct SignalsView: View {
    let signals: [SignalExplanation]?
    let onRetakeQuiz: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let signals = signals, !signals.isEmpty {
                // Collapsible disclosure
                Button {
                    withAnimation(theme.animation.standard) {
                        isExpanded.toggle()
                    }
                    HapticManager.light()
                } label: {
                    HStack {
                        Image(systemName: "sparkle.magnifyingglass")
                            .foregroundColor(theme.colors.accent)
                            .font(.system(size: 14))

                        Text("How we determined this")
                            .font(theme.typography.labelLarge)
                            .foregroundColor(theme.colors.textPrimary)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textTertiary)
                    }
                    .padding(theme.spacing.md)
                }
                .buttonStyle(PlainButtonStyle())

                if isExpanded {
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        ForEach(Array(signals.enumerated()), id: \.offset) { _, signal in
                            HStack(alignment: .top, spacing: theme.spacing.sm) {
                                Circle()
                                    .fill(theme.colors.accent)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)

                                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                                    Text(signal.summary)
                                        .font(theme.typography.bodySmall)
                                        .foregroundColor(theme.colors.textPrimary)

                                    Text(signal.axisLabel)
                                        .font(theme.typography.caption)
                                        .foregroundColor(theme.colors.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.bottom, theme.spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else {
                // Pre-v2 user: show retake prompt
                VStack(spacing: theme.spacing.sm) {
                    Text("Retake your quiz to see how we determined your type")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        onRetakeQuiz()
                    } label: {
                        Text("Retake Quiz")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.accent)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(theme.spacing.md)
                .frame(maxWidth: .infinity)
            }
        }
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}
