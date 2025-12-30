//
//  WorkoutsView.swift
//  JackApp
//
//  Created by Jack on 30/12/2025.
//

import SwiftUI

struct WorkoutsView: View {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    WorkoutCard(workout: .workoutA)
                    WorkoutCard(workout: .workoutB)
                    WorkoutCard(workout: .workoutC)
                    WorkoutCard(workout: .workoutD)
                }
                .padding()
            }
            .navigationTitle("My Workouts")
        }
    }
}

#Preview {
    WorkoutsView()
}
