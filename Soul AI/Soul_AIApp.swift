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
                .onAppear {
                    #if DEBUG
                    if let url = Bundle.main.url(forResource: "Subscriptions", withExtension: "storekit") {
                        try? SKPaymentQueue.default().add(SKPaymentQueueHandler(storefront: .default))
                        try? SKAdministrativeCenter.default().loadStorefrontForTesting(from: url)
                    }
                    #endif
                }
        }
    }
}
