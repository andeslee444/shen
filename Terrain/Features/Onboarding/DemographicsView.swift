//
//  DemographicsView.swift
//  Terrain
//
//  Demographics collection screen for onboarding (age, gender, ethnicity)
//

import SwiftUI

// MARK: - Type-Safe Enums

enum Gender: String, CaseIterable, Identifiable {
    case male
    case female
    case nonBinary = "non_binary"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .nonBinary: return "Non-binary"
        }
    }

    var icon: String {
        switch self {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        case .nonBinary: return "figure.2"
        }
    }
}

enum Ethnicity: String, CaseIterable, Identifiable {
    case chinese
    case eastAsian = "east_asian"
    case southAsian = "south_asian"
    case southeastAsian = "southeast_asian"
    case white
    case black
    case hispanic
    case middleEastern = "middle_eastern"
    case mixed
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chinese: return "Chinese"
        case .eastAsian: return "East Asian (non-Chinese)"
        case .southAsian: return "South Asian"
        case .southeastAsian: return "Southeast Asian"
        case .white: return "White / Caucasian"
        case .black: return "Black / African"
        case .hispanic: return "Hispanic / Latino"
        case .middleEastern: return "Middle Eastern"
        case .mixed: return "Mixed / Multiracial"
        case .other: return "Other"
        }
    }
}

// MARK: - Demographics View

struct DemographicsView: View {
    @Binding var selectedAge: Int?
    @Binding var selectedGender: String?
    @Binding var selectedEthnicity: String?
    let onContinue: () -> Void
    let onBack: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var showContent = false
    @State private var showEthnicityMessage = false

    private var canContinue: Bool {
        selectedAge != nil && selectedGender != nil && selectedEthnicity != nil
    }

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: theme.spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(theme.typography.labelMedium)
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, theme.spacing.md)

            // Title
            VStack(spacing: theme.spacing.sm) {
                Text("A little about you")
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("This helps personalize your experience")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.lg)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 10)

            // Content
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    ageSection
                    genderSection
                    ethnicitySection

                    // Playful message (animated)
                    if let ethnicity = selectedEthnicity, showEthnicityMessage {
                        ethnicityMessageView(for: ethnicity)
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.xl)
            }
            .opacity(showContent ? 1 : 0)
            .animation(theme.animation.standard.delay(0.1), value: showContent)

            Spacer()

            // Continue button
            TerrainPrimaryButton(
                title: "Continue",
                action: onContinue,
                isEnabled: canContinue
            )
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.md)
            .opacity(showContent ? 1 : 0)
            .animation(theme.animation.standard.delay(0.2), value: showContent)
        }
        .onAppear {
            withAnimation(theme.animation.standard) {
                showContent = true
            }
        }
    }

    // MARK: - Age Section

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Age")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            Picker("Age", selection: $selectedAge) {
                Text("Select").tag(nil as Int?)
                ForEach(18...100, id: \.self) { age in
                    Text("\(age)").tag(age as Int?)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
        }
    }

    // MARK: - Gender Section

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Gender")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            HStack(spacing: theme.spacing.sm) {
                ForEach(Gender.allCases) { gender in
                    DemographicChip(
                        title: gender.displayName,
                        icon: gender.icon,
                        isSelected: selectedGender == gender.rawValue,
                        action: {
                            HapticManager.light()
                            selectedGender = gender.rawValue
                        }
                    )
                }
            }
        }
    }

    // MARK: - Ethnicity Section

    private var ethnicitySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Ethnicity")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: theme.spacing.xs) {
                ForEach(Ethnicity.allCases) { ethnicity in
                    DemographicOptionCard(
                        title: ethnicity.displayName,
                        isSelected: selectedEthnicity == ethnicity.rawValue,
                        action: {
                            HapticManager.light()
                            selectedEthnicity = ethnicity.rawValue
                            withAnimation(theme.animation.standard) {
                                showEthnicityMessage = true
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Ethnicity Message

    @ViewBuilder
    private func ethnicityMessageView(for ethnicity: String) -> some View {
        // TCM is a universal health practice based on natural principles,
        // not an ethnic identity. The message welcomes everyone equally.
        Text("Welcome to the wisdom of Traditional Chinese Medicine.")
            .font(theme.typography.bodyLarge)
            .foregroundColor(theme.colors.accent)
            .multilineTextAlignment(.center)
            .padding(theme.spacing.md)
            .frame(maxWidth: .infinity)
            .background(theme.colors.accent.opacity(0.1))
            .cornerRadius(theme.cornerRadius.large)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - Demographic Chip (for Gender)

struct DemographicChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? theme.colors.accent : theme.colors.textSecondary)

                Text(title)
                    .font(theme.typography.labelMedium)
                    .foregroundColor(isSelected ? theme.colors.accent : theme.colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(isSelected ? theme.colors.accent.opacity(0.08) : theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(isSelected ? theme.colors.accent : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Demographic Option Card (for Ethnicity)

struct DemographicOptionCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.colors.accent)
                } else {
                    Circle()
                        .strokeBorder(theme.colors.textTertiary.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(theme.spacing.md)
            .background(isSelected ? theme.colors.accent.opacity(0.08) : theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(isSelected ? theme.colors.accent : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var age: Int? = nil
        @State private var gender: String? = nil
        @State private var ethnicity: String? = nil

        var body: some View {
            DemographicsView(
                selectedAge: $age,
                selectedGender: $gender,
                selectedEthnicity: $ethnicity,
                onContinue: {},
                onBack: {}
            )
            .environment(\.terrainTheme, TerrainTheme.default)
        }
    }

    return PreviewWrapper()
}
