//
//  MovementPlayerSheet.swift
//  Terrain
//
//  Movement player with frame-by-frame illustrations
//

import SwiftUI

struct MovementPlayerSheet: View {
    let level: RoutineLevel
    let onComplete: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var currentFrame = 0
    @State private var isPlaying = false
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var playButtonScale: CGFloat = 1.0

    private var movement: MovementData {
        MovementData.forLevel(level)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress
                ProgressView(value: Double(currentFrame) / Double(movement.frames.count))
                    .tint(theme.colors.accent)
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)

                // Content
                VStack(spacing: theme.spacing.lg) {
                    Spacer()

                    // Frame illustration with smooth transitions
                    ZStack {
                        RoundedRectangle(cornerRadius: theme.cornerRadius.xl)
                            .fill(theme.colors.backgroundSecondary)
                            .frame(height: 300)

                        if currentFrame < movement.frames.count {
                            VStack(spacing: theme.spacing.md) {
                                Image(systemName: movement.frames[currentFrame].icon)
                                    .font(.system(size: 80))
                                    .foregroundColor(theme.colors.accent)
                                    .id(currentFrame) // Enables transition
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .scale(scale: 1.1).combined(with: .opacity)
                                    ))

                                Text("Frame \(currentFrame + 1) of \(movement.frames.count)")
                                    .font(theme.typography.caption)
                                    .foregroundColor(theme.colors.textTertiary)
                            }
                            .animation(theme.animation.standard, value: currentFrame)
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    // Cue text with smooth transition
                    if currentFrame < movement.frames.count {
                        VStack(spacing: theme.spacing.sm) {
                            Text(movement.frames[currentFrame].cue)
                                .font(theme.typography.headlineSmall)
                                .foregroundColor(theme.colors.textPrimary)
                                .multilineTextAlignment(.center)
                                .id("cue-\(currentFrame)")
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                                .animation(theme.animation.standard, value: currentFrame)

                            if isPlaying {
                                Text("\(timeRemaining)s")
                                    .font(theme.typography.displayMedium)
                                    .foregroundColor(theme.colors.accent)
                                    .contentTransition(.numericText())
                            } else {
                                Text("\(movement.frames[currentFrame].seconds)s")
                                    .font(theme.typography.bodyMedium)
                                    .foregroundColor(theme.colors.textTertiary)
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)
                    }

                    Spacer()

                    // Controls
                    HStack(spacing: theme.spacing.xl) {
                        // Previous
                        Button(action: previousFrame) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 24))
                                .foregroundColor(currentFrame > 0 ? theme.colors.textPrimary : theme.colors.textTertiary)
                        }
                        .disabled(currentFrame == 0)

                        // Play/Pause with pulse animation when playing
                        Button(action: togglePlayPause) {
                            ZStack {
                                Circle()
                                    .fill(theme.colors.accent)
                                    .frame(width: 64, height: 64)
                                    .scaleEffect(playButtonScale)

                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        .onChange(of: isPlaying) { _, playing in
                            if playing {
                                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    playButtonScale = 1.08
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    playButtonScale = 1.0
                                }
                            }
                        }

                        // Next/Complete
                        Button(action: nextFrame) {
                            Image(systemName: currentFrame < movement.frames.count - 1 ? "forward.fill" : "checkmark")
                                .font(.system(size: 24))
                                .foregroundColor(theme.colors.textPrimary)
                        }
                    }
                    .padding(.bottom, theme.spacing.lg)

                    // Frame indicators with animation
                    HStack(spacing: theme.spacing.xs) {
                        ForEach(0..<movement.frames.count, id: \.self) { index in
                            Circle()
                                .fill(index <= currentFrame ? theme.colors.accent : theme.colors.textTertiary.opacity(0.3))
                                .frame(width: index == currentFrame ? 10 : 8, height: index == currentFrame ? 10 : 8)
                                .animation(theme.animation.quick, value: currentFrame)
                        }
                    }
                    .padding(.bottom, theme.spacing.lg)
                }
            }
            .background(theme.colors.background)
            .navigationTitle(movement.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        stopTimer()
                        dismiss()
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func togglePlayPause() {
        if isPlaying {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        guard currentFrame < movement.frames.count else { return }

        isPlaying = true
        timeRemaining = movement.frames[currentFrame].seconds

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Auto-advance to next frame
                if currentFrame < movement.frames.count - 1 {
                    currentFrame += 1
                    timeRemaining = movement.frames[currentFrame].seconds
                } else {
                    // Completed
                    stopTimer()
                    onComplete()
                    dismiss()
                }
            }
        }
    }

    private func stopTimer() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    private func previousFrame() {
        stopTimer()
        if currentFrame > 0 {
            currentFrame -= 1
        }
    }

    private func nextFrame() {
        stopTimer()
        if currentFrame < movement.frames.count - 1 {
            currentFrame += 1
        } else {
            onComplete()
            dismiss()
        }
    }
}

// MARK: - Mock Data

struct MovementData {
    let title: String
    let frames: [MovementFrameData]

    static func forLevel(_ level: RoutineLevel) -> MovementData {
        switch level {
        case .full:
            return MovementData(
                title: "Morning Qi Flow",
                frames: [
                    MovementFrameData(cue: "Stand with feet hip-width apart, arms relaxed", icon: "figure.stand", seconds: 10),
                    MovementFrameData(cue: "Inhale deeply, raising arms overhead", icon: "figure.arms.open", seconds: 8),
                    MovementFrameData(cue: "Exhale slowly, folding forward", icon: "figure.cooldown", seconds: 10),
                    MovementFrameData(cue: "Inhale, rise halfway with flat back", icon: "figure.flexibility", seconds: 8),
                    MovementFrameData(cue: "Exhale, fold deeper", icon: "figure.cooldown", seconds: 10),
                    MovementFrameData(cue: "Inhale, roll up slowly, arms rising", icon: "figure.arms.open", seconds: 10),
                    MovementFrameData(cue: "Gentle twist to the right", icon: "figure.flexibility", seconds: 15),
                    MovementFrameData(cue: "Gentle twist to the left", icon: "figure.flexibility", seconds: 15),
                    MovementFrameData(cue: "Side stretch right", icon: "figure.flexibility", seconds: 12),
                    MovementFrameData(cue: "Side stretch left", icon: "figure.flexibility", seconds: 12),
                    MovementFrameData(cue: "Return to standing, hands to heart", icon: "figure.stand", seconds: 10)
                ]
            )

        case .lite:
            return MovementData(
                title: "Gentle Stretches",
                frames: [
                    MovementFrameData(cue: "Neck circles: slowly roll your head right", icon: "figure.cooldown", seconds: 15),
                    MovementFrameData(cue: "Neck circles: slowly roll your head left", icon: "figure.cooldown", seconds: 15),
                    MovementFrameData(cue: "Shoulder rolls: forward", icon: "figure.arms.open", seconds: 15),
                    MovementFrameData(cue: "Shoulder rolls: backward", icon: "figure.arms.open", seconds: 15),
                    MovementFrameData(cue: "Gentle seated twist right", icon: "figure.flexibility", seconds: 20),
                    MovementFrameData(cue: "Gentle seated twist left", icon: "figure.flexibility", seconds: 20)
                ]
            )

        case .minimum:
            return MovementData(
                title: "3 Deep Breaths",
                frames: [
                    MovementFrameData(cue: "Inhale slowly for 4 counts", icon: "lungs.fill", seconds: 4),
                    MovementFrameData(cue: "Hold gently for 4 counts", icon: "pause.fill", seconds: 4),
                    MovementFrameData(cue: "Exhale slowly for 6 counts", icon: "wind", seconds: 6),
                    MovementFrameData(cue: "Inhale slowly for 4 counts", icon: "lungs.fill", seconds: 4),
                    MovementFrameData(cue: "Hold gently for 4 counts", icon: "pause.fill", seconds: 4),
                    MovementFrameData(cue: "Exhale slowly for 6 counts", icon: "wind", seconds: 6),
                    MovementFrameData(cue: "Inhale slowly for 4 counts", icon: "lungs.fill", seconds: 4),
                    MovementFrameData(cue: "Hold gently for 4 counts", icon: "pause.fill", seconds: 4),
                    MovementFrameData(cue: "Exhale slowly for 6 counts", icon: "wind", seconds: 6)
                ]
            )
        }
    }
}

struct MovementFrameData {
    let cue: String
    let icon: String
    let seconds: Int
}

#Preview {
    MovementPlayerSheet(level: .full, onComplete: {})
        .environment(\.terrainTheme, TerrainTheme.default)
}
