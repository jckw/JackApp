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
        }
    }
}

#Preview {
    ContentView()
}
