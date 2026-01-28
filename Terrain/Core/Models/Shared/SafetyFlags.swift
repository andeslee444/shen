//
//  SafetyFlags.swift
//  Terrain
//
//  Safety warning flags for content
//

import Foundation

/// Safety flags for ingredients and routines
/// Used to surface soft warnings; not medical advice
enum SafetyFlag: String, Codable, CaseIterable, Identifiable {
    case pregnancyCaution = "pregnancy_caution"
    case breastfeedingCaution = "breastfeeding_caution"
    case gerdCaution = "gerd_caution"
    case bloodThinnerCaution = "blood_thinner_caution"
    case bpMedsCaution = "bp_meds_caution"
    case thyroidMedsCaution = "thyroid_meds_caution"
    case diabetesMedsCaution = "diabetes_meds_caution"
    case caffeine
    case highHistamine = "high_histamine"
    case allergenCommon = "allergen_common"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pregnancyCaution: return "Pregnancy Caution"
        case .breastfeedingCaution: return "Breastfeeding Caution"
        case .gerdCaution: return "GERD/Reflux Caution"
        case .bloodThinnerCaution: return "Blood Thinner Caution"
        case .bpMedsCaution: return "Blood Pressure Meds Caution"
        case .thyroidMedsCaution: return "Thyroid Meds Caution"
        case .diabetesMedsCaution: return "Diabetes Meds Caution"
        case .caffeine: return "Contains Caffeine"
        case .highHistamine: return "High Histamine"
        case .allergenCommon: return "Common Allergen"
        }
    }

    var warningMessage: String {
        switch self {
        case .pregnancyCaution:
            return "May not be suitable during pregnancy. Consult your healthcare provider."
        case .breastfeedingCaution:
            return "May not be suitable while breastfeeding. Consult your healthcare provider."
        case .gerdCaution:
            return "May aggravate acid reflux or GERD symptoms."
        case .bloodThinnerCaution:
            return "May interact with blood thinning medications."
        case .bpMedsCaution:
            return "May interact with blood pressure medications."
        case .thyroidMedsCaution:
            return "May interact with thyroid medications."
        case .diabetesMedsCaution:
            return "May affect blood sugar levels."
        case .caffeine:
            return "Contains caffeine. May affect sleep if consumed late."
        case .highHistamine:
            return "High in histamine. May trigger reactions in sensitive individuals."
        case .allergenCommon:
            return "Common allergen. Check for sensitivities."
        }
    }

    var icon: String {
        switch self {
        case .pregnancyCaution, .breastfeedingCaution:
            return "figure.and.child.holdinghands"
        case .gerdCaution:
            return "flame"
        case .bloodThinnerCaution, .bpMedsCaution, .thyroidMedsCaution, .diabetesMedsCaution:
            return "pills"
        case .caffeine:
            return "cup.and.saucer"
        case .highHistamine, .allergenCommon:
            return "exclamationmark.triangle"
        }
    }
}

/// User's safety preferences set during onboarding
struct SafetyPreferences: Codable, Hashable {
    var isPregnant: Bool = false
    var isBreastfeeding: Bool = false
    var hasGerd: Bool = false
    var takesBloodThinners: Bool = false
    var takesBpMeds: Bool = false
    var takesThyroidMeds: Bool = false
    var takesDiabetesMeds: Bool = false
    var avoidsCaffeine: Bool = false
    var hasHistamineIntolerance: Bool = false
    var commonAllergens: [String] = []

    /// Returns safety flags that apply to this user
    var applicableFlags: Set<SafetyFlag> {
        var flags: Set<SafetyFlag> = []

        if isPregnant { flags.insert(.pregnancyCaution) }
        if isBreastfeeding { flags.insert(.breastfeedingCaution) }
        if hasGerd { flags.insert(.gerdCaution) }
        if takesBloodThinners { flags.insert(.bloodThinnerCaution) }
        if takesBpMeds { flags.insert(.bpMedsCaution) }
        if takesThyroidMeds { flags.insert(.thyroidMedsCaution) }
        if takesDiabetesMeds { flags.insert(.diabetesMedsCaution) }
        if avoidsCaffeine { flags.insert(.caffeine) }
        if hasHistamineIntolerance { flags.insert(.highHistamine) }
        if !commonAllergens.isEmpty { flags.insert(.allergenCommon) }

        return flags
    }

    /// Checks if content with given flags should show a warning
    func shouldWarn(for contentFlags: [SafetyFlag]) -> Bool {
        !applicableFlags.isDisjoint(with: contentFlags)
    }

    /// Returns warnings for content with given flags
    func warnings(for contentFlags: [SafetyFlag]) -> [SafetyFlag] {
        Array(applicableFlags.intersection(contentFlags))
    }
}
