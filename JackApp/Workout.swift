//
//  Workout.swift
//  JackApp
//
//  Created by Jack on 30/12/2025.
//

import Foundation
import SwiftUI

struct Workout: Identifiable {
    let id = UUID()
    let name: String
    let letter: String
    let focus: String
    let description: String
    let color: Color
    let icon: String
    let blocks: [WorkoutBlock]
}

struct WorkoutBlock: Identifiable {
    let id = UUID()
    let type: BlockType
    let exercises: [Exercise]
    let repeatCount: Int?
    
    enum BlockType {
        case warmup
        case work
    }
    
    init(type: BlockType, exercises: [Exercise], repeatCount: Int? = nil) {
        self.type = type
        self.exercises = exercises
        self.repeatCount = repeatCount
    }
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: String
    let isOptional: Bool
    let icon: String
    
    init(name: String, sets: String, isOptional: Bool = false, icon: String = "dumbbell.fill") {
        self.name = name
        self.sets = sets
        self.isOptional = isOptional
        self.icon = icon
    }
}

extension Workout {
    static let workoutA = Workout(
        name: "Workout A",
        letter: "A",
        focus: "Bench Focus",
        description: "Chest and triceps focused session with horizontal pressing movements",
        color: Color.orange,
        icon: "figure.strengthtraining.traditional",
        blocks: [
            WorkoutBlock(type: .warmup, exercises: [
                Exercise(name: "Light cardio & dynamic stretches", sets: "5 min", icon: "figure.walk")
            ]),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "DB or BB Bench Press", sets: "4×6–8")
            ], repeatCount: 4),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Chest-Supported Row", sets: "3×8–10")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "45° Back Extension (glute bias)", sets: "3×10–12")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Incline DB Fly or Cable Fly", sets: "3×10–12")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Face Pull", sets: "3×12–15")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Rope triceps pushdown", sets: "2×10–12", isOptional: true)
            ], repeatCount: 2)
        ]
    )
    
    static let workoutB = Workout(
        name: "Workout B",
        letter: "B",
        focus: "Overhead Press Focus",
        description: "Shoulders and biceps focused session with vertical pressing movements",
        color: Color.purple,
        icon: "figure.arms.open",
        blocks: [
            WorkoutBlock(type: .warmup, exercises: [
                Exercise(name: "Light cardio & shoulder mobility", sets: "5 min", icon: "figure.walk")
            ]),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Overhead Press (DB or BB)", sets: "4×6–8")
            ], repeatCount: 4),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Lat Pulldown or Assisted Pull-Up", sets: "4×8–10")
            ], repeatCount: 4),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Romanian Deadlift (DB or cable pull-through)", sets: "3×8–10")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Cable Lateral Raise", sets: "3×12–15")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Preacher Curl", sets: "2×10–12")
            ], repeatCount: 2),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Cable crunch", sets: "2×12–15", isOptional: true)
            ], repeatCount: 2)
        ]
    )
    
    static let workoutC = Workout(
        name: "Workout C",
        letter: "C",
        focus: "Shoulder Focus",
        description: "Shoulder and horizontal pulling focused full body session",
        color: Color.teal,
        icon: "figure.arms.open",
        blocks: [
            WorkoutBlock(type: .warmup, exercises: [
                Exercise(name: "Light cardio & shoulder mobility", sets: "5 min", icon: "figure.walk")
            ]),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "DB Shoulder Press or Arnold Press", sets: "4×6–8")
            ], repeatCount: 4),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Chest-Supported Row or T-Bar Row", sets: "3×8–10")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Leg Press or Front Squat", sets: "3×8–10", icon: "figure.strengthtraining.functional")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Incline DB Bench or Machine Press", sets: "3×10–12")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Cable or DB Lateral Raise", sets: "3×12–15")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Face Pull or Rear-Delt Fly", sets: "2×12–15", isOptional: true)
            ], repeatCount: 2)
        ]
    )

    static let workoutD = Workout(
        name: "Workout D",
        letter: "D",
        focus: "Horizontal Pull / Chest Accessory",
        description: "Row variations and chest accessories with glute-biased leg work",
        color: Color.indigo,
        icon: "figure.rowing",
        blocks: [
            WorkoutBlock(type: .warmup, exercises: [
                Exercise(name: "Light cardio & upper back stretches", sets: "5 min", icon: "figure.walk")
            ]),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Chest-Supported Row (variation)", sets: "4×6–8")
            ], repeatCount: 4),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "DB Bench Press (variation)", sets: "3×8–10")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Single-Leg Leg Press or Split Squat", sets: "3×8–10 each", icon: "figure.strengthtraining.functional")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Cable Fly (variation)", sets: "3×10–12")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Straight-Arm Pulldown", sets: "3×10–12")
            ], repeatCount: 3),
            WorkoutBlock(type: .work, exercises: [
                Exercise(name: "Incline DB Curl or Band Pull-Aparts", sets: "2×10–12 / 2×20", isOptional: true)
            ], repeatCount: 2)
        ]
    )
}
