//
//  MovementPlayerSheet.swift
//  Terrain
//
//  Movement player with frame-by-frame illustrations
//

import SwiftUI

struct MovementPlayerSheet: View {
    let level: RoutineLevel
    var movementModel: Movement? = nil
    /// Callback with the start timestamp for duration analytics
    let onComplete: (Date?) -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var currentFrame = 0
    @State private var isPlaying = false
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var playButtonScale: CGFloat = 1.0
    @State private var showFeedbackSheet = false
    /// Tracks when the movement was started for duration analytics
    @State private var startedAt: Date = Date()

    /// Uses real SwiftData model when available, falls back to mock data
    private var movement: MovementData {
        if let model = movementModel, !model.frames.isEmpty {
            return MovementData(
                title: model.displayName,
                frames: model.frames.enumerated().map { index, frame in
                    MovementFrameData(
                        cue: frame.cue.localized,
                        icon: sfSymbolForFrame(
                            movementId: model.id,
                            frameIndex: index,
                            asset: frame.asset,
                            cue: frame.cue.localized
                        ),
                        seconds: frame.seconds
                    )
                }
            )
        }
        return MovementData.forLevel(level)
    }

    /// The "why it helps" text from the SwiftData model, for the feedback sheet
    private var whyItHelps: String? {
        movementModel?.why.expanded?.plain.localized ?? movementModel?.why.oneLine.localized
    }

    /// Hand-curated SF Symbol sequences for every movement, indexed by movement ID.
    /// Each array maps 1:1 to the movement's frame array in the content pack.
    ///
    /// The guiding principle is **physical position accuracy**: the icon must reflect
    /// where the person's body actually is (seated, standing, lying down), not just
    /// what their hands are doing. When no SF Symbol perfectly matches a micro-adjustment
    /// (e.g., "press your knees down" while seated), we keep the base position icon
    /// rather than showing a misleading different-position icon.
    ///
    /// Breathing icons (lungs.fill, wind) are position-neutral — they don't claim a body
    /// position, so they're safe to use when the cue shifts focus to breathwork.
    ///
    /// TODO: Replace SF Symbols with AI-generated pose illustrations when the asset
    /// pipeline exists. SF Symbols can only approximate ~12 distinct poses, while
    /// movements need 50+. A small image-generation model prompted with each cue
    /// ("person sitting in butterfly pose pressing knees down") would produce accurate
    /// per-frame illustrations in the app's design language.
    private static let movementIconMap: [String: [String]] = [

        // ── Standing flow: stand → arms → fold → half-lift → fold → arms → twist ──
        "morning-qi-flow-full": [
            "figure.stand",           // Stand with feet hip-width apart
            "figure.arms.open",       // Raising arms overhead
            "figure.cooldown",        // Folding forward
            "figure.yoga",            // Rise halfway, flat back (upward energy; half-lift is a GAP)
            "figure.cooldown",        // Fold deeper
            "figure.arms.open",       // Roll up, arms rising
            "figure.taichi",          // Twist right (grounded + rotational; TCM-native)
            "figure.taichi",          // Twist left
            "figure.arms.open",       // Repeat full sequence
            "figure.arms.open",       // Circle arms wide
            "figure.stand",           // Stand quietly
            "figure.stand",           // Rub palms, place on belly (still standing)
            "lungs.fill",             // Three deep breaths
        ],

        // ── Seated throughout: meditation, self-care, acupressure, breathwork ──
        "evening-wind-down": [
            "figure.mind.and.body",   // Sit comfortably, close eyes
            "figure.mind.and.body",   // Roll neck (still seated)
            "lungs.fill",             // Hand on belly, breathe deeply
            "lungs.fill",             // Inhale 4, exhale 6
            "figure.mind.and.body",   // Massage temples
            "figure.mind.and.body",   // Press between eyebrows
            "figure.mind.and.body",   // Massage base of skull
            "figure.mind.and.body",   // Palms over navel, breathe warmth
            "figure.mind.and.body",   // Sit in complete stillness
            "figure.mind.and.body",   // Open eyes slowly
        ],

        // ── Standing: neck tilts, shoulder work, breathing ──
        // Person stands in place throughout — variety is in the cue text, not body position.
        // GAP: no SF Symbol for neck tilt or shoulder roll (custom icon candidates).
        "shoulder-neck-release": [
            "figure.stand",           // Stand or sit tall, drop shoulders
            "figure.stand",           // Tilt right ear to shoulder (standing, head tilts — GAP)
            "figure.stand",           // Tilt left ear to shoulder (standing, head tilts — GAP)
            "figure.stand",           // Interlace fingers behind head (standing, hands up — GAP)
            "figure.stand",           // Shrug shoulders (standing micro-gesture)
            "figure.stand",           // Roll shoulders (standing micro-gesture — GAP)
            "lungs.fill",             // Three deep breaths
        ],

        // ── Floor: butterfly (seated) → folds → pigeon → supine ──
        // Person is SEATED on floor throughout frames 1-9. figure.cooldown shows a
        // standing fold — wrong base position. We keep seated icon and let the cue
        // text communicate the fold action. GAP: seated forward fold icon.
        "hip-opening-stretch": [
            "figure.mind.and.body",   // Butterfly pose (seated on floor)
            "figure.mind.and.body",   // Press knees down (still in butterfly)
            "figure.mind.and.body",   // Fold forward from seated (GAP: seated fold)
            "lungs.fill",             // Breathe into hips (breath focus, still in fold)
            "figure.mind.and.body",   // Extend right leg, fold over left (GAP: seated fold)
            "figure.mind.and.body",   // Extend left leg, fold over right (GAP: seated fold)
            "figure.pilates",         // Pigeon pose right
            "figure.pilates",         // Pigeon pose left
            "figure.mind.and.body",   // Return to butterfly, sit tall
            "figure.roll",            // Lie on back, knees to chest
        ],

        // ── Seated breathing: eyes closed, counting exhales ──
        "breath-counting": [
            "figure.mind.and.body",   // Sit comfortably, eyes closed
            "lungs.fill",             // Count exhale 1
            "lungs.fill",             // Continue counting to 10
            "figure.mind.and.body",   // If lose count, start at 1 (mindfulness cue)
            "figure.mind.and.body",   // Sit in silence
            "figure.mind.and.body",   // Open eyes
        ],

        // ── Floor: seated → twist right → twist left → center ──
        // Person is SEATED on floor twisting — not standing. Keep seated icon.
        // GAP: seated twist icon.
        "gentle-spinal-twist": [
            "figure.mind.and.body",   // Sit on floor, legs extended
            "figure.mind.and.body",   // Bend knee, cross over (still seated)
            "figure.mind.and.body",   // Twist to the right (seated — GAP: seated twist)
            "lungs.fill",             // Hold twist, breathe into belly
            "figure.mind.and.body",   // Unwind, switch sides (return to center)
            "figure.mind.and.body",   // Twist to the left (seated — GAP: seated twist)
            "figure.mind.and.body",   // Return to center, breathe
        ],

        // ── Standing flow: sun salute with plank and backbend ──
        "warming-sun-salute": [
            "figure.stand",           // Stand, palms together
            "figure.arms.open",       // Sweep arms overhead
            "figure.cooldown",        // Fold forward
            "figure.yoga",            // Halfway up, flat back (GAP: half-lift)
            "figure.pilates",         // Plank hold (horizontal/tabletop ≈ plank; GAP: true plank)
            "figure.yoga",            // Lower, gentle backbend (GAP: cobra/prone backbend)
            "figure.cooldown",        // Downward dog
            "figure.stand",           // Step forward, rise to standing
            "figure.arms.open",       // Repeat salute
            "figure.stand",           // Return standing, palms together
            "lungs.fill",             // Three deep breaths
        ],

        // ── Standing → folds → seated fold → rest ──
        "cooling-forward-folds": [
            "figure.stand",           // Stand, close eyes
            "figure.cooldown",        // Fold forward (standing — correct)
            "figure.cooldown",        // Head hang heavy, sway (still standing fold)
            "figure.cooldown",        // Bend knees, hold elbows in fold (still standing)
            "lungs.fill",             // Breathe into legs (breath focus)
            "figure.stand",           // Roll up slowly
            "figure.cooldown",        // Repeat fold, legs straighter (standing — correct)
            "figure.mind.and.body",   // Seated forward fold (now SEATED — GAP: seated fold)
            "figure.mind.and.body",   // Sit up, palms on knees
            "figure.mind.and.body",   // Rest in stillness
        ],

        // ── Standing: shaking sequence → stillness ──
        "tension-release-shaking": [
            "figure.stand",           // Stand, knees soft
            "figure.cross.training",  // Shake hands
            "figure.cross.training",  // Shake up to arms and shoulders
            "figure.cross.training",  // Whole body shaking
            "figure.cross.training",  // Shake vigorously, slow down
            "figure.stand",           // Come to stillness
            "lungs.fill",             // Three deep breaths
        ],

        // ── Standing: shake → swing → bounce → fold → horse stance → stillness ──
        "dynamic-tension-release-full": [
            "figure.cross.training",  // Shake hands at sides
            "figure.cross.training",  // Full body shaking
            "figure.cross.training",  // Arm swings, torso twist
            "figure.cross.training",  // Bouncing + swinging
            "figure.cooldown",        // Wide-legged forward fold
            "figure.martial.arts",    // Horse stance (martial arts position, not gym squat)
            "figure.martial.arts",    // Pulse in horse stance
            "figure.cross.training",  // Resume shaking, slower
            "figure.stand",           // Slow to stillness, eyes closed
            "lungs.fill",             // Palms on belly, deep breaths
        ],

        // ── Standing: self-care warmth → arm circles → march → stillness ──
        "quick-qi-warm-up-medium": [
            "figure.stand",           // Rub palms (standing)
            "figure.stand",           // Warm palms on lower back (standing)
            "figure.stand",           // Rub palms, place on belly (standing)
            "figure.arms.open",       // Circle arms overhead
            "figure.arms.open",       // Arms down, palms facing floor
            "figure.arms.open",       // Repeat arm circles
            "figure.walk",            // March in place
            "figure.stand",           // Stillness, palms on heart
        ],

        // ── Seated: sitali breath, nostril breathing ──
        "cooling-breath-flow-medium": [
            "figure.mind.and.body",   // Sit comfortably, palms up
            "lungs.fill",             // Sitali breath (tongue straw inhale)
            "wind",                   // Exhale through nose
            "lungs.fill",             // Left-nostril inhale
            "wind",                   // Exhale right nostril
            "figure.mind.and.body",   // Natural breathing, notice coolness
            "figure.mind.and.body",   // Sit in silence
        ],

        // ── Standing: quick warm-up micro ──
        "standing-warm-up-lite": [
            "figure.stand",           // Rub palms (standing)
            "figure.stand",           // Warm palms on lower back (standing)
            "figure.walk",            // March in place
            "figure.stand",           // Come to stillness
        ],

        // ── Seated/standing: three deep breaths ──
        "three-deep-breaths-lite": [
            "figure.mind.and.body",   // Close eyes
            "lungs.fill",             // Inhale 4, exhale 6
            "lungs.fill",             // Deeper inhale, longer exhale
            "wind",                   // Deepest breath, soften on exhale
        ],

        // ── Seated: cooling exhale pattern ──
        "cool-down-exhale-lite": [
            "figure.mind.and.body",   // Sit or stand, drop shoulders
            "wind",                   // Inhale 3, exhale 8 pursed lips
            "wind",                   // Repeat
            "wind",                   // Final round
        ],

        // ── Standing: shoulder drops and rolls ──
        "shoulder-drop-reset-lite": [
            "figure.stand",           // Lift shoulders to ears (standing)
            "wind",                   // Drop on exhale
            "figure.stand",           // Squeeze up again
            "wind",                   // Drop with jaw open
            "figure.stand",           // Roll shoulders back (standing — GAP: shoulder roll)
        ],

        // ── Seated: chair twists ──
        // Person is SEATED in chair — keep seated icon. GAP: seated twist.
        "seated-twist-lite": [
            "figure.mind.and.body",   // Sit tall in chair
            "figure.mind.and.body",   // Twist right (seated — GAP: seated twist)
            "figure.mind.and.body",   // Twist left (seated — GAP: seated twist)
            "figure.mind.and.body",   // Return to center, breathe
        ],

        // ── Seated: body scan meditation ──
        "body-scan-breath-lite": [
            "figure.mind.and.body",   // Close eyes, notice tension
            "figure.mind.and.body",   // Breathe into forehead/jaw
            "figure.mind.and.body",   // Breathe into shoulders/chest
            "figure.mind.and.body",   // Breathe into belly/hips
            "figure.mind.and.body",   // Open eyes
        ],
    ]

    /// Returns the SF Symbol for a specific frame in a movement.
    ///
    /// Strategy (in priority order):
    /// 1. **Hand-curated map** — every known movement has a position-accurate icon
    ///    sequence that respects physical continuity (e.g., "press knees" during
    ///    butterfly keeps the seated icon, not a standing lunge).
    /// 2. **Keyword fallback** — for future movements not yet in the map, uses
    ///    cue text heuristics. Less accurate but reasonable for unknown content.
    /// 3. **Default** — `figure.stand`
    private func sfSymbolForFrame(movementId: String, frameIndex: Int, asset: MediaAsset, cue: String) -> String {
        // 1. Hand-curated map (preferred — physically accurate)
        if let icons = Self.movementIconMap[movementId], frameIndex < icons.count {
            return icons[frameIndex]
        }

        // 2. Keyword fallback for movements not yet in the map
        return sfSymbolFromCue(cue, asset: asset)
    }

    /// Keyword-based SF Symbol matching. Used as a fallback when a movement isn't
    /// in the hand-curated map (e.g., newly added content pack movements).
    ///
    /// NOTE: `figure.flexibility` (standing lunge) is intentionally NOT used here.
    /// It matches nothing in our movement vocabulary. If you're tempted to add it,
    /// find a more position-accurate icon instead.
    private func sfSymbolFromCue(_ cue: String, asset: MediaAsset) -> String {
        let c = cue.lowercased()

        // Floor positions
        if c.contains("lie on your back") || c.contains("lying") { return "figure.roll" }
        if c.contains("pigeon pose") { return "figure.pilates" }

        // Folds (standing only — seated folds should match the seated block below)
        if c.contains("fold forward") || c.contains("fold deeper") || c.contains("fold over")
            || c.contains("fold gently") || c.contains("fold slowly") || c.contains("downward dog")
            || c.contains("head hang") || c.contains("hang heavy") {
            return "figure.cooldown"
        }

        // Power holds — horse stance is a martial arts position
        if c.contains("horse stance") || c.contains("wide squat") {
            return "figure.martial.arts"
        }
        if c.contains("plank") { return "figure.pilates" }

        // Dynamic movement
        if c.contains("shak") || c.contains("bouncing") { return "figure.cross.training" }
        if c.contains("swing") && (c.contains("arm") || c.contains("torso")) {
            return "figure.cross.training"
        }

        // Walking
        if c.contains("march") { return "figure.walk" }

        // Twists — figure.taichi for standing, figure.mind.and.body for seated
        if c.contains("twist") {
            if c.contains("seat") || c.contains("chair") || c.contains("floor") {
                return "figure.mind.and.body"
            }
            return "figure.taichi"
        }

        // Arms raised
        if c.contains("arms overhead") || c.contains("raising arms")
            || c.contains("sweep arms") || c.contains("circle arms") {
            return "figure.arms.open"
        }

        // Half-lift / backbend — figure.yoga (upward energy)
        if c.contains("half") && c.contains("back") { return "figure.yoga" }
        if c.contains("backbend") || c.contains("cobra") { return "figure.yoga" }

        // Standing micro-movements (neck tilts, shoulder rolls, interlace) — stay standing
        if c.contains("tilt") && (c.contains("ear") || c.contains("head")) { return "figure.stand" }
        if c.contains("interlace") { return "figure.stand" }
        if c.contains("roll shoulder") { return "figure.stand" }

        // Breathing (position-neutral icons — safe regardless of body position)
        if c.contains("nostril") || c.contains("sitali") { return "lungs.fill" }
        if c.contains("exhale") && (c.contains("slowly") || c.contains("pursed") || c.contains("count")) {
            return "wind"
        }
        if c.contains("inhale") && c.contains("count") { return "lungs.fill" }
        if c.contains("deep breath") || c.contains("three breath") { return "lungs.fill" }

        // Seated / meditative
        if c.contains("butterfly") || c.contains("close your eyes") || c.contains("silence")
            || c.contains("stillness") || c.contains("open your eyes") || c.contains("massage") {
            return "figure.mind.and.body"
        }
        if c.contains("sit") && (c.contains("floor") || c.contains("comfortably")
            || c.contains("tall") || c.contains("chair") || c.contains("quietly")) {
            return "figure.mind.and.body"
        }

        // Standing
        if c.contains("stand") || c.contains("rise") || c.contains("roll up") {
            return "figure.stand"
        }

        // URI fallback
        let uri = asset.uri.lowercased()
        if uri.contains("breath") || uri.contains("lung") { return "lungs.fill" }
        if uri.contains("twist") { return "figure.taichi" }
        if uri.contains("cool") || uri.contains("fold") { return "figure.cooldown" }
        if uri.contains("warm") || uri.contains("scan") { return "figure.mind.and.body" }
        if uri.contains("tension") || uri.contains("shak") { return "figure.cross.training" }
        if uri.contains("stand") { return "figure.stand" }
        if uri.contains("shoulder") { return "figure.stand" }

        return "figure.stand"
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
        .sheet(isPresented: $showFeedbackSheet, onDismiss: {
            // Fire the completion callback with start time for duration analytics
            onComplete(startedAt)
            dismiss()
        }) {
            PostRoutineFeedbackSheet(
                routineTitle: movement.title,
                whyItHelps: whyItHelps,
                onDismiss: { }
            )
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
                    // Completed — show feedback before dismissing
                    stopTimer()
                    showFeedbackSheet = true
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
            showFeedbackSheet = true
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
                    MovementFrameData(cue: "Inhale, rise halfway with flat back", icon: "figure.yoga", seconds: 8),
                    MovementFrameData(cue: "Exhale, fold deeper", icon: "figure.cooldown", seconds: 10),
                    MovementFrameData(cue: "Inhale, roll up slowly, arms rising", icon: "figure.arms.open", seconds: 10),
                    MovementFrameData(cue: "Gentle twist to the right", icon: "figure.taichi", seconds: 15),
                    MovementFrameData(cue: "Gentle twist to the left", icon: "figure.taichi", seconds: 15),
                    MovementFrameData(cue: "Side stretch right", icon: "figure.taichi", seconds: 12),
                    MovementFrameData(cue: "Side stretch left", icon: "figure.taichi", seconds: 12),
                    MovementFrameData(cue: "Return to standing, hands to heart", icon: "figure.stand", seconds: 10)
                ]
            )

        case .medium:
            return MovementData(
                title: "Gentle Stretches",
                frames: [
                    MovementFrameData(cue: "Neck circles: slowly roll your head right", icon: "figure.stand", seconds: 15),
                    MovementFrameData(cue: "Neck circles: slowly roll your head left", icon: "figure.stand", seconds: 15),
                    MovementFrameData(cue: "Shoulder rolls: forward", icon: "figure.arms.open", seconds: 15),
                    MovementFrameData(cue: "Shoulder rolls: backward", icon: "figure.arms.open", seconds: 15),
                    MovementFrameData(cue: "Gentle seated twist right", icon: "figure.mind.and.body", seconds: 20),
                    MovementFrameData(cue: "Gentle seated twist left", icon: "figure.mind.and.body", seconds: 20)
                ]
            )

        case .lite:
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
    MovementPlayerSheet(level: .full, onComplete: { _ in })
        .environment(\.terrainTheme, TerrainTheme.default)
}
