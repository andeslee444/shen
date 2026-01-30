//
//  TerrainPatternBackground.swift
//  Terrain
//
//  Animated pattern backgrounds based on terrain type
//  Creates a subtle, mystical atmosphere for key screens
//

import SwiftUI

/// Animated background that generates patterns based on terrain type:
/// - Cold types: flowing water/mist particles
/// - Warm types: radiating warmth lines
/// - Damp types: cloud-like floating circles
/// - Dry types: crackle/desert line patterns
struct TerrainPatternBackground: View {
    let terrainType: TerrainScoringEngine.PrimaryType

    @Environment(\.terrainTheme) private var theme
    @State private var animationPhase: CGFloat = 0

    private var patternColor: Color {
        switch terrainType {
        case .coldDeficient, .coldBalanced:
            return theme.colors.terrainCool
        case .warmDeficient, .warmBalanced, .warmExcess:
            return theme.colors.terrainWarm
        case .neutralDeficient, .neutralBalanced, .neutralExcess:
            return theme.colors.terrainNeutral
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                RadialGradient(
                    gradient: Gradient(colors: [
                        patternColor.opacity(0.08),
                        theme.colors.background.opacity(0)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: geometry.size.height * 0.6
                )

                // Pattern layer based on terrain type
                patternView(size: geometry.size)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
    }

    @ViewBuilder
    private func patternView(size: CGSize) -> some View {
        switch terrainType {
        case .coldDeficient, .coldBalanced:
            coldMistPattern(size: size)
        case .warmDeficient, .warmBalanced, .warmExcess:
            warmRadiatePattern(size: size)
        case .neutralDeficient, .neutralBalanced, .neutralExcess:
            neutralFlowPattern(size: size)
        }
    }

    // MARK: - Cold: Flowing Mist Particles

    private func coldMistPattern(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                let baseX = CGFloat(index % 4) / 3 * size.width
                let baseY = CGFloat(index / 4) / 3 * size.height

                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                patternColor.opacity(0.15),
                                patternColor.opacity(0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .position(
                        x: baseX + sin(animationPhase * .pi * 2 + CGFloat(index) * 0.5) * 20,
                        y: baseY + cos(animationPhase * .pi * 2 + CGFloat(index) * 0.7) * 15
                    )
                    .blur(radius: 20)
            }
        }
    }

    // MARK: - Warm: Radiating Lines

    private func warmRadiatePattern(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                let angle = Double(index) / 8 * .pi * 2

                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                patternColor.opacity(0.1),
                                patternColor.opacity(0)
                            ]),
                            startPoint: .center,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size.width * 0.4, height: 2)
                    .rotationEffect(.radians(angle))
                    .position(x: size.width / 2, y: size.height * 0.3)
                    .scaleEffect(1 + animationPhase * 0.1)
                    .opacity(0.5 + animationPhase * 0.3)
            }

            // Pulsing center glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            patternColor.opacity(0.2),
                            patternColor.opacity(0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .position(x: size.width / 2, y: size.height * 0.3)
                .scaleEffect(0.8 + animationPhase * 0.4)
        }
    }

    // MARK: - Neutral: Gentle Flow

    private func neutralFlowPattern(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                let yOffset = size.height * (0.2 + CGFloat(index) * 0.12)

                WavePath(
                    amplitude: 15,
                    frequency: 2,
                    phase: animationPhase * .pi * 2 + CGFloat(index) * 0.5
                )
                .stroke(
                    patternColor.opacity(0.1 - Double(index) * 0.01),
                    lineWidth: 1.5
                )
                .frame(width: size.width, height: 40)
                .position(x: size.width / 2, y: yOffset)
            }
        }
    }
}

// MARK: - Wave Path Shape

struct WavePath: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.height / 2

        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: rect.width, by: 2) {
            let relativeX = x / rect.width
            let y = midY + sin((relativeX * frequency * .pi * 2) + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

// MARK: - Preview

#Preview("Cold Type") {
    TerrainPatternBackground(terrainType: .coldDeficient)
        .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Warm Type") {
    TerrainPatternBackground(terrainType: .warmExcess)
        .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Neutral Type") {
    TerrainPatternBackground(terrainType: .neutralBalanced)
        .environment(\.terrainTheme, TerrainTheme.default)
}
