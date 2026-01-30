//
//  InlineCheckInView.swift
//  Terrain
//
//  Inline symptom chip selection for quick daily check-in
//

import SwiftUI

/// Inline check-in with toggleable symptom chips and a Skip button.
/// Allows users to quickly note what's affecting them today without opening a sheet.
struct InlineCheckInView: View {
    @Binding var selectedSymptoms: Set<QuickSymptom>
    let onSkip: () -> Void

    /// Symptoms sorted by relevance to the user's terrain type.
    /// Defaults to QuickSymptom.allCases if not provided.
    var sortedSymptoms: [QuickSymptom] = QuickSymptom.allCases.map { $0 }

    @Environment(\.terrainTheme) private var theme
    @State private var isSkipped = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Anything affecting you today?")
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textSecondary)

            // Symptom chips in a flow layout, ordered by terrain relevance
            FlowLayout(spacing: theme.spacing.xs) {
                ForEach(sortedSymptoms, id: \.self) { symptom in
                    SymptomChipButton(
                        symptom: symptom,
                        isSelected: selectedSymptoms.contains(symptom),
                        onTap: {
                            toggleSymptom(symptom)
                        }
                    )
                }

                // Skip button
                Button(action: {
                    withAnimation(theme.animation.quick) {
                        isSkipped = true
                    }
                    HapticManager.light()
                    onSkip()
                }) {
                    Text("Skip")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textTertiary)
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, theme.spacing.xxs)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius.full)
                                .stroke(theme.colors.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(isSkipped ? 0.5 : 1.0)
            }
        }
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

/// Individual symptom chip button
struct SymptomChipButton: View {
    let symptom: QuickSymptom
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            Text(symptom.displayName.lowercased())
                .font(theme.typography.labelSmall)
                .foregroundColor(isSelected ? theme.colors.textInverted : theme.colors.textSecondary)
                .padding(.horizontal, theme.spacing.sm)
                .padding(.vertical, theme.spacing.xxs)
                .background(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
                .cornerRadius(theme.cornerRadius.full)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(theme.animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
