//
//  DailyCheckInSheet.swift
//  Terrain
//
//  Daily check-in modal for logging symptoms and energy
//

import SwiftUI

struct DailyCheckInSheet: View {
    let onComplete: ([Symptom], SymptomOnset?, EnergyLevel?) -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSymptoms: Set<Symptom> = []
    @State private var selectedOnset: SymptomOnset?
    @State private var selectedEnergy: EnergyLevel?
    @State private var step = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: theme.spacing.lg) {
                // Progress
                ProgressView(value: Double(step + 1) / 3.0)
                    .tint(theme.colors.accent)
                    .padding(.horizontal, theme.spacing.lg)

                Spacer()

                // Content based on step
                Group {
                    switch step {
                    case 0:
                        symptomsStep
                    case 1:
                        if !selectedSymptoms.isEmpty {
                            onsetStep
                        } else {
                            energyStep
                        }
                    case 2:
                        energyStep
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal, theme.spacing.lg)

                Spacer()

                // Buttons
                HStack(spacing: theme.spacing.md) {
                    if step > 0 {
                        TerrainSecondaryButton(title: "Back") {
                            step -= 1
                        }
                    }

                    TerrainPrimaryButton(title: step == lastStep ? "Done" : "Next") {
                        if step == lastStep {
                            complete()
                        } else {
                            step += 1
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.lg)
            }
            .background(theme.colors.background)
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        complete()
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
    }

    private var lastStep: Int {
        selectedSymptoms.isEmpty ? 1 : 2
    }

    private var symptomsStep: some View {
        VStack(spacing: theme.spacing.lg) {
            Text("Anything affecting you today?")
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: theme.spacing.sm) {
                ForEach(Symptom.allCases) { symptom in
                    TerrainCheckboxOption(
                        title: symptom.displayName,
                        isSelected: selectedSymptoms.contains(symptom),
                        action: {
                            if selectedSymptoms.contains(symptom) {
                                selectedSymptoms.remove(symptom)
                            } else {
                                selectedSymptoms.insert(symptom)
                            }
                        }
                    )
                }
            }

            Text("Select all that apply, or skip if none")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
        }
    }

    private var onsetStep: some View {
        VStack(spacing: theme.spacing.lg) {
            Text("When did it start?")
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: theme.spacing.sm) {
                ForEach(SymptomOnset.allCases, id: \.self) { onset in
                    TerrainSelectionOption(
                        title: onset.displayName,
                        isSelected: selectedOnset == onset,
                        action: { selectedOnset = onset }
                    )
                }
            }
        }
    }

    private var energyStep: some View {
        VStack(spacing: theme.spacing.lg) {
            Text("How's your energy today?")
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: theme.spacing.sm) {
                ForEach(EnergyLevel.allCases, id: \.self) { level in
                    TerrainSelectionOption(
                        title: level.displayName,
                        isSelected: selectedEnergy == level,
                        action: { selectedEnergy = level }
                    )
                }
            }
        }
    }

    private func complete() {
        onComplete(Array(selectedSymptoms), selectedOnset, selectedEnergy)
        dismiss()
    }
}

#Preview {
    DailyCheckInSheet(onComplete: { _, _, _ in })
        .environment(\.terrainTheme, TerrainTheme.default)
}
