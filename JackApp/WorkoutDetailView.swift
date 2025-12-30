//
//  WorkoutDetailView.swift
//  JackApp
//
//  Created by Jack on 30/12/2025.
//

import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @State private var showSetTracking = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with description
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(workout.color.opacity(0.15))
                            .frame(width: 52, height: 52)
                        
                        Text(workout.letter)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(workout.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.focus)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(workout.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                
                // Blocks
                ForEach(workout.blocks) { block in
                    WorkoutBlockView(
                        block: block,
                        color: workout.color,
                        showSetTracking: $showSetTracking
                    )
                }
            }
            .padding()
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showSetTracking.toggle()
                    }
                } label: {
                    Image(systemName: showSetTracking ? "square.grid.3x3.fill" : "square.grid.3x3")
                        .foregroundStyle(workout.color)
                        .font(.system(size: 20))
                }
            }
        }
    }
}

struct WorkoutBlockView: View {
    let block: WorkoutBlock
    let color: Color
    @Binding var showSetTracking: Bool
    @State private var completedSets: Set<String> = []
    @State private var failedSets: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Block title
            HStack(spacing: 6) {
                Text(block.type == .warmup ? "Warmup" : "Block")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                if let repeatCount = block.repeatCount {
                    Text("·")
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("\(repeatCount) sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Exercises
            ForEach(block.exercises) { exercise in
                ExerciseRow(
                    exercise: exercise,
                    blockRepeatCount: block.repeatCount,
                    color: color,
                    showSetTracking: showSetTracking,
                    completedSets: $completedSets,
                    failedSets: $failedSets
                )
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let blockRepeatCount: Int?
    let color: Color
    let showSetTracking: Bool
    @Binding var completedSets: Set<String>
    @Binding var failedSets: Set<String>
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: exercise.icon)
                    .font(.title3)
                    .foregroundStyle(exercise.isOptional ? Color.secondary : color)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.body)
                        .foregroundStyle(exercise.isOptional ? .secondary : .primary)
                    
                    if exercise.isOptional {
                        Text("Optional")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text(exercise.sets)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            
            // Set tracking
            if showSetTracking, let repeatCount = blockRepeatCount {
                Divider()
                    .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(repeatCount, 4)), spacing: 8) {
                    ForEach(1...repeatCount, id: \.self) { setNum in
                        let key = "\(exercise.id)-\(setNum)"
                        let isComplete = completedSets.contains(key)
                        let isFailed = failedSets.contains(key)
                        
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                if isComplete || isFailed {
                                    completedSets.remove(key)
                                    failedSets.remove(key)
                                } else {
                                    completedSets.insert(key)
                                }
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isFailed ? Color.red.opacity(0.2) : (isComplete ? color.opacity(0.2) : Color(.tertiarySystemBackground)))
                                    .frame(height: 40)
                                
                                if isFailed {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.red)
                                } else if isComplete {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(color)
                                } else {
                                    Text("\(setNum)")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    completedSets.remove(key)
                                    failedSets.insert(key)
                                }
                            } label: {
                                Label("Mark as Failure", systemImage: "xmark.circle")
                            }
                            
                            if isFailed || isComplete {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                        completedSets.remove(key)
                                        failedSets.remove(key)
                                    }
                                } label: {
                                    Label("Clear", systemImage: "arrow.uturn.backward")
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: .workoutA)
    }
}
