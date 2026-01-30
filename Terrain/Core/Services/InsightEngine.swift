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

    /// Generate the main headline for the day based on terrain type and symptoms
    func generateHeadline(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        symptoms: Set<QuickSymptom> = []
    ) -> HeadlineContent {
        // Check for symptom-adjusted headlines first
        if let adjustedHeadline = symptomAdjustedHeadline(for: symptoms, terrainType: terrainType) {
            return HeadlineContent(text: adjustedHeadline, isSymptomAdjusted: true)
        }

        // Base headline by terrain type
        let text = baseHeadline(for: terrainType)
        return HeadlineContent(text: text, isSymptomAdjusted: false)
    }

    private func baseHeadline(for terrainType: TerrainScoringEngine.PrimaryType) -> String {
        switch terrainType {
        case .coldDeficient:
            return "Your energy returns when you warm the center first."
        case .coldBalanced:
            return "Warm your core, then let the day flow."
        case .neutralDeficient:
            return "Build steadily today. Small inputs, big returns."
        case .neutralBalanced:
            return "Your rhythm is your power. Stay anchored."
        case .neutralExcess:
            return "Release first. Then everything flows."
        case .warmBalanced:
            return "Stay light today. Evening cool is your reset."
        case .warmExcess:
            return "Downshift early. Your nervous system will thank you."
        case .warmDeficient:
            return "Nourish and soften. Your glow comes from rest."
        }
    }

    private func symptomAdjustedHeadline(
        for symptoms: Set<QuickSymptom>,
        terrainType: TerrainScoringEngine.PrimaryType
    ) -> String? {
        // Priority order: stressed > poorSleep > cramps > headache > cold > bloating > stiff > tired
        if symptoms.contains(.stressed) {
            return "Pause before you push. Calm is today's foundation."
        }
        if symptoms.contains(.poorSleep) {
            return "Gentle day ahead. Your body is asking for restoration."
        }
        if symptoms.contains(.cramps) {
            return "Warm and soothe. Your body needs softness today."
        }
        if symptoms.contains(.headache) {
            return "Ease the tension. Less input, more space."
        }
        if symptoms.contains(.cold) {
            switch terrainType {
            case .coldDeficient, .coldBalanced:
                return "Extra warmth today. Your body needs building up."
            case .warmBalanced, .warmExcess, .warmDeficient:
                return "Feeling cold? Time to nourish and protect."
            default:
                return "Warm and steady wins today."
            }
        }
        if symptoms.contains(.bloating) {
            return "Keep things moving. Light meals, gentle motion."
        }
        if symptoms.contains(.stiff) {
            return "Your body is asking to move. Small stretches, big relief."
        }
        if symptoms.contains(.tired) {
            return "Rest is productive. Build slowly today."
        }
        return nil
    }

    // MARK: - Do/Don't Generation

    /// Generate do's and don'ts for the terrain type
    func generateDoDont(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        symptoms: Set<QuickSymptom> = []
    ) -> (dos: [DoDontItem], donts: [DoDontItem]) {
        var dos = baseDos(for: terrainType)
        var donts = baseDonts(for: terrainType)

        // Add modifier-specific items
        addModifierItems(modifier: modifier, dos: &dos, donts: &donts)

        // Add symptom-specific items
        addSymptomItems(symptoms: symptoms, dos: &dos, donts: &donts)

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

    // MARK: - Areas of Life

    /// Generate area of life content for terrain type
    func generateAreas(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none,
        symptoms: Set<QuickSymptom> = []
    ) -> [AreaOfLifeContent] {
        var areas: [AreaOfLifeContent] = []

        // Energy & Focus
        areas.append(generateEnergyArea(for: terrainType, modifier: modifier, symptoms: symptoms))

        // Digestion
        areas.append(generateDigestionArea(for: terrainType, modifier: modifier, symptoms: symptoms))

        // Sleep & Wind-down
        areas.append(generateSleepArea(for: terrainType, modifier: modifier, symptoms: symptoms))

        // Mood & Stress
        areas.append(generateMoodArea(for: terrainType, modifier: modifier, symptoms: symptoms))

        return areas
    }

    private func generateEnergyArea(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>
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

        let tcmNote: String?
        switch terrainType {
        case .coldDeficient, .neutralDeficient, .warmDeficient:
            tcmNote = "Qi and Yang need building. Gentle support over pushing."
        case .neutralExcess, .warmExcess:
            tcmNote = "Excess energy needs movement and release."
        default:
            tcmNote = nil
        }

        return AreaOfLifeContent(type: .energyFocus, tips: tips, tcmNote: tcmNote)
    }

    private func generateDigestionArea(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>
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

        let tcmNote = "The Spleen transforms food into energy. Support it with appropriate temperature and texture."

        return AreaOfLifeContent(type: .digestion, tips: tips, tcmNote: tcmNote)
    }

    private func generateSleepArea(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>
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

        let tcmNote = "Sleep anchors the Shen (spirit). A settled mind finds rest."

        return AreaOfLifeContent(type: .sleepWindDown, tips: tips, tcmNote: tcmNote)
    }

    private func generateMoodArea(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>
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

        let tcmNote: String?
        if modifier == .shen || symptoms.contains(.stressed) || symptoms.contains(.poorSleep) {
            tcmNote = "The Shen (spirit) needs anchoring. Calm the mind to calm the body."
        } else {
            tcmNote = nil
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
        date: Date = Date()
    ) -> SeasonalNoteContent {
        let season = TCMSeason.current(for: date)
        let note: String
        let tips: [String]

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

        return SeasonalNoteContent(
            season: season.displayName,
            icon: season.icon,
            note: note,
            tips: tips
        )
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
    func sortSymptomsByRelevance(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier = .none
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

            return (symptom, score)
        }

        return scored
            .sorted { $0.score > $1.score }
            .map { $0.symptom }
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
