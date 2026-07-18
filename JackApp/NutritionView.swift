//
//  NutritionView.swift
//  JackApp
//
//  Created by Jack on 30/12/2025.
//

import SwiftUI

struct Macros {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let sugar: Int
}

struct Meal: Identifiable {
    let id: String
    let emoji: String
    let name: String
    let section: MealSection
    let macros: Macros
}

enum MealSection: String, CaseIterable {
    case breakfast = "Breakfast"
    case snacks = "Snacks"
    case meals = "Meals"
}

struct MacroTargets {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

enum DayType: String, CaseIterable, Identifiable {
    case rest = "Rest"
    case training = "Training"
    case endurance = "Long run"

    var id: String { rawValue }

    func targets(for mode: NutritionMode) -> MacroTargets {
        switch mode {
        case .cut:
            switch self {
            case .rest:      return MacroTargets(calories: 1900, protein: 175, carbs: 165, fat: 60)
            case .training:  return MacroTargets(calories: 2450, protein: 175, carbs: 310, fat: 57)
            case .endurance: return MacroTargets(calories: 2950, protein: 180, carbs: 420, fat: 61)
            }
        case .maintenance:
            // TDEE estimate via Katch-McArdle (5'11", 27yo male, 170lb, 17% bf) scaled by day-type activity.
            switch self {
            case .rest:      return MacroTargets(calories: 2400, protein: 170, carbs: 250, fat: 80)
            case .training:  return MacroTargets(calories: 2700, protein: 175, carbs: 320, fat: 80)
            case .endurance: return MacroTargets(calories: 3000, protein: 180, carbs: 390, fat: 80)
            }
        }
    }
}

private let allMeals: [Meal] = [
    // MARK: - Breakfast

    Meal(
        id: "oatmeal_whey",
        emoji: "🥣",
        name: "Oatmeal + whey",
        section: .breakfast,
        macros: Macros(
            calories: 330,
            protein: 31,
            carbs: 41,
            fat: 5,
            sugar: 13
        )
    ),

    Meal(
        id: "greek_yog_whey_fruit",
        emoji: "🫙",
        name: "200g 0% Greek yog, whey, forest fruits",
        section: .breakfast,
        macros: Macros(
            calories: 285,
            protein: 45,
            carbs: 23,
            fat: 1,
            sugar: 15
        )
    ),

    // MARK: - Snacks

    Meal(
        id: "lucky_charms_cup",
        emoji: "🌈",
        name: "Cup of dry Lucky Charms",
        section: .snacks,
        macros: Macros(
            calories: 140,
            protein: 3,
            carbs: 30,
            fat: 2,
            sugar: 12
        )
    ),

    Meal(
        id: "barebells_bar",
        emoji: "🍫",
        name: "Barebells protein bar",
        section: .snacks,
        macros: Macros(
            calories: 200,
            protein: 20,
            carbs: 15,
            fat: 7,
            sugar: 1
        )
    ),

    Meal(
        id: "fig_bar_packet",
        emoji: "🍪",
        name: "Fig bar packet",
        section: .snacks,
        macros: Macros(
            calories: 200,
            protein: 3,
            carbs: 38,
            fat: 5,
            sugar: 19
        )
    ),

    Meal(
        id: "rice_krispies_treat",
        emoji: "🍘",
        name: "Rice Krispies Treat",
        section: .snacks,
        macros: Macros(
            calories: 90,
            protein: 1,
            carbs: 17,
            fat: 2,
            sugar: 8
        )
    ),

    Meal(
        id: "flat_white",
        emoji: "☕️",
        name: "Flat White (10oz)",
        section: .snacks,
        macros: Macros(
            calories: 180,
            protein: 9,
            carbs: 14,
            fat: 10,
            sugar: 13
        )
    ),

    Meal(
        id: "gatorade_20oz",
        emoji: "🥤",
        name: "Gatorade (20oz)",
        section: .snacks,
        macros: Macros(
            calories: 140,
            protein: 0,
            carbs: 36,
            fat: 0,
            sugar: 34
        )
    ),

    Meal(
        id: "pain_au_chocolat",
        emoji: "🥐",
        name: "Pain au chocolat",
        section: .snacks,
        macros: Macros(
            calories: 300,
            protein: 6,
            carbs: 30,
            fat: 17,
            sugar: 9
        )
    ),

    // MARK: - Meals

    Meal(
        id: "small_bagel_cream_cheese",
        emoji: "🥯",
        name: "Smaller bagel w cream cheese",
        section: .meals,
        macros: Macros(
            calories: 350,
            protein: 10,
            carbs: 50,
            fat: 11,
            sugar: 5
        )
    ),

    Meal(
        id: "normal_bagel_cream_cheese",
        emoji: "🥯",
        name: "Normal bagel w cream cheese",
        section: .meals,
        macros: Macros(
            calories: 520,
            protein: 16,
            carbs: 65,
            fat: 20,
            sugar: 7
        )
    ),

    Meal(
        id: "sweetgreen_hot_honey_chicken",
        emoji: "🥗",
        name: "Sweetgreen Hot Honey Chicken",
        section: .meals,
        macros: Macros(
            calories: 875,
            protein: 49,
            carbs: 68,
            fat: 41,
            sugar: 10
        )
    ),

    Meal(
        id: "sweetgreen_double_chicken_bowl",
        emoji: "🥗",
        name: "Sweetgreen double chicken bowl",
        section: .meals,
        macros: Macros(
            calories: 850,
            protein: 55,
            carbs: 65,
            fat: 35,
            sugar: 10
        )
    ),

    Meal(
        id: "bone_broth_rice_chicken_broccoli",
        emoji: "🍲",
        name: "200g bone broth rice, 180g chicken thigh, broccoli",
        section: .meals,
        macros: Macros(
            calories: 650,
            protein: 54,
            carbs: 63,
            fat: 20,
            sugar: 3
        )
    )
]

private let pizzaMacros = Macros(
    calories: 350,
    protein: 14,
    carbs: 40,
    fat: 15,
    sugar: 4
)

struct NutritionView: View {
    @AppStorage(NutritionMode.storageKey) private var nutritionMode: NutritionMode = .default
    @State private var dayType: DayType = .rest
    @State private var checkedIDs: Set<String> = []
    @State private var pizzaSlices = 0
    @State private var lunchDinnerSplit: Double = 0.6
    @State private var showingBodyProgress = false
    @State private var macrosMeal: Meal?

    private var targets: MacroTargets { dayType.targets(for: nutritionMode) }
    private var dailyTarget: Int { targets.calories }
    private var proteinTarget: Int { targets.protein }

    private var consumedMacros: Macros {
        let checked = allMeals.filter { checkedIDs.contains($0.id) }.map(\.macros)
        let pizza = (0..<pizzaSlices).map { _ in pizzaMacros }
        let all = checked + pizza
        return Macros(
            calories: all.reduce(0) { $0 + $1.calories },
            protein:  all.reduce(0) { $0 + $1.protein },
            carbs:    all.reduce(0) { $0 + $1.carbs },
            fat:      all.reduce(0) { $0 + $1.fat },
            sugar:    all.reduce(0) { $0 + $1.sugar }
        )
    }

    private var remainingForMeals: Int { max(0, dailyTarget - consumedMacros.calories) }
    private var lunchBudget: Int { Int(Double(remainingForMeals) * lunchDinnerSplit) }
    private var dinnerBudget: Int { remainingForMeals - lunchBudget }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Day Type", selection: $dayType) {
                        ForEach(DayType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Target")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(consumedMacros.calories) / \(dailyTarget) kcal")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        CircularProgressView(
                            progress: Double(consumedMacros.calories) / Double(dailyTarget),
                            color: consumedMacros.calories > dailyTarget ? .red : .green
                        )
                        .frame(width: 60, height: 60)
                        .onLongPressGesture(minimumDuration: 1.0) {
                            openBodyProgress()
                        }
                    }
                    .padding(.vertical, 8)
                }

                ForEach(MealSection.allCases, id: \.self) { section in
                    Section(section.rawValue) {
                        ForEach(allMeals.filter { $0.section == section }) { meal in
                            Toggle(isOn: Binding(
                                get: { checkedIDs.contains(meal.id) },
                                set: { if $0 { checkedIDs.insert(meal.id) } else { checkedIDs.remove(meal.id) } }
                            )) {
                                HStack {
                                    Text(meal.emoji)
                                    Text(meal.name)
                                    Spacer()
                                    Text("\(meal.macros.calories) kcal")
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onLongPressGesture {
                                    showMacros(for: meal)
                                }
                            }
                        }
                    }
                }

                Section("General") {
                    Stepper(value: $pizzaSlices, in: 0...10) {
                        HStack {
                            Text("🍕")
                            Text("Pizza Slice")
                            Spacer()
                            if pizzaSlices > 0 {
                                Text("\(pizzaSlices) × \(pizzaMacros.calories) = \(pizzaSlices * pizzaMacros.calories) kcal")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(pizzaMacros.calories) kcal")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Lunch & Dinner Budget") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Remaining: \(remainingForMeals) kcal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Lunch")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(lunchBudget) kcal")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Dinner")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(dinnerBudget) kcal")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.purple)
                            }
                        }

                        Slider(value: $lunchDinnerSplit, in: 0.3...0.7, step: 0.05)
                            .tint(.orange)

                        Text("Lunch \(Int(lunchDinnerSplit * 100))% / Dinner \(Int((1 - lunchDinnerSplit) * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical, 8)
                }

                Section("Macros") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Protein")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(consumedMacros.protein) / \(proteinTarget)g")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        CircularProgressView(
                            progress: Double(consumedMacros.protein) / Double(proteinTarget),
                            color: consumedMacros.protein >= proteinTarget ? .green : .blue
                        )
                        .frame(width: 50, height: 50)
                    }
                    .padding(.vertical, 8)

                    MacroBarView(label: "Carbs", value: consumedMacros.carbs, color: .orange, target: targets.carbs)
                    MacroBarView(label: "Fat",   value: consumedMacros.fat,   color: .purple, target: targets.fat)
                    MacroBarView(label: "Sugar", value: consumedMacros.sugar, color: .pink)
                }
            }
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .disabled(checkedIDs.isEmpty && pizzaSlices == 0)
                }
            }
            .fullScreenCover(isPresented: $showingBodyProgress) {
                BodyProgressView()
            }
            .alert(
                macrosMeal.map { "\($0.emoji) \($0.name)" } ?? "",
                isPresented: Binding(
                    get: { macrosMeal != nil },
                    set: { if !$0 { macrosMeal = nil } }
                ),
                presenting: macrosMeal
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { meal in
                Text(
                    """
                    \(meal.macros.calories) kcal
                    Protein \(meal.macros.protein)g
                    Carbs \(meal.macros.carbs)g
                    Fat \(meal.macros.fat)g
                    Sugar \(meal.macros.sugar)g
                    """
                )
            }
        }
    }

    private func reset() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        withAnimation {
            checkedIDs.removeAll()
            pizzaSlices = 0
        }
    }

    private func showMacros(for meal: Meal) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        macrosMeal = meal
    }

    private func openBodyProgress() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        showingBodyProgress = true
    }
}

struct MacroBarView: View {
    let label: String
    let value: Int
    let color: Color
    var target: Int? = nil

    private var scale: CGFloat {
        if let target, target > 0 { return CGFloat(target) }
        return 200
    }

    private var valueText: String {
        if let target { return "\(value)/\(target)g" }
        return "\(value)g"
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .frame(width: 50, alignment: .leading)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: min(CGFloat(value) / scale * geometry.size.width, geometry.size.width))
                        .animation(.easeInOut, value: value)
                }
            }
            .frame(height: 8)
            Text(valueText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .trailing)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 6)
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    NutritionView()
}
