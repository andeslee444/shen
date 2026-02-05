//
//  TerrainPulseCheckIn.swift
//  Terrain
//
//  Lightweight 5-question pulse check-in for quarterly terrain drift detection.
//  Each question targets one scoring axis to build a mini terrain vector.
//

import Foundation

struct PulseCheckInQuestion: Identifiable {
    let id: Int
    let text: String
    let axis: String  // "cold_heat", "def_excess", "damp_dry", "qi_stagnation", "shen_unsettled"
    let options: [PulseCheckInOption]
}

struct PulseCheckInOption: Identifiable {
    let id: Int
    let text: String
    let value: Int  // Score contribution to the axis
}

enum PulseCheckInQuestions {
    static let all: [PulseCheckInQuestion] = [
        // 1. Temperature (cold_heat)
        PulseCheckInQuestion(
            id: 1,
            text: "Lately, do you run cold or warm?",
            axis: "cold_heat",
            options: [
                PulseCheckInOption(id: 1, text: "Cold hands and feet", value: -3),
                PulseCheckInOption(id: 2, text: "Comfortable", value: 0),
                PulseCheckInOption(id: 3, text: "Run warm, seek cool", value: 3)
            ]
        ),
        // 2. Energy (def_excess)
        PulseCheckInQuestion(
            id: 2,
            text: "How's your energy been?",
            axis: "def_excess",
            options: [
                PulseCheckInOption(id: 4, text: "Tired often, need rest", value: -3),
                PulseCheckInOption(id: 5, text: "Steady and adequate", value: 0),
                PulseCheckInOption(id: 6, text: "Restless, excess energy", value: 3)
            ]
        ),
        // 3. Moisture (damp_dry)
        PulseCheckInQuestion(
            id: 3,
            text: "Any fluid or moisture patterns?",
            axis: "damp_dry",
            options: [
                PulseCheckInOption(id: 7, text: "Heavy, puffy, sluggish digestion", value: -3),
                PulseCheckInOption(id: 8, text: "Normal", value: 0),
                PulseCheckInOption(id: 9, text: "Dry skin, thirsty, constipated", value: 3)
            ]
        ),
        // 4. Qi flow (qi_stagnation)
        PulseCheckInQuestion(
            id: 4,
            text: "How does your body feel in terms of tension?",
            axis: "qi_stagnation",
            options: [
                PulseCheckInOption(id: 10, text: "Relaxed and flowing", value: 0),
                PulseCheckInOption(id: 11, text: "Some tightness", value: 2),
                PulseCheckInOption(id: 12, text: "Stuck, stiff, headaches", value: 4)
            ]
        ),
        // 5. Mind (shen_unsettled)
        PulseCheckInQuestion(
            id: 5,
            text: "How's your sleep and mind?",
            axis: "shen_unsettled",
            options: [
                PulseCheckInOption(id: 13, text: "Peaceful, sleep well", value: 0),
                PulseCheckInOption(id: 14, text: "Occasionally restless", value: 2),
                PulseCheckInOption(id: 15, text: "Racing thoughts, poor sleep", value: 4)
            ]
        )
    ]
}
