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
}

struct SettingsView: View {
    @AppStorage(NutritionMode.storageKey) private var nutritionMode: NutritionMode = .default

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
                } footer: {
                    Text("Maintenance targets are estimated for a 5'11\", 27-year-old male, 170lb at 17% body fat.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
