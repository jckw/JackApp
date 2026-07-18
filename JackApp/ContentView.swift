//
//  ContentView.swift
//  JackApp
//
//  Created by Jack on 30/12/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }

            WorkoutsView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }

            RunningView()
                .tabItem {
                    Label("Running", systemImage: "figure.run")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}
