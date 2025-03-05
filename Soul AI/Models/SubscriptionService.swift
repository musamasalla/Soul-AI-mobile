import Foundation
import StoreKit

// Product identifiers for in-app purchases
enum SubscriptionProduct: String, CaseIterable {
    case premium = "com.soulai.premium"
    case guided = "com.soulai.guided"
}

class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isLoading = false
    
    private var productIDs = Set(SubscriptionProduct.allCases.map { $0.rawValue })
    private var updates: Task<Void, Error>? = nil
    
    override init() {
        super.init()
        self.updates = observeTransactionUpdates()
        Task {
            await requestProducts()
            await updatePurchasedProducts()
        }
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
            isLoading = false
        } catch {
            print("Failed to load products: \(error)")
            isLoading = false
        }
    }
    
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
                    // Transaction failed verification
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            throw error
        }
    }
    
    // Restore purchases
    @MainActor
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }
    
    // Update the list of purchased products
    @MainActor
    func updatePurchasedProducts() async {
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
        let preferences = UserPreferences()
        
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
                    await self.updatePurchasedProducts()
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