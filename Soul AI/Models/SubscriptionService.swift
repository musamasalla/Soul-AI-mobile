import Foundation
import StoreKit

// Product identifiers for in-app purchases
enum SubscriptionProduct: String, CaseIterable {
    case premium = "com.soulai.premium"
    case guided = "com.soulai.guided"
}

#if DEBUG
// Mock product for testing that doesn't subclass Product
struct MockSubscriptionProduct {
    let id: String
    let displayName: String
    let description: String
    let price: Decimal
    let displayPrice: String
    
    static var mockProducts: [Product] = []
    
    static func createMockProducts() -> [Product] {
        // Create mock products using StoreKit's testing API
        
        // Use the StoreKit testing configuration to create products
        Task {
            do {
                // Try to load products from the StoreKit configuration
                let products = try await Product.products(for: [
                    SubscriptionProduct.premium.rawValue,
                    SubscriptionProduct.guided.rawValue
                ])
                
                if !products.isEmpty {
                    // Fix for Swift 6 concurrency warning - use local variable first
                    let loadedProducts = products
                    await MainActor.run {
                        mockProducts = loadedProducts
                    }
                }
            } catch {
                print("Error creating mock products: \(error.localizedDescription)")
            }
        }
        
        return mockProducts
    }
}
#endif

class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isLoading = false
    
    private var productIDs = Set(SubscriptionProduct.allCases.map { $0.rawValue })
    private var updates: Task<Void, Error>? = nil
    
    // Add a reference to UserPreferences
    private var userPreferences: UserPreferences?
    
    override init() {
        super.init()
        
        // Defer initialization to improve app launch time
        Task {
            // Add a small delay to prioritize UI rendering
            try? await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds
            
            // Start transaction updates observer
            self.updates = observeTransactionUpdates()
            
            // Request products after a delay
            await requestProducts()
            
            // Try to update purchased products
            do {
                try await updatePurchasedProducts()
            } catch {
                print("Warning: Could not update purchased products: \(error.localizedDescription)")
                // Continue anyway - this is expected in the testing environment
            }
        }
    }
    
    // Add a method to set the UserPreferences instance
    func setUserPreferences(_ preferences: UserPreferences) {
        self.userPreferences = preferences
    }
    
    deinit {
        updates?.cancel()
    }
    
    // Request products from App Store
    @MainActor
    func requestProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIDs)
            print("Successfully loaded \(products.count) products")
            for product in products {
                print("Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }
            
            // If no products were loaded, create mock products in debug mode
            #if DEBUG
            if products.isEmpty {
                print("No products loaded from StoreKit, creating mock products")
                createHardcodedMockProducts()
            }
            #endif
            
            isLoading = false
        } catch {
            print("Failed to load products: \(error)")
            
            // For testing environment, create mock products if real ones fail to load
            #if DEBUG
            print("Creating mock products for testing environment")
            createHardcodedMockProducts()
            #endif
            
            isLoading = false
        }
    }
    
    // Create hardcoded mock products for testing
    #if DEBUG
    private func createHardcodedMockProducts() {
        print("Creating hardcoded mock products")
        
        // Use the StoreKit testing API to create products
        let mockProducts = MockSubscriptionProduct.createMockProducts()
        
        if !mockProducts.isEmpty {
            self.products = mockProducts
            print("Created \(self.products.count) mock products from StoreKit testing")
        } else {
            print("Failed to create mock products, simulating premium subscription directly")
            // If we can't create mock products, simulate a premium subscription directly
            simulatePremiumSubscription()
        }
    }
    
    private func simulatePremiumSubscription() {
        // Directly update the user's subscription status without going through the purchase flow
        Task {
            await updateSubscriptionTier(for: SubscriptionProduct.premium.rawValue)
            print("Simulated premium subscription activated")
        }
    }
    
    private func createMockProductsForTesting() {
        // This method is now replaced by createHardcodedMockProducts
        createHardcodedMockProducts()
    }
    #endif
    
    // Purchase a product
    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Check if the transaction is verified
                switch verification {
                case .verified(let transaction):
                    // Update the user's subscription tier
                    await updateSubscriptionTier(for: product.id)
                    await transaction.finish()
                    return true
                case .unverified:
                    // For testing, accept unverified transactions too
                    #if DEBUG
                    print("Accepting unverified transaction in debug mode")
                    await updateSubscriptionTier(for: product.id)
                    // We can't finish an unverified transaction, but we can still update the subscription
                    return true
                    #else
                    // Transaction failed verification
                    return false
                    #endif
                }
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            // Special handling for testing environment
            #if DEBUG
            print("Purchase error: \(error.localizedDescription)")
            if (error as NSError).domain == "ASDErrorDomain" && (error as NSError).code == 509 {
                print("StoreKit testing environment error: No active account. Simulating successful purchase.")
                // Simulate a successful purchase for testing
                await updateSubscriptionTier(for: product.id)
                return true
            }
            
            // For any other error in debug mode, simulate success
            print("Simulating successful purchase despite error")
            await updateSubscriptionTier(for: product.id)
            return true
            #endif
            
            // This code will never be executed in DEBUG mode, but is needed for RELEASE
            #if !DEBUG
            throw error
            #endif
        }
    }
    
    // Restore purchases
    @MainActor
    func restorePurchases() async throws {
        do {
            try await AppStore.sync()
            try await updatePurchasedProducts()
        } catch {
            // Special handling for testing environment
            #if DEBUG
            if (error as NSError).domain == "ASDErrorDomain" && (error as NSError).code == 509 {
                print("StoreKit testing environment error: No active account. Skipping restore.")
                // Don't throw the error in testing environment
                return
            }
            #endif
            
            throw error
        }
    }
    
    // Update the list of purchased products
    @MainActor
    func updatePurchasedProducts() async throws {
        // We don't need to track errors here since we're using for-await which will throw if there's an error
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    purchasedProductIDs.insert(transaction.productID)
                    await updateSubscriptionTier(for: transaction.productID)
                } else {
                    purchasedProductIDs.remove(transaction.productID)
                }
            }
        }
    }
    
    // Update the user's subscription tier based on the purchased product
    @MainActor
    private func updateSubscriptionTier(for productID: String) async {
        // Use the injected UserPreferences instance if available, otherwise create a new one
        guard let preferences = userPreferences else {
            print("Warning: UserPreferences not set in SubscriptionService")
            return
        }
        
        switch productID {
        case SubscriptionProduct.premium.rawValue:
            preferences.subscriptionTier = .premium
        case SubscriptionProduct.guided.rawValue:
            preferences.subscriptionTier = .guided
        default:
            preferences.subscriptionTier = .free
        }
        
        // Set expiry date to 1 month from now (for subscription)
        if productID == SubscriptionProduct.premium.rawValue || productID == SubscriptionProduct.guided.rawValue {
            let calendar = Calendar.current
            if let expiryDate = calendar.date(byAdding: .month, value: 1, to: Date()) {
                preferences.subscriptionExpiryDate = expiryDate
            }
        }
    }
    
    // Observe transaction updates
    private func observeTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            for await verificationResult in Transaction.updates {
                if case .verified(let transaction) = verificationResult {
                    do {
                        try await self.updatePurchasedProducts()
                    } catch {
                        print("Error updating purchased products: \(error.localizedDescription)")
                    }
                    await transaction.finish()
                }
            }
        }
    }
    
    // Check if a specific product is purchased
    func isProductPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    // Get a product by ID
    func product(for productID: SubscriptionProduct) -> Product? {
        return products.first(where: { $0.id == productID.rawValue })
    }
} 