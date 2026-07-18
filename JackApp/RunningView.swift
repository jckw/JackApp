//
//  RunningView.swift
//  JackApp
//
//  Created by Jack on 18/07/2026.
//

import SwiftUI

enum PaceUnit: String, CaseIterable, Identifiable {
    case km = "/km"
    case mile = "/mile"

    var id: String { rawValue }

    var distanceLabel: String {
        switch self {
        case .km:   return "kilometre"
        case .mile: return "mile"
        }
    }
}

private let metresPerMile = 1609.344

struct RunningView: View {
    /// The pace the user is entering, expressed in the currently selected unit.
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var unit: PaceUnit = .km

    // MARK: - Derived values

    /// Total seconds of the entered pace, in the selected unit's distance.
    private var enteredSeconds: Double { Double(minutes * 60 + seconds) }

    private var secondsPerKm: Double {
        switch unit {
        case .km:   return enteredSeconds
        case .mile: return enteredSeconds / metresPerMile * 1000
        }
    }

    private var secondsPerMile: Double {
        secondsPerKm * metresPerMile / 1000
    }

    private var kmPerHour: Double {
        secondsPerKm > 0 ? 3600 / secondsPerKm : 0
    }

    private var milesPerHour: Double {
        secondsPerMile > 0 ? 3600 / secondsPerMile : 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    paceResultCard
                    unitPicker
                    timePicker
                    speedCard
                    finishTimesCard
                }
                .padding()
            }
            .navigationTitle("Running")
        }
    }

    // MARK: - Pace result

    private var paceResultCard: some View {
        HStack(spacing: 0) {
            paceColumn(
                value: formatPace(secondsPerKm),
                unit: "/km",
                isActive: unit == .km
            )

            Divider()
                .frame(height: 56)

            paceColumn(
                value: formatPace(secondsPerMile),
                unit: "/mile",
                isActive: unit == .mile
            )
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func paceColumn(value: String, unit unitLabel: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isActive ? Color.accentColor : .primary)
            Text(unitLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Unit picker

    private var unitPicker: some View {
        VStack(spacing: 8) {
            Picker("Entering pace in", selection: $unit) {
                ForEach(PaceUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: unit) { oldUnit, newUnit in
                convertEnteredPace(from: oldUnit, to: newUnit)
            }

            Text("Enter your pace per \(unit.distanceLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Time picker

    private var timePicker: some View {
        HStack(spacing: 0) {
            wheel(selection: $minutes, range: 0...59, label: "min")
            Text(":")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            wheel(selection: $seconds, range: 0...59, label: "sec")
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func wheel(selection: Binding<Int>, range: ClosedRange<Int>, label: String) -> some View {
        HStack(spacing: 4) {
            Picker(label, selection: selection) {
                ForEach(range, id: \.self) { value in
                    Text(String(format: "%02d", value))
                        .font(.system(.title2, design: .rounded))
                        .monospacedDigit()
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 140)
            .clipped()

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Speed

    private var speedCard: some View {
        HStack(spacing: 0) {
            speedColumn(value: formatSpeed(kmPerHour), unit: "km/h")
            Divider().frame(height: 40)
            speedColumn(value: formatSpeed(milesPerHour), unit: "mph")
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func speedColumn(value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)
                .monospacedDigit()
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Finish times

    private var finishTimesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Finish times at this pace")
                .font(.headline)
                .padding(.bottom, 12)

            ForEach(Array(RaceDistance.all.enumerated()), id: \.element.name) { index, race in
                HStack {
                    Text(race.name)
                        .font(.subheadline)
                    Spacer()
                    Text(formatDuration(secondsPerKm * race.kilometres))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)

                if index < RaceDistance.all.count - 1 {
                    Divider()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    /// Re-express the entered minutes/seconds when the user switches units, so the
    /// underlying real-world pace stays the same.
    private func convertEnteredPace(from oldUnit: PaceUnit, to newUnit: PaceUnit) {
        guard oldUnit != newUnit else { return }
        let total = Double(minutes * 60 + seconds)
        let converted: Double
        switch newUnit {
        case .mile: converted = total * metresPerMile / 1000  // per km -> per mile
        case .km:   converted = total / metresPerMile * 1000  // per mile -> per km
        }
        let rounded = Int(converted.rounded())
        minutes = min(59, rounded / 60)
        seconds = rounded % 60
    }

    private func formatPace(_ totalSeconds: Double) -> String {
        guard totalSeconds.isFinite, totalSeconds > 0 else { return "–:--" }
        let rounded = Int(totalSeconds.rounded())
        return String(format: "%d:%02d", rounded / 60, rounded % 60)
    }

    private func formatSpeed(_ value: Double) -> String {
        guard value.isFinite, value > 0 else { return "–" }
        return String(format: "%.1f", value)
    }

    private func formatDuration(_ totalSeconds: Double) -> String {
        guard totalSeconds.isFinite, totalSeconds > 0 else { return "–" }
        let s = Int(totalSeconds.rounded())
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let secs = s % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }
}

private struct RaceDistance {
    let name: String
    let kilometres: Double

    static let all: [RaceDistance] = [
        RaceDistance(name: "5K", kilometres: 5),
        RaceDistance(name: "10K", kilometres: 10),
        RaceDistance(name: "Half marathon", kilometres: 21.0975),
        RaceDistance(name: "Marathon", kilometres: 42.195)
    ]
}

#Preview {
    RunningView()
}
