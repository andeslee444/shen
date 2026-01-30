//
//  ProgramDayView.swift
//  Terrain
//
//  Daily program content view - shows routines, movements, and lessons for a specific day
//

import SwiftUI
import SwiftData

struct ProgramDayView: View {
    let program: Program
    let day: ProgramDay
    let enrollment: ProgramEnrollment?
    let onComplete: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var routines: [Routine]
    @Query private var movements: [Movement]
    @Query private var lessons: [Lesson]

    @State private var selectedRoutine: Routine?
    @State private var selectedMovement: Movement?
    @State private var selectedLesson: Lesson?

    /// Items completed for this day, read from enrollment persistence
    private var completedItems: Set<String> {
        enrollment?.completedItemIds(forDay: day.day) ?? []
    }

    /// Routines for this day
    private var dayRoutines: [Routine] {
        routines.filter { day.routineRefs.contains($0.id) }
    }

    /// Movements for this day
    private var dayMovements: [Movement] {
        movements.filter { day.movementRefs.contains($0.id) }
    }

    /// Lesson for this day (if any)
    private var dayLesson: Lesson? {
        guard let ref = day.lessonRef else { return nil }
        return lessons.first { $0.id == ref }
    }

    /// Total items to complete
    private var totalItems: Int {
        day.routineRefs.count + day.movementRefs.count + (day.lessonRef != nil ? 1 : 0)
    }

    /// Progress through the day
    private var progress: Double {
        guard totalItems > 0 else { return 1.0 }
        return Double(completedItems.count) / Double(totalItems)
    }

    /// Whether all items are complete
    private var isComplete: Bool {
        completedItems.count >= totalItems
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Day header
                    VStack(spacing: theme.spacing.sm) {
                        Text("Day \(day.day)")
                            .font(theme.typography.displayMedium)
                            .foregroundColor(theme.colors.textPrimary)

                        Text(program.displayName)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)

                        // Progress indicator
                        VStack(spacing: theme.spacing.xxs) {
                            ProgressView(value: progress)
                                .tint(theme.colors.accent)
                                .frame(maxWidth: 200)

                            Text("\(completedItems.count) of \(totalItems) complete")
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)
                        }
                        .padding(.top, theme.spacing.sm)
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)

                    // Content sections
                    VStack(spacing: theme.spacing.lg) {
                        // Routines section
                        if !dayRoutines.isEmpty {
                            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                                SectionHeader(title: "Routines", icon: "cup.and.saucer.fill")

                                ForEach(dayRoutines) { routine in
                                    DayItemCard(
                                        title: routine.displayName,
                                        subtitle: "\(routine.durationMin) min",
                                        icon: "cup.and.saucer",
                                        isCompleted: completedItems.contains(routine.id),
                                        onTap: {
                                            selectedRoutine = routine
                                            HapticManager.light()
                                        },
                                        onComplete: {
                                            toggleComplete(routine.id)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        }

                        // Movements section
                        if !dayMovements.isEmpty {
                            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                                SectionHeader(title: "Movements", icon: "figure.walk")

                                ForEach(dayMovements) { movement in
                                    DayItemCard(
                                        title: movement.displayName,
                                        subtitle: "\(movement.durationMin) min \u{2022} \(movement.intensity.displayName)",
                                        icon: "figure.walk",
                                        isCompleted: completedItems.contains(movement.id),
                                        onTap: {
                                            selectedMovement = movement
                                            HapticManager.light()
                                        },
                                        onComplete: {
                                            toggleComplete(movement.id)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        }

                        // Lesson section
                        if let lesson = dayLesson {
                            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                                SectionHeader(title: "Today's Lesson", icon: "book.fill")

                                DayItemCard(
                                    title: lesson.displayName,
                                    subtitle: "Learn about \(lesson.topic)",
                                    icon: "book",
                                    isCompleted: completedItems.contains(lesson.id),
                                    onTap: {
                                        selectedLesson = lesson
                                        HapticManager.light()
                                    },
                                    onComplete: {
                                        toggleComplete(lesson.id)
                                    }
                                )
                            }
                            .padding(.horizontal, theme.spacing.lg)
                        }
                    }

                    Spacer(minLength: theme.spacing.xxl)

                    // Complete day button
                    if isComplete {
                        VStack(spacing: theme.spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(theme.colors.success)

                            Text("Day Complete!")
                                .font(theme.typography.headlineSmall)
                                .foregroundColor(theme.colors.textPrimary)

                            TerrainPrimaryButton(
                                title: "Continue",
                                action: {
                                    onComplete()
                                    dismiss()
                                }
                            )
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.bottom, theme.spacing.lg)
                    }
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
            // Sheets for detail views would go here
            // .sheet(item: $selectedRoutine) { routine in RoutineDetailSheet(routine: routine) }
            // .sheet(item: $selectedMovement) { movement in MovementPlayerSheet(movement: movement) }
            // .sheet(item: $selectedLesson) { lesson in LessonDetailSheet(lesson: lesson) }
        }
    }

    // MARK: - Helpers

    private func toggleComplete(_ id: String) {
        guard let enrollment = enrollment else { return }

        if completedItems.contains(id) {
            // Remove from completion list
            if let dayIndex = enrollment.dayCompletions.firstIndex(where: { $0.day == day.day }) {
                enrollment.dayCompletions[dayIndex].completedItemIds.removeAll { $0 == id }
            }
        } else {
            // Add to completion list
            enrollment.markItemCompleted(id, forDay: day.day)
            HapticManager.success()
        }

        enrollment.updatedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(theme.colors.accent)

            Text(title)
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)
        }
    }
}

// MARK: - Day Item Card

struct DayItemCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isCompleted: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            // Completion toggle
            Button {
                onComplete()
            } label: {
                ZStack {
                    Circle()
                        .stroke(
                            isCompleted ? theme.colors.success : theme.colors.textTertiary.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)

                    if isCompleted {
                        Circle()
                            .fill(theme.colors.success)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }

            // Content (tappable to view details)
            Button {
                onTap()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        Text(title)
                            .font(theme.typography.labelMedium)
                            .foregroundColor(isCompleted ? theme.colors.textTertiary : theme.colors.textPrimary)
                            .strikethrough(isCompleted)

                        Text(subtitle)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.medium)
    }
}

#Preview {
    ProgramDayView(
        program: Program(
            id: "preview-program",
            title: "7-Day Digestive Reset",
            durationDays: 7
        ),
        day: ProgramDay(
            day: 1,
            routineRefs: ["warm-start-congee-full", "ginger-honey-tea-lite"],
            movementRefs: ["morning-qi-flow-full"],
            lessonRef: "understanding-cold-heat"
        ),
        enrollment: ProgramEnrollment(programId: "preview-program"),
        onComplete: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
