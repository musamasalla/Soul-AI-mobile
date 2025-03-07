import StoreKit
import Combine

/// A class that handles StoreKit 2 transaction operations
class SKPaymentQueueHandler: NSObject {
    
    static let shared = SKPaymentQueueHandler()
    
    private var transactionListener: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupTransactionListener()
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Transaction Listener
    
    private func setupTransactionListener() {
        // Start listening for transactions
        transactionListener = Task.detached {
            // Iterate through any transactions that don't have a call to `finish()`
            for await verificationResult in Transaction.updates {
                // Check the verification result
                switch verificationResult {
                case .verified(let transaction):
                    // Handle the transaction
                    await self.handleVerifiedTransaction(transaction)
                case .unverified(let transaction, let error):
                    // Handle the unverified transaction
                    print("Unverified transaction: \(error.localizedDescription)")
                    await self.handleUnverifiedTransaction(transaction, error: error)
                }
            }
        }
    }
    
    // MARK: - Transaction Handling
    
    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        // Handle the transaction based on its state
        if let _ = transaction.revocationDate {
            // Transaction was revoked
            print("Transaction was revoked: \(transaction.productID)")
        } else {
            // Transaction is valid
            switch transaction.productType {
            case .autoRenewable:
                await handleAutoRenewableTransaction(transaction)
            case .nonConsumable:
                await handleNonConsumableTransaction(transaction)
            case .consumable:
                await handleConsumableTransaction(transaction)
            case .nonRenewable:
                await handleNonRenewableTransaction(transaction)
            default:
                print("Unknown product type: \(transaction.productType)")
            }
        }
        
        // Finish the transaction
        await transaction.finish()
    }
    
    private func handleUnverifiedTransaction(_ transaction: Transaction, error: VerificationResult<Transaction>.VerificationError) async {
        // Handle unverified transaction
        print("Unverified transaction: \(transaction.productID), error: \(error)")
        
        // Post notification about the failed verification
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .subscriptionVerificationFailed, object: error)
        }
        
        // Finish the transaction
        await transaction.finish()
    }
    
    private func handleAutoRenewableTransaction(_ transaction: Transaction) async {
        print("Auto-renewable subscription transaction: \(transaction.productID)")
        
        // Verify the purchase with your server
        verifyPurchase(productID: transaction.productID, transactionID: transaction.id)
        
        // Notify that a purchase was completed
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .subscriptionPurchaseCompleted, object: transaction)
        }
    }
    
    private func handleNonConsumableTransaction(_ transaction: Transaction) async {
        print("Non-consumable transaction: \(transaction.productID)")
        
        // Verify the purchase with your server
        verifyPurchase(productID: transaction.productID, transactionID: transaction.id)
        
        // Notify that a purchase was completed
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .subscriptionPurchaseCompleted, object: transaction)
        }
    }
    
    private func handleConsumableTransaction(_ transaction: Transaction) async {
        print("Consumable transaction: \(transaction.productID)")
        
        // Verify the purchase with your server
        verifyPurchase(productID: transaction.productID, transactionID: transaction.id)
        
        // Notify that a purchase was completed
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .subscriptionPurchaseCompleted, object: transaction)
        }
    }
    
    private func handleNonRenewableTransaction(_ transaction: Transaction) async {
        print("Non-renewable transaction: \(transaction.productID)")
        
        // Verify the purchase with your server
        verifyPurchase(productID: transaction.productID, transactionID: transaction.id)
        
        // Notify that a purchase was completed
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .subscriptionPurchaseCompleted, object: transaction)
        }
    }
    
    // MARK: - Purchase Methods
    
    /// Purchase a product
    /// - Parameter productID: The product identifier to purchase
    func purchase(productID: String) async throws {
        // Get the product
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw StoreError.productNotFound
        }
        
        // Purchase the product
        let result = try await product.purchase()
        
        // Handle the purchase result
        switch result {
        case .success(let verificationResult):
            // Check the verification result
            switch verificationResult {
            case .verified(let transaction):
                // Handle the transaction
                await handleVerifiedTransaction(transaction)
            case .unverified(let transaction, let error):
                // Handle the unverified transaction
                await handleUnverifiedTransaction(transaction, error: error)
            }
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            print("Purchase is pending")
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    /// Restore purchases
    func restorePurchases() async {
        do {
            // Request a refresh of the app receipt
            try await AppStore.sync()
            
            // Check for any transactions
            var hasTransactions = false
            var transactionCount = 0
            
            // Process current entitlements
            for await verificationResult in Transaction.currentEntitlements {
                hasTransactions = true
                transactionCount += 1
                
                switch verificationResult {
                case .verified(let transaction):
                    // Handle the transaction
                    await handleVerifiedTransaction(transaction)
                case .unverified(let transaction, let error):
                    // Handle the unverified transaction
                    await handleUnverifiedTransaction(transaction, error: error)
                }
            }
            
            // Notify that restoration is complete
            DispatchQueue.main.async {
                if hasTransactions {
                    print("Restored \(transactionCount) transactions")
                } else {
                    print("No transactions to restore")
                }
                NotificationCenter.default.post(name: .subscriptionRestoreCompleted, object: nil)
            }
        } catch {
            print("Restore failed with error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .subscriptionRestoreFailed, object: error)
            }
        }
    }
    
    // MARK: - Purchase Verification
    
    private func verifyPurchase(productID: String, transactionID: UInt64) {
        // Here you would typically validate the receipt with Apple's servers
        // and update your backend about the purchase
        
        // For now, we'll just post a notification that a verification is needed
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .subscriptionVerificationNeeded,
                object: ["productID": productID, "transactionID": transactionID]
            )
        }
    }
}

// MARK: - Store Errors

enum StoreError: Error {
    case productNotFound
    case userCancelled
    case unknown
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionPurchaseCompleted = Notification.Name("subscriptionPurchaseCompleted")
    static let subscriptionPurchaseFailed = Notification.Name("subscriptionPurchaseFailed")
    static let subscriptionRestoreCompleted = Notification.Name("subscriptionRestoreCompleted")
    static let subscriptionRestoreFailed = Notification.Name("subscriptionRestoreFailed")
    static let subscriptionVerificationNeeded = Notification.Name("subscriptionVerificationNeeded")
    static let subscriptionVerificationFailed = Notification.Name("subscriptionVerificationFailed")
} 
