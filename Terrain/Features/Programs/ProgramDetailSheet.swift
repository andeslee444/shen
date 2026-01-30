//
//  ProgramDetailSheet.swift
//  Terrain
//
//  Program details with day-by-day preview and enrollment
//

import SwiftUI

struct ProgramDetailSheet: View {
    let program: Program
    let enrollment: ProgramEnrollment?
    let onEnroll: () -> Void
    let onUnenroll: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDay: ProgramDay?

    private var isEnrolled: Bool { enrollment?.isActive == true }

    private var currentDay: Int {
        enrollment?.computedCurrentDay(programDurationDays: program.durationDays) ?? 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Header
                    VStack(spacing: theme.spacing.sm) {
                        Text(program.displayName)
                            .font(theme.typography.headlineLarge)
                            .foregroundColor(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)

                        if let subtitle = program.subtitle {
                            Text(subtitle.localized)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        // Duration and status
                        HStack(spacing: theme.spacing.md) {
                            Label("\(program.durationDays) days", systemImage: "calendar")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.textSecondary)

                            if isEnrolled {
                                Text("Day \(currentDay)")
                                    .font(theme.typography.labelMedium)
                                    .foregroundColor(theme.colors.accent)
                                    .padding(.horizontal, theme.spacing.sm)
                                    .padding(.vertical, theme.spacing.xxs)
                                    .background(theme.colors.accent.opacity(0.1))
                                    .cornerRadius(theme.cornerRadius.full)
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)

                    // Goals section
                    if !program.goals.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Focus Areas")
                                .font(theme.typography.labelLarge)
                                .foregroundColor(theme.colors.textPrimary)

                            FlowLayout(spacing: theme.spacing.xs) {
                                ForEach(program.goals, id: \.self) { goal in
                                    GoalChip(goal: goal)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, theme.spacing.lg)
                    }

                    // Day-by-day preview
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Daily Overview")
                            .font(theme.typography.labelLarge)
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.horizontal, theme.spacing.lg)

                        if program.days.isEmpty {
                            VStack(spacing: theme.spacing.sm) {
                                ForEach(1...program.durationDays, id: \.self) { day in
                                    ProgramDayPreviewCard(
                                        dayNumber: day,
                                        isCompleted: isEnrolled && (enrollment?.isDayCompleted(day) == true),
                                        isCurrent: isEnrolled && day == currentDay,
                                        isLocked: !isEnrolled || day > currentDay
                                    )
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        } else {
                            VStack(spacing: theme.spacing.sm) {
                                ForEach(program.days) { day in
                                    Button {
                                        if isEnrolled && day.day <= currentDay {
                                            selectedDay = day
                                            HapticManager.light()
                                        }
                                    } label: {
                                        ProgramDayPreviewCard(
                                            dayNumber: day.day,
                                            routineCount: day.routineRefs.count,
                                            movementCount: day.movementRefs.count,
                                            hasLesson: day.lessonRef != nil,
                                            isCompleted: isEnrolled && (enrollment?.isDayCompleted(day.day) == true),
                                            isCurrent: isEnrolled && day.day == currentDay,
                                            isLocked: !isEnrolled || day.day > currentDay
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(!isEnrolled || day.day > currentDay)
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        }
                    }

                    Spacer(minLength: theme.spacing.xxl)

                    // Enroll/Unenroll button
                    VStack(spacing: theme.spacing.md) {
                        if isEnrolled {
                            TerrainPrimaryButton(
                                title: "Continue Day \(currentDay)",
                                action: {
                                    if let day = program.days.first(where: { $0.day == currentDay }) {
                                        selectedDay = day
                                    }
                                }
                            )

                            Button {
                                onUnenroll()
                                dismiss()
                            } label: {
                                Text("Leave Program")
                                    .font(theme.typography.labelMedium)
                                    .foregroundColor(theme.colors.textTertiary)
                            }
                        } else {
                            TerrainPrimaryButton(
                                title: "Start Program",
                                action: {
                                    onEnroll()
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.lg)
                }
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(theme.colors.textTertiary)
                    }
                }
            }
            .sheet(item: $selectedDay) { day in
                ProgramDayView(
                    program: program,
                    day: day,
                    enrollment: enrollment,
                    onComplete: {
                        // Mark day complete in enrollment
                        if let enrollment = enrollment {
                            enrollment.markDayCompleted(day.day, programDurationDays: program.durationDays)
                            try? modelContext.save()
                        }
                        selectedDay = nil
                    }
                )
            }
        }
    }
}

// MARK: - Program Day Preview Card

struct ProgramDayPreviewCard: View {
    let dayNumber: Int
    var routineCount: Int = 0
    var movementCount: Int = 0
    var hasLesson: Bool = false
    var isCompleted: Bool = false
    var isCurrent: Bool = false
    var isLocked: Bool = false

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            // Day indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.colors.success)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textTertiary)
                } else {
                    Text("\(dayNumber)")
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(isCurrent ? theme.colors.accent : theme.colors.textPrimary)
                }
            }

            // Content summary
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text("Day \(dayNumber)")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(isLocked ? theme.colors.textTertiary : theme.colors.textPrimary)

                if routineCount > 0 || movementCount > 0 || hasLesson {
                    HStack(spacing: theme.spacing.sm) {
                        if routineCount > 0 {
                            Label("\(routineCount)", systemImage: "cup.and.saucer")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)
                        }
                        if movementCount > 0 {
                            Label("\(movementCount)", systemImage: "figure.walk")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)
                        }
                        if hasLesson {
                            Label("Lesson", systemImage: "book")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)
                        }
                    }
                } else {
                    Text(isLocked ? "Unlock by completing previous days" : "Routines and movements")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
            }

            Spacer()

            if isCurrent {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.colors.accent)
            }
        }
        .padding(theme.spacing.md)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .fill(isCurrent ? theme.colors.accent.opacity(0.05) : theme.colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                        .stroke(
                            isCurrent ? theme.colors.accent.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .opacity(isLocked ? 0.6 : 1)
    }

    private var statusColor: Color {
        if isCompleted {
            return theme.colors.success
        } else if isCurrent {
            return theme.colors.accent
        } else {
            return theme.colors.textTertiary
        }
    }
}

// MARK: - Goal Chip

struct GoalChip: View {
    let goal: String

    @Environment(\.terrainTheme) private var theme

    private var icon: String {
        switch goal.lowercased() {
        case "digestion": return "fork.knife"
        case "energy": return "bolt.fill"
        case "sleep": return "moon.fill"
        case "stress": return "brain.head.profile"
        case "skin": return "sparkles"
        default: return "star.fill"
        }
    }

    var body: some View {
        HStack(spacing: theme.spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(goal.capitalized)
                .font(theme.typography.labelSmall)
        }
        .foregroundColor(theme.colors.textSecondary)
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xxs)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.cornerRadius.full)
    }
}

#Preview {
    ProgramDetailSheet(
        program: Program(
            id: "preview-program",
            title: "7-Day Digestive Reset",
            subtitle: "Rebuild your digestive fire with warming routines",
            durationDays: 7,
            goals: ["digestion", "energy"],
            days: [
                ProgramDay(day: 1, routineRefs: ["warm-start-congee-full"], movementRefs: ["morning-qi-flow-full"], lessonRef: "understanding-cold-heat"),
                ProgramDay(day: 2, routineRefs: ["ginger-honey-tea-lite"], movementRefs: []),
                ProgramDay(day: 3, routineRefs: ["warm-start-congee-full"], movementRefs: ["morning-qi-flow-full"])
            ]
        ),
        enrollment: ProgramEnrollment(programId: "preview-program"),
        onEnroll: {},
        onUnenroll: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
