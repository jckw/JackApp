//
//  BiometricAuthManager.swift
//  JackApp
//
//  Created by Jack on 18/01/2026.
//

import LocalAuthentication
import SwiftUI

@Observable
class BiometricAuthManager {
    var isAuthenticated = false
    var authError: String?

    private let context = LAContext()

    var biometricType: LABiometryType {
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    var biometricName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometrics"
        }
    }

    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "lock.shield"
        }
    }

    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            await MainActor.run {
                authError = error?.localizedDescription ?? "Biometric authentication not available"
            }
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock your progress photos"
            )

            await MainActor.run {
                isAuthenticated = success
                if !success {
                    authError = "Authentication failed"
                }
            }

            return success
        } catch {
            await MainActor.run {
                authError = error.localizedDescription
                isAuthenticated = false
            }
            return false
        }
    }

    func lock() {
        isAuthenticated = false
        authError = nil
    }
}
