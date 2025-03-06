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
                .onAppear {
                    #if DEBUG
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
}
