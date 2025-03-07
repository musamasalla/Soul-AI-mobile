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
    
    // Initialize the payment queue handler
    private let paymentQueueHandler = SKPaymentQueueHandler.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(subscriptionService)
                .preferredColorScheme(preferences.isDarkMode ? .dark : .light)
                .onChange(of: preferences.isDarkMode) { _, newValue in
                    // Force UI update when dark mode changes
                    print("DEBUG: Dark mode changed to \(newValue ? "dark" : "light")")
                }
                .onAppear {
                    #if DEBUG
                    // Debug option to reset subscription tier to free
                    // Uncomment the line below to reset to free plan for testing
                    // resetToFreePlan()
                    
                    if let url = Bundle.main.url(forResource: "Subscriptions", withExtension: "storekit") {
                        // Use our SKPaymentQueueHandler singleton that's already initialized
                        // and already added to the payment queue
                        
                        // For StoreKit 2 testing configuration (iOS 15+)
                        if #available(iOS 15.0, *) {
                            // StoreKit 2 uses a different approach for testing
                            // The .storekit file is automatically loaded in debug mode
                            // No need to manually load it
                        } else {
                            // For older iOS versions, we rely on our SKPaymentQueueHandler
                            // which is already set up
                        }
                    }
                    #endif
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
