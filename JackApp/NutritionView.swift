//
//  NutritionView.swift
//  JackApp
//
//  Created by Jack on 30/12/2025.
//

import SwiftUI

struct NutritionView: View {
    private let dailyTarget = 1950
    
    @State private var oatmealChecked = false
    @State private var proteinPowderChecked = false
    @State private var flatWhiteChecked = false
    @State private var pizzaChecked = false
    @State private var bagelChecked = false
    @State private var lunchDinnerSplit: Double = 0.6
    
    private let oatmealCalories = 210
    private let proteinPowderCalories = 120
    private let flatWhiteCalories = 180
    private let pizzaCalories = 290
    private let bagelCalories = 450
    
    private var breakfastCalories: Int {
        var total = 0
        if oatmealChecked { total += oatmealCalories }
        if proteinPowderChecked { total += proteinPowderCalories }
        if flatWhiteChecked { total += flatWhiteCalories }
        return total
    }
    
    private var generalCalories: Int {
        var total = 0
        if pizzaChecked { total += pizzaCalories }
        if bagelChecked { total += bagelCalories }
        return total
    }
    
    private var totalConsumed: Int {
        breakfastCalories + generalCalories
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
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Breakfast") {
                    Toggle(isOn: $oatmealChecked) {
                        HStack {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(.orange)
                            Text("Instant Oatmeal")
                            Spacer()
                            Text("\(oatmealCalories) kcal")
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
                                Text("+\(proteinPowderCalories) kcal")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.leading, 24)
                    }
                    
                    Toggle(isOn: $flatWhiteChecked) {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                                .foregroundStyle(.brown)
                            Text("Flat White (10oz)")
                            Spacer()
                            Text("\(flatWhiteCalories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("General") {
                    Toggle(isOn: $pizzaChecked) {
                        HStack {
                            Image(systemName: "triangle.fill")
                                .foregroundStyle(.red)
                            Text("Pizza Slice")
                            Spacer()
                            Text("\(pizzaCalories) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $bagelChecked) {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.yellow)
                            Text("Cream cheese bagel")
                            Spacer()
                            Text("\(bagelCalories) kcal")
                                .foregroundStyle(.secondary)
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
            }
            .navigationTitle("Nutrition")
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
