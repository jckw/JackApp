import Foundation
import SwiftData

@Model
final class NutritionDay {
    var date: Date
    var dayTypeRaw: String
    var selectedMealIDs: [String]
    var pizzaSlices: Int
    var lunchDinnerSplit: Double

    // Mirrors last-written Health values so we can skip no-op syncs
    var syncedCalories: Int?
    var syncedProtein: Int?
    var syncedCarbs: Int?
    var syncedFat: Int?
    var syncedSugar: Int?

    init(date: Date) {
        self.date = date
        self.dayTypeRaw = DayType.rest.rawValue
        self.selectedMealIDs = []
        self.pizzaSlices = 0
        self.lunchDinnerSplit = 0.6
    }

    func matchesSynced(_ macros: Macros) -> Bool {
        syncedCalories == macros.calories &&
        syncedProtein  == macros.protein  &&
        syncedCarbs    == macros.carbs    &&
        syncedFat      == macros.fat      &&
        syncedSugar    == macros.sugar
    }

    func recordSync(_ macros: Macros) {
        syncedCalories = macros.calories
        syncedProtein  = macros.protein
        syncedCarbs    = macros.carbs
        syncedFat      = macros.fat
        syncedSugar    = macros.sugar
    }
}
