//
//  InlineCheckInView.swift
//  Terrain
//
//  Inline symptom chip selection for quick daily check-in
//

import SwiftUI

/// Inline check-in with toggleable symptom chips inside a card, and a "Nothing today" text button.
/// Uses a 2-column grid with icon+label rectangular chips to differentiate from identity pills.
/// Selections are staged locally — the card stays visible until the user taps "Confirm".
struct InlineCheckInView: View {
    @Binding var selectedSymptoms: Set<QuickSymptom>
    @Binding var moodRating: Int?
    var onSkip: (() -> Void)? = nil

    // TCM diagnostic signal bindings (optional Phase 13 detail pickers)
    @Binding var sleepQuality: SleepQuality?
    @Binding var dominantEmotion: DominantEmotion?
    @Binding var thermalFeeling: ThermalFeeling?
    @Binding var digestiveState: DigestiveState?

    /// Symptoms sorted by relevance to the user's terrain type.
    /// Defaults to QuickSymptom.allCases if not provided.
    var sortedSymptoms: [QuickSymptom] = QuickSymptom.allCases.map { $0 }

    /// When true, hides the Confirm button (for sheet context where Done button is used)
    /// and auto-commits changes when the view disappears.
    var hideConfirmButton: Bool = false

    @Environment(\.terrainTheme) private var theme
    @State private var isSkipped = false
    /// Local staging set — selections stay here until the user confirms.
    @State private var stagedSymptoms: Set<QuickSymptom> = []
    /// Local staging for mood slider value (1-10, displayed as continuous slider)
    @State private var stagedMoodRating: Double = 5.0
    /// Whether the user has interacted with the mood slider
    @State private var hasStagedMood: Bool = false

    // TCM detail staging
    @State private var showTCMDetails = false
    @State private var stagedSleepQuality: SleepQuality?
    @State private var stagedEmotion: DominantEmotion?
    @State private var stagedThermal: ThermalFeeling?
    @State private var stagedAppetite: AppetiteLevel?
    @State private var stagedStool: StoolQuality?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Mood rating section
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("How are you feeling today?")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                // Discrete numbered circles
                HStack(spacing: 0) {
                    ForEach(1...10, id: \.self) { value in
                        Button {
                            withAnimation(theme.animation.quick) {
                                stagedMoodRating = Double(value)
                                if !hasStagedMood {
                                    hasStagedMood = true
                                }
                            }
                            HapticManager.selection()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Int(stagedMoodRating) == value ? theme.colors.accent : Color.clear)
                                Circle()
                                    .stroke(
                                        Int(stagedMoodRating) == value ? theme.colors.accent : theme.colors.textTertiary.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                                Text("\(value)")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(
                                        Int(stagedMoodRating) == value ? theme.colors.textInverted : theme.colors.textSecondary
                                    )
                            }
                            .frame(width: 28, height: 28)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Rate \(value) out of 10")
                        .accessibilityAddTraits(Int(stagedMoodRating) == value ? .isSelected : [])

                        if value < 10 {
                            Spacer(minLength: 0)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Mood rating")
            }

            Divider()
                .padding(.vertical, theme.spacing.xxs)

            // Symptom header
            Text("Anything affecting you today?")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            // 2-column symptom grid
            LazyVGrid(columns: columns, spacing: theme.spacing.xs) {
                ForEach(sortedSymptoms, id: \.self) { symptom in
                    SymptomChipButton(
                        symptom: symptom,
                        isSelected: stagedSymptoms.contains(symptom),
                        onTap: {
                            toggleSymptom(symptom)
                        }
                    )
                }
            }

            // Expandable TCM details section
            tcmDetailsSection

            // Bottom row: "Nothing today" left, "Confirm" right
            HStack {
                if let skipAction = onSkip {
                    Button(action: {
                        withAnimation(theme.animation.quick) {
                            isSkipped = true
                        }
                        HapticManager.light()
                        skipAction()
                    }) {
                        Text("Nothing today")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(isSkipped ? 0.5 : 1.0)
                }

                Spacer()

                if !hideConfirmButton && (!stagedSymptoms.isEmpty || hasStagedMood) {
                    Button(action: confirmSelection) {
                        Text("Confirm")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textInverted)
                            .padding(.horizontal, theme.spacing.md)
                            .padding(.vertical, theme.spacing.xs)
                            .background(theme.colors.accent)
                            .cornerRadius(theme.cornerRadius.full)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .accessibilityLabel("Confirm symptom selection")
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .padding(.horizontal, theme.spacing.lg)
        .onDisappear {
            // Auto-commit when used in sheet context (hideConfirmButton = true)
            if hideConfirmButton {
                confirmSelection()
            }
        }
        .onAppear {
            stagedSymptoms = selectedSymptoms
            if let existingMood = moodRating {
                stagedMoodRating = Double(existingMood)
                hasStagedMood = true
            }
            // Load existing TCM data
            stagedSleepQuality = sleepQuality
            stagedEmotion = dominantEmotion
            stagedThermal = thermalFeeling
            stagedAppetite = digestiveState?.appetiteLevel
            stagedStool = digestiveState?.stoolQuality
        }
    }

    // MARK: - TCM Details Section

    @ViewBuilder
    private var tcmDetailsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Toggle button to expand/collapse
            Button(action: {
                withAnimation(theme.animation.standard) {
                    showTCMDetails.toggle()
                }
                HapticManager.light()
            }) {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: showTCMDetails ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                    Text("More details")
                        .font(theme.typography.labelSmall)
                    Spacer()
                    if hasTCMData {
                        Text("\(tcmDataCount) logged")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.accent)
                    }
                }
                .foregroundColor(theme.colors.textTertiary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, theme.spacing.xs)

            if showTCMDetails {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    // Sleep Quality
                    tcmPickerSection(
                        title: "How did you sleep?",
                        icon: "moon.zzz",
                        options: SleepQuality.allCases,
                        selection: $stagedSleepQuality,
                        displayName: { $0.displayName },
                        optionIcon: { $0.icon }
                    )

                    // Dominant Emotion
                    tcmPickerSection(
                        title: "Emotional state today",
                        icon: "heart",
                        options: DominantEmotion.allCases,
                        selection: $stagedEmotion,
                        displayName: { $0.displayName },
                        optionIcon: { $0.icon }
                    )

                    // Thermal Feeling
                    tcmPickerSection(
                        title: "Body temperature feeling",
                        icon: "thermometer.medium",
                        options: ThermalFeeling.allCases,
                        selection: $stagedThermal,
                        displayName: { $0.displayName },
                        optionIcon: { $0.icon }
                    )

                    // Digestion - Appetite
                    tcmPickerSection(
                        title: "Appetite today",
                        icon: "fork.knife",
                        options: AppetiteLevel.allCases,
                        selection: $stagedAppetite,
                        displayName: { $0.displayName },
                        optionIcon: { $0.icon }
                    )

                    // Digestion - Stool
                    tcmPickerSection(
                        title: "Digestion quality",
                        icon: "leaf",
                        options: StoolQuality.allCases,
                        selection: $stagedStool,
                        displayName: { $0.displayName },
                        optionIcon: { _ in "circle.fill" }
                    )
                }
                .padding(.top, theme.spacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func tcmPickerSection<T: Hashable>(
        title: String,
        icon: String,
        options: [T],
        selection: Binding<T?>,
        displayName: @escaping (T) -> String,
        optionIcon: @escaping (T) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(theme.colors.textTertiary)
                Text(title)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(options, id: \.self) { option in
                        TCMOptionChip(
                            label: displayName(option),
                            icon: optionIcon(option),
                            isSelected: selection.wrappedValue == option,
                            onTap: {
                                withAnimation(theme.animation.quick) {
                                    if selection.wrappedValue == option {
                                        selection.wrappedValue = nil
                                    } else {
                                        selection.wrappedValue = option
                                    }
                                }
                                HapticManager.selection()
                            }
                        )
                    }
                }
            }
        }
    }

    private var hasTCMData: Bool {
        stagedSleepQuality != nil ||
        stagedEmotion != nil ||
        stagedThermal != nil ||
        stagedAppetite != nil ||
        stagedStool != nil
    }

    private var tcmDataCount: Int {
        [
            stagedSleepQuality != nil,
            stagedEmotion != nil,
            stagedThermal != nil,
            stagedAppetite != nil,
            stagedStool != nil
        ].filter { $0 }.count
    }

    private func toggleSymptom(_ symptom: QuickSymptom) {
        withAnimation(theme.animation.quick) {
            if stagedSymptoms.contains(symptom) {
                stagedSymptoms.remove(symptom)
            } else {
                stagedSymptoms.insert(symptom)
            }
        }
        HapticManager.selection()
    }

    private func confirmSelection() {
        selectedSymptoms = stagedSymptoms
        if hasStagedMood {
            moodRating = Int(stagedMoodRating)
        }
        // Save TCM diagnostic data
        sleepQuality = stagedSleepQuality
        dominantEmotion = stagedEmotion
        thermalFeeling = stagedThermal
        if stagedAppetite != nil || stagedStool != nil {
            digestiveState = DigestiveState(
                appetiteLevel: stagedAppetite ?? .normal,
                stoolQuality: stagedStool ?? .normal
            )
        }
        HapticManager.success()
    }
}

// MARK: - TCM Option Chip

/// Small chip for TCM detail selection with icon and label
struct TCMOptionChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(theme.typography.caption)
            }
            .foregroundColor(isSelected ? theme.colors.textInverted : theme.colors.textSecondary)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            .cornerRadius(theme.cornerRadius.full)
        }
        .buttonStyle(PlainButtonStyle())
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
        @State private var mood: Int? = nil
        @State private var sleepQuality: SleepQuality?
        @State private var emotion: DominantEmotion?
        @State private var thermal: ThermalFeeling?
        @State private var digestive: DigestiveState?

        var body: some View {
            InlineCheckInView(
                selectedSymptoms: $symptoms,
                moodRating: $mood,
                onSkip: { print("Skipped") },
                sleepQuality: $sleepQuality,
                dominantEmotion: $emotion,
                thermalFeeling: $thermal,
                digestiveState: $digestive
            )
        }
    }

    return PreviewWrapper()
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "FAFAF8"))
        .environment(\.terrainTheme, TerrainTheme.default)
}
