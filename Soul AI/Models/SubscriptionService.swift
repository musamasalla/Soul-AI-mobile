import Foundation
import StoreKit

// Product identifiers for in-app purchases
enum SubscriptionProduct: String, CaseIterable {
    case premium = "com.soulai.premium"
    case guided = "com.soulai.guided"
}

// Mock product for testing
#if DEBUG
class MockProduct: Product {
    let mockID: String
    let mockDisplayName: String
    let mockDescription: String
    let mockPrice: Decimal
    let mockDisplayPrice: String
    let mockIsFamilyShareable: Bool
    
    init(id: String, displayName: String, description: String, price: Decimal) {
        self.mockID = id
        self.mockDisplayName = displayName
        self.mockDescription = description
        self.mockPrice = price
        self.mockDisplayPrice = "$\(price)"
        self.mockIsFamilyShareable = false
        super.init()
    }
    
    override var id: String {
        return mockID
    }
    
    override var displayName: String {
        return mockDisplayName
    }
    
    override var description: String {
        return mockDescription
    }
    
    override var price: Decimal {
        return mockPrice
    }
    
    override var displayPrice: String {
        return mockDisplayPrice
    }
    
    override var isFamilyShareable: Bool {
        return mockIsFamilyShareable
    }
    
    override var subscription: Product.SubscriptionInfo? {
        return nil
    }
    
    override func purchase(options: Set<Product.PurchaseOption> = []) async throws -> Product.PurchaseResult {
        // Simulate a successful purchase
        return .success(StoreKit.Transaction.VerificationResult<StoreKit.Transaction>.unverified(MockTransaction(productID: id)))
    }
}

// Mock transaction for testing
class MockTransaction: StoreKit.Transaction {
    let mockProductID: String
    
    init(productID: String) {
        self.mockProductID = productID
        super.init()
    }
    
    override var productID: String {
        return mockProductID
    }
    
    override var productType: Product.ProductType {
        return .autoRenewable
    }
    
    override var purchaseDate: Date {
        return Date()
    }
    
    override var expirationDate: Date? {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: 1, to: Date())
    }
    
    override var revocationDate: Date? {
        return nil
    }
    
    override var webOrderLineItemID: UInt64 {
        return 0
    }
    
    override var quantity: Int {
        return 1
    }
    
    override var environment: StoreKit.Transaction.Environment {
        return .sandbox
    }
    
    override var appBundleID: String {
        return Bundle.main.bundleIdentifier ?? "com.soulai.app"
    }
    
    override var appAccountToken: UUID? {
        return nil
    }
    
    override var deviceVerification: Data? {
        return nil
    }
    
    override var deviceVerificationNonce: UUID? {
        return nil
    }
    
    override var originalID: UInt64 {
        return 0
    }
    
    override var originalPurchaseDate: Date {
        return Date()
    }
    
    override var originalAppVersion: String? {
        return "1.0"
    }
    
    override var signedDate: Date {
        return Date()
    }
    
    override var ownershipType: StoreKit.Transaction.OwnershipType {
        return .purchased
    }
    
    override func finish() async {
        // Do nothing
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
    
    override init() {
        super.init()
        self.updates = observeTransactionUpdates()
        Task {
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
        
        // Create mock premium product
        let premiumProduct = MockProduct(
            id: SubscriptionProduct.premium.rawValue,
            displayName: "Soul AI Premium",
            description: "Unlock advanced meditation features and personalized guidance",
            price: 9.99
        )
        
        // Create mock guided product
        let guidedProduct = MockProduct(
            id: SubscriptionProduct.guided.rawValue,
            displayName: "Soul AI Guided",
            description: "Get personalized spiritual guidance with 1-on-1 advisor",
            price: 29.99
        )
        
        // Add mock products to the products array
        self.products = [premiumProduct, guidedProduct]
        
        print("Created \(self.products.count) mock products")
        for product in self.products {
            print("Mock Product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
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
                case .unverified(let transaction):
                    // For testing, accept unverified transactions too
                    #if DEBUG
                    print("Accepting unverified transaction in debug mode")
                    await updateSubscriptionTier(for: product.id)
                    await transaction.finish()
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
            
            throw error
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