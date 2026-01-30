//
//  ProgramsView.swift
//  Terrain
//
//  Programs listing - browse and enroll in multi-day programs
//

import SwiftUI
import SwiftData

struct ProgramsView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Program.id) private var programs: [Program]
    @Query private var userProfiles: [UserProfile]
    @Query private var enrollments: [ProgramEnrollment]

    @State private var selectedProgram: Program?

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    /// The currently active enrollment (only one at a time)
    private var activeEnrollment: ProgramEnrollment? {
        enrollments.first { $0.isActive }
    }

    /// Programs that fit the user's terrain type
    private var recommendedPrograms: [Program] {
        guard let profileId = userProfile?.terrainProfileId else {
            return programs
        }
        return programs.filter { $0.terrainFit.isEmpty || $0.terrainFit.contains(profileId) }
    }

    /// Programs the user is not enrolled in
    private var availablePrograms: [Program] {
        let enrolledId = activeEnrollment?.programId
        return recommendedPrograms.filter { $0.id != enrolledId }
    }

    /// Currently enrolled program
    private var enrolledProgram: Program? {
        guard let enrolledId = activeEnrollment?.programId else { return nil }
        return programs.first { $0.id == enrolledId }
    }

    /// Current day in the enrollment (auto-advances by calendar)
    private var currentDay: Int {
        guard let enrollment = activeEnrollment,
              let program = enrolledProgram else { return 1 }
        return enrollment.computedCurrentDay(programDurationDays: program.durationDays)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Header
                    VStack(spacing: theme.spacing.sm) {
                        Text("Programs")
                            .font(theme.typography.headlineLarge)
                            .foregroundColor(theme.colors.textPrimary)
                            .accessibilityAddTraits(.isHeader)

                        Text("Multi-day guided journeys for deeper wellness")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)

                    // Enrolled program (if any)
                    if let enrolled = enrolledProgram {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            HStack {
                                Text("Currently Enrolled")
                                    .font(theme.typography.labelLarge)
                                    .foregroundColor(theme.colors.textPrimary)

                                Spacer()

                                Text("Day \(currentDay) of \(enrolled.durationDays)")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.accent)
                            }
                            .padding(.horizontal, theme.spacing.lg)

                            Button {
                                selectedProgram = enrolled
                                HapticManager.light()
                            } label: {
                                EnrolledProgramCard(program: enrolled, currentDay: currentDay)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, theme.spacing.lg)
                        }
                    }

                    // Available programs
                    if programs.isEmpty {
                        emptyStateView
                    } else {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text(enrolledProgram != nil ? "More Programs" : "Available Programs")
                                .font(theme.typography.labelLarge)
                                .foregroundColor(theme.colors.textPrimary)
                                .padding(.horizontal, theme.spacing.lg)

                            LazyVStack(spacing: theme.spacing.md) {
                                ForEach(availablePrograms) { program in
                                    Button {
                                        selectedProgram = program
                                        HapticManager.light()
                                    } label: {
                                        ProgramCard(program: program)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        }
                    }

                    Spacer(minLength: theme.spacing.xxl)
                }
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedProgram) { program in
                ProgramDetailSheet(
                    program: program,
                    enrollment: activeEnrollment?.programId == program.id ? activeEnrollment : nil,
                    onEnroll: { enrollInProgram(program) },
                    onUnenroll: { unenrollFromProgram() }
                )
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.textTertiary)

            Text("No Programs Yet")
                .font(theme.typography.headlineSmall)
                .foregroundColor(theme.colors.textPrimary)

            Text("Multi-day programs are coming soon.\nCheck back for guided wellness journeys.")
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xxl)
        .padding(.horizontal, theme.spacing.lg)
    }

    // MARK: - Actions

    private func enrollInProgram(_ program: Program) {
        // Deactivate any existing active enrollment
        if let existing = activeEnrollment {
            existing.isActive = false
            existing.updatedAt = Date()
        }

        // Create new enrollment
        let enrollment = ProgramEnrollment(programId: program.id)
        modelContext.insert(enrollment)
        try? modelContext.save()
        HapticManager.success()
    }

    private func unenrollFromProgram() {
        if let enrollment = activeEnrollment {
            enrollment.isActive = false
            enrollment.updatedAt = Date()
            try? modelContext.save()
        }
        HapticManager.light()
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    let program: Program

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(program.displayName)
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.textPrimary)

                    if let subtitle = program.subtitle {
                        Text(subtitle.localized)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                // Duration badge
                Text("\(program.durationDays) days")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.colors.accent)
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xxs)
                    .background(theme.colors.accent.opacity(0.1))
                    .cornerRadius(theme.cornerRadius.full)
            }

            // Goals chips
            if !program.goals.isEmpty {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(program.goals.prefix(3), id: \.self) { goal in
                        Text(goal.capitalized)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                            .padding(.horizontal, theme.spacing.xs)
                            .padding(.vertical, 2)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.cornerRadius.small)
                    }
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Enrolled Program Card

struct EnrolledProgramCard: View {
    let program: Program
    let currentDay: Int

    @Environment(\.terrainTheme) private var theme

    private var progress: Double {
        Double(currentDay) / Double(program.durationDays)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(program.displayName)
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.textPrimary)

                    Text("Continue your journey")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.colors.textTertiary)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                ProgressView(value: progress)
                    .tint(theme.colors.accent)

                Text("\(Int(progress * 100))% complete")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                .fill(theme.colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                        .stroke(theme.colors.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    ProgramsView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
