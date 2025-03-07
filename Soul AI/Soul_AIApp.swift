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
    // Use lazy initialization for services that aren't needed immediately
    @StateObject private var preferences = UserPreferences()
    
    // Lazy load subscription service only when needed
    private var subscriptionServiceProvider: () -> SubscriptionService = {
        let service = SubscriptionService.shared
        return service
    }
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    @StateObject private var themeManager = ThemeManager(isDarkMode: UserDefaults.standard.bool(forKey: "isDarkMode"))
    
    // Initialize the payment queue handler lazily
    private lazy var paymentQueueHandler = SKPaymentQueueHandler.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(subscriptionService)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onChange(of: preferences.isDarkMode) { _, newValue in
                    // Update theme manager when preferences change
                    themeManager.updateColorScheme(isDarkMode: newValue)
                    print("DEBUG: App detected isDarkMode change to \(newValue)")
                }
                .task {
                    // Defer non-essential initialization to after the UI is shown
                    #if DEBUG
                    // Debug option to reset subscription tier to free
                    // Uncomment the line below to reset to free plan for testing
                    // resetToFreePlan()
                    
                    // For StoreKit 2 testing configuration
                    // The .storekit file is automatically loaded in debug mode
                    // No need to manually load it
                    #endif
                    
                    // Start listening for transactions
                    // This is handled by our SKPaymentQueueHandler
                    _ = paymentQueueHandler
                }
        }
    }
    
    #if DEBUG
    // Debug function to reset subscription to free plan
    private func resetToFreePlan() {
        UserDefaults.standard.set("free", forKey: "subscriptionTier")
        UserDefaults.standard.removeObject(forKey: "subscriptionExpiryDate")
        print("DEBUG: Reset to free plan for testing")
    }
    #endif
}
