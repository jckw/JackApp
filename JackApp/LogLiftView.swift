//
//  LogLiftView.swift
//  JackApp
//
//  Created by Jack on 03/08/2026.
//

import SwiftData
import SwiftUI

/// Draft for a single set while composing a new log entry.
private struct SetDraft: Identifiable {
    let id = UUID()
    var weight: Double = 0
    var reps: Int = 0

    var isEmpty: Bool { weight == 0 && reps == 0 }
    var isValid: Bool { reps > 0 }
}

struct LogLiftView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WeightUnit.storageKey) private var weightUnit: WeightUnit = .default

    /// When presented from an exercise's history, its name is pre-filled and locked.
    var prefilledExercise: String?

    @Query(sort: \LiftEntry.date, order: .reverse) private var entries: [LiftEntry]

    @State private var exerciseName = ""
    @State private var date = Date()
    @State private var sets: [SetDraft] = [SetDraft()]

    init(prefilledExercise: String? = nil) {
        self.prefilledExercise = prefilledExercise
        _exerciseName = State(initialValue: prefilledExercise ?? "")
    }

    /// Recently used names first, then any core movements not yet used.
    private var suggestions: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for entry in entries where !seen.contains(entry.exerciseName) {
            seen.insert(entry.exerciseName)
            result.append(entry.exerciseName)
        }
        for movement in CoreMovement.suggestions where !seen.contains(movement) {
            seen.insert(movement)
            result.append(movement)
        }
        return result
    }

    private var bestOneRepMax: Double {
        sets.filter(\.isValid)
            .map { $0.reps <= 1 ? $0.weight : $0.weight * (1 + Double($0.reps) / 30.0) }
            .max() ?? 0
    }

    private var canSave: Bool {
        !exerciseName.trimmingCharacters(in: .whitespaces).isEmpty
            && sets.contains(where: \.isValid)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("e.g. Bench Press", text: $exerciseName)
                        .autocorrectionDisabled()

                    if prefilledExercise == nil {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { name in
                                    Button {
                                        exerciseName = name
                                    } label: {
                                        Text(name)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                exerciseName == name
                                                    ? Color.accentColor.opacity(0.2)
                                                    : Color(.tertiarySystemBackground)
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    }
                }

                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section {
                    ForEach(sets.indices, id: \.self) { index in
                        HStack(spacing: 12) {
                            Text("Set \(index + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 48, alignment: .leading)

                            TextField("0", value: $sets[index].weight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity)
                            Text(weightUnit.abbreviation)
                                .foregroundStyle(.secondary)

                            Text("×")
                                .foregroundStyle(.secondary)

                            TextField("0", value: $sets[index].reps, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 48)
                            Text("reps")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in
                        sets.remove(atOffsets: offsets)
                        if sets.isEmpty { sets = [SetDraft()] }
                    }

                    Button {
                        // Pre-fill the new set from the last one for quick entry.
                        var draft = SetDraft()
                        if let last = sets.last {
                            draft.weight = last.weight
                            draft.reps = last.reps
                        }
                        sets.append(draft)
                    } label: {
                        Label("Add Set", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Sets")
                } footer: {
                    if bestOneRepMax > 0 {
                        Text("Estimated 1RM this session: \(LiftFormat.formatted(bestOneRepMax, in: weightUnit))")
                    }
                }
            }
            .navigationTitle(prefilledExercise ?? "Log Lift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let name = exerciseName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let entry = LiftEntry(exerciseName: name, date: date)
        modelContext.insert(entry)

        var order = 0
        for draft in sets where draft.isValid {
            // Drafts are entered in the user's chosen unit; store canonical kg.
            let set = LiftSet(weight: weightUnit.kilograms(from: draft.weight), reps: draft.reps, order: order)
            modelContext.insert(set)
            // Setting the inverse updates entry.sets automatically.
            set.entry = entry
            order += 1
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        dismiss()
    }
}

#Preview {
    LogLiftView()
        .modelContainer(for: [LiftEntry.self, LiftSet.self], inMemory: true)
}
