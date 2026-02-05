//
//  DailySurveySheet.swift
//  Terrain
//
//  Bottom sheet wrapper for the daily survey (mood + symptoms + TCM diagnostics)
//

import SwiftUI

/// Bottom sheet presentation of the daily survey
struct DailySurveySheet: View {
    @Binding var selectedSymptoms: Set<QuickSymptom>
    @Binding var moodRating: Int?
    @Binding var sleepQuality: SleepQuality?
    @Binding var dominantEmotion: DominantEmotion?
    @Binding var thermalFeeling: ThermalFeeling?
    @Binding var digestiveState: DigestiveState?
    let sortedSymptoms: [QuickSymptom]
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.terrainTheme) private var theme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    InlineCheckInView(
                        selectedSymptoms: $selectedSymptoms,
                        moodRating: $moodRating,
                        onSkip: nil,
                        sleepQuality: $sleepQuality,
                        dominantEmotion: $dominantEmotion,
                        thermalFeeling: $thermalFeeling,
                        digestiveState: $digestiveState,
                        sortedSymptoms: sortedSymptoms,
                        hideConfirmButton: true
                    )

                    // Done button
                    Button(action: {
                        HapticManager.success()
                        onDismiss()
                        dismiss()
                    }) {
                        Text("Done")
                            .font(theme.typography.labelLarge)
                            .foregroundColor(theme.colors.textInverted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, theme.spacing.md)
                            .background(theme.colors.accent)
                            .cornerRadius(theme.cornerRadius.large)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.xl)
                }
            }
            .background(theme.colors.background)
            .navigationTitle("Daily Survey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
        }
    }
}

#Preview {
    DailySurveySheet(
        selectedSymptoms: .constant([]),
        moodRating: .constant(5),
        sleepQuality: .constant(nil),
        dominantEmotion: .constant(nil),
        thermalFeeling: .constant(nil),
        digestiveState: .constant(nil),
        sortedSymptoms: QuickSymptom.allCases,
        onDismiss: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
