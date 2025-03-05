//
//  Soul_AIApp.swift
//  Soul AI
//
//  Created by Musa Masalla on 2025/03/03.
//

import SwiftUI
import StoreKit

@main
struct Soul_AIApp: App {
    @StateObject private var preferences = UserPreferences()
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(subscriptionService)
                .task {
                    #if DEBUG
                    // Set up StoreKit testing configuration
                    if let url = Bundle.main.url(forResource: "Subscriptions", withExtension: "storekit") {
                        // Simply log that we found the configuration file
                        // The StoreKit testing environment should automatically use it
                        // if it's included in the app bundle
                        print("StoreKit configuration file found at: \(url)")
                    } else {
                        print("StoreKit configuration file not found")
                    }
                    #endif
                }
        }
    }
}
