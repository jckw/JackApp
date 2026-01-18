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

    @State private var oatmealChecked = false
    @State private var showingBodyProgress = false
    @State private var proteinPowderChecked = false
    @State private var flatWhiteChecked = false
    @State private var pizzaSlices = 0
    @State private var bagelChecked = false
    @State private var loxChecked = false
    @State private var lunchDinnerSplit: Double = 0.6
    
    struct Macros {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let sugar: Int
    }
    
    private let oatmealMacros = Macros(calories: 210, protein: 7, carbs: 38, fat: 4, sugar: 12)
    private let proteinPowderMacros = Macros(calories: 120, protein: 24, carbs: 3, fat: 1, sugar: 1)
    private let flatWhiteMacros = Macros(calories: 180, protein: 9, carbs: 14, fat: 10, sugar: 13)
    private let pizzaMacros = Macros(calories: 290, protein: 12, carbs: 36, fat: 11, sugar: 4)
    private let bagelMacros = Macros(calories: 450, protein: 16, carbs: 54, fat: 18, sugar: 6)
    private let loxMacros = Macros(calories: 150, protein: 20, carbs: 0, fat: 7, sugar: 0)
    
    private var breakfastCalories: Int {
        var total = 0
        if oatmealChecked { total += oatmealMacros.calories }
        if oatmealChecked && proteinPowderChecked { total += proteinPowderMacros.calories }
        if flatWhiteChecked { total += flatWhiteMacros.calories }
        return total
    }
    
    private var generalCalories: Int {
        var total = 0
        total += pizzaSlices * pizzaMacros.calories
        if bagelChecked { total += bagelMacros.calories }
        if bagelChecked && loxChecked { total += loxMacros.calories }
        return total
    }
    
    private var totalConsumed: Int {
        breakfastCalories + generalCalories
    }
    
    private var totalProtein: Int {
        var total = 0
        if oatmealChecked { total += oatmealMacros.protein }
        if oatmealChecked && proteinPowderChecked { total += proteinPowderMacros.protein }
        if flatWhiteChecked { total += flatWhiteMacros.protein }
        total += pizzaSlices * pizzaMacros.protein
        if bagelChecked { total += bagelMacros.protein }
        if bagelChecked && loxChecked { total += loxMacros.protein }
        return total
    }
    
    private var totalCarbs: Int {
        var total = 0
        if oatmealChecked { total += oatmealMacros.carbs }
        if oatmealChecked && proteinPowderChecked { total += proteinPowderMacros.carbs }
        if flatWhiteChecked { total += flatWhiteMacros.carbs }
        total += pizzaSlices * pizzaMacros.carbs
        if bagelChecked { total += bagelMacros.carbs }
        if bagelChecked && loxChecked { total += loxMacros.carbs }
        return total
    }
    
    private var totalFat: Int {
        var total = 0
        if oatmealChecked { total += oatmealMacros.fat }
        if oatmealChecked && proteinPowderChecked { total += proteinPowderMacros.fat }
        if flatWhiteChecked { total += flatWhiteMacros.fat }
        total += pizzaSlices * pizzaMacros.fat
        if bagelChecked { total += bagelMacros.fat }
        if bagelChecked && loxChecked { total += loxMacros.fat }
        return total
    }
    
    private var totalSugar: Int {
        var total = 0
        if oatmealChecked { total += oatmealMacros.sugar }
        if oatmealChecked && proteinPowderChecked { total += proteinPowderMacros.sugar }
        if flatWhiteChecked { total += flatWhiteMacros.sugar }
        total += pizzaSlices * pizzaMacros.sugar
        if bagelChecked { total += bagelMacros.sugar }
        if bagelChecked && loxChecked { total += loxMacros.sugar }
        return total
    }
    
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
                    Toggle(isOn: $oatmealChecked) {
                        HStack {
                            Text("🥣")
                            Text("Instant Oatmeal")
                            Spacer()
                            Text("\(oatmealMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if oatmealChecked {
                        Toggle(isOn: $proteinPowderChecked) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Protein Powder")
                                Spacer()
                                Text("+\(proteinPowderMacros.calories) kcal")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.leading, 24)
                    }
                    
                    Toggle(isOn: $flatWhiteChecked) {
                        HStack {
                            Text("☕️")
                            Text("Flat White (10oz)")
                            Spacer()
                            Text("\(flatWhiteMacros.calories) kcal")
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
                    
                    Toggle(isOn: $bagelChecked) {
                        HStack {
                            Text("🥯")
                            Text("Cream cheese bagel")
                            Spacer()
                            Text("\(bagelMacros.calories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if bagelChecked {
                        Toggle(isOn: $loxChecked) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Lox")
                                Spacer()
                                Text("+\(loxMacros.calories) kcal")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.leading, 24)
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
