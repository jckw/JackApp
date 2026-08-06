//
//  ExerciseHistoryView.swift
//  JackApp
//
//  Created by Jack on 03/08/2026.
//

import SwiftData
import SwiftUI

struct ExerciseHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(WeightUnit.storageKey) private var weightUnit: WeightUnit = .default

    let exerciseName: String
    @Query private var entries: [LiftEntry]
    @State private var showingLog = false

    init(exerciseName: String) {
        self.exerciseName = exerciseName
        let name = exerciseName
        _entries = Query(
            filter: #Predicate<LiftEntry> { $0.exerciseName == name },
            sort: \LiftEntry.date,
            order: .reverse
        )
    }

    private var bestOneRepMax: Double {
        entries.map(\.bestOneRepMax).max() ?? 0
    }

    private var heaviestWeight: Double {
        entries.map(\.topSetWeight).max() ?? 0
    }

    /// The single best set overall (highest estimated 1RM), for the "best set" PB.
    private var bestSet: LiftSet? {
        entries.flatMap(\.sets).max { $0.estimatedOneRepMax < $1.estimatedOneRepMax }
    }

    var body: some View {
        List {
            if !entries.isEmpty {
                Section("Personal Bests") {
                    HStack(spacing: 12) {
                        PBCard(title: "Est. 1RM", value: LiftFormat.weight(bestOneRepMax, in: weightUnit))
                        PBCard(title: "Heaviest", value: LiftFormat.weight(heaviestWeight, in: weightUnit))
                        if let bestSet {
                            PBCard(
                                title: "Best Set",
                                value: "\(LiftFormat.weight(bestSet.weight, in: weightUnit)) × \(bestSet.reps)"
                            )
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            Section("History") {
                ForEach(entries) { entry in
                    SessionRow(
                        entry: entry,
                        isTopWeight: entry.topSetWeight == heaviestWeight && heaviestWeight > 0,
                        weightUnit: weightUnit
                    )
                }
                .onDelete(perform: deleteEntries)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    showingLog = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingLog) {
            LogLiftView(prefilledExercise: exerciseName)
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
    }
}

private struct PBCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SessionRow: View {
    let entry: LiftEntry
    let isTopWeight: Bool
    let weightUnit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if isTopWeight {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                Spacer()
                Text("est. 1RM \(LiftFormat.weight(entry.bestOneRepMax, in: weightUnit))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(entry.orderedSets) { set in
                HStack {
                    Text("\(LiftFormat.weight(set.weight, in: weightUnit)) × \(set.reps)")
                        .font(.subheadline)
                        .monospacedDigit()
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ExerciseHistoryView(exerciseName: "Bench Press")
    }
    .modelContainer(for: [LiftEntry.self, LiftSet.self], inMemory: true)
}
