//
//  ContentView.swift
//  Soul AI
//
//  Created by Musa Masalla on 2025/03/03.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var preferences = UserPreferences()
    @State private var showSettings = false
    
    var body: some View {
        Group {
            if !preferences.hasSeenWelcome {
                WelcomeView(hasSeenWelcome: $preferences.hasSeenWelcome)
            } else {
                ZStack {
                    ChatView()
                        .preferredColorScheme(preferences.isDarkMode ? .dark : .light)
                        .sheet(isPresented: $showSettings) {
                            SettingsView(preferences: preferences)
                        }
                        .navigationBarItems(trailing: Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 18))
                        })
                }
            }
        }
        .environmentObject(preferences)
    }
}

#Preview {
    ContentView()
}
