//
//  HealthKitManager.swift
//  JackApp
//
//  Created by Jack on 02/08/2026.
//

import Foundation
import HealthKit

/// Reads today's Active Energy Burned from Apple Health so custom nutrition
/// days can be pre-filled from the watch's move ring instead of typed in by
/// hand. Read-only — the app never writes back to Health.
@MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    private let activeEnergyType = HKQuantityType(.activeEnergyBurned)

    /// Whether HealthKit data exists on this device (false on iPad, in some
    /// Simulators, and where the framework is otherwise unavailable).
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private init() {}

    /// Prompts for read access to Active Energy Burned. Safe to call repeatedly:
    /// iOS only shows the sheet the first time, and for privacy it never reveals
    /// whether read access was actually granted.
    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: [activeEnergyType])
    }

    /// Sum of Active Energy Burned (kcal) from midnight until now, matching the
    /// figure the Fitness app shows on the move ring. Returns 0 when there is no
    /// data — or when the user declined read access, which HealthKit reports the
    /// same way — so callers should treat 0 as "nothing to sync".
    func todayActiveEnergy() async throws -> Double {
        guard isAvailable else { return 0 }

        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let kcal = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: kcal)
            }
            store.execute(query)
        }
    }
}
