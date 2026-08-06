//
//  LiftLog.swift
//  JackApp
//
//  Created by Jack on 03/08/2026.
//

import Foundation
import SwiftData

/// A single logged session for one exercise (e.g. "Bench Press" on a given day).
@Model
final class LiftEntry {
    var id: UUID = UUID()
    var exerciseName: String = ""
    var date: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \LiftSet.entry)
    var sets: [LiftSet] = []

    init(exerciseName: String, date: Date = Date()) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.date = date
        self.sets = []
    }
}

/// A single set within a logged session: a weight lifted for a number of reps.
@Model
final class LiftSet {
    var id: UUID = UUID()
    var weight: Double = 0
    var reps: Int = 0
    var order: Int = 0
    var entry: LiftEntry?

    init(weight: Double, reps: Int, order: Int) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.order = order
    }
}

// MARK: - Derived values

extension LiftSet {
    /// Estimated one-rep max using the Epley formula.
    var estimatedOneRepMax: Double {
        reps <= 1 ? weight : weight * (1 + Double(reps) / 30.0)
    }
}

extension LiftEntry {
    var orderedSets: [LiftSet] {
        sets.sorted { $0.order < $1.order }
    }

    /// Heaviest weight lifted for any set in this session.
    var topSetWeight: Double {
        sets.map(\.weight).max() ?? 0
    }

    /// Best estimated one-rep max across the session's sets.
    var bestOneRepMax: Double {
        sets.map(\.estimatedOneRepMax).max() ?? 0
    }

    /// Total weight moved (Σ weight × reps).
    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.weight * Double($1.reps) }
    }
}

// MARK: - Suggested core movements

enum CoreMovement {
    static let suggestions = [
        "Bench Press",
        "Squat",
        "Deadlift",
        "Overhead Press",
        "Barbell Row",
        "Romanian Deadlift",
        "Incline Bench Press",
        "Weighted Pull-Up"
    ]
}

// MARK: - Formatting

enum LiftFormat {
    /// Formats a canonical kilogram weight in the given unit, dropping a
    /// trailing ".0".
    static func weight(_ kilograms: Double, in unit: WeightUnit) -> String {
        formatted(unit.value(fromKilograms: kilograms), in: unit)
    }

    /// Formats a value already expressed in `unit`, dropping a trailing ".0".
    static func formatted(_ value: Double, in unit: WeightUnit) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "\(Int(rounded)) \(unit.abbreviation)"
        }
        return String(format: "%.1f %@", rounded, unit.abbreviation)
    }
}
