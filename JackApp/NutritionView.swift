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

private let allMeals: [Meal] = [
    Meal(id: "oatmeal_whey",      emoji: "🥣", name: "Oatmeal + whey",                                    section: .breakfast, macros: Macros(calories: 330, protein: 31, carbs: 41, fat:  5, sugar: 13)),
    Meal(id: "greek_yog",         emoji: "🫙", name: "200g 0% Greek yog, whey, forest fruits",             section: .breakfast, macros: Macros(calories: 285, protein: 45, carbs: 23, fat:  1, sugar: 15)),
    Meal(id: "lucky_charms",      emoji: "🌈", name: "Cup of dry Lucky Charms",                            section: .snacks,    macros: Macros(calories: 150, protein:  3, carbs: 30, fat:  2, sugar: 13)),
    Meal(id: "barebells",         emoji: "🍫", name: "Barebells protein bar",                              section: .snacks,    macros: Macros(calories: 200, protein: 20, carbs: 15, fat:  7, sugar:  1)),
    Meal(id: "fig_bar",           emoji: "🍪", name: "Fig bar",                                            section: .snacks,    macros: Macros(calories: 100, protein:  1, carbs: 20, fat:  2, sugar: 11)),
    Meal(id: "rice_krispies",     emoji: "🍘", name: "Rice Krispies treat",                               section: .snacks,    macros: Macros(calories:  90, protein:  1, carbs: 17, fat:  2, sugar:  8)),
    Meal(id: "small_bagel",       emoji: "🥯", name: "Smaller bagel w cream cheese",                      section: .meals,     macros: Macros(calories: 270, protein:  8, carbs: 38, fat:  8, sugar:  4)),
    Meal(id: "normal_bagel",      emoji: "🥯", name: "Normal bagel w cream cheese",                       section: .meals,     macros: Macros(calories: 450, protein: 16, carbs: 54, fat: 18, sugar:  6)),
    Meal(id: "sweetgreen",        emoji: "🥗", name: "850 kcal double chicken Sweetgreen",                section: .meals,     macros: Macros(calories: 850, protein: 65, carbs: 65, fat: 30, sugar: 10)),
    Meal(id: "bone_broth_bowl",   emoji: "🍲", name: "200g bone broth rice, 180g chicken thigh, broccoli", section: .meals,   macros: Macros(calories: 615, protein: 54, carbs: 63, fat: 15, sugar:  3)),
]

private let pizzaMacros = Macros(calories: 290, protein: 12, carbs: 36, fat: 11, sugar: 4)

struct NutritionView: View {
    private let dailyTarget = 1950
    private let proteinTarget = 150

    @State private var checkedIDs: Set<String> = []
    @State private var pizzaSlices = 0
    @State private var lunchDinnerSplit: Double = 0.6
    @State private var showingBodyProgress = false

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

                    MacroBarView(label: "Carbs", value: consumedMacros.carbs, color: .orange)
                    MacroBarView(label: "Fat",   value: consumedMacros.fat,   color: .purple)
                    MacroBarView(label: "Sugar", value: consumedMacros.sugar, color: .pink)
                }
            }
            .navigationTitle("Nutrition")
            .fullScreenCover(isPresented: $showingBodyProgress) {
                BodyProgressView()
            }
        }
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
                        .frame(width: min(CGFloat(value) / 200.0 * geometry.size.width, geometry.size.width))
                        .animation(.easeInOut, value: value)
                }
            }
            .frame(height: 8)
            Text("\(value)g")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)
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
