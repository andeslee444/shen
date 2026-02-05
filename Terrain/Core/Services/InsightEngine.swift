//
//  InsightEngine.swift
//  Terrain
//
//  Content generation engine for personalized Home tab insights.
//  Generates headlines, do/don'ts, area tips, and themes based on terrain type
//  and current symptoms.
//

import Foundation

/// Engine that generates personalized content for the Home tab.
/// Think of this as the "brain" that translates a user's terrain type into
/// actionable, personalized guidance throughout the day.
final class InsightEngine {

    // MARK: - Headline Generation

    /// Generate the main headline for the day based on terrain type, symptoms, and weather
    /// Returns punchy headline (2-5 words) + flowing paragraph of personalized truths
    func generateHeadline(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        symptoms: Set<QuickSymptom> = [],
        weatherCondition: String? = nil,
        stepCount: Int? = nil
    ) -> HeadlineContent {
        // Get base headline and truths for terrain
        var headline = baseWisdom(for: terrainType)
        var truths = baseTruths(for: terrainType, modifier: modifier)

        // Layer in symptom-specific content (highest priority)
        if !symptoms.isEmpty {
            let symptomContent = symptomWisdomAndTruths(for: symptoms, terrainType: terrainType)
            headline = symptomContent.wisdom
            truths.insert(contentsOf: symptomContent.truths, at: 0)
        }

        // Layer in weather influence
        if let weather = weatherCondition {
            if let weatherTruth = weatherTruth(for: terrainType, weather: weather) {
                truths.append(weatherTruth)
            }
        }

        // Layer in step count observation
        if let steps = stepCount {
            if let stepTruth = stepTruth(for: terrainType, steps: steps) {
                truths.append(stepTruth)
            }
        }

        // Limit to 4 truths and combine into flowing paragraph
        let limitedTruths = Array(truths.prefix(4))
        let paragraph = limitedTruths.joined(separator: " ")

        return HeadlineContent(
            headline: headline,
            paragraph: paragraph,
            isSymptomAdjusted: !symptoms.isEmpty
        )
    }

    // MARK: - Two-Word Wisdom

    private func baseWisdom(for terrainType: TerrainScoringEngine.PrimaryType) -> String {
        switch terrainType {
        case .coldDeficient:
            return "Kindle gently."
        case .coldBalanced:
            return "Warm within."
        case .neutralDeficient:
            return "Build steady."
        case .neutralBalanced:
            return "Stay anchored."
        case .neutralExcess:
            return "Move freely."
        case .warmBalanced:
            return "Keep flowing."
        case .warmExcess:
            return "Cool down."
        case .warmDeficient:
            return "Nourish deeply."
        }
    }

    // MARK: - Base Truths by Terrain

    private func baseTruths(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> [String] {
        var truths: [String] = []

        // Core terrain truth
        switch terrainType {
        case .coldDeficient:
            truths.append("Your Spleen needs warmth to transform food into energy.")
            truths.append("Cold patterns run deep—rebuild with patience.")
        case .coldBalanced:
            truths.append("Your center holds steady when kept warm.")
            truths.append("Morning warmth sets the tone for the whole day.")
        case .neutralDeficient:
            truths.append("Your reserves are precious—spend wisely.")
            truths.append("Small nourishments compound into lasting strength.")
        case .neutralBalanced:
            truths.append("Balance is your gift—protect it with rhythm.")
            truths.append("Your body knows what it needs. Listen.")
        case .neutralExcess:
            truths.append("Excess qi seeks movement to stay clear.")
            truths.append("What doesn't flow, stagnates.")
        case .warmBalanced:
            truths.append("Your inner fire burns bright—feed it wisely.")
            truths.append("Heat rises. Ground yourself with cooling roots.")
        case .warmExcess:
            truths.append("Your Liver holds tension—release before it builds.")
            truths.append("Intensity without rest depletes even strong reserves.")
        case .warmDeficient:
            truths.append("Your flame burns hot but fuel runs low.")
            truths.append("Rest is not weakness—it's how you refill.")
        }

        // Modifier-specific truth
        switch modifier {
        case .damp:
            truths.append("Dampness weighs on your Spleen. Light, warm foods cut through.")
        case .dry:
            truths.append("Dryness craves moisture. Soups and seeds nourish your fluids.")
        case .stagnation:
            truths.append("Stuck qi needs movement. Even sighing helps it flow.")
        case .shen:
            truths.append("Your spirit runs restless. Stillness is medicine today.")
        case .none:
            break
        }

        return truths
    }

    // MARK: - Symptom Wisdom and Truths

    private func symptomWisdomAndTruths(
        for symptoms: Set<QuickSymptom>,
        terrainType: TerrainScoringEngine.PrimaryType
    ) -> (wisdom: String, truths: [String]) {
        // Priority: stressed > poorSleep > cramps > headache > cold > bloating > stiff > tired

        if symptoms.contains(.stressed) {
            return (
                wisdom: "Breathe first.",
                truths: [
                    "Stress tightens the Liver and blocks qi flow.",
                    "Your nervous system is asking for pause, not push."
                ]
            )
        }

        if symptoms.contains(.poorSleep) {
            return (
                wisdom: "Rest deep.",
                truths: [
                    "Poor sleep scatters the Shen and weakens tomorrow.",
                    "Your body repairs between 11pm and 3am—honor that window."
                ]
            )
        }

        if symptoms.contains(.cramps) {
            return (
                wisdom: "Soften now.",
                truths: [
                    "Cramps signal stagnation—warmth and movement help.",
                    "Blood needs to flow freely. Gentle heat opens the path."
                ]
            )
        }

        if symptoms.contains(.headache) {
            return (
                wisdom: "Ease tension.",
                truths: [
                    "Headaches often rise from Liver qi pushing upward.",
                    "Less stimulation, more space. Your head needs quiet."
                ]
            )
        }

        if symptoms.contains(.cold) {
            let coldTruth: String
            switch terrainType {
            case .coldDeficient, .coldBalanced:
                coldTruth = "Feeling cold on a cold pattern—your fire needs stoking."
            case .warmBalanced, .warmExcess, .warmDeficient:
                coldTruth = "Feeling cold despite inner warmth—your defenses are down."
            default:
                coldTruth = "Cold creeps in when qi is weak. Warm from within."
            }
            return (
                wisdom: "Warm through.",
                truths: [coldTruth]
            )
        }

        if symptoms.contains(.bloating) {
            return (
                wisdom: "Move light.",
                truths: [
                    "Bloating means your Spleen is struggling to transform.",
                    "Light meals and gentle walks help qi descend."
                ]
            )
        }

        if symptoms.contains(.stiff) {
            return (
                wisdom: "Stretch slow.",
                truths: [
                    "Stiffness is stuck qi in the channels.",
                    "Movement—even small—reminds your body to flow."
                ]
            )
        }

        if symptoms.contains(.tired) {
            return (
                wisdom: "Restore now.",
                truths: [
                    "Fatigue is your body's honest request for rest.",
                    "Pushing through tired only deepens the debt."
                ]
            )
        }

        return (wisdom: baseWisdom(for: terrainType), truths: [])
    }

    // MARK: - Weather Truths

    private func weatherTruth(for terrainType: TerrainScoringEngine.PrimaryType, weather: String) -> String? {
        switch weather {
        case "cold":
            switch terrainType {
            case .coldDeficient, .coldBalanced:
                return "Cold outside meets cold within—extra layers and warm drinks are medicine."
            case .warmExcess, .warmBalanced:
                return "Cold air cools your inner heat naturally. Use it wisely."
            default:
                return "Cold day—your body needs more fuel to stay warm."
            }
        case "hot":
            switch terrainType {
            case .warmExcess, .warmBalanced:
                return "Heat outside compounds heat within. Cool foods and slow pace."
            case .coldDeficient, .coldBalanced:
                return "Warm day warms your cold pattern—enjoy, but don't overheat."
            default:
                return "Hot day—stay hydrated and rest during peak heat."
            }
        case "humid", "rainy":
            return "Damp air burdens the Spleen. Keep meals light and warm."
        case "dry":
            return "Dry air pulls moisture. Soups and pears nourish your fluids."
        case "windy":
            return "Wind scatters qi. Protect your neck and stay grounded."
        default:
            return nil
        }
    }

    // MARK: - Step Count Truths

    private func stepTruth(for terrainType: TerrainScoringEngine.PrimaryType, steps: Int) -> String? {
        if steps < 2000 {
            switch terrainType {
            case .neutralExcess, .warmExcess:
                return "Low movement today—your excess qi has nowhere to go."
            default:
                return "Stillness has its place, but even gentle walks shift stagnant energy."
            }
        } else if steps > 10000 {
            switch terrainType {
            case .coldDeficient, .neutralDeficient, .warmDeficient:
                return "High movement—make sure to replenish what you've spent."
            default:
                return "Active day. Your qi is flowing well."
            }
        }
        return nil
    }

    // Legacy method for backwards compatibility
    private func symptomAdjustedHeadline(
        for symptoms: Set<QuickSymptom>,
        terrainType: TerrainScoringEngine.PrimaryType
    ) -> String? {
        if symptoms.isEmpty { return nil }
        let content = symptomWisdomAndTruths(for: symptoms, terrainType: terrainType)
        return content.wisdom
    }

    // MARK: - Weather-Adjusted Headlines

    /// Generate a terrain+weather specific headline when weather data is available.
    /// Returns nil when no weather condition is set, letting the base headline win.
    private func weatherAdjustedHeadline(
        for terrainType: TerrainScoringEngine.PrimaryType,
        weatherCondition: String?
    ) -> String? {
        guard let weather = weatherCondition else { return nil }

        switch weather {
        case "cold":
            switch terrainType {
            case .coldDeficient, .coldBalanced:
                return "Cold day, cold terrain. Layer up and warm from within."
            case .warmExcess, .warmBalanced:
                return "Cold outside, warm inside. Your natural heat protects you today."
            default:
                return "Cold day ahead. Warm drinks and warm layers are your foundation."
            }
        case "hot":
            switch terrainType {
            case .warmExcess, .warmBalanced:
                return "Heat outside meets heat inside. Cool and slow today."
            case .warmDeficient:
                return "Hot day — stay hydrated and rest often. Your reserves run thin in heat."
            case .coldDeficient, .coldBalanced:
                return "Warm day — your cold pattern gets a natural assist. Enjoy it gently."
            default:
                return "Hot day. Stay light, stay hydrated, stay cool."
            }
        case "humid", "rainy":
            return "Damp day. Keep your digestion light and warm."
        case "windy":
            return "Windy day. Ground yourself and protect your neck."
        case "dry":
            switch terrainType {
            case .warmDeficient:
                return "Dry air meets your dry pattern. Moistening foods and extra hydration today."
            default:
                return "Dry day. Sip warm water throughout and favor moistening foods."
            }
        default:
            return nil
        }
    }

    // MARK: - Do/Don't Generation

    /// Generate do's and don'ts for the terrain type
    func generateDoDont(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        symptoms: Set<QuickSymptom> = [],
        weatherCondition: String? = nil,
        alcoholFrequency: String? = nil,
        smokingStatus: String? = nil,
        stepCount: Int? = nil
    ) -> (dos: [DoDontItem], donts: [DoDontItem]) {
        var dos = baseDos(for: terrainType)
        var donts = baseDonts(for: terrainType)

        // Add modifier-specific items
        addModifierItems(modifier: modifier, dos: &dos, donts: &donts)

        // Add symptom-specific items
        addSymptomItems(symptoms: symptoms, dos: &dos, donts: &donts)

        // Add weather-specific items
        addWeatherItems(weatherCondition: weatherCondition, dos: &dos, donts: &donts)

        // Add lifestyle-aware items
        if alcoholFrequency == "weekly" || alcoholFrequency == "daily" {
            donts.insert(DoDontItem(text: "Cold drinks after alcohol", priority: 0, whyForYou: "Alcohol generates dampness and heat. Cold drinks on top of that shock your digestion while it's already processing."), at: 0)
            dos.insert(DoDontItem(text: "Warm congee mornings after", priority: 0, whyForYou: "Congee gently restores your spleen after alcohol taxes it. Think of it as a warm reset for your digestive center."), at: 0)
        }
        if smokingStatus == "occasional" || smokingStatus == "regular" {
            dos.insert(DoDontItem(text: "Moistening foods (pears, honey)", priority: 0, whyForYou: "Smoke dries your lung tissue and throat. Moistening foods replenish the fluids that smoke depletes."), at: 0)
        }

        // Add step-count-aware items
        if let steps = stepCount {
            if steps < 2000 {
                dos.insert(DoDontItem(text: "Gentle movement", priority: 0, whyForYou: "Low movement days let qi stagnate. Even a short walk helps keep energy circulating."), at: 0)
            } else if steps > 10000 {
                dos.insert(DoDontItem(text: "Nourishing recovery food", priority: 0, whyForYou: "High activity depletes qi and fluids. Warm, nourishing food helps your body rebuild what movement used."), at: 0)
            }
        }

        // Sort by priority and limit to top 4
        dos.sort { $0.priority < $1.priority }
        donts.sort { $0.priority < $1.priority }

        return (Array(dos.prefix(4)), Array(donts.prefix(4)))
    }

    private func baseDos(for terrainType: TerrainScoringEngine.PrimaryType) -> [DoDontItem] {
        switch terrainType {
        case .coldDeficient:
            return [
                DoDontItem(text: "Warm start", priority: 1, whyForYou: "Your digestive fire runs low in the morning. Warm food kindles it — think of warming up a car engine on a cold morning."),
                DoDontItem(text: "Cooked food", priority: 2, whyForYou: "Raw food requires more energy to digest. Cooking pre-processes it, so your body spends less effort breaking it down."),
                DoDontItem(text: "Gentle movement", priority: 3, whyForYou: "Light activity generates warmth without depleting your reserves. Intense exercise can drain what you're trying to build."),
                DoDontItem(text: "Rest when tired", priority: 4, whyForYou: "Your system runs on a smaller battery. Pushing through fatigue costs you more than it costs other types.")
            ]
        case .coldBalanced:
            return [
                DoDontItem(text: "Warm drinks", priority: 1, whyForYou: "Your core temperature runs cool. Warm beverages maintain your internal warmth like adding fuel to a steady fire."),
                DoDontItem(text: "Moderate activity", priority: 2, whyForYou: "Movement generates warmth from within. Consistent moderate activity keeps your flame steady."),
                DoDontItem(text: "Warm layers", priority: 3, whyForYou: "Cold accumulates quietly in your type. Staying warm prevents sluggishness before it starts."),
                DoDontItem(text: "Grounding foods", priority: 4, whyForYou: "Root vegetables and grains anchor your energy and provide sustained warmth.")
            ]
        case .neutralDeficient:
            return [
                DoDontItem(text: "Consistent meals", priority: 1, whyForYou: "Your body thrives on predictable fuel. Regular meals prevent the energy dips you're prone to."),
                DoDontItem(text: "Early sleep", priority: 2, whyForYou: "Sleep is when you rebuild. You recover faster than other types — but only if you actually rest."),
                DoDontItem(text: "Gentle exercise", priority: 3, whyForYou: "Gentle routines give big returns for your type. Intensity costs more than it gains."),
                DoDontItem(text: "Nourishing broths", priority: 4, whyForYou: "Easy-to-digest warm liquids deliver nutrients without taxing your digestion.")
            ]
        case .neutralBalanced:
            return [
                DoDontItem(text: "Keep your rhythm", priority: 1, whyForYou: "Consistency is your superpower. Your body adapts fast — routine keeps you calibrated."),
                DoDontItem(text: "Balanced portions", priority: 2, whyForYou: "You can handle variety, but your body loves moderation. Neither too much nor too little."),
                DoDontItem(text: "Regular exercise", priority: 3, whyForYou: "Movement maintains your natural balance. It's preventive maintenance for your type."),
                DoDontItem(text: "Variety in diet", priority: 4, whyForYou: "Seasonal variety keeps your adaptable system well-rounded.")
            ]
        case .neutralExcess:
            return [
                DoDontItem(text: "Move your body", priority: 1, whyForYou: "Excess energy stagnates when still. Movement is your release valve — your body needs it daily."),
                DoDontItem(text: "Express creatively", priority: 2, whyForYou: "Suppressed energy turns into tension. Creative outlets channel your drive productively."),
                DoDontItem(text: "Deep breathing", priority: 3, whyForYou: "Breath is the fastest way to move stuck energy. Even 3 deep breaths shifts your state."),
                DoDontItem(text: "Light meals", priority: 4, whyForYou: "Heavy food adds to the stuckness. Light meals keep energy flowing freely.")
            ]
        case .warmBalanced:
            return [
                DoDontItem(text: "Stay hydrated", priority: 1, whyForYou: "Your warmth burns through fluids faster. Room-temperature water throughout the day keeps your flame clean."),
                DoDontItem(text: "Cool foods", priority: 2, whyForYou: "Cooling foods balance your natural heat without shocking your system the way ice does."),
                DoDontItem(text: "Evening wind-down", priority: 3, whyForYou: "Your body holds heat. A deliberate cool-down prevents restless sleep."),
                DoDontItem(text: "Shade and rest", priority: 4, whyForYou: "When external heat meets internal warmth, you overheat faster. Shade is medicine for you.")
            ]
        case .warmExcess:
            return [
                DoDontItem(text: "Cooling foods", priority: 1, whyForYou: "Your system runs hot with excess energy. Cooling foods act like a thermostat, bringing you back to center."),
                DoDontItem(text: "Slow down", priority: 2, whyForYou: "Your intensity is an asset, but it burns fuel fast. Pacing prevents the crash."),
                DoDontItem(text: "Evening quiet", priority: 3, whyForYou: "Your nervous system needs a deliberate signal to downshift. Quiet evenings protect your sleep."),
                DoDontItem(text: "Release tension", priority: 4, whyForYou: "Excess energy held in the body becomes heat and tension. Release prevents buildup.")
            ]
        case .warmDeficient:
            return [
                DoDontItem(text: "Moistening foods", priority: 1, whyForYou: "Your warmth dries you out from inside. Moistening foods like pear and honey replenish what heat depletes."),
                DoDontItem(text: "Early rest", priority: 2, whyForYou: "You burn bright but thin. Evening rest prevents the wired-tired state your type is prone to."),
                DoDontItem(text: "Gentle hydration", priority: 3, whyForYou: "Sipping throughout the day keeps you nourished. Gulping cold water shocks your system."),
                DoDontItem(text: "Avoid overwork", priority: 4, whyForYou: "You have less reserve than your energy suggests. Protect what you have.")
            ]
        }
    }

    private func baseDonts(for terrainType: TerrainScoringEngine.PrimaryType) -> [DoDontItem] {
        switch terrainType {
        case .coldDeficient:
            return [
                DoDontItem(text: "Ice drinks", priority: 1, whyForYou: "Cold drinks extinguish digestive fire. For your type, that's like pouring water on an already-small campfire."),
                DoDontItem(text: "Raw salads", priority: 2, whyForYou: "Raw food requires extra energy to process. Your digestion is already working hard — cooked food gives it a break."),
                DoDontItem(text: "Skipping meals", priority: 3, whyForYou: "Your energy tank is smaller. Skipping meals empties it faster than other types."),
                DoDontItem(text: "Overexertion", priority: 4, whyForYou: "Intense exercise depletes warmth and qi. It costs you double what it costs warmer types.")
            ]
        case .coldBalanced:
            return [
                DoDontItem(text: "Cold foods", priority: 1, whyForYou: "Cold accumulates in your type. Each cold input makes the next one hit harder."),
                DoDontItem(text: "Cold exposure", priority: 2, whyForYou: "External cold weakens your core warmth. Layering is more effective than toughing it out."),
                DoDontItem(text: "Heavy dairy", priority: 3, whyForYou: "Dairy can create dampness, which compounds cold patterns."),
                DoDontItem(text: "Late nights", priority: 4, whyForYou: "Sleep rebuilds warmth. Late nights drain what you spent the day building.")
            ]
        case .neutralDeficient:
            return [
                DoDontItem(text: "Overworking", priority: 1, whyForYou: "You feel it in sleep, digestion, and focus when you overcommit. Protect your limits."),
                DoDontItem(text: "Skipping rest", priority: 2, whyForYou: "Rest is when your body rebuilds. Skipping it compounds tomorrow's deficit."),
                DoDontItem(text: "Heavy exercise", priority: 3, whyForYou: "Intensity depletes faster than it builds for your type. Gentle and consistent wins."),
                DoDontItem(text: "Irregular meals", priority: 4, whyForYou: "Your digestion needs rhythm. Irregular eating creates energy rollercoasters.")
            ]
        case .neutralBalanced:
            return [
                DoDontItem(text: "Extremes", priority: 1, whyForYou: "Your balance is your strength. Extremes in any direction throw you off center."),
                DoDontItem(text: "Overthinking", priority: 2, whyForYou: "Analysis paralysis disrupts your natural rhythm. Trust your instincts."),
                DoDontItem(text: "Skipping routine", priority: 3, whyForYou: "When your schedule breaks, your body follows. Routine is your anchor."),
                DoDontItem(text: "Excess anything", priority: 4, whyForYou: "Too much of even good things disrupts balance. Moderation is your medicine.")
            ]
        case .neutralExcess:
            return [
                DoDontItem(text: "Sitting too long", priority: 1, whyForYou: "Stuck body equals stuck energy. Movement is essential for your type, not optional."),
                DoDontItem(text: "Suppressing", priority: 2, whyForYou: "Held-in energy turns into tension. Better out than in — through movement or expression."),
                DoDontItem(text: "Heavy foods", priority: 3, whyForYou: "Heavy meals add to stagnation. Light food keeps your energy flowing."),
                DoDontItem(text: "Rushing", priority: 4, whyForYou: "Rushing adds tension to a system already full. Pacing releases pressure.")
            ]
        case .warmBalanced:
            return [
                DoDontItem(text: "Spicy foods", priority: 1, whyForYou: "You're already warm inside. Spice adds heat to heat — your skin and sleep show it first."),
                DoDontItem(text: "Overheating", priority: 2, whyForYou: "External heat compounds your internal warmth. Seek shade and cool environments."),
                DoDontItem(text: "Late nights", priority: 3, whyForYou: "Night is when your body cools down. Late activity keeps the heat running."),
                DoDontItem(text: "Alcohol", priority: 4, whyForYou: "Alcohol generates heat and disrupts sleep — two things your type is already managing.")
            ]
        case .warmExcess:
            return [
                DoDontItem(text: "Stimulants", priority: 1, whyForYou: "Your system is already running hot. Caffeine and stimulants add fuel to a fire that's already big."),
                DoDontItem(text: "Spicy food", priority: 2, whyForYou: "Heat on heat. Your body needs cooling inputs, not more intensity."),
                DoDontItem(text: "Confrontation", priority: 3, whyForYou: "Emotional heat compounds physical heat. Choose your battles wisely today."),
                DoDontItem(text: "Pushing through", priority: 4, whyForYou: "Your intensity masks fatigue. Pushing through costs you more than you realize.")
            ]
        case .warmDeficient:
            return [
                DoDontItem(text: "Drying foods", priority: 1, whyForYou: "Your warmth already dries you out. Dry, crunchy foods accelerate fluid loss."),
                DoDontItem(text: "Excess coffee", priority: 2, whyForYou: "Coffee heats and dries — both things your type needs less of."),
                DoDontItem(text: "Late nights", priority: 3, whyForYou: "Night is your repair window. Your reserves are thinner — use sleep wisely."),
                DoDontItem(text: "Overexertion", priority: 4, whyForYou: "You feel warm but may be running on fumes. Gentle is your speed.")
            ]
        }
    }

    private func addModifierItems(
        modifier: TerrainScoringEngine.Modifier,
        dos: inout [DoDontItem],
        donts: inout [DoDontItem]
    ) {
        switch modifier {
        case .damp:
            dos.insert(DoDontItem(text: "Light movement", priority: 0, whyForYou: "Dampness is heavy and stagnant. Movement helps your body process and drain what's stuck."), at: 0)
            donts.insert(DoDontItem(text: "Heavy dairy", priority: 0, whyForYou: "Dairy creates more dampness in your system — like adding water to soggy ground."), at: 0)
        case .dry:
            dos.insert(DoDontItem(text: "Moistening foods", priority: 0, whyForYou: "Your body runs dry. Pear, honey, and soups replenish the fluids your system needs."), at: 0)
            donts.insert(DoDontItem(text: "Drying alcohol", priority: 0, whyForYou: "Alcohol heats and dries. For your modifier, it accelerates the depletion you're managing."), at: 0)
        case .stagnation:
            dos.insert(DoDontItem(text: "Move and stretch", priority: 0, whyForYou: "Your energy gets stuck easily. Physical movement is the most direct way to get it flowing again."), at: 0)
            donts.insert(DoDontItem(text: "Sitting still", priority: 0, whyForYou: "Stillness compounds stagnation. Even micro-breaks help keep your qi circulating."), at: 0)
        case .shen:
            dos.insert(DoDontItem(text: "Calming routine", priority: 0, whyForYou: "Your mind races more than most. A structured wind-down gives your spirit a place to settle."), at: 0)
            donts.insert(DoDontItem(text: "Screen time late", priority: 0, whyForYou: "Screens stimulate an already-active mind. Your shen needs quiet signals to settle for sleep."), at: 0)
        case .none:
            break
        }
    }

    private func addSymptomItems(
        symptoms: Set<QuickSymptom>,
        dos: inout [DoDontItem],
        donts: inout [DoDontItem]
    ) {
        if symptoms.contains(.cold) {
            dos.insert(DoDontItem(text: "Warm ginger tea", priority: 0, whyForYou: "Ginger disperses cold from within. A cup now helps warm your center for hours."), at: 0)
        }
        if symptoms.contains(.bloating) {
            dos.insert(DoDontItem(text: "Post-meal walk", priority: 0, whyForYou: "Gentle walking stimulates digestion and helps move trapped gas and food."), at: 0)
            donts.insert(DoDontItem(text: "Large meals", priority: 0, whyForYou: "A bloated system needs smaller inputs. Smaller meals let your digestion catch up."), at: 0)
        }
        if symptoms.contains(.stressed) {
            dos.insert(DoDontItem(text: "Deep breaths", priority: 0, whyForYou: "Breath activates your parasympathetic nervous system — the body's built-in calm switch."), at: 0)
            donts.insert(DoDontItem(text: "Caffeine", priority: 0, whyForYou: "Caffeine amplifies the stress response. Your system needs calming, not more stimulation."), at: 0)
        }
        if symptoms.contains(.poorSleep) {
            dos.insert(DoDontItem(text: "Early wind-down", priority: 0, whyForYou: "Your body needs lead time to transition to rest. Starting earlier helps."), at: 0)
            donts.insert(DoDontItem(text: "Late screens", priority: 0, whyForYou: "Blue light suppresses melatonin. Your sleep cycle needs a clear signal."), at: 0)
        }
        if symptoms.contains(.cramps) {
            dos.insert(DoDontItem(text: "Warmth on belly", priority: 0, whyForYou: "Heat relaxes smooth muscle and improves blood flow to cramping areas."), at: 0)
            donts.insert(DoDontItem(text: "Cold drinks", priority: 0, whyForYou: "Cold constricts blood vessels and can worsen cramping. Warm drinks help."), at: 0)
        }
        if symptoms.contains(.headache) {
            dos.insert(DoDontItem(text: "Gentle neck stretches", priority: 0, whyForYou: "Tension in the neck and shoulders often feeds headaches. Gentle stretches release the grip."), at: 0)
            donts.insert(DoDontItem(text: "Excess screen time", priority: 0, whyForYou: "Screen glare and posture strain contribute to headache patterns. Take breaks."), at: 0)
        }
        if symptoms.contains(.stiff) {
            dos.insert(DoDontItem(text: "Movement breaks", priority: 0, whyForYou: "Stiffness is your body asking to move. Short breaks throughout the day prevent buildup."), at: 0)
            donts.insert(DoDontItem(text: "Sitting still", priority: 0, whyForYou: "Prolonged stillness creates more stiffness. Even 2 minutes of stretching helps."), at: 0)
        }
    }

    private func addWeatherItems(
        weatherCondition: String?,
        dos: inout [DoDontItem],
        donts: inout [DoDontItem]
    ) {
        guard let weather = weatherCondition else { return }

        switch weather {
        case "cold":
            dos.insert(DoDontItem(text: "Warm ginger tea", priority: 0, whyForYou: "Cold weather calls for internal warming. Ginger disperses cold and supports digestion."), at: 0)
            donts.insert(DoDontItem(text: "Cold drinks", priority: 0, whyForYou: "Adding cold to a cold day taxes your system. Warm and room-temperature are best."), at: 0)
        case "hot":
            dos.insert(DoDontItem(text: "Room-temp water often", priority: 0, whyForYou: "Heat increases fluid loss. Frequent sipping prevents dehydration without shocking your digestion."), at: 0)
            donts.insert(DoDontItem(text: "Heavy meals at midday", priority: 0, whyForYou: "Your body diverts energy to cooling in hot weather. Light meals keep you from overheating."), at: 0)
        case "humid", "rainy":
            dos.insert(DoDontItem(text: "Light warm meals", priority: 0, whyForYou: "External dampness adds to internal dampness. Light, warm food helps your spleen process what's accumulating."), at: 0)
            donts.insert(DoDontItem(text: "Dairy and sweets", priority: 0, whyForYou: "Dairy and sugar generate dampness. On a humid day, they compound what the weather is already doing."), at: 0)
        case "dry":
            dos.insert(DoDontItem(text: "Moistening soups", priority: 0, whyForYou: "Dry air pulls moisture from your body. Soups and stews replenish what the environment takes."), at: 0)
            donts.insert(DoDontItem(text: "Excess coffee", priority: 0, whyForYou: "Coffee is warming and drying. On a dry day, it accelerates fluid depletion."), at: 0)
        case "windy":
            dos.insert(DoDontItem(text: "Protect your neck", priority: 0, whyForYou: "In TCM, wind enters through the back of the neck. A scarf or collar shields this vulnerable point."), at: 0)
        default:
            break
        }
    }

    // MARK: - Areas of Life

    /// Generate area of life content for terrain type, optionally personalized by TCM diagnostic signals
    func generateAreas(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        symptoms: Set<QuickSymptom> = [],
        sleepQuality: SleepQuality? = nil,
        dominantEmotion: DominantEmotion? = nil,
        thermalFeeling: ThermalFeeling? = nil,
        digestiveState: DigestiveState? = nil
    ) -> [AreaOfLifeContent] {
        var areas: [AreaOfLifeContent] = []

        // Energy & Focus
        areas.append(generateEnergyArea(for: terrainType, modifier: modifier, symptoms: symptoms, thermalFeeling: thermalFeeling))

        // Digestion
        areas.append(generateDigestionArea(for: terrainType, modifier: modifier, symptoms: symptoms, digestiveState: digestiveState))

        // Sleep & Wind-down
        areas.append(generateSleepArea(for: terrainType, modifier: modifier, symptoms: symptoms, sleepQuality: sleepQuality))

        // Mood & Stress
        areas.append(generateMoodArea(for: terrainType, modifier: modifier, symptoms: symptoms, dominantEmotion: dominantEmotion))

        return areas
    }

    private func generateEnergyArea(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>,
        thermalFeeling: ThermalFeeling? = nil
    ) -> AreaOfLifeContent {
        var tips: [String]

        switch terrainType {
        case .coldDeficient:
            tips = [
                "Start with warm water before anything else",
                "Eat breakfast within an hour of waking",
                "Short walks, not intense cardio"
            ]
        case .coldBalanced:
            tips = [
                "Warm drinks support steady energy",
                "Layer up to preserve your warmth",
                "Moderate pace throughout the day"
            ]
        case .neutralDeficient:
            tips = [
                "Regular small meals beat big ones",
                "Nap if you need to—it's productive",
                "Build up gradually, don't sprint"
            ]
        case .neutralBalanced:
            tips = [
                "Maintain your natural rhythm",
                "Balanced effort, balanced rest",
                "Trust your baseline energy"
            ]
        case .neutralExcess:
            tips = [
                "Channel excess into movement",
                "Creative outlets help release",
                "Don't let energy stagnate"
            ]
        case .warmBalanced:
            tips = [
                "Hydration is your fuel",
                "Morning activity beats evening",
                "Rest in the afternoon heat"
            ]
        case .warmExcess:
            tips = [
                "Slow and steady prevents burnout",
                "Cool environments help focus",
                "Release before building more"
            ]
        case .warmDeficient:
            tips = [
                "Rest is how you recharge",
                "Gentle hydration throughout",
                "Protect your reserves"
            ]
        }

        if symptoms.contains(.tired) {
            tips.insert("Honor your fatigue—rest is repair", at: 0)
        }

        // TCM thermal feeling personalization
        if let thermal = thermalFeeling {
            switch thermal {
            case .cold, .cool:
                // User feels cold — prioritize warming strategies
                switch terrainType {
                case .warmExcess, .warmBalanced:
                    // Warm terrain but feeling cold = temporary yang depletion
                    tips.insert("Feeling cold despite warm terrain? Rest and warm drinks today.", at: 0)
                default:
                    tips.insert("Warm drinks and layered clothing protect your yang.", at: 0)
                }
            case .hot, .warm:
                // User feels hot — prioritize cooling strategies
                switch terrainType {
                case .coldDeficient, .coldBalanced:
                    // Cold terrain but feeling hot = heat from deficiency
                    tips.insert("Feeling hot despite cold terrain? Rest and hydrate—this is deficiency heat.", at: 0)
                default:
                    tips.insert("Cool drinks and lighter activity help release excess heat.", at: 0)
                }
            case .comfortable:
                break // No adjustment needed
            }
        }

        let tcmNote: String
        switch terrainType {
        case .coldDeficient, .neutralDeficient, .warmDeficient:
            tcmNote = "Qi and Yang need building. Gentle support over pushing."
        case .neutralExcess, .warmExcess:
            tcmNote = "Excess energy needs movement and release."
        default:
            tcmNote = "Steady Qi sustains focus. Protect your rhythm."
        }

        return AreaOfLifeContent(type: .energyFocus, tips: tips, tcmNote: tcmNote)
    }

    private func generateDigestionArea(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>,
        digestiveState: DigestiveState? = nil
    ) -> AreaOfLifeContent {
        var tips: [String]

        switch terrainType {
        case .coldDeficient, .coldBalanced:
            tips = [
                "Cooked and warm foods digest best",
                "Avoid cold drinks with meals",
                "Ginger aids your digestion"
            ]
        case .neutralDeficient:
            tips = [
                "Easy-to-digest foods today",
                "Chew thoroughly, eat slowly",
                "Regular meal times matter"
            ]
        case .neutralBalanced:
            tips = [
                "Variety and balance in meals",
                "Don't eat too quickly",
                "Portion control, not restriction"
            ]
        case .neutralExcess:
            tips = [
                "Lighter portions help flow",
                "Walk after eating",
                "Avoid greasy, heavy foods"
            ]
        case .warmBalanced, .warmExcess:
            tips = [
                "Cool foods soothe your system",
                "Bitter greens support digestion",
                "Avoid spicy and fried foods"
            ]
        case .warmDeficient:
            tips = [
                "Moistening soups and stews",
                "Gentle, not raw vegetables",
                "Hydrate between meals"
            ]
        }

        if symptoms.contains(.bloating) {
            tips.insert("Small portions, more frequently", at: 0)
            tips.insert("Fennel or mint tea after meals", at: 1)
        }

        if modifier == .damp {
            tips.insert("Avoid dairy and excess sugar", at: 0)
        }

        // TCM digestive state personalization
        if let digestion = digestiveState {
            // Appetite-based tips
            switch digestion.appetiteLevel {
            case .none:
                tips.insert("No appetite often signals Spleen qi stagnation. Warm, aromatic foods may help.", at: 0)
            case .low:
                tips.insert("Low appetite? Focus on easily digestible, warm foods.", at: 0)
            case .strong:
                tips.insert("Strong appetite can indicate stomach heat. Favor cooling, moistening foods.", at: 0)
            case .normal:
                break // No adjustment needed
            }

            // Stool quality-based tips
            switch digestion.stoolQuality {
            case .loose:
                tips.insert("Loose stools suggest Spleen qi deficiency. Avoid cold and raw foods.", at: 0)
            case .constipated:
                tips.insert("Constipation often indicates heat or yin deficiency. More fluids and fiber.", at: 0)
            case .sticky:
                tips.insert("Sticky stools suggest dampness. Reduce greasy foods and dairy.", at: 0)
            case .mixed:
                tips.insert("Variable digestion suggests Liver-Spleen disharmony. Regular meals help.", at: 0)
            case .normal:
                break // No adjustment needed
            }
        }

        let tcmNote = "The Spleen transforms food into energy. Support it with appropriate temperature and texture."

        return AreaOfLifeContent(type: .digestion, tips: tips, tcmNote: tcmNote)
    }

    private func generateSleepArea(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>,
        sleepQuality: SleepQuality? = nil
    ) -> AreaOfLifeContent {
        var tips: [String]

        switch terrainType {
        case .coldDeficient:
            tips = [
                "Warm feet before bed helps sleep",
                "Earlier bedtime replenishes",
                "Keep bedroom cozy but ventilated"
            ]
        case .coldBalanced:
            tips = [
                "Warm bath before sleep",
                "Consistent bedtime matters",
                "Warm blankets, cool room air"
            ]
        case .neutralDeficient:
            tips = [
                "Sleep is when you rebuild",
                "Aim for 8+ hours tonight",
                "Wind down early"
            ]
        case .neutralBalanced:
            tips = [
                "Regular sleep schedule supports you",
                "Don't sacrifice sleep for productivity",
                "Quality matters as much as quantity"
            ]
        case .neutralExcess:
            tips = [
                "Release tension before bed",
                "Journaling can quiet the mind",
                "Physical release helps sleep"
            ]
        case .warmBalanced, .warmExcess:
            tips = [
                "Cool down before bed",
                "No screens 1 hour before sleep",
                "Calming tea in the evening"
            ]
        case .warmDeficient:
            tips = [
                "Early to bed, early to rise",
                "Nourishing evening routine",
                "Avoid stimulation after dinner"
            ]
        }

        if symptoms.contains(.poorSleep) {
            tips.insert("No caffeine after noon today", at: 0)
            tips.insert("Try a calming breathwork practice", at: 1)
        }

        if modifier == .shen {
            tips.insert("Your mind needs extra settling tonight", at: 0)
        }

        // TCM sleep quality personalization
        if let sleep = sleepQuality {
            switch sleep {
            case .hardToFallAsleep:
                tips.insert("Difficulty falling asleep often signals Shen disturbance. Calming herbs help.", at: 0)
            case .wokeMiddleOfNight:
                tips.insert("Waking 1-3 AM suggests Liver qi stagnation. Release tension before bed.", at: 0)
            case .wokeEarly:
                tips.insert("Early waking can indicate yin deficiency. Nourishing foods and earlier bedtime.", at: 0)
            case .unrefreshing:
                tips.insert("Unrefreshing sleep often signals damp accumulation. Lighter dinners help.", at: 0)
            case .fellAsleepEasily:
                break // Good sleep, no adjustment needed
            }
        }

        let tcmNote = "Sleep anchors the Shen (spirit). A settled mind finds rest."

        return AreaOfLifeContent(type: .sleepWindDown, tips: tips, tcmNote: tcmNote)
    }

    private func generateMoodArea(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>,
        dominantEmotion: DominantEmotion? = nil
    ) -> AreaOfLifeContent {
        var tips: [String]

        switch terrainType {
        case .coldDeficient:
            tips = [
                "Low mood often follows low energy",
                "Warmth and nourishment lift spirits",
                "Be gentle with yourself today"
            ]
        case .coldBalanced:
            tips = [
                "Staying warm supports mood",
                "Connection with others helps",
                "Sunlight when possible"
            ]
        case .neutralDeficient:
            tips = [
                "Rest is not laziness",
                "Small accomplishments count",
                "Nourish to lift mood"
            ]
        case .neutralBalanced:
            tips = [
                "Maintain your routines for stability",
                "Balance prevents extremes",
                "Trust your steady nature"
            ]
        case .neutralExcess:
            tips = [
                "Express rather than suppress",
                "Movement helps mood flow",
                "Creative outlets release pressure"
            ]
        case .warmBalanced:
            tips = [
                "Cooling helps irritability",
                "Don't let frustration build",
                "Evening quiet time essential"
            ]
        case .warmExcess:
            tips = [
                "Pause before reacting",
                "Cool your system, cool your mood",
                "Release through movement, not confrontation"
            ]
        case .warmDeficient:
            tips = [
                "Anxiety may signal depletion",
                "Rest is your reset button",
                "Nourish the nervous system"
            ]
        }

        if symptoms.contains(.stressed) {
            tips.insert("5 deep breaths, right now", at: 0)
            tips.insert("Name what's stressing you, then set it aside", at: 1)
        }

        if modifier == .stagnation {
            tips.insert("Movement unsticks stuck emotions", at: 0)
        }

        // TCM dominant emotion personalization
        if let emotion = dominantEmotion {
            switch emotion {
            case .irritable:
                tips.insert("Irritability signals Liver qi rising. Sour foods and stretching help.", at: 0)
            case .worried:
                tips.insert("Worry taxes the Spleen. Ground yourself with warm, nourishing food.", at: 0)
            case .anxious:
                tips.insert("Anxiety often roots in Kidney deficiency. Rest and warmth restore.", at: 0)
            case .sad:
                tips.insert("Grief affects the Lung. Deep breathing and white foods support.", at: 0)
            case .restless:
                tips.insert("Restlessness signals unsettled Shen. Calming routines before bed.", at: 0)
            case .overwhelmed:
                tips.insert("Overwhelm depletes Spleen and Kidney. Simplify and restore today.", at: 0)
            case .calm:
                break // Balanced emotional state, no adjustment needed
            }
        }

        let tcmNote: String
        if modifier == .shen || symptoms.contains(.stressed) || symptoms.contains(.poorSleep) || dominantEmotion == .restless || dominantEmotion == .anxious {
            tcmNote = "The Shen (spirit) needs anchoring. Calm the mind to calm the body."
        } else {
            tcmNote = "Emotions flow with Qi. When energy moves freely, mood follows."
        }

        return AreaOfLifeContent(type: .moodStress, tips: tips, tcmNote: tcmNote)
    }

    // MARK: - Theme Today

    /// Generate the concluding theme for the day
    func generateTheme(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        symptoms: Set<QuickSymptom> = []
    ) -> ThemeTodayContent {
        let body: String

        // Symptom-adjusted themes take priority
        if symptoms.contains(.stressed) || symptoms.contains(.poorSleep) {
            body = "Today is about restoration, not achievement. Your body is asking for gentleness. Trust that rest is productive, and pace yourself with compassion."
        } else if symptoms.contains(.cramps) {
            body = "Cramps signal tension and cold in the lower body. Warmth, gentle movement, and avoiding cold foods or drinks will help your body relax and release."
        } else if symptoms.contains(.headache) {
            body = "Headaches often signal tension rising upward or qi not flowing smoothly. Reduce stimulation, stretch gently, and give your system space to recalibrate."
        } else if symptoms.contains(.stiff) {
            body = "Stiffness is stuck energy asking to move. Your body doesn't need a big workout — just consistent small movements throughout the day to keep things flowing."
        } else if symptoms.contains(.cold) || symptoms.contains(.tired) {
            body = "Warmth is your foundation today. Start gentle, build slowly, and let each small act of self-care compound. Your energy will follow your intention."
        } else {
            body = baseTheme(for: terrainType, modifier: modifier)
        }

        return ThemeTodayContent(body: body)
    }

    private func baseTheme(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> String {
        switch terrainType {
        case .coldDeficient:
            return "Warmth is your foundation. Every warm drink, every cooked meal, every gentle movement is building something. Trust the slow accumulation."

        case .coldBalanced:
            return "Your cool nature is a strength when balanced. Keep warmth as your baseline, and everything else flows from there."

        case .neutralDeficient:
            return "Today is about steady building. You don't need to push—just show up consistently and let small inputs create big returns."

        case .neutralBalanced:
            return "Your balance is your superpower. Protect your rhythm, trust your instincts, and let moderation guide your choices."

        case .neutralExcess:
            return "Energy wants to move. Today, find ways to release, express, and flow. What you let go of makes room for what serves you."

        case .warmBalanced:
            return "Your warmth is an asset when channeled well. Stay light, stay cool, and save your fire for what matters most."

        case .warmExcess:
            return "Downshifting isn't weakness—it's wisdom. Your system runs hot; give it the cooling and rest it craves, and watch your clarity return."

        case .warmDeficient:
            return "Your brightness needs nourishment to sustain. Rest deeply, hydrate gently, and let your natural glow replenish from within."
        }
    }

    // MARK: - Seasonal Awareness (Phase 4B)

    /// TCM uses 5 seasons: Spring, Summer, Late Summer, Autumn, Winter
    enum TCMSeason: String {
        case spring, summer, lateSummer, autumn, winter

        var displayName: String {
            switch self {
            case .spring: return "Spring"
            case .summer: return "Summer"
            case .lateSummer: return "Late Summer"
            case .autumn: return "Autumn"
            case .winter: return "Winter"
            }
        }

        var icon: String {
            switch self {
            case .spring: return "leaf.fill"
            case .summer: return "sun.max.fill"
            case .lateSummer: return "cloud.sun.fill"
            case .autumn: return "wind"
            case .winter: return "snowflake"
            }
        }

        /// Maps rawValue (camelCase) to the snake_case key used in content pack season arrays.
        var contentPackKey: String {
            switch self {
            case .lateSummer: return "late_summer"
            default: return rawValue
            }
        }

        static func current(for date: Date = Date()) -> TCMSeason {
            let month = Calendar.current.component(.month, from: date)
            switch month {
            case 3...5: return .spring
            case 6, 7: return .summer
            case 8, 9: return .lateSummer
            case 10, 11: return .autumn
            default: return .winter // Dec, Jan, Feb
            }
        }
    }

    /// Generate a seasonal awareness note for the Home tab
    func generateSeasonalNote(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        date: Date = Date(),
        weatherCondition: String? = nil
    ) -> SeasonalNoteContent {
        let season = TCMSeason.current(for: date)
        let note: String
        var tips: [String]

        switch (season, terrainType) {
        // Winter — cold types need extra care
        case (.winter, .coldDeficient):
            note = "Winter amplifies your cold pattern. Your body works harder to stay warm. This is your most important season for warm starts."
            tips = ["Favor soups, stews, and root vegetables", "Warm water first thing, always", "Layer up — cold accumulates quietly", "Avoid raw food until spring"]
        case (.winter, .coldBalanced):
            note = "Winter is your highest-risk season. Double down on warming practices to prevent cold from settling in."
            tips = ["Warming spices in every meal", "Keep core temperature stable", "Ginger tea becomes essential"]
        case (.winter, _) where terrainType == .warmExcess || terrainType == .warmBalanced:
            note = "Winter gives your warm system a natural break. Use this season to restore balance."
            tips = ["Your body can handle more warming foods now", "Still hydrate — indoor heating dries you out", "Enjoy seasonal soups and broths"]

        // Summer — warm types need cooling
        case (.summer, .warmExcess):
            note = "Summer intensifies your heat pattern. Be proactive about cooling before symptoms show."
            tips = ["Cooling foods: mung bean, cucumber, watermelon", "Stay hydrated — room temp, not icy", "Evening wind-down is critical now", "Avoid midday heat when possible"]
        case (.summer, .warmBalanced):
            note = "Summer heat meets your internal warmth. Stay ahead of it with cooling practices."
            tips = ["Chrysanthemum tea becomes your best friend", "Light meals, cool ingredients", "Rest during peak heat hours"]
        case (.summer, _) where terrainType == .coldDeficient || terrainType == .coldBalanced:
            note = "Summer gives your cold pattern a natural assist. Enjoy more variety, but don't overdo cold foods."
            tips = ["Room-temp fruits are fine now", "Still avoid ice — it shocks your system", "This is your best season for building warmth reserves"]

        // Spring — liver season, movement
        case (.spring, _) where modifier == .stagnation:
            note = "Spring is the liver's season — and your stagnation pattern responds strongly. Movement matters more now."
            tips = ["Increase stretching and walks", "Try sour flavors to support the liver", "Express emotions rather than holding them"]
        case (.spring, _):
            note = "Spring is the season of upward energy. Support your liver with movement and fresh greens."
            tips = ["Add more leafy greens to meals", "Increase outdoor activity", "This is a natural renewal period"]

        // Late Summer — spleen season, dampness
        case (.lateSummer, _) where modifier == .damp:
            note = "Late Summer is the dampness danger zone for your pattern. Your spleen needs extra support now."
            tips = ["Avoid dairy, sugar, and greasy foods", "Light movement to drain dampness", "Favor warming, drying foods like ginger"]
        case (.lateSummer, _):
            note = "Late Summer supports the spleen and digestion. Focus on easy-to-digest, warm meals."
            tips = ["Cooked foods digest better in this transition", "Root vegetables and grains are ideal", "Stay regular with meal times"]

        // Autumn — lung season, dryness
        case (.autumn, _) where modifier == .dry:
            note = "Autumn dryness hits you hardest. Your body is already dry — moistening practices are essential now."
            tips = ["Steamed pear with honey is ideal", "Increase moistening foods: sesame, lily bulb", "Sip warm water throughout the day"]
        case (.autumn, _):
            note = "Autumn is the lung's season. The air dries out — moistening foods protect your system."
            tips = ["Pear, honey, and goji berries nourish dryness", "Warm soups are transitional medicine", "Prepare for winter with nourishing routines"]

        // Default fallback
        default:
            note = "\(season.displayName) is a good time to tune into your body's seasonal rhythms."
            tips = ["Eat with the season", "Adjust your routines to match the weather", "Listen to what your body asks for"]
        }

        // Append a weather-specific tip when weather data is available
        if let weatherTip = weatherSeasonalTip(for: weatherCondition) {
            tips.append(weatherTip)
        }

        return SeasonalNoteContent(
            season: season.displayName,
            icon: season.icon,
            note: note,
            tips: tips
        )
    }

    /// Returns an extra seasonal tip based on today's weather condition.
    private func weatherSeasonalTip(for weatherCondition: String?) -> String? {
        guard let weather = weatherCondition else { return nil }
        switch weather {
        case "cold":  return "Today's cold weather calls for extra warming practices"
        case "hot":   return "Today's heat means extra hydration and lighter meals"
        case "humid", "rainy": return "Damp weather today — favor warm, light, easily-digested food"
        case "dry":   return "Dry air today — sip warm water and add moistening ingredients"
        case "windy": return "Wind today — protect your neck and favor grounding practices"
        default:      return nil
        }
    }

    // MARK: - Lesson Ranking (Phase 3A)

    /// Rank lessons by relevance to the user's terrain type and modifier.
    /// Returns the input array sorted by relevance score (highest first).
    func rankLessons(
        _ lessons: [Lesson],
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        goals: [String] = []
    ) -> [Lesson] {
        let scored = lessons.map { lesson -> (lesson: Lesson, score: Int) in
            var score = 0

            // +5 if lesson's terrain_relevance explicitly includes this terrain
            if lesson.terrainRelevance.contains(terrainType.terrainProfileId) {
                score += 5
            }

            // +3 if topic matches primary axis
            let topic = lesson.topic
            switch terrainType {
            case .coldDeficient, .coldBalanced:
                if topic == "cold_heat" { score += 3 }
            case .warmDeficient, .warmBalanced, .warmExcess:
                if topic == "cold_heat" { score += 3 }
            case .neutralDeficient, .neutralBalanced, .neutralExcess:
                if topic == "methods" || topic == "qi_flow" { score += 3 }
            }

            // +2 if topic matches modifier
            switch modifier {
            case .damp:
                if topic == "damp_dry" { score += 2 }
            case .dry:
                if topic == "damp_dry" { score += 2 }
            case .shen:
                if topic == "shen" { score += 2 }
            case .stagnation:
                if topic == "qi_flow" { score += 2 }
            case .none:
                break
            }

            // +1 if topic aligns with user goals
            let topicGoalMap: [String: [String]] = [
                "cold_heat": ["energy", "digestion"],
                "damp_dry": ["digestion", "skin"],
                "shen": ["sleep", "stress"],
                "qi_flow": ["energy", "stress"],
                "seasonality": ["energy", "digestion"],
                "methods": ["digestion", "energy"],
                "safety": ["sleep", "stress"]
            ]
            if let topicGoals = topicGoalMap[topic] {
                for goal in goals {
                    if topicGoals.contains(goal) {
                        score += 1
                        break
                    }
                }
            }

            return (lesson, score)
        }

        return scored
            .sorted { $0.score > $1.score }
            .map { $0.lesson }
    }

    // MARK: - Symptom Relevance Ordering (Phase 3B)

    /// Sort symptoms by relevance to terrain type, placing the most relevant ones first.
    /// Weather context adds bonus scores — cold weather makes the "cold" symptom more
    /// likely, humid weather bumps "bloating", etc.
    func sortSymptomsByRelevance(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        weatherCondition: String? = nil
    ) -> [QuickSymptom] {
        let scored = QuickSymptom.allCases.map { symptom -> (symptom: QuickSymptom, score: Int) in
            var score = 0

            switch symptom {
            case .cold:
                if case .coldDeficient = terrainType { score += 3 }
                if case .coldBalanced = terrainType { score += 3 }
            case .tired:
                if case .coldDeficient = terrainType { score += 2 }
                if case .neutralDeficient = terrainType { score += 3 }
                if case .warmDeficient = terrainType { score += 2 }
            case .bloating:
                if modifier == .damp { score += 3 }
                if case .coldDeficient = terrainType { score += 1 }
            case .stressed:
                if modifier == .shen { score += 3 }
                if case .neutralExcess = terrainType { score += 2 }
                if case .warmExcess = terrainType { score += 2 }
            case .poorSleep:
                if modifier == .shen { score += 3 }
                if case .warmExcess = terrainType { score += 2 }
                if case .warmDeficient = terrainType { score += 2 }
            case .headache:
                if case .warmExcess = terrainType { score += 3 }
                if case .warmBalanced = terrainType { score += 2 }
                if modifier == .stagnation { score += 2 }
            case .cramps:
                if case .coldDeficient = terrainType { score += 2 }
                if case .coldBalanced = terrainType { score += 2 }
                if modifier == .stagnation { score += 1 }
            case .stiff:
                if modifier == .stagnation { score += 3 }
                if case .neutralExcess = terrainType { score += 2 }
            }

            // Weather-based symptom relevance boosts
            if let weather = weatherCondition {
                switch (symptom, weather) {
                case (.cold, "cold"):       score += 2
                case (.stiff, "cold"):      score += 1
                case (.headache, "hot"):    score += 1
                case (.headache, "windy"):  score += 1
                case (.bloating, "humid"):  score += 1
                case (.bloating, "rainy"):  score += 1
                default: break
                }
            }

            return (symptom, score)
        }

        return scored
            .sorted { $0.score > $1.score }
            .map { $0.symptom }
    }

    // MARK: - Life Area Readings (Co-Star Style)

    /// Generate Co-Star style life area readings with focus levels and personalized content
    func generateLifeAreaReadings(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        symptoms: Set<QuickSymptom> = [],
        weatherCondition: String? = nil,
        stepCount: Int? = nil
    ) -> [LifeAreaReading] {
        var readings: [LifeAreaReading] = []

        readings.append(generateEnergyReading(for: terrainType, modifier: modifier, symptoms: symptoms, stepCount: stepCount))
        readings.append(generateDigestionReading(for: terrainType, modifier: modifier, symptoms: symptoms))
        readings.append(generateSleepReading(for: terrainType, modifier: modifier, symptoms: symptoms))
        readings.append(generateMoodReading(for: terrainType, modifier: modifier, symptoms: symptoms))
        readings.append(generateSeasonalityReading(for: terrainType, modifier: modifier, weatherCondition: weatherCondition))

        return readings
    }

    /// Generate modifier areas when conditions warrant (Inner Climate, Fluid Balance, Qi Movement)
    func generateModifierAreaReadings(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        symptoms: Set<QuickSymptom> = []
    ) -> [ModifierAreaReading] {
        var readings: [ModifierAreaReading] = []

        // Inner Climate — temperature imbalance
        if case .coldDeficient = terrainType {
            readings.append(ModifierAreaReading(
                type: .innerClimate,
                reading: "Your inner temperature runs cold. The digestive fire that transforms food into energy burns low. You feel it as fatigue, cold hands, or sluggish mornings.",
                balanceAdvice: "Warm foods and drinks kindle the fire. Avoid ice and raw foods that extinguish what you're trying to build.",
                reasons: [ReadingReason(source: "Quiz", detail: "Your quiz revealed cold-deficient patterns")]
            ))
        } else if case .warmExcess = terrainType {
            readings.append(ModifierAreaReading(
                type: .innerClimate,
                reading: "Your inner temperature runs hot. Heat accumulates easily and shows up as restlessness, skin issues, or difficulty cooling down at night.",
                balanceAdvice: "Cooling foods and calm activities bring the temperature down. Avoid spicy foods and late-night intensity.",
                reasons: [ReadingReason(source: "Quiz", detail: "Your quiz revealed warm-excess patterns")]
            ))
        }

        // Fluid Balance — damp/dry patterns
        if modifier == .damp {
            readings.append(ModifierAreaReading(
                type: .fluidBalance,
                reading: "Your body holds onto fluid. Dampness is heavy—it shows up as sluggishness, foggy thinking, or a thick tongue coating. Your digestion works harder to process moisture.",
                balanceAdvice: "Light, warm foods help drain what's stuck. Avoid dairy, sugar, and greasy meals that add to the accumulation.",
                reasons: [ReadingReason(source: "Quiz", detail: "Your responses indicate a damp pattern")]
            ))
        } else if modifier == .dry {
            readings.append(ModifierAreaReading(
                type: .fluidBalance,
                reading: "Your body runs dry. Fluids don't replenish easily—you might notice dry skin, thirst that's hard to quench, or constipation.",
                balanceAdvice: "Moistening foods like pear, honey, and soups nourish your fluids. Sip warm water throughout the day.",
                reasons: [ReadingReason(source: "Quiz", detail: "Your responses indicate a dry pattern")]
            ))
        }

        // Qi Movement — stagnation patterns
        if modifier == .stagnation {
            readings.append(ModifierAreaReading(
                type: .qiMovement,
                reading: "Your energy tends to get stuck. When qi doesn't flow, it shows up as tension, frustration, or feeling physically tight. Movement is medicine for your pattern.",
                balanceAdvice: "Physical activity, stretching, and deep breathing help move what's stuck. Avoid prolonged sitting and suppressed emotions.",
                reasons: [ReadingReason(source: "Quiz", detail: "Your responses indicate qi stagnation")]
            ))
        } else if symptoms.contains(.stiff) || symptoms.contains(.stressed) {
            readings.append(ModifierAreaReading(
                type: .qiMovement,
                reading: "Energy feels blocked today. Stiffness and stress are signals that qi wants to move but can't find a path.",
                balanceAdvice: "Even small movements help—a walk, some stretches, or deep sighs release the pressure.",
                reasons: symptoms.contains(.stiff)
                    ? [ReadingReason(source: "Symptoms", detail: "You checked 'stiff' today")]
                    : [ReadingReason(source: "Symptoms", detail: "You checked 'stressed' today")]
            ))
        }

        return readings
    }

    // MARK: - Individual Life Area Readings

    private func generateEnergyReading(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>,
        stepCount: Int?
    ) -> LifeAreaReading {
        var focusLevel: FocusLevel = .neutral
        var reasons: [ReadingReason] = []
        var reading: String
        var balanceAdvice: String

        // Base reading from terrain
        switch terrainType {
        case .coldDeficient:
            reading = "Your energy reserves run low. The fire that powers you burns small—gentle, not roaring. You build strength through accumulation, not intensity."
            balanceAdvice = "Warm starts, cooked foods, and paced activity. Rest when tired rather than pushing through."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Your terrain shows deficient patterns"))
        case .coldBalanced:
            reading = "Your energy is steady but cool. You maintain well when warmth is protected. Cold inputs drain faster than you realize."
            balanceAdvice = "Warm drinks, layered clothing, and consistent routines keep your fuel steady."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "You have a cool-balanced constitution"))
        case .neutralDeficient:
            reading = "Your energy needs deliberate building. Your reserves don't refill automatically—each rest period and nourishing meal matters."
            balanceAdvice = "Regular meals, early sleep, and gentle movement compound into sustainable energy."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Your terrain shows deficient patterns"))
        case .neutralBalanced:
            reading = "Your energy is naturally stable. You adapt well and maintain balance without dramatic swings. Consistency is your superpower."
            balanceAdvice = "Protect your rhythm. Don't sacrifice sleep or meals for productivity—your balance depends on it."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "You have balanced energy reserves"))
        case .neutralExcess:
            reading = "You have energy to spare. The challenge isn't generating it—it's channeling it. Unused energy turns into restlessness or tension."
            balanceAdvice = "Movement, creative outlets, and physical release prevent buildup. Don't let energy stagnate."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Your terrain shows excess patterns"))
        case .warmBalanced:
            reading = "Your inner fire burns bright and steady. Heat drives your energy but needs management to prevent overheating."
            balanceAdvice = "Hydration, cooling foods, and evening wind-down keep your flame clean and sustainable."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "You have a warm-balanced constitution"))
        case .warmExcess:
            reading = "Your energy runs hot and high. Intensity comes naturally but burns fuel fast. The crash follows the sprint."
            balanceAdvice = "Cooling foods, paced activity, and deliberate rest prevent burnout. Slow is sustainable."
            focusLevel = .priority
            reasons.append(ReadingReason(source: "Quiz", detail: "Your terrain shows warm-excess patterns"))
        case .warmDeficient:
            reading = "Your flame burns bright but thin. You look energetic but run on fumes. The gap between appearance and reserves needs bridging."
            balanceAdvice = "Moistening foods, early rest, and avoiding overcommitment rebuild what intensity depletes."
            focusLevel = .priority
            reasons.append(ReadingReason(source: "Quiz", detail: "Your terrain shows deficient patterns"))
        }

        // Symptom adjustments
        if symptoms.contains(.tired) {
            focusLevel = .priority
            reading = "Fatigue is present. Your body is honest when it's depleted—this isn't laziness, it's a request for rest."
            reasons.append(ReadingReason(source: "Symptoms", detail: "You checked 'tired' today"))
        }

        // Step count observations
        if let steps = stepCount {
            if steps < 2000 {
                reasons.append(ReadingReason(source: "Activity", detail: "Low movement today (\(steps) steps)"))
                if focusLevel == .neutral { focusLevel = .moderate }
            } else if steps > 10000 {
                reasons.append(ReadingReason(source: "Activity", detail: "Active day (\(steps) steps)"))
                switch terrainType {
                case .coldDeficient, .neutralDeficient, .warmDeficient:
                    balanceAdvice += " High activity means extra nourishment tonight."
                default:
                    break
                }
            }
        }

        return LifeAreaReading(
            type: .energy,
            focusLevel: focusLevel,
            reading: reading,
            balanceAdvice: balanceAdvice,
            reasons: reasons
        )
    }

    private func generateDigestionReading(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>
    ) -> LifeAreaReading {
        var focusLevel: FocusLevel = .neutral
        var reasons: [ReadingReason] = []
        var reading: String
        var balanceAdvice: String

        switch terrainType {
        case .coldDeficient, .coldBalanced:
            reading = "Your digestive fire needs protection. Cold foods and drinks extinguish the flame that transforms food into energy. Warmth is medicine."
            balanceAdvice = "Cooked foods, warm drinks, and ginger support your digestion. Avoid ice and raw meals."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Cold patterns affect digestion first"))
        case .neutralDeficient:
            reading = "Your digestion works but tires easily. Large meals overwhelm; regular small ones sustain. Timing matters as much as content."
            balanceAdvice = "Easy-to-digest foods, consistent meal times, and chewing thoroughly help your system keep up."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Deficiency shows in digestive stamina"))
        case .neutralBalanced:
            reading = "Your digestion handles variety well. You can adapt to different foods without major consequences. Moderation keeps it that way."
            balanceAdvice = "Don't take your adaptability for granted. Balanced portions and variety maintain your flexibility."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "Balanced digestion is your baseline"))
        case .neutralExcess:
            reading = "Your digestion is strong but can become sluggish when energy doesn't move. Heavy meals plus inactivity equals stagnation."
            balanceAdvice = "Light meals, post-meal walks, and avoiding greasy foods keep things flowing."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "Excess patterns need movement to digest well"))
        case .warmBalanced, .warmExcess:
            reading = "Your digestion runs hot. It processes quickly but can become inflamed. Cooling foods soothe without slowing things down."
            balanceAdvice = "Cool foods, bitter greens, and avoiding spicy meals keep digestive heat in check."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Warm patterns tend toward digestive heat"))
        case .warmDeficient:
            reading = "Your digestion is warm but delicate. Heat dries the stomach—you need moisture as much as you need fuel."
            balanceAdvice = "Moistening soups, gentle vegetables, and hydration between meals nourish without aggravating."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Warm-deficient needs moisture"))
        }

        // Modifier adjustments
        if modifier == .damp {
            focusLevel = .priority
            reading = "Dampness sits heavy on digestion. Your spleen struggles to process moisture—it shows as bloating, sluggishness, or foggy thinking."
            balanceAdvice = "Avoid dairy, sugar, and greasy foods. Light, warm meals help your spleen drain what's stuck."
            reasons.append(ReadingReason(source: "Quiz", detail: "Damp modifier directly affects digestion"))
        }

        // Symptom adjustments
        if symptoms.contains(.bloating) {
            focusLevel = .priority
            reading = "Bloating is present. Your digestion is asking for space—smaller inputs, gentler processing, time to catch up."
            balanceAdvice = "Small frequent meals, post-meal walks, and fennel or mint tea help move trapped energy."
            reasons.append(ReadingReason(source: "Symptoms", detail: "You checked 'bloating' today"))
        }

        return LifeAreaReading(
            type: .digestion,
            focusLevel: focusLevel,
            reading: reading,
            balanceAdvice: balanceAdvice,
            reasons: reasons
        )
    }

    private func generateSleepReading(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>
    ) -> LifeAreaReading {
        var focusLevel: FocusLevel = .neutral
        var reasons: [ReadingReason] = []
        var reading: String
        var balanceAdvice: String

        switch terrainType {
        case .coldDeficient:
            reading = "Sleep rebuilds what day depletes. Your reserves are smaller—every hour of quality rest compounds into tomorrow's energy."
            balanceAdvice = "Warm feet before bed, earlier bedtimes, and avoiding cold drinks at night support deep sleep."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "Deficiency makes rest more precious"))
        case .coldBalanced:
            reading = "Your sleep is stable when warmth is protected. Cold bedrooms might feel fresh but can disturb your rest."
            balanceAdvice = "Warm blankets, consistent bedtime, and a wind-down routine anchor your sleep."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "Cool constitutions need warmth to sleep well"))
        case .neutralDeficient:
            reading = "Sleep is your primary repair mechanism. You notice the difference when you don't get enough—it shows in energy, focus, and mood."
            balanceAdvice = "Prioritize 8+ hours. Earlier bedtime beats sleeping in. Wind down rather than powering down."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Deficiency means sleep is extra important"))
        case .neutralBalanced:
            reading = "Your sleep is naturally stable. You recover well when you give yourself the hours. Consistency matters more than tricks."
            balanceAdvice = "Regular schedule, no screens before bed, and protecting your rhythm keep sleep reliable."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "Balanced sleep is your baseline"))
        case .neutralExcess:
            reading = "Excess energy can make settling difficult. Your body has fuel to burn—it needs release before it can rest."
            balanceAdvice = "Physical activity earlier in the day, journaling at night, and releasing tension before bed."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Excess energy affects settling"))
        case .warmBalanced:
            reading = "Heat rises at night. Your body holds warmth that can disturb sleep if not released through deliberate cool-down."
            balanceAdvice = "Cool room, light evening meals, and a wind-down routine help heat dissipate for rest."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Warm constitutions need to cool before sleep"))
        case .warmExcess:
            reading = "Your mind and body run hot at night. The intensity that drives you during the day keeps running when you need it to stop."
            balanceAdvice = "Evening quiet, no screens, cooling tea, and deliberate downshift are essential."
            focusLevel = .priority
            reasons.append(ReadingReason(source: "Quiz", detail: "Warm-excess patterns disrupt sleep"))
        case .warmDeficient:
            reading = "You look wired but feel tired. The nervous system runs even when reserves are low—anxiety at bedtime masks exhaustion."
            balanceAdvice = "Calming routines, nourishing evening food, and permission to rest even when your mind races."
            focusLevel = .priority
            reasons.append(ReadingReason(source: "Quiz", detail: "Warm-deficient often has restless sleep"))
        }

        // Modifier adjustments
        if modifier == .shen {
            focusLevel = .priority
            reading = "Your spirit runs active. The mind doesn't settle easily—thoughts loop, sleep eludes, and rest feels incomplete."
            balanceAdvice = "Extra wind-down time, calming herbs, and no stimulation after dinner help settle the shen."
            reasons.append(ReadingReason(source: "Quiz", detail: "Shen modifier directly affects sleep"))
        }

        // Symptom adjustments
        if symptoms.contains(.poorSleep) {
            focusLevel = .priority
            reading = "Sleep was poor recently. The deficit compounds—today needs gentleness and tonight needs protection."
            balanceAdvice = "No caffeine after noon, early wind-down, and prioritizing rest over productivity today."
            reasons.append(ReadingReason(source: "Symptoms", detail: "You checked 'poor sleep' today"))
        }

        return LifeAreaReading(
            type: .sleep,
            focusLevel: focusLevel,
            reading: reading,
            balanceAdvice: balanceAdvice,
            reasons: reasons
        )
    }

    private func generateMoodReading(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>
    ) -> LifeAreaReading {
        var focusLevel: FocusLevel = .neutral
        var reasons: [ReadingReason] = []
        var reading: String
        var balanceAdvice: String

        switch terrainType {
        case .coldDeficient:
            reading = "Mood follows energy. When reserves are low, the emotional buffer shrinks. You feel more, tire faster emotionally."
            balanceAdvice = "Warmth and nourishment lift spirits. Rest before you're depleted. Small comforts matter."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "Deficiency affects emotional reserves"))
        case .coldBalanced:
            reading = "Your emotional baseline is steady but sensitive to cold and isolation. Connection and warmth support your mood."
            balanceAdvice = "Warm drinks, social connection, and sunlight when possible lift your spirits."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "Cool constitutions need warmth for mood"))
        case .neutralDeficient:
            reading = "Your mood reflects your resources. When depleted, worry and doubt creep in. When nourished, clarity returns."
            balanceAdvice = "Rest is not laziness. Small accomplishments count. Nourish before pushing."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "Deficiency patterns show in worry"))
        case .neutralBalanced:
            reading = "Your emotional life is stable. You don't swing dramatically—consistency and rhythm support your natural equilibrium."
            balanceAdvice = "Protect your routines. Balance prevents the extremes your system doesn't handle well."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Quiz", detail: "Balanced mood is your baseline"))
        case .neutralExcess:
            reading = "You feel things strongly. Emotions build up and need outlets—suppression creates pressure that leaks out sideways."
            balanceAdvice = "Express rather than hold. Movement, creativity, and voicing feelings release what builds."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Excess patterns need emotional release"))
        case .warmBalanced:
            reading = "Your emotional temperature runs warm. Passion is an asset but can tip into irritability when heat builds."
            balanceAdvice = "Cooling practices help mood. Don't let frustration accumulate—release before it builds."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Quiz", detail: "Warm patterns can tip to irritability"))
        case .warmExcess:
            reading = "Intensity is your baseline. Emotions come fast and strong. The heat that drives you can also burn bridges."
            balanceAdvice = "Pause before reacting. Cool the system to cool the mood. Evening quiet is essential."
            focusLevel = .priority
            reasons.append(ReadingReason(source: "Quiz", detail: "Warm-excess affects emotional regulation"))
        case .warmDeficient:
            reading = "Anxiety runs beneath the surface. Your nervous system is depleted but doesn't know how to stop."
            balanceAdvice = "Rest is your reset. Nourish the nervous system. Let yourself stop before you crash."
            focusLevel = .priority
            reasons.append(ReadingReason(source: "Quiz", detail: "Warm-deficient often feels anxious"))
        }

        // Modifier adjustments
        if modifier == .stagnation {
            focusLevel = max(focusLevel, .moderate)
            reading = "Emotions get stuck like energy gets stuck. What isn't expressed builds pressure. Movement helps mood as much as body."
            balanceAdvice = "Physical release, creative expression, and not suppressing feelings keep emotions flowing."
            reasons.append(ReadingReason(source: "Quiz", detail: "Stagnation affects emotional flow"))
        }

        // Symptom adjustments
        if symptoms.contains(.stressed) {
            focusLevel = .priority
            reading = "Stress is present and pressing. Your nervous system is in high alert—the body needs signals of safety."
            balanceAdvice = "Deep breaths, reduced stimulation, and permission to pause. You don't have to solve everything today."
            reasons.append(ReadingReason(source: "Symptoms", detail: "You checked 'stressed' today"))
        }

        return LifeAreaReading(
            type: .mood,
            focusLevel: focusLevel,
            reading: reading,
            balanceAdvice: balanceAdvice,
            reasons: reasons
        )
    }

    private func generateSeasonalityReading(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        weatherCondition: String?
    ) -> LifeAreaReading {
        let season = TCMSeason.current()
        var focusLevel: FocusLevel = .neutral
        var reasons: [ReadingReason] = []
        var reading: String
        var balanceAdvice: String

        // Season + terrain interaction
        switch (season, terrainType) {
        case (.winter, .coldDeficient), (.winter, .coldBalanced):
            reading = "Winter amplifies your cold pattern. External cold meets internal cold—your body works harder to maintain warmth."
            balanceAdvice = "Extra warming practices are essential. Soups, layers, and avoiding cold inputs protect your core."
            focusLevel = .priority
            reasons.append(ReadingReason(source: "Patterns", detail: "Winter challenges cold constitutions"))

        case (.summer, .warmExcess), (.summer, .warmBalanced):
            reading = "Summer intensifies your heat. External heat compounds internal heat—be proactive about cooling before symptoms appear."
            balanceAdvice = "Cooling foods, hydration, and avoiding midday heat help manage the double warmth."
            focusLevel = .priority
            reasons.append(ReadingReason(source: "Patterns", detail: "Summer challenges warm constitutions"))

        case (.lateSummer, _) where modifier == .damp:
            reading = "Late summer is peak dampness season. Your damp pattern is most vulnerable now—the spleen needs extra support."
            balanceAdvice = "Avoid dairy, sugar, and heavy foods. Light movement and warm meals drain what accumulates."
            focusLevel = .priority
            reasons.append(ReadingReason(source: "Patterns", detail: "Late summer amplifies damp patterns"))

        case (.autumn, _) where modifier == .dry:
            reading = "Autumn dryness meets your dry pattern. The air pulls moisture your body is already short on."
            balanceAdvice = "Moistening foods are essential—pears, honey, soups. Sip warm water throughout the day."
            focusLevel = .priority
            reasons.append(ReadingReason(source: "Patterns", detail: "Autumn amplifies dry patterns"))

        case (.spring, _) where modifier == .stagnation:
            reading = "Spring is the season of rising energy. Your stagnation pattern responds strongly—movement matters more now."
            balanceAdvice = "Increase stretching and walks. Express rather than hold. Spring wants energy to flow."
            focusLevel = .moderate
            reasons.append(ReadingReason(source: "Patterns", detail: "Spring activates stagnation patterns"))

        default:
            reading = "\(season.displayName) is here. Your body naturally responds to the season—tuning in helps you ride rather than fight the rhythm."
            balanceAdvice = "Eat seasonally, adjust routines to daylight, and listen to what your body asks for."
            focusLevel = .neutral
            reasons.append(ReadingReason(source: "Patterns", detail: "Seasonal awareness supports balance"))
        }

        // Weather conditions add urgency
        if let weather = weatherCondition {
            switch weather {
            case "cold":
                reasons.append(ReadingReason(source: "Weather", detail: "Cold weather today"))
                if case .coldDeficient = terrainType { focusLevel = max(focusLevel, .priority) }
                if case .coldBalanced = terrainType { focusLevel = max(focusLevel, .moderate) }
            case "hot":
                reasons.append(ReadingReason(source: "Weather", detail: "Hot weather today"))
                if case .warmExcess = terrainType { focusLevel = max(focusLevel, .priority) }
                if case .warmBalanced = terrainType { focusLevel = max(focusLevel, .moderate) }
            case "humid", "rainy":
                reasons.append(ReadingReason(source: "Weather", detail: "Humid conditions today"))
                if modifier == .damp { focusLevel = max(focusLevel, .priority) }
            case "dry":
                reasons.append(ReadingReason(source: "Weather", detail: "Dry air today"))
                if modifier == .dry { focusLevel = max(focusLevel, .priority) }
            case "windy":
                reasons.append(ReadingReason(source: "Weather", detail: "Windy conditions today"))
            default:
                break
            }
        }

        return LifeAreaReading(
            type: .seasonality,
            focusLevel: focusLevel,
            reading: reading,
            balanceAdvice: balanceAdvice,
            reasons: reasons
        )
    }

    // MARK: - Why For You Generators (Phase 2B)

    /// Generate a terrain-specific explanation for why a routine matters
    func generateWhyForYou(
        routineTags: [String],
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> String? {
        let isWarming = routineTags.contains("warming")
        let isCooling = routineTags.contains("cooling")
        let isCalming = routineTags.contains("calms_shen")
        let isMovesQi = routineTags.contains("moves_qi")

        switch terrainType {
        case .coldDeficient, .coldBalanced:
            if isWarming { return "Warming routines kindle your digestive fire and build the heat your body needs to function at its best." }
        case .warmExcess, .warmBalanced:
            if isCooling { return "Cooling routines bring your natural heat back to a manageable level, protecting your sleep and skin." }
        case .neutralExcess:
            if isMovesQi { return "Moving stuck qi prevents the tension and restlessness your type is prone to." }
        case .warmDeficient:
            if isCalming { return "Calming routines let your nervous system rest, which is how your depleted reserves rebuild." }
        default:
            break
        }

        if modifier == .shen && isCalming {
            return "Your shen modifier means your mind is more active than most. Calming practices settle the spirit for better sleep and clarity."
        }
        if modifier == .stagnation && isMovesQi {
            return "Stagnation means energy gets stuck easily. This routine helps get things flowing again."
        }
        if modifier == .damp && routineTags.contains("dries_damp") {
            return "Your damp modifier means excess moisture accumulates. This routine helps your body process and drain what's stuck."
        }

        return nil
    }

    /// Generate a terrain-specific explanation for an ingredient
    func generateWhyForYou(
        ingredientTags: [String],
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> String? {
        let isWarming = ingredientTags.contains("warming")
        let isCooling = ingredientTags.contains("cooling")
        let isMoistening = ingredientTags.contains("moistens_dryness")
        let isCalming = ingredientTags.contains("calms_shen")

        switch terrainType {
        case .coldDeficient, .coldBalanced:
            if isWarming { return "Warming ingredients directly support your cold pattern by building internal heat." }
            if isCooling { return "Use sparingly — cooling ingredients can weaken your digestive fire." }
        case .warmExcess, .warmBalanced:
            if isCooling { return "Cooling ingredients are your allies. They balance your natural heat without shocking your system." }
            if isWarming { return "Be careful — warming ingredients add heat to a system that's already warm." }
        case .warmDeficient:
            if isMoistening { return "Your warmth dries you out. Moistening ingredients replenish the fluids your body needs." }
        case .neutralDeficient:
            if ingredientTags.contains("supports_deficiency") { return "Your body needs building up. This ingredient gently nourishes without taxing your digestion." }
        default:
            break
        }

        if modifier == .shen && isCalming {
            return "Your shen modifier means your mind benefits especially from calming ingredients."
        }
        if modifier == .damp && ingredientTags.contains("dries_damp") {
            return "Your damp modifier makes this ingredient particularly helpful — it supports drainage of excess moisture."
        }

        return nil
    }
}
