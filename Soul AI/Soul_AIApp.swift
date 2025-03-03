//
//  Soul_AIApp.swift
//  Soul AI
//
//  Created by Musa Masalla on 2025/03/03.
//

import SwiftUI

@main
struct Soul_AIApp: App {
    @StateObject private var preferences = UserPreferences()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
        }
    }
}
