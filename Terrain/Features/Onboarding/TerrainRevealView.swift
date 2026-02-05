//
//  TerrainRevealView.swift
//  Terrain
//
//  Terrain reveal screen - the signature moment
//  Two-phase reveal: emotional identity first, then practical guidance.
//

import SwiftUI

struct TerrainRevealView: View {
    let result: TerrainScoringEngine.ScoringResult
    let onContinue: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealPhase = 0
    @State private var pulseScale: CGFloat = 0.8
    @State private var pulseOpacity: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var particleOffset: CGFloat = 0
    @State private var showingPracticalScreen = false

    private var terrainCopy: TerrainCopy {
        TerrainCopy.forType(result.primaryType, modifier: result.modifier)
    }

    /// Color for the terrain type glow effect
    private var terrainGlowColor: Color {
        switch result.primaryType {
        case .coldDeficient, .coldBalanced:
            return Color(hex: "7A8E9E") // Cool blue-grey
        case .warmDeficient, .warmBalanced, .warmExcess:
            return Color(hex: "C9956E") // Warm amber
        case .neutralDeficient, .neutralBalanced, .neutralExcess:
            return Color(hex: "9E9E8E") // Neutral earth
        }
    }

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            if !showingPracticalScreen {
                // PHASE 1: Emotional — the identity moment
                emotionalReveal
                    .transition(.opacity)
            } else {
                // PHASE 2: Practical — what this means for you
                practicalReveal
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .background(theme.colors.background)
        .onAppear {
            animateReveal()
        }
    }

    // MARK: - Phase 1: Emotional Reveal

    private var emotionalReveal: some View {
        ZStack {
            // Mystical background with radial gradient pulse
            RadialGradient(
                gradient: Gradient(colors: [
                    terrainGlowColor.opacity(glowIntensity * 0.3),
                    theme.colors.background.opacity(0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .scaleEffect(pulseScale)
            .opacity(pulseOpacity)
            .animation(reduceMotion ? nil : .easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseScale)

            // Floating particles effect (hidden when reduceMotion is on)
            if !reduceMotion {
                GeometryReader { geometry in
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(terrainGlowColor.opacity(0.2))
                            .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
                            .position(
                                x: geometry.size.width * CGFloat.random(in: 0.2...0.8),
                                y: geometry.size.height * (0.2 + CGFloat(index) * 0.08) - particleOffset
                            )
                            .opacity(revealPhase >= 1 ? 0.6 : 0)
                            .animation(
                                .easeInOut(duration: Double.random(in: 3...5))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: particleOffset
                            )
                    }
                }
                .allowsHitTesting(false)
            }

            VStack(spacing: theme.spacing.xxl) {
                Spacer()

                // "Your Terrain" label
                Text("Your Terrain")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(3)
                    .opacity(revealPhase >= 1 ? 1 : 0)

                // Nickname — the hero moment, large and centered
                Text(result.primaryType.nickname)
                    .font(theme.typography.displayLarge)
                    .foregroundColor(theme.colors.textPrimary)
                    .opacity(revealPhase >= 1 ? 1 : 0)
                    .scaleEffect(revealPhase >= 1 ? 1 : 0.7)
                    .blur(radius: revealPhase >= 1 ? 0 : 10)
                    .shadow(color: reduceMotion ? .clear : terrainGlowColor.opacity(0.5), radius: 10, x: 0, y: 0)

                // Superpower — the emotional hook
                VStack(spacing: theme.spacing.sm) {
                    Text("Your Superpower")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(terrainCopy.superpower)
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.xl)
                }
                .opacity(revealPhase >= 2 ? 1 : 0)
                .offset(y: revealPhase >= 2 ? 0 : 10)

                // Community normalization
                Text(CommunityStats.normalizationText(for: result.primaryType.terrainProfileId))
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
                    .opacity(revealPhase >= 2 ? 1 : 0)

                Spacer()

                // Continue to Phase 2
                TerrainPrimaryButton(title: "Continue", action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showingPracticalScreen = true
                    }
                })
                .padding(.horizontal, theme.spacing.lg)
                .opacity(revealPhase >= 2 ? 1 : 0)
                .animation(theme.animation.reveal.delay(0.3), value: revealPhase)

                Spacer(minLength: theme.spacing.lg)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: revealPhase)
        }
    }

    // MARK: - Phase 2: Practical Reveal

    private var practicalReveal: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                Spacer(minLength: theme.spacing.xl)

                // Header — echoes the identity
                VStack(spacing: theme.spacing.sm) {
                    Text("What this means for you")
                        .font(theme.typography.headlineLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(result.primaryType.nickname)
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.accent)
                }

                // Modifier explanation (if present)
                if result.modifier != .none {
                    VStack(spacing: theme.spacing.xs) {
                        TerrainChip(title: result.modifier.displayName, isSelected: true)

                        Text(modifierExplanation)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, theme.spacing.xl)
                    }
                    .padding(.vertical, theme.spacing.sm)
                }

                // Trap + Ritual cards
                VStack(spacing: theme.spacing.lg) {
                    TerrainRevealCard(
                        icon: "exclamationmark.triangle",
                        title: "Your Trap",
                        content: terrainCopy.trap
                    )

                    TerrainRevealCard(
                        icon: "sun.horizon",
                        title: "Your Signature Ritual",
                        content: terrainCopy.signatureRitual
                    )
                }
                .padding(.horizontal, theme.spacing.lg)

                // Truths
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("Truths about you")
                        .font(theme.typography.labelLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    ForEach(Array(terrainCopy.truths.prefix(3).enumerated()), id: \.offset) { _, truth in
                        HStack(alignment: .top, spacing: theme.spacing.sm) {
                            Circle()
                                .fill(theme.colors.accent)
                                .frame(width: 6, height: 6)
                                .padding(.top, 8)

                            Text(truth)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.lg)

                // Best matches preview
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("Your best matches")
                        .font(theme.typography.labelLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(terrainCopy.bestMatchesIntro)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)

                    // Ingredient chips
                    FlowLayout(spacing: theme.spacing.xs) {
                        ForEach(terrainCopy.recommendedIngredients, id: \.self) { ingredient in
                            IngredientChip(name: ingredient)
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.lg)

                Spacer(minLength: theme.spacing.xxl)

                // Continue to next onboarding step
                TerrainPrimaryButton(title: "Continue", action: onContinue)
                    .padding(.horizontal, theme.spacing.lg)

                Spacer(minLength: theme.spacing.lg)
            }
        }
    }

    // MARK: - Modifier Explanation

    private var modifierExplanation: String {
        switch result.modifier {
        case .shen:
            return "Your modifier adds nuance — it means your mind tends to run restless, affecting sleep and focus."
        case .stagnation:
            return "Your modifier adds nuance — energy tends to get stuck, causing tension and emotional build-up."
        case .damp:
            return "Your modifier adds nuance — your body tends to hold onto heaviness, affecting energy and clarity."
        case .dry:
            return "Your modifier adds nuance — your body runs dry, craving moisture for skin, throat, and comfort."
        case .none:
            return ""
        }
    }

    // MARK: - Animation

    private func animateReveal() {
        if reduceMotion {
            // Skip all animations — show everything at once
            pulseOpacity = 1
            glowIntensity = 1
            pulseScale = 1.0
            revealPhase = 2
            return
        }

        // Start background glow immediately
        withAnimation(.easeIn(duration: 0.8)) {
            pulseOpacity = 1
            glowIntensity = 1
        }

        // Start pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }

        // Start particle floating
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            particleOffset = 30
        }

        // Phase 1: Nickname reveal with dramatic scale
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            revealPhase = 1
        }

        // Phase 2: Superpower and community stats
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                revealPhase = 2
            }
        }
    }
}

struct TerrainRevealCard: View {
    let icon: String
    let title: String
    let content: String

    @Environment(\.terrainTheme) private var theme
    @State private var isPressed = false

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(theme.colors.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(content)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)
            }

            Spacer()
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        // Modern elevated shadow for depth
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

/// Flow layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                self.size.width = max(self.size.width, currentX)
            }

            self.size.height = currentY + lineHeight
        }
    }
}

#Preview {
    let result = TerrainScoringEngine.ScoringResult(
        vector: TerrainVector(coldHeat: -4, defExcess: -4),
        primaryType: .coldDeficient,
        modifier: .damp,
        flags: []
    )
    return TerrainRevealView(result: result, onContinue: {})
        .environment(\.terrainTheme, TerrainTheme.default)
}
