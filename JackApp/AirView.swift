//
//  AirView.swift
//  JackApp
//
//  Live readings from the Aranet4 at home, relayed by an ESP32 to a Cloudflare Worker,
//  plus the heater's power draw from a Shelly plug that posts to the same Worker.
//  The read token is entered once in the app and kept in the Keychain, never in source.
//

import Charts
import Security
import SwiftUI

// MARK: - Model

struct AirReading: Decodable, Identifiable {
    let ts: TimeInterval
    let temperature: Double
    let humidity: Int
    let pressure: Double
    let co2: Int

    var id: TimeInterval { ts }
    var date: Date { Date(timeIntervalSince1970: ts) }
}

struct PowerSample: Decodable, Identifiable {
    let ts: TimeInterval
    let watts: Double

    var id: TimeInterval { ts }
    var date: Date { Date(timeIntervalSince1970: ts) }
}

struct PowerSnapshot: Decodable {
    struct Latest: Decodable {
        let ts: TimeInterval
        let watts: Double
        let on: Bool
    }

    let latest: Latest
    /// Energy used over the selected range.
    let energyWh: Double
    let readings: [PowerSample]
}

struct AirSnapshot: Decodable {
    struct Bridge: Decodable {
        let lastSeen: TimeInterval
        let rssi: Int?
    }

    let latest: AirReading?
    let battery: Int?
    let bridge: Bridge?
    let readings: [AirReading]
    let power: PowerSnapshot?
}

enum AirRange: Int, CaseIterable, Identifiable {
    case day = 24
    case week = 168

    var id: Int { rawValue }
    var label: String { self == .day ? "24 hours" : "7 days" }
}

// MARK: - Keychain

private enum AirKeychain {
    private static let service = "JackApp.Air"

    static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func write(_ account: String, _ value: String) {
        delete(account)
        let item: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: Data(value.utf8),
        ]
        SecItemAdd(item as CFDictionary, nil)
    }

    static func delete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Client

private struct AirConnection {
    static let defaultURL = "https://aranet.jackweatherilt.workers.dev"

    let baseURL: URL
    let token: String

    static func load() -> AirConnection? {
        guard let url = AirKeychain.read("url").flatMap(URL.init(string:)),
              let token = AirKeychain.read("token"), !token.isEmpty else { return nil }
        return AirConnection(baseURL: url, token: token)
    }

    func save() {
        AirKeychain.write("url", baseURL.absoluteString)
        AirKeychain.write("token", token)
    }

    static func clear() {
        AirKeychain.delete("url")
        AirKeychain.delete("token")
    }

    func fetch(range: AirRange) async throws -> AirSnapshot {
        var components = URLComponents(url: baseURL.appendingPathComponent("readings"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "hours", value: String(range.rawValue))]
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw AirError.unauthorized }
        guard status == 200 else { throw AirError.server(status) }
        return try JSONDecoder().decode(AirSnapshot.self, from: data)
    }
}

private enum AirError: LocalizedError {
    case unauthorized
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "The token was rejected. Check it in Settings."
        case .server(let code): return "The server returned an error (\(code)). Pull to retry."
        }
    }
}

// MARK: - Thresholds

private enum CO2Level {
    // Aranet4's own display thresholds.
    static func color(_ ppm: Int) -> Color {
        switch ppm {
        case ..<1000: return .green
        case ..<1400: return .orange
        default: return .red
        }
    }
}

/// The bridge and the plug each post every minute; after 10 minutes of silence call them offline.
private let bridgeOfflineAfter: TimeInterval = 10 * 60

private func isOnline(_ lastSeen: TimeInterval) -> Bool {
    Date().timeIntervalSince1970 - lastSeen < bridgeOfflineAfter
}

// MARK: - Views

struct AirView: View {
    @State private var connection = AirConnection.load()
    @State private var snapshot: AirSnapshot?
    @State private var errorMessage: String?
    @State private var range: AirRange = .day
    @State private var showingSettings = false
    /// Raw x-position under the finger while scrubbing any of the charts.
    @State private var scrubSelection: Date?

    var body: some View {
        NavigationStack {
            Group {
                if let connection {
                    content(connection)
                } else {
                    AirConnectForm { saved in
                        connection = saved
                    }
                }
            }
            .navigationTitle("Air")
            .toolbar {
                if connection != nil {
                    Button("Settings", systemImage: "gearshape") { showingSettings = true }
                }
            }
            .confirmationDialog("Air settings", isPresented: $showingSettings) {
                Button("Disconnect", role: .destructive) {
                    AirConnection.clear()
                    connection = nil
                    snapshot = nil
                }
            } message: {
                Text("Disconnecting removes the saved token from this iPhone.")
            }
        }
    }

    private func content(_ connection: AirConnection) -> some View {
        List {
            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            if let latest = snapshot?.latest {
                Section {
                    currentReading(latest)
                }
            } else if snapshot != nil {
                Section {
                    Text("No readings yet. They appear once the bridge has posted one.")
                        .foregroundStyle(.secondary)
                }
            }

            if let snapshot, !snapshot.readings.isEmpty {
                Section {
                    Picker("Range", selection: $range) {
                        ForEach(AirRange.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    let readings = snapshot.readings
                    let selected = nearestReading(to: scrubSelection, in: readings)
                    // Haptics on one chart only, so a step doesn't buzz three times.
                    metricChart("Temperature", readings: readings, selected: selected, color: .orange,
                                height: 180, unit: "°C", fractionDigits: 1, haptics: true) { $0.temperature }
                    metricChart("Humidity", readings: readings, selected: selected, color: .blue,
                                height: 140, unit: "%") { Double($0.humidity) }
                    metricChart("CO₂", readings: readings, selected: selected, color: .teal,
                                height: 140, unit: "ppm", limit: 1000) { Double($0.co2) }
                }
            }

            if let power = snapshot?.power {
                Section("Heater") {
                    heaterSummary(power)
                    if !power.readings.isEmpty {
                        powerChart(power.readings, alignedWith: snapshot?.readings ?? [])
                    }
                }
            }

            if let snapshot {
                Section("Sensor") {
                    bridgeRow(snapshot.bridge)
                    if let power = snapshot.power {
                        statusRow("Heater plug", lastSeen: power.latest.ts)
                    }
                    if let battery = snapshot.battery {
                        LabeledContent("Battery", value: "\(battery)%")
                    }
                }
            }
        }
        .overlay {
            if snapshot == nil && errorMessage == nil { ProgressView() }
        }
        .refreshable { await load(connection) }
        .task(id: range) {
            // Refresh every minute while the tab is on screen.
            while !Task.isCancelled {
                await load(connection)
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    private func load(_ connection: AirConnection) async {
        do {
            snapshot = try await connection.fetch(range: range)
            errorMessage = nil
        } catch is CancellationError {
        } catch let error as URLError where error.code == .cancelled {
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func currentReading(_ r: AirReading) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(r.temperature, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()
                Text("°C")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 24) {
                metric("CO₂", "\(r.co2)", "ppm", color: CO2Level.color(r.co2))
                metric("Humidity", "\(r.humidity)", "%")
                metric("Pressure", r.pressure.formatted(.number.precision(.fractionLength(0))), "hPa")
            }
            Text("Measured \(r.date, style: .relative) ago")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func metric(_ label: String, _ value: String, _ unit: String, color: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(color ?? .primary)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// The reading closest in time to `date`, so the scrubber snaps to real samples.
    private func nearestReading(to date: Date?, in readings: [AirReading]) -> AirReading? {
        guard let date else { return nil }
        let t = date.timeIntervalSince1970
        return readings.min { abs($0.ts - t) < abs($1.ts - t) }
    }

    private var selectionTimeFormat: Date.FormatStyle {
        range == .day
            ? .dateTime.hour().minute()
            : .dateTime.weekday(.abbreviated).hour().minute()
    }

    /// One scrubbable chart. All charts share `scrubSelection`, so scrubbing any of them
    /// highlights the same moment on every chart.
    private func metricChart(
        _ title: String,
        readings: [AirReading],
        selected: AirReading?,
        color: Color,
        height: CGFloat,
        unit: String,
        fractionDigits: Int = 0,
        limit: Double? = nil,
        haptics: Bool = false,
        value: @escaping (AirReading) -> Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // The header doubles as the scrub readout, so nothing gets clipped at the chart edges.
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline)
                Spacer()
                if let selected {
                    Text("\(value(selected), format: .number.precision(.fractionLength(fractionDigits))) \(unit)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(color)
                    Text(selected.date, format: selectionTimeFormat)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Chart {
                ForEach(readings) {
                    LineMark(x: .value("Time", $0.date), y: .value(unit, value($0)))
                        .interpolationMethod(.linear)
                        .foregroundStyle(color)
                }
                if let limit {
                    RuleMark(y: .value("Limit", limit))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.secondary)
                }
                if let selected {
                    RuleMark(x: .value("Selected", selected.date))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.secondary)
                    PointMark(x: .value("Time", selected.date), y: .value(unit, value(selected)))
                        .symbolSize(60)
                        .foregroundStyle(color)
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXSelection(value: $scrubSelection)
            .sensoryFeedback(.selection, trigger: haptics ? selected?.id : nil)
            .frame(height: height)
        }
        .padding(.vertical, 4)
    }

    private func heaterSummary(_ power: PowerSnapshot) -> some View {
        let online = isOnline(power.latest.ts)
        return HStack(alignment: .firstTextBaseline, spacing: 24) {
            metric(
                "Now",
                online ? power.latest.watts.formatted(.number.precision(.fractionLength(0))) : "–",
                "W",
                color: online && power.latest.watts >= 5 ? .orange : nil
            )
            metric("Used, \(range.label)", (power.energyWh / 1000).formatted(.number.precision(.fractionLength(2))), "kWh")
            if !power.latest.on {
                metric("Plug", "Off", "")
            }
        }
        .padding(.vertical, 4)
    }

    /// Heater draw, on the same time axis as the air charts and joined to the shared scrubber,
    /// so heater cycles line up with the temperature they cause.
    private func powerChart(_ readings: [PowerSample], alignedWith air: [AirReading]) -> some View {
        let selected = scrubSelection.flatMap { date in
            readings.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
        }
        let dates = (air.map(\.date) + readings.map(\.date))
        let domain = dates.min().flatMap { lo in dates.max().map { lo...$0 } }
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Power")
                    .font(.subheadline)
                Spacer()
                if let selected {
                    Text("\(selected.watts, format: .number.precision(.fractionLength(0))) W")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                    Text(selected.date, format: selectionTimeFormat)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Chart {
                ForEach(readings) {
                    AreaMark(x: .value("Time", $0.date), y: .value("W", $0.watts))
                        .interpolationMethod(.stepEnd)
                        .foregroundStyle(.orange.opacity(0.6))
                }
                if let selected {
                    RuleMark(x: .value("Selected", selected.date))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXScale(domain: domain ?? Date.distantPast...Date.distantFuture)
            .chartYScale(domain: .automatic(includesZero: true))
            .chartXSelection(value: $scrubSelection)
            .frame(height: 140)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func bridgeRow(_ bridge: AirSnapshot.Bridge?) -> some View {
        if let bridge {
            statusRow("Bridge", lastSeen: bridge.lastSeen)
        } else {
            LabeledContent("Bridge", value: "Never connected")
        }
    }

    private func statusRow(_ label: String, lastSeen ts: TimeInterval) -> some View {
        let lastSeen = Date(timeIntervalSince1970: ts)
        let online = isOnline(ts)
        return LabeledContent(label) {
            HStack(spacing: 6) {
                Circle()
                    .fill(online ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                if online {
                    Text("Online")
                } else {
                    Text("Offline since \(lastSeen, style: .relative) ago")
                }
            }
        }
    }
}

private struct AirConnectForm: View {
    let onSave: (AirConnection) -> Void

    @State private var urlText = AirConnection.defaultURL
    @State private var token = ""

    private var connection: AirConnection? {
        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespaces)), url.scheme == "https" else { return nil }
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : AirConnection(baseURL: url, token: t)
    }

    var body: some View {
        Form {
            Section {
                TextField("Server", text: $urlText)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Read token", text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } footer: {
                Text("Paste the read token for your Aranet relay. It's saved in this iPhone's Keychain.")
            }
            Section {
                Button("Connect") {
                    guard let connection else { return }
                    connection.save()
                    onSave(connection)
                }
                .disabled(connection == nil)
            }
        }
    }
}

#Preview {
    AirView()
}
