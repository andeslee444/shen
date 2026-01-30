//
//  InlineCheckInView.swift
//  Terrain
//
//  Inline symptom chip selection for quick daily check-in
//

import SwiftUI

/// Inline check-in with toggleable symptom chips inside a card, and a "Nothing today" text button.
/// Uses a 2-column grid with icon+label rectangular chips to differentiate from identity pills.
struct InlineCheckInView: View {
    @Binding var selectedSymptoms: Set<QuickSymptom>
    let onSkip: () -> Void

    /// Symptoms sorted by relevance to the user's terrain type.
    /// Defaults to QuickSymptom.allCases if not provided.
    var sortedSymptoms: [QuickSymptom] = QuickSymptom.allCases.map { $0 }

    @Environment(\.terrainTheme) private var theme
    @State private var isSkipped = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Header with wave icon
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "hand.wave")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Text("Anything affecting you today?")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            // 2-column symptom grid
            LazyVGrid(columns: columns, spacing: theme.spacing.xs) {
                ForEach(sortedSymptoms, id: \.self) { symptom in
                    SymptomChipButton(
                        symptom: symptom,
                        isSelected: selectedSymptoms.contains(symptom),
                        onTap: {
                            toggleSymptom(symptom)
                        }
                    )
                }
            }

            // "Nothing today" — right-aligned, separated from the grid
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(theme.animation.quick) {
                        isSkipped = true
                    }
                    HapticManager.light()
                    onSkip()
                }) {
                    Text("Nothing today")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(isSkipped ? 0.5 : 1.0)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .padding(.horizontal, theme.spacing.lg)
    }

    private func toggleSymptom(_ symptom: QuickSymptom) {
        withAnimation(theme.animation.quick) {
            if selectedSymptoms.contains(symptom) {
                selectedSymptoms.remove(symptom)
            } else {
                selectedSymptoms.insert(symptom)
            }
        }
        HapticManager.selection()
    }
}

/// Individual symptom chip button — rectangular (not pill) with SF Symbol icon.
/// Uses cornerRadius.medium to visually differentiate from pill-shaped identity badges.
struct SymptomChipButton: View {
    let symptom: QuickSymptom
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: symptom.icon)
                    .font(.system(size: 14))

                Text(symptom.displayName.lowercased())
                    .font(theme.typography.labelSmall)
            }
            .foregroundColor(isSelected ? theme.colors.textInverted : theme.colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.sm)
            .background(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            .cornerRadius(theme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(theme.animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(symptom.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// Note: FlowLayout is defined in Features/Onboarding/TerrainRevealView.swift

#Preview {
    struct PreviewWrapper: View {
        @State private var symptoms: Set<QuickSymptom> = [.cold]

        var body: some View {
            InlineCheckInView(
                selectedSymptoms: $symptoms,
                onSkip: { print("Skipped") }
            )
        }
    }

    return PreviewWrapper()
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "FAFAF8"))
        .environment(\.terrainTheme, TerrainTheme.default)
}
