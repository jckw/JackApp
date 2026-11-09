//
//  AirView.swift
//  JackApp
//
//  Live readings from the Aranet4 at home, relayed by an ESP32 to a Cloudflare Worker.
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

struct AirSnapshot: Decodable {
    struct Bridge: Decodable {
        let lastSeen: TimeInterval
        let rssi: Int?
    }

    let latest: AirReading?
    let battery: Int?
    let bridge: Bridge?
    let readings: [AirReading]
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

/// The bridge posts a heartbeat every minute; after 10 minutes of silence call it offline.
private let bridgeOfflineAfter: TimeInterval = 10 * 60

// MARK: - Views

struct AirView: View {
    @State private var connection = AirConnection.load()
    @State private var snapshot: AirSnapshot?
    @State private var errorMessage: String?
    @State private var range: AirRange = .day
    @State private var showingSettings = false

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
                    temperatureChart(snapshot.readings)
                    co2Chart(snapshot.readings)
                }
            }

            if let snapshot {
                Section("Sensor") {
                    bridgeRow(snapshot.bridge)
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

    private func temperatureChart(_ readings: [AirReading]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Temperature")
                .font(.subheadline)
            Chart(readings) {
                LineMark(x: .value("Time", $0.date), y: .value("°C", $0.temperature))
                    .interpolationMethod(.linear)
                    .foregroundStyle(.orange)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 180)
        }
        .padding(.vertical, 4)
    }

    private func co2Chart(_ readings: [AirReading]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CO₂")
                .font(.subheadline)
            Chart {
                ForEach(readings) {
                    LineMark(x: .value("Time", $0.date), y: .value("ppm", $0.co2))
                        .interpolationMethod(.linear)
                        .foregroundStyle(.teal)
                }
                RuleMark(y: .value("Limit", 1000))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 140)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func bridgeRow(_ bridge: AirSnapshot.Bridge?) -> some View {
        if let bridge {
            let lastSeen = Date(timeIntervalSince1970: bridge.lastSeen)
            let online = Date().timeIntervalSince(lastSeen) < bridgeOfflineAfter
            LabeledContent("Bridge") {
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
        } else {
            LabeledContent("Bridge", value: "Never connected")
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
