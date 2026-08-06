//
//  SettingsView.swift
//  JackApp
//
//  Created by Jack on 16/07/2026.
//

import SwiftUI

enum NutritionMode: String, CaseIterable, Identifiable {
    case cut = "Cut"
    case maintenance = "Maintenance"

    static let storageKey = "nutritionMode"
    static let `default`: NutritionMode = .cut

    var id: String { rawValue }

    var description: String {
        switch self {
        case .cut:         return "Calorie targets are set at a deficit to lose fat."
        case .maintenance: return "Calorie targets are set at TDEE to maintain current weight."
        }
    }

    /// Daily calorie deficit applied to maintenance to reach the target.
    var calorieDeficit: Double {
        switch self {
        case .cut:         return 500
        case .maintenance: return 0
        }
    }
}

/// The body composition targets are computed from. Persisted via `@AppStorage`
/// so a single current value drives the whole app; defaults preserve the
/// figures the targets were originally hand-tuned for.
struct BodyProfile {
    var weightLb: Double
    var bodyFatPercent: Double

    static let weightKey = "bodyWeightLb"
    static let bodyFatKey = "bodyFatPercent"
    static let defaultWeightLb: Double = 170
    static let defaultBodyFatPercent: Double = 17

    /// Lean body mass in kilograms — the only input Katch-McArdle needs.
    var leanMassKg: Double {
        weightLb * 0.453592 * (1 - bodyFatPercent / 100)
    }

    /// Resting metabolic rate via Katch-McArdle.
    var restingEnergy: Double {
        370 + 21.6 * leanMassKg
    }

    /// Resting metabolic rate, rounded for display.
    var basalMetabolicRate: Int {
        Int(restingEnergy.rounded())
    }
}

struct SettingsView: View {
    @AppStorage(NutritionMode.storageKey) private var nutritionMode: NutritionMode = .default
    @AppStorage(BodyProfile.weightKey) private var weightLb: Double = BodyProfile.defaultWeightLb
    @AppStorage(BodyProfile.bodyFatKey) private var bodyFatPercent: Double = BodyProfile.defaultBodyFatPercent
    @AppStorage(WeightUnit.storageKey) private var weightUnit: WeightUnit = .default
    @AppStorage(PaceUnit.storageKey) private var paceUnit: PaceUnit = .default

    @FocusState private var isFieldFocused: Bool

    private var profile: BodyProfile {
        BodyProfile(weightLb: weightLb, bodyFatPercent: bodyFatPercent)
    }

    /// Body weight in the chosen unit, converting to/from canonical pounds so the
    /// stored value (and every calorie target derived from it) is unchanged.
    private var displayWeight: Binding<Double> {
        Binding(
            get: { weightUnit.value(fromPounds: weightLb) },
            set: { weightLb = weightUnit.pounds(from: $0) }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Nutrition Mode", selection: $nutritionMode) {
                        ForEach(NutritionMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(nutritionMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Nutrition")
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Lifts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Lifts", selection: $weightUnit) {
                            ForEach(WeightUnit.allCases) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .padding(.vertical, 2)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Running")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Running", selection: $paceUnit) {
                            ForEach(PaceUnit.allCases) { unit in
                                Text(unit.systemName).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text("Units")
                } footer: {
                    Text("Choose units independently for lifts and for running. "
                        + "Switching re-expresses your existing data — nothing is "
                        + "re-entered, so your logs read the same in either system.")
                }

                Section {
                    LabeledContent("Weight") {
                        HStack(spacing: 4) {
                            TextField("Weight", value: displayWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($isFieldFocused)
                            Text(weightUnit.abbreviation).foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent("Body Fat") {
                        HStack(spacing: 4) {
                            TextField("Body Fat", value: $bodyFatPercent, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($isFieldFocused)
                            Text("%").foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent("Resting metabolism", value: "\(profile.basalMetabolicRate) kcal")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Body")
                } footer: {
                    Text("Targets are calculated from your weight and body fat using the "
                        + "Katch-McArdle formula, scaled by day type. Update these as your "
                        + "body changes and every target follows.")
                }

                Section {
                    ForEach(DayType.allCases) { day in
                        if let maintenance = day.maintenanceCalories(for: profile) {
                            let targets = MacroTargets.from(maintenance: maintenance, mode: nutritionMode, weightLb: weightLb)
                            LabeledContent(day.rawValue) {
                                Text("\(targets.calories) kcal · P\(targets.protein) C\(targets.carbs) F\(targets.fat)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Daily Targets")
                } footer: {
                    Text("Custom days add the active calories you enter on the Nutrition tab "
                        + "to your resting metabolism.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFieldFocused = false
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
