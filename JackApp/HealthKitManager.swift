import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitManager {
    private let store = HKHealthStore()
    @ObservationIgnored private var debounceTask: Task<Void, Never>?

    var isAuthorized = false

    private static let dietaryTypes: Set<HKSampleType> = [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietarySugar),
    ]

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await store.requestAuthorization(toShare: Self.dietaryTypes, read: [])
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    // Cancels any pending sync and schedules a new one after 1.5 s of inactivity.
    func scheduleSync(macros: Macros, date: Date, day: NutritionDay) {
        guard isAuthorized, macros.calories > 0 else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await performSync(macros: macros, date: date, day: day)
        }
    }

    // Cancels any pending debounced sync and writes immediately (used on backgrounding).
    func syncNow(macros: Macros, date: Date, day: NutritionDay) async {
        guard isAuthorized, macros.calories > 0 else { return }
        debounceTask?.cancel()
        debounceTask = nil
        await performSync(macros: macros, date: date, day: day)
    }

    // MARK: - Private

    private func performSync(macros: Macros, date: Date, day: NutritionDay) async {
        // Integrity check: skip if Health already has exactly these values from us.
        guard !day.matchesSynced(macros) else { return }

        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return }

        await deleteOurSamples(start: start, end: end)
        await writeSamples(macros: macros, start: start, end: end)
        day.recordSync(macros)
    }

    // Deletes all samples that our app wrote for the given day range.
    // Uses deleteObjects(of:predicate:) which requires only write authorization — no read needed.
    private func deleteOurSamples(start: Date, end: Date) async {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            HKQuery.predicateForSamples(withStart: start, end: end),
            HKQuery.predicateForObjects(from: [HKSource.default()]),
        ])
        for type in Self.dietaryTypes {
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                store.deleteObjects(of: type, predicate: predicate) { _, _, _ in
                    cont.resume()
                }
            }
        }
    }

    private func writeSamples(macros: Macros, start: Date, end: Date) async {
        let samples: [HKQuantitySample] = [
            HKQuantitySample(
                type: HKQuantityType(.dietaryEnergyConsumed),
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: Double(macros.calories)),
                start: start, end: end
            ),
            HKQuantitySample(
                type: HKQuantityType(.dietaryProtein),
                quantity: HKQuantity(unit: .gram(), doubleValue: Double(macros.protein)),
                start: start, end: end
            ),
            HKQuantitySample(
                type: HKQuantityType(.dietaryCarbohydrates),
                quantity: HKQuantity(unit: .gram(), doubleValue: Double(macros.carbs)),
                start: start, end: end
            ),
            HKQuantitySample(
                type: HKQuantityType(.dietaryFatTotal),
                quantity: HKQuantity(unit: .gram(), doubleValue: Double(macros.fat)),
                start: start, end: end
            ),
            HKQuantitySample(
                type: HKQuantityType(.dietarySugar),
                quantity: HKQuantity(unit: .gram(), doubleValue: Double(macros.sugar)),
                start: start, end: end
            ),
        ]
        try? await store.save(samples)
    }
}
