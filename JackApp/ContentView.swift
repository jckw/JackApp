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
            WorkoutsView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }
            
            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
        }
    }
}

#Preview {
    ContentView()
}
