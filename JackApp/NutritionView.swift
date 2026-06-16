//
//  NutritionView.swift
//  JackApp
//
//  Created by Jack on 30/12/2025.
//

import SwiftUI

struct NutritionView: View {
    private let dailyTarget = 1950
    private let proteinTarget = 150

    @State private var oatmealWheyChecked = false
    @State private var greekYogurtChecked = false
    @State private var luckyCharmsChecked = false
    @State private var bareballsChecked = false
    @State private var figBarChecked = false
    @State private var riceKrispiesChecked = false
    @State private var smallBagelChecked = false
    @State private var normalBagelChecked = false
    @State private var sweetgreenChecked = false
    @State private var boneBrothBowlChecked = false
    @State private var pizzaSlices = 0
    @State private var showingBodyProgress = false
    @State private var lunchDinnerSplit: Double = 0.6

    struct Macros {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let sugar: Int
    }

    private let oatmealWheyMacros = Macros(calories: 330, protein: 31, carbs: 41, fat: 5, sugar: 13)
    private let greekYogurtMacros = Macros(calories: 285, protein: 45, carbs: 23, fat: 1, sugar: 15)
    private let luckyCharmsMacros = Macros(calories: 150, protein: 3, carbs: 30, fat: 2, sugar: 13)
    private let bareballsMacros = Macros(calories: 200, protein: 20, carbs: 15, fat: 7, sugar: 1)
    private let figBarMacros = Macros(calories: 100, protein: 1, carbs: 20, fat: 2, sugar: 11)
    private let riceKrispiesMacros = Macros(calories: 90, protein: 1, carbs: 17, fat: 2, sugar: 8)
    private let smallBagelMacros = Macros(calories: 270, protein: 8, carbs: 38, fat: 8, sugar: 4)
    private let normalBagelMacros = Macros(calories: 450, protein: 16, carbs: 54, fat: 18, sugar: 6)
    private let sweetgreenMacros = Macros(calories: 850, protein: 65, carbs: 65, fat: 30, sugar: 10)
    private let boneBrothBowlMacros = Macros(calories: 615, protein: 54, carbs: 63, fat: 15, sugar: 3)
    private let pizzaMacros = Macros(calories: 290, protein: 12, carbs: 36, fat: 11, sugar: 4)

    private var allConsumed: [Macros] {
        var items: [Macros] = []
        if oatmealWheyChecked { items.append(oatmealWheyMacros) }
        if greekYogurtChecked { items.append(greekYogurtMacros) }
        if luckyCharmsChecked { items.append(luckyCharmsMacros) }
        if bareballsChecked { items.append(bareballsMacros) }
        if figBarChecked { items.append(figBarMacros) }
        if riceKrispiesChecked { items.append(riceKrispiesMacros) }
        if smallBagelChecked { items.append(smallBagelMacros) }
        if normalBagelChecked { items.append(normalBagelMacros) }
        if sweetgreenChecked { items.append(sweetgreenMacros) }
        if boneBrothBowlChecked { items.append(boneBrothBowlMacros) }
        for _ in 0..<pizzaSlices { items.append(pizzaMacros) }
        return items
    }

    private var totalConsumed: Int { allConsumed.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Int { allConsumed.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Int { allConsumed.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Int { allConsumed.reduce(0) { $0 + $1.fat } }
    private var totalSugar: Int { allConsumed.reduce(0) { $0 + $1.sugar } }

    private var remainingForMeals: Int {
        max(0, dailyTarget - totalConsumed)
    }

    private var lunchBudget: Int {
        Int(Double(remainingForMeals) * lunchDinnerSplit)
    }

    private var dinnerBudget: Int {
        remainingForMeals - lunchBudget
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Target")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(totalConsumed) / \(dailyTarget) kcal")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        CircularProgressView(
                            progress: Double(totalConsumed) / Double(dailyTarget),
                            color: totalConsumed > dailyTarget ? .red : .green
                        )
                        .frame(width: 60, height: 60)
                        .onLongPressGesture(minimumDuration: 1.0) {
                            openBodyProgress()
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Breakfast") {
                    Toggle(isOn: $oatmealWheyChecked) {
                        HStack {
                            Text("🥣")
                            Text("Oatmeal + whey")
                            Spacer()
                            Text("\(oatmealWheyMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $greekYogurtChecked) {
                        HStack {
                            Text("🫙")
                            Text("200g 0% Greek yog, whey, forest fruits")
                            Spacer()
                            Text("\(greekYogurtMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Snacks") {
                    Toggle(isOn: $luckyCharmsChecked) {
                        HStack {
                            Text("🌈")
                            Text("Cup of dry Lucky Charms")
                            Spacer()
                            Text("\(luckyCharmsMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $bareballsChecked) {
                        HStack {
                            Text("🍫")
                            Text("Barebells protein bar")
                            Spacer()
                            Text("\(bareballsMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $figBarChecked) {
                        HStack {
                            Text("🍪")
                            Text("Fig bar")
                            Spacer()
                            Text("\(figBarMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $riceKrispiesChecked) {
                        HStack {
                            Text("🍘")
                            Text("Rice Krispies treat")
                            Spacer()
                            Text("\(riceKrispiesMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Meals") {
                    Toggle(isOn: $smallBagelChecked) {
                        HStack {
                            Text("🥯")
                            Text("Smaller bagel w cream cheese")
                            Spacer()
                            Text("\(smallBagelMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $normalBagelChecked) {
                        HStack {
                            Text("🥯")
                            Text("Normal bagel w cream cheese")
                            Spacer()
                            Text("\(normalBagelMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $sweetgreenChecked) {
                        HStack {
                            Text("🥗")
                            Text("850 kcal double chicken Sweetgreen")
                            Spacer()
                            Text("\(sweetgreenMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $boneBrothBowlChecked) {
                        HStack {
                            Text("🍲")
                            Text("200g bone broth rice, 180g chicken thigh, broccoli")
                            Spacer()
                            Text("\(boneBrothBowlMacros.calories) kcal")
                                .foregroundStyle(.secondary)
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
                            Text("\(totalProtein) / \(proteinTarget)g")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        CircularProgressView(
                            progress: Double(totalProtein) / Double(proteinTarget),
                            color: totalProtein >= proteinTarget ? .green : .blue
                        )
                        .frame(width: 50, height: 50)
                    }
                    .padding(.vertical, 8)

                    MacroBarView(label: "Carbs", value: totalCarbs, color: .orange)
                    MacroBarView(label: "Fat", value: totalFat, color: .purple)
                    MacroBarView(label: "Sugar", value: totalSugar, color: .pink)
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
