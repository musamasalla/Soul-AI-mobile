import StoreKit

/// A class that handles StoreKit payment queue operations
class SKPaymentQueueHandler: NSObject, SKPaymentTransactionObserver {
    
    static let shared = SKPaymentQueueHandler()
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - SKPaymentTransactionObserver
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                handlePurchasingState(for: transaction)
            case .purchased:
                handlePurchasedState(for: transaction)
            case .failed:
                handleFailedState(for: transaction)
            case .restored:
                handleRestoredState(for: transaction)
            case .deferred:
                handleDeferredState(for: transaction)
            @unknown default:
                print("Unknown transaction state: \(transaction.transactionState)")
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print("Removed transactions: \(transactions.count)")
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("Restore failed with error: \(error.localizedDescription)")
        NotificationCenter.default.post(name: .subscriptionRestoreFailed, object: error)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("Restore completed")
        NotificationCenter.default.post(name: .subscriptionRestoreCompleted, object: nil)
    }
    
    // MARK: - Transaction Handling
    
    private func handlePurchasingState(for transaction: SKPaymentTransaction) {
        print("Transaction is in purchasing state: \(transaction.payment.productIdentifier)")
    }
    
    private func handlePurchasedState(for transaction: SKPaymentTransaction) {
        print("Transaction purchased: \(transaction.payment.productIdentifier)")
        
        // Verify the purchase with your server or validate the receipt
        verifyPurchase(transaction: transaction)
        
        // Finish the transaction after verification
        SKPaymentQueue.default().finishTransaction(transaction)
        
        // Notify that a purchase was completed
        NotificationCenter.default.post(name: .subscriptionPurchaseCompleted, object: transaction)
    }
    
    private func handleFailedState(for transaction: SKPaymentTransaction) {
        print("Transaction failed: \(transaction.payment.productIdentifier)")
        
        if let error = transaction.error {
            print("Error: \(error.localizedDescription)")
            NotificationCenter.default.post(name: .subscriptionPurchaseFailed, object: error)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleRestoredState(for transaction: SKPaymentTransaction) {
        print("Transaction restored: \(transaction.payment.productIdentifier)")
        
        // Verify the restored purchase
        verifyPurchase(transaction: transaction)
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handleDeferredState(for transaction: SKPaymentTransaction) {
        print("Transaction deferred: \(transaction.payment.productIdentifier)")
        // The transaction is in the queue, but its final status is pending external action
    }
    
    // MARK: - Purchase Verification
    
    private func verifyPurchase(transaction: SKPaymentTransaction) {
        // Here you would typically validate the receipt with Apple's servers
        // and update your backend about the purchase
        
        // For now, we'll just post a notification that a verification is needed
        NotificationCenter.default.post(name: .subscriptionVerificationNeeded, object: transaction)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionPurchaseCompleted = Notification.Name("subscriptionPurchaseCompleted")
    static let subscriptionPurchaseFailed = Notification.Name("subscriptionPurchaseFailed")
    static let subscriptionRestoreCompleted = Notification.Name("subscriptionRestoreCompleted")
    static let subscriptionRestoreFailed = Notification.Name("subscriptionRestoreFailed")
    static let subscriptionVerificationNeeded = Notification.Name("subscriptionVerificationNeeded")
} 