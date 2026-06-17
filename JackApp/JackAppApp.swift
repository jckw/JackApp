//
//  JackAppApp.swift
//  JackApp
//
//  Created by Jack on 30/12/2025.
//

import SwiftData
import SwiftUI

@main
struct JackAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [BodyPhoto.self, NutritionDay.self])
    }
}
