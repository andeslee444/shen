//
//  TerrainRevealView.swift
//  Terrain
//
//  Terrain reveal screen - the signature moment
//

import SwiftUI

struct TerrainRevealView: View {
    let result: TerrainScoringEngine.ScoringResult
    let onContinue: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var revealPhase = 0

    private var terrainCopy: TerrainCopy {
        TerrainCopy.forType(result.primaryType, modifier: result.modifier)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.xl) {
                Spacer(minLength: theme.spacing.xxl)

                // Header
                VStack(spacing: theme.spacing.sm) {
                    Text("Your Terrain")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(2)
                        .opacity(revealPhase >= 1 ? 1 : 0)

                    // Primary Label
                    Text(result.primaryType.label)
                        .font(theme.typography.displayMedium)
                        .foregroundColor(theme.colors.textPrimary)
                        .opacity(revealPhase >= 1 ? 1 : 0)
                        .scaleEffect(revealPhase >= 1 ? 1 : 0.9)

                    // Nickname
                    Text("(\(result.primaryType.nickname))")
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.colors.accent)
                        .opacity(revealPhase >= 2 ? 1 : 0)

                    // Modifier chip
                    if result.modifier != .none {
                        TerrainChip(title: result.modifier.displayName, isSelected: true)
                            .opacity(revealPhase >= 2 ? 1 : 0)
                    }
                }
                .animation(theme.animation.reveal, value: revealPhase)

                // Superpower / Trap / Ritual
                VStack(spacing: theme.spacing.lg) {
                    TerrainRevealCard(
                        icon: "sparkles",
                        title: "Your Superpower",
                        content: terrainCopy.superpower
                    )
                    .opacity(revealPhase >= 3 ? 1 : 0)
                    .offset(y: revealPhase >= 3 ? 0 : 20)

                    TerrainRevealCard(
                        icon: "exclamationmark.triangle",
                        title: "Your Trap",
                        content: terrainCopy.trap
                    )
                    .opacity(revealPhase >= 3 ? 1 : 0)
                    .offset(y: revealPhase >= 3 ? 0 : 20)

                    TerrainRevealCard(
                        icon: "sun.horizon",
                        title: "Your Signature Ritual",
                        content: terrainCopy.signatureRitual
                    )
                    .opacity(revealPhase >= 3 ? 1 : 0)
                    .offset(y: revealPhase >= 3 ? 0 : 20)
                }
                .padding(.horizontal, theme.spacing.lg)
                .animation(theme.animation.reveal.delay(0.2), value: revealPhase)

                // Truths
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("Truths about you")
                        .font(theme.typography.labelLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    ForEach(Array(terrainCopy.truths.prefix(3).enumerated()), id: \.offset) { index, truth in
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
                .opacity(revealPhase >= 4 ? 1 : 0)
                .animation(theme.animation.reveal.delay(0.3), value: revealPhase)

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
                .opacity(revealPhase >= 4 ? 1 : 0)
                .animation(theme.animation.reveal.delay(0.4), value: revealPhase)

                Spacer(minLength: theme.spacing.xxl)

                // Continue button
                TerrainPrimaryButton(title: "Continue", action: onContinue)
                    .padding(.horizontal, theme.spacing.lg)
                    .opacity(revealPhase >= 4 ? 1 : 0)
                    .animation(theme.animation.reveal.delay(0.5), value: revealPhase)

                Spacer(minLength: theme.spacing.lg)
            }
        }
        .onAppear {
            animateReveal()
        }
    }

    private func animateReveal() {
        withAnimation(theme.animation.reveal) {
            revealPhase = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(theme.animation.reveal) {
                revealPhase = 2
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(theme.animation.reveal) {
                revealPhase = 3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(theme.animation.reveal) {
                revealPhase = 4
            }
        }
    }
}

struct TerrainRevealCard: View {
    let icon: String
    let title: String
    let content: String

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(theme.colors.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textTertiary)

                Text(content)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)
            }

            Spacer()
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
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

// MARK: - Terrain Copy Data

struct TerrainCopy {
    let superpower: String
    let trap: String
    let signatureRitual: String
    let truths: [String]
    let bestMatchesIntro: String
    let recommendedIngredients: [String]

    static func forType(_ type: TerrainScoringEngine.PrimaryType, modifier: TerrainScoringEngine.Modifier) -> TerrainCopy {
        switch type {
        case .coldDeficient:
            return TerrainCopy(
                superpower: "When you're consistent, you become steady. Warmth and routine unlock your best energy.",
                trap: "Cold inputs and skipping meals drain you faster than you expect.",
                signatureRitual: "Warm start within 30 minutes of waking.",
                truths: [
                    "Your system does better with gentle build-up than big pushes.",
                    "Cooked food stabilizes you—raw/cold hits harder for you than most.",
                    "Movement works best for you when it warms you up, not when it exhausts you."
                ],
                bestMatchesIntro: "Your best matches tend to be warming, digestion-supporting, and steadying.",
                recommendedIngredients: ["Ginger", "Red Dates", "Cinnamon", "Oats", "Rice", "Sweet Potato"]
            )

        case .coldBalanced:
            return TerrainCopy(
                superpower: "You stay composed under pressure. Warmth turns that calm into momentum.",
                trap: "If you stay too cold for too long, you get sluggish and heavy.",
                signatureRitual: "Warm your center before your day speeds up.",
                truths: [
                    "You can handle a lot—until cold quietly accumulates.",
                    "Warm prep methods make you feel clearer without changing your diet drastically.",
                    "A little movement goes a long way for you when it's consistent."
                ],
                bestMatchesIntro: "You do best with warming basics and light daily movement.",
                recommendedIngredients: ["Ginger", "Scallion", "Black Pepper", "Lamb", "Walnuts", "Longan"]
            )

        case .neutralDeficient:
            return TerrainCopy(
                superpower: "You're sensitive in a good way. Small changes give you big returns.",
                trap: "Overcommitting drains you. You feel it in sleep, digestion, and focus.",
                signatureRitual: "A steady breakfast + a short reset movement.",
                truths: [
                    "Your body thrives on predictable fuel.",
                    "You recover fastest with gentle routines, not intensity.",
                    "When you're depleted, your mind gets louder—protect your evenings."
                ],
                bestMatchesIntro: "You do best with steady nourishment, gentle movement, and calm evenings.",
                recommendedIngredients: ["Rice", "Chicken", "Eggs", "Sweet Potato", "Mushrooms", "Honey"]
            )

        case .neutralBalanced:
            return TerrainCopy(
                superpower: "You adapt well. With the right ritual, you can fine-tune sleep, digestion, and energy quickly.",
                trap: "When your schedule gets chaotic, your body follows.",
                signatureRitual: "A daily anchor: one warm drink + one short movement.",
                truths: [
                    "You're responsive—small routines keep you aligned.",
                    "Your biggest lever is consistency, not strictness.",
                    "You can tolerate variety, but your body loves rhythm."
                ],
                bestMatchesIntro: "You benefit from balanced routines that keep your rhythm steady.",
                recommendedIngredients: ["Green Tea", "Rice", "Vegetables", "Tofu", "Fish", "Sesame"]
            )

        case .neutralExcess:
            return TerrainCopy(
                superpower: "You have drive. When your flow is smooth, you're magnetic and productive.",
                trap: "You can run on tension. It looks like energy, but it costs sleep and digestion.",
                signatureRitual: "A 3-minute unwind to release tension daily.",
                truths: [
                    "Your body holds stress in your breath, jaw, and shoulders.",
                    "You feel best when you move the stuck energy early.",
                    "Evening calm is your performance enhancer."
                ],
                bestMatchesIntro: "You do best with routines that move tension and settle the mind.",
                recommendedIngredients: ["Chamomile", "Citrus Peel", "Radish", "Celery", "Mint", "Jasmine"]
            )

        case .warmBalanced:
            return TerrainCopy(
                superpower: "You have natural spark. When you stay cool-headed, you feel light and clear.",
                trap: "Too much stimulation (stress, late nights, spicy/alcohol) tips you into restlessness.",
                signatureRitual: "A cooling-down cue in the evening.",
                truths: [
                    "You run better with room-temp hydration than icy extremes.",
                    "When you're over-heated, sleep and skin show it first.",
                    "Gentle movement keeps your flame clean."
                ],
                bestMatchesIntro: "You do best with light, cooling-leaning habits and calming evenings.",
                recommendedIngredients: ["Cucumber", "Mung Bean", "Pear", "Chrysanthemum", "Green Tea", "Watermelon"]
            )

        case .warmExcess:
            return TerrainCopy(
                superpower: "You have intensity. When it's directed, you're powerful and sharp.",
                trap: "You can overrun your nervous system—sleep becomes the first casualty.",
                signatureRitual: "A nightly downshift: breath + screens off.",
                truths: [
                    "Your body runs hot under stress.",
                    "You need deliberate cooling signals, not more stimulation.",
                    "Your best days start with calm, not urgency."
                ],
                bestMatchesIntro: "You do best with calming routines that reduce heat and restlessness.",
                recommendedIngredients: ["Mung Bean", "Bitter Melon", "Celery", "Lotus Root", "Pear", "Mint"]
            )

        case .warmDeficient:
            return TerrainCopy(
                superpower: "You're bright and sensitive. When nourished, you're glowing and creative.",
                trap: "You can feel warm but depleted—restless sleep, dryness, and wired-tired energy.",
                signatureRitual: "Moistening nourishment + a consistent bedtime cue.",
                truths: [
                    "You burn quickly when you skip recovery.",
                    "Your best energy is smooth, not pushed.",
                    "Evening routines matter more for you than morning intensity."
                ],
                bestMatchesIntro: "You do best with moistening nourishment and nervous-system calming habits.",
                recommendedIngredients: ["Pear", "Honey", "Sesame", "Lily Bulb", "Tremella", "Goji Berry"]
            )
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
