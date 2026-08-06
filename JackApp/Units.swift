//
//  Units.swift
//  JackApp
//
//  Created by Jack on 05/08/2026.
//

import Foundation

/// The unit weights are displayed and entered in. Storage stays canonical
/// (lifts in kilograms, body weight in pounds) and everything is converted at
/// the display layer, so switching units re-expresses existing data rather than
/// reinterpreting the stored numbers.
enum WeightUnit: String, CaseIterable, Identifiable {
    case kilograms = "kg"
    case pounds = "lb"

    static let storageKey = "weightUnit"
    static let `default`: WeightUnit = .kilograms

    var id: String { rawValue }

    /// Short suffix shown next to a value, e.g. "kg".
    var abbreviation: String { rawValue }

    var displayName: String {
        switch self {
        case .kilograms: return "Metric (kg)"
        case .pounds:    return "Imperial (lb)"
        }
    }

    private static let kilogramsPerPound = 0.45359237

    // MARK: Kilogram-based storage (lifts)

    /// Convert a canonical kilogram value into this unit.
    func value(fromKilograms kilograms: Double) -> Double {
        switch self {
        case .kilograms: return kilograms
        case .pounds:    return kilograms / Self.kilogramsPerPound
        }
    }

    /// Convert a value expressed in this unit back into canonical kilograms.
    func kilograms(from value: Double) -> Double {
        switch self {
        case .kilograms: return value
        case .pounds:    return value * Self.kilogramsPerPound
        }
    }

    // MARK: Pound-based storage (body weight)

    /// Convert a canonical pound value into this unit.
    func value(fromPounds pounds: Double) -> Double {
        switch self {
        case .kilograms: return pounds * Self.kilogramsPerPound
        case .pounds:    return pounds
        }
    }

    /// Convert a value expressed in this unit back into canonical pounds.
    func pounds(from value: Double) -> Double {
        switch self {
        case .kilograms: return value / Self.kilogramsPerPound
        case .pounds:    return value
        }
    }
}
