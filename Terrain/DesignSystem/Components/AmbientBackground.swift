//
//  AmbientBackground.swift
//  Terrain
//
//  Phase-aware gradient background with optional floating particles.
//  Creates an atmospheric, "living" backdrop for detail sheets.
//

import SwiftUI

/// A subtle, breathing background that responds to time of day and scroll position.
///
/// Morning routines get warm amber gradients (sunrise energy),
/// evening routines get cool blue-gray gradients (moonlit calm).
/// The gradient fades as the user scrolls, focusing attention on content.
struct AmbientBackground: View {
    let phase: DayPhase
    let scrollOffset: CGFloat
    let showParticles: Bool

    @Environment(\.terrainTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(phase: DayPhase, scrollOffset: CGFloat = 0, showParticles: Bool = true) {
        self.phase = phase
        self.scrollOffset = scrollOffset
        self.showParticles = showParticles
    }

    private var gradientColor: Color {
        phase == .morning ? theme.colors.terrainWarm : theme.colors.terrainCool
    }

    /// Fade out gradient as user scrolls (0% at 300pt scroll)
    private var gradientOpacity: Double {
        let fadeProgress = min(scrollOffset / 300, 1.0)
        return 0.12 * (1.0 - fadeProgress * 0.6)
    }

    var body: some View {
        ZStack {
            // Phase-aware gradient
            LinearGradient(
                colors: [
                    gradientColor.opacity(gradientOpacity),
                    gradientColor.opacity(gradientOpacity * 0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Floating particles (optional, respects reduceMotion)
            if showParticles && !reduceMotion {
                FloatingParticles(
                    color: gradientColor,
                    count: 8
                )
                .opacity(0.4 * (1.0 - min(scrollOffset / 200, 1.0)))
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Floating Particles

/// Ambient floating elements that drift slowly across the view.
/// Creates a subtle "alive" feeling without being distracting.
struct FloatingParticles: View {
    let color: Color
    let count: Int

    @State private var particles: [Particle] = []
    @State private var animationTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(color.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .blur(radius: particle.size * 0.3)
                        .position(particle.position)
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
                startAnimation()
            }
            .onDisappear {
                // Invalidate timer to prevent memory leak
                animationTimer?.invalidate()
                animationTimer = nil
            }
        }
    }

    private func initializeParticles(in size: CGSize) {
        particles = (0..<count).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height * 0.6)
                ),
                size: CGFloat.random(in: 20...60),
                opacity: Double.random(in: 0.03...0.08),
                velocity: CGPoint(
                    x: CGFloat.random(in: -0.3...0.3),
                    y: CGFloat.random(in: -0.2...0.1)
                )
            )
        }
    }

    private func startAnimation() {
        // Slow drift animation (30 FPS)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { _ in
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y

                // Gentle boundary wrap
                if particles[i].position.x < -50 {
                    particles[i].position.x = UIScreen.main.bounds.width + 50
                }
                if particles[i].position.x > UIScreen.main.bounds.width + 50 {
                    particles[i].position.x = -50
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let opacity: Double
    let velocity: CGPoint
}

// MARK: - Preview

#Preview("Morning") {
    ZStack {
        AmbientBackground(phase: .morning, scrollOffset: 0)
        VStack {
            Text("Morning Routine")
                .font(.title)
            Spacer()
        }
        .padding(.top, 100)
    }
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Evening") {
    ZStack {
        AmbientBackground(phase: .evening, scrollOffset: 0)
        VStack {
            Text("Evening Routine")
                .font(.title)
            Spacer()
        }
        .padding(.top, 100)
    }
    .environment(\.terrainTheme, TerrainTheme.default)
}
