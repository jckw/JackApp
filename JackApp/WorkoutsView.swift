//
//  WorkoutsView.swift
//  JackApp
//
//  Created by Jack on 30/12/2025.
//

import SwiftData
import SwiftUI

/// Per-exercise roll-up shown in the main logger list.
private struct ExerciseSummary: Identifiable {
    let name: String
    let bestOneRepMax: Double
    let topWeight: Double
    let lastDate: Date
    let sessionCount: Int

    var id: String { name }
}

struct WorkoutsView: View {
    @Query(sort: \LiftEntry.date, order: .reverse) private var entries: [LiftEntry]
    @State private var showingLog = false

    private var summaries: [ExerciseSummary] {
        let grouped = Dictionary(grouping: entries, by: \.exerciseName)
        return grouped.map { name, entries in
            ExerciseSummary(
                name: name,
                bestOneRepMax: entries.map(\.bestOneRepMax).max() ?? 0,
                topWeight: entries.map(\.topSetWeight).max() ?? 0,
                lastDate: entries.map(\.date).max() ?? .distantPast,
                sessionCount: entries.count
            )
        }
        .sorted { $0.lastDate > $1.lastDate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if summaries.isEmpty {
                    emptyState
                } else {
                    exerciseList
                }
            }
            .navigationTitle("Lifts")
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
                LogLiftView()
            }
        }
    }

    private var exerciseList: some View {
        List {
            ForEach(summaries) { summary in
                NavigationLink {
                    ExerciseHistoryView(exerciseName: summary.name)
                } label: {
                    ExerciseSummaryRow(summary: summary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No Lifts Logged")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Log your working sets for bench, squat, deadlift and more to track your PBs week by week.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                showingLog = true
            } label: {
                Label("Log a Lift", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .padding()
    }
}

private struct ExerciseSummaryRow: View {
    let summary: ExerciseSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(summary.name)
                    .font(.headline)
                Spacer()
                Text(summary.lastDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                StatBadge(
                    label: "Best est. 1RM",
                    value: LiftFormat.weight(summary.bestOneRepMax)
                )
                StatBadge(
                    label: "Heaviest",
                    value: LiftFormat.weight(summary.topWeight)
                )
                Spacer()
                Text("\(summary.sessionCount) \(summary.sessionCount == 1 ? "session" : "sessions")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Small label-over-value stat used in list rows.
struct StatBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }
}

#Preview {
    WorkoutsView()
        .modelContainer(for: [LiftEntry.self, LiftSet.self], inMemory: true)
}
