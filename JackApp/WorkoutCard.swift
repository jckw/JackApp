//
//  WorkoutCard.swift
//  JackApp
//
//  Created by Jack on 30/12/2025.
//

import SwiftUI

struct WorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        NavigationLink {
            WorkoutDetailView(workout: workout)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Letter in a circle
                ZStack {
                    Circle()
                        .fill(workout.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Text(workout.letter)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(workout.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 0)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.focus)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
            .frame(height: 160)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .simultaneousGesture(TapGesture().onEnded {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        })
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                WorkoutCard(workout: .workoutA)
                WorkoutCard(workout: .workoutB)
                WorkoutCard(workout: .workoutC)
            }
            .padding()
        }
    }
}
