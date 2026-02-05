//
//  ConstitutionService.swift
//  Terrain
//
//  Pure-function service that generates practitioner-style content
//  for the You tab: readout, signals, defaults, and watch-fors.
//

import Foundation

final class ConstitutionService {

    // MARK: - Constitution Readout

    /// Maps each axis score to a human-readable label with magnitude qualifier and tooltip.
    func generateReadout(
        vector: TerrainVector,
        modifier: TerrainScoringEngine.Modifier
    ) -> ConstitutionReadout {
        let axes = [
            ConstitutionReadout.Axis(
                label: "Temperature",
                value: temperatureLabel(vector.coldHeat),
                tooltip: "Reflects whether your body tends to run cold or warm. This shapes which foods, drinks, and environments support you best."
            ),
            ConstitutionReadout.Axis(
                label: "Energy Reserve",
                value: energyReserveLabel(vector.defExcess),
                tooltip: "Measures how much energy your body holds in reserve. Low reserve means you deplete quickly; high reserve means energy builds up and needs release."
            ),
            ConstitutionReadout.Axis(
                label: "Fluid Balance",
                value: fluidBalanceLabel(vector.dampDry),
                tooltip: "Reflects how your body handles moisture. Damp means heaviness and sluggish digestion; dry means thirst, dry skin, and depletion of fluids."
            ),
            ConstitutionReadout.Axis(
                label: "Flow",
                value: flowLabel(vector.qiStagnation),
                tooltip: "Tracks how freely energy moves through your body. Stagnation shows up as tension, irritability, or feeling stuck."
            ),
            ConstitutionReadout.Axis(
                label: "Mind & Sleep",
                value: mindSleepLabel(vector.shenUnsettled),
                tooltip: "Reflects how settled your mind and sleep are. An unsettled mind shows up as racing thoughts, restless sleep, or difficulty winding down."
            )
        ]
        return ConstitutionReadout(axes: axes)
    }

    // MARK: - Temperature Labels

    private func temperatureLabel(_ score: Int) -> String {
        switch score {
        case ...(-7): return "Cold (strongly cold-leaning)"
        case -6...(-3): return "Cool (cold-leaning)"
        case -2...2: return magnitudeQualifier(score, neutral: "Neutral", slight: "Neutral (slight %@)", positiveDirection: "warmth", negativeDirection: "coolness")
        case 3...6: return "Warm (heat-leaning)"
        case 7...: return "Hot (strongly heat-leaning)"
        default: return "Neutral"
        }
    }

    // MARK: - Energy Reserve Labels

    private func energyReserveLabel(_ score: Int) -> String {
        switch score {
        case ...(-7): return "Very Low (deeply deficient)"
        case -6...(-3): return "Low (deficient)"
        case -2...2: return magnitudeQualifier(score, neutral: "Balanced", slight: "Balanced (slight %@)", positiveDirection: "excess", negativeDirection: "deficiency")
        case 3...6: return "High (excess)"
        case 7...: return "Very High (strongly excess)"
        default: return "Balanced"
        }
    }

    // MARK: - Fluid Balance Labels

    private func fluidBalanceLabel(_ score: Int) -> String {
        switch score {
        case ...(-7): return "Very Damp (heavy dampness)"
        case -6...(-3): return "Damp (fluid accumulation)"
        case -2...2: return magnitudeQualifier(score, neutral: "Balanced", slight: "Balanced (slight %@)", positiveDirection: "dryness", negativeDirection: "dampness")
        case 3...6: return "Dry (fluid depletion)"
        case 7...: return "Very Dry (deep dryness)"
        default: return "Balanced"
        }
    }

    // MARK: - Flow Labels

    private func flowLabel(_ score: Int) -> String {
        switch score {
        case 0...1: return "Smooth (flowing freely)"
        case 2...3: return "Mild tension"
        case 4...6: return "Stagnant (energy stuck)"
        case 7...: return "Very Stagnant (deeply stuck)"
        default: return "Smooth"
        }
    }

    // MARK: - Mind & Sleep Labels

    private func mindSleepLabel(_ score: Int) -> String {
        switch score {
        case 0...1: return "Settled (calm mind)"
        case 2...3: return "Mildly restless"
        case 4...6: return "Unsettled (restless mind)"
        case 7...: return "Very Unsettled (deeply restless)"
        default: return "Settled"
        }
    }

    /// Helper for bipolar axes in the neutral zone to add "slight warmth" / "slight coolness" etc.
    /// Each axis has its own positive/negative direction names.
    private func magnitudeQualifier(
        _ score: Int,
        neutral: String,
        slight: String,
        positiveDirection: String,
        negativeDirection: String
    ) -> String {
        if score == 0 { return neutral }
        let direction = score > 0 ? positiveDirection : negativeDirection
        return String(format: slight, direction)
    }

    // MARK: - Signal Explanations

    /// Replays quiz responses through the question bank, ranks by delta magnitude,
    /// and returns the top 3 as human-readable explanations.
    /// Returns nil if the user hasn't completed the v2 quiz (no saved responses).
    func generateSignals(responses: [QuizResponse]?) -> [SignalExplanation]? {
        guard let responses = responses, !responses.isEmpty else { return nil }

        // Build (questionTitle, optionLabel, totalDeltaMagnitude, dominantAxis) tuples
        struct SignalCandidate {
            let questionTitle: String
            let optionLabel: String
            let magnitude: Int
            let dominantAxis: String
        }

        var candidates: [SignalCandidate] = []

        for response in responses {
            guard let question = QuizQuestions.all.first(where: { $0.id == response.questionId }),
                  let option = question.options.first(where: { $0.id == response.optionId }) else {
                continue
            }

            let delta = question.weight != 1.0
                ? option.delta.weighted(by: question.weight)
                : option.delta

            let magnitude = abs(delta.coldHeat) + abs(delta.defExcess) + abs(delta.dampDry)
                + abs(delta.qiStagnation) + abs(delta.shenUnsettled)

            // Skip neutral answers (zero delta)
            guard magnitude > 0 else { continue }

            let dominantAxis = dominantAxisName(for: delta)

            candidates.append(SignalCandidate(
                questionTitle: question.title,
                optionLabel: option.label,
                magnitude: magnitude,
                dominantAxis: dominantAxis
            ))
        }

        // Sort by magnitude descending and take top 3
        candidates.sort { $0.magnitude > $1.magnitude }
        let top = Array(candidates.prefix(3))

        return top.map { candidate in
            SignalExplanation(
                summary: "\"\(candidate.optionLabel)\" — this shaped your \(candidate.dominantAxis) reading",
                axisLabel: candidate.dominantAxis
            )
        }
    }

    /// Finds which axis a delta affects the most
    private func dominantAxisName(for delta: TerrainDelta) -> String {
        let axes: [(String, Int)] = [
            ("Temperature", abs(delta.coldHeat)),
            ("Energy Reserve", abs(delta.defExcess)),
            ("Fluid Balance", abs(delta.dampDry)),
            ("Flow", abs(delta.qiStagnation)),
            ("Mind & Sleep", abs(delta.shenUnsettled))
        ]
        return axes.max(by: { $0.1 < $1.1 })?.0 ?? "Temperature"
    }

    // MARK: - Defaults

    /// Generates stable baseline guidance for a terrain type.
    /// Distinct from InsightEngine's daily do/don'ts — these describe your
    /// constitutional defaults, not today's advice.
    func generateDefaults(
        type: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> DefaultsContent {
        var best: [String]
        var avoid: [String]

        switch type {
        case .coldDeficient:
            best = [
                "Warm, cooked meals as your baseline",
                "Gentle daily movement (walking, qi gong)",
                "Layering up — your body conserves warmth poorly",
                "Earlier bedtimes to rebuild reserves"
            ]
            avoid = [
                "Cold or raw foods as regular meals",
                "Intense exercise on empty reserves",
                "Skipping breakfast"
            ]
        case .coldBalanced:
            best = [
                "Warm drinks year-round",
                "Moderate, consistent exercise",
                "Keeping extremities warm",
                "Root vegetables and warming spices"
            ]
            avoid = [
                "Extended cold exposure",
                "Heavy dairy in large quantities",
                "Staying up past 11pm regularly"
            ]
        case .neutralDeficient:
            best = [
                "Regular, small nourishing meals",
                "Prioritizing sleep above all else",
                "Gentle, restorative movement",
                "Bone broths and well-cooked grains"
            ]
            avoid = [
                "Overcommitting your schedule",
                "High-intensity workouts without recovery",
                "Irregular eating patterns"
            ]
        case .neutralBalanced:
            best = [
                "Maintaining your natural rhythm",
                "Balanced variety in diet",
                "Consistent sleep and wake times",
                "Moderate exercise you enjoy"
            ]
            avoid = [
                "Extreme diets or fasting protocols",
                "Dramatic schedule changes",
                "Excess of any one thing"
            ]
        case .neutralExcess:
            best = [
                "Daily physical activity to release buildup",
                "Creative expression as an outlet",
                "Lighter meals, especially dinner",
                "Deep breathing throughout the day"
            ]
            avoid = [
                "Sitting for long stretches",
                "Suppressing emotions or frustration",
                "Heavy, greasy foods regularly"
            ]
        case .warmBalanced:
            best = [
                "Cooling foods: cucumber, melon, leafy greens",
                "Hydrating throughout the day",
                "Evening wind-down rituals",
                "Morning activity over evening"
            ]
            avoid = [
                "Spicy food as a regular staple",
                "Overheating environments",
                "Late-night stimulation or alcohol"
            ]
        case .warmExcess:
            best = [
                "Cooling, bitter foods (greens, herbal teas)",
                "Deliberate downshifts during the day",
                "Evening quiet time without screens",
                "Movement that releases, not adds, intensity"
            ]
            avoid = [
                "Stimulants (excess caffeine, energy drinks)",
                "Confrontation when already heated",
                "Pushing through without pausing",
                "Spicy and fried foods"
            ]
        case .warmDeficient:
            best = [
                "Moistening foods: soups, stews, congee",
                "Earlier bedtime to replenish",
                "Gentle, sustained hydration",
                "Yin-nourishing practices (restorative yoga)"
            ]
            avoid = [
                "Drying foods and excess coffee",
                "Late nights and overwork",
                "Hot, spicy foods that further deplete fluids"
            ]
        }

        // Modifier overlays
        switch modifier {
        case .damp:
            best.insert("Light movement to circulate fluids", at: 0)
            avoid.insert("Excess dairy, sugar, and greasy foods", at: 0)
        case .dry:
            best.insert("Moistening foods and gentle hydration", at: 0)
            avoid.insert("Drying alcohol and excess caffeine", at: 0)
        case .stagnation:
            best.insert("Daily stretching or movement to unblock", at: 0)
            avoid.insert("Long periods of sitting or emotional suppression", at: 0)
        case .shen:
            best.insert("Calming evening routine (no screens)", at: 0)
            avoid.insert("Late-night stimulation and overthinking", at: 0)
        case .none:
            break
        }

        return DefaultsContent(bestDefaults: best, avoidDefaults: avoid)
    }

    // MARK: - Watch-Fors

    /// Generates identity-level symptom signatures — chronic patterns
    /// the user should recognize as their "off-balance" signals.
    /// Distinct from daily symptoms or InsightEngine's today-focused advice.
    func generateWatchFors(
        type: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> [WatchForItem] {
        var items: [WatchForItem]

        switch type {
        case .coldDeficient:
            items = [
                WatchForItem(text: "Feeling cold even in warm rooms", icon: "thermometer.snowflake"),
                WatchForItem(text: "Fatigue that sleep doesn't fix", icon: "battery.25"),
                WatchForItem(text: "Loose stools or poor appetite", icon: "fork.knife")
            ]
        case .coldBalanced:
            items = [
                WatchForItem(text: "Stiff joints in cold weather", icon: "figure.walk"),
                WatchForItem(text: "Slow to warm up in the morning", icon: "sunrise"),
                WatchForItem(text: "Nasal congestion when it's damp out", icon: "nose")
            ]
        case .neutralDeficient:
            items = [
                WatchForItem(text: "Hitting a wall mid-afternoon", icon: "battery.25"),
                WatchForItem(text: "Getting sick more easily than others", icon: "shield"),
                WatchForItem(text: "Low mood following low energy", icon: "cloud")
            ]
        case .neutralBalanced:
            items = [
                WatchForItem(text: "Feeling off when routines change", icon: "calendar"),
                WatchForItem(text: "Mild symptoms from excess of any kind", icon: "scale.3d"),
                WatchForItem(text: "Sensitivity to dramatic weather shifts", icon: "cloud.sun")
            ]
        case .neutralExcess:
            items = [
                WatchForItem(text: "Tension headaches or jaw clenching", icon: "brain.head.profile"),
                WatchForItem(text: "Difficulty sitting still or relaxing", icon: "figure.run"),
                WatchForItem(text: "Irritability that builds without release", icon: "bolt")
            ]
        case .warmBalanced:
            items = [
                WatchForItem(text: "Flushing or overheating easily", icon: "thermometer.high"),
                WatchForItem(text: "Thirst that spikes in the afternoon", icon: "drop"),
                WatchForItem(text: "Restless sleep on hot nights", icon: "moon.zzz")
            ]
        case .warmExcess:
            items = [
                WatchForItem(text: "Snapping at people before you realize it", icon: "bolt"),
                WatchForItem(text: "Skin breakouts or redness", icon: "flame"),
                WatchForItem(text: "Burning indigestion after meals", icon: "fork.knife"),
                WatchForItem(text: "Wired energy that won't shut off", icon: "bolt.circle")
            ]
        case .warmDeficient:
            items = [
                WatchForItem(text: "Dry skin and lips despite drinking water", icon: "drop.triangle"),
                WatchForItem(text: "Night sweats or hot flashes", icon: "thermometer.high"),
                WatchForItem(text: "Anxiety that comes from nowhere", icon: "brain.head.profile")
            ]
        }

        // Modifier overlay: add one extra watch-for at the end
        switch modifier {
        case .damp:
            items.append(WatchForItem(text: "Heavy, foggy feeling after eating", icon: "cloud.fog"))
        case .dry:
            items.append(WatchForItem(text: "Dry cough or scratchy throat", icon: "lungs.fill"))
        case .stagnation:
            items.append(WatchForItem(text: "Tension that moves — neck, ribs, temples", icon: "arrow.triangle.branch"))
        case .shen:
            items.append(WatchForItem(text: "Racing thoughts at 3 AM", icon: "moon.zzz"))
        case .none:
            break
        }

        return items
    }
}
