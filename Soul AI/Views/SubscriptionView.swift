import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Soul AI Premium")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.brandMint)
                        
                        Text("Unlock the full spiritual experience")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Current subscription status
                    currentSubscriptionStatus
                    
                    // Direct purchase button for testing
                    Button(action: {
                        Task {
                            await purchaseDirectly()
                        }
                    }) {
                        Text("Test Purchase Premium (StoreKit Testing)")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brandMint)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Subscription plans
                    subscriptionPlans
                    
                    // Restore purchases button
                    Button(action: {
                        Task {
                            await restorePurchases()
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.brandMint)
                    }
                    .padding(.top, 10)
                    
                    // Terms and privacy
                    VStack(spacing: 4) {
                        Text("By subscribing, you agree to our")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Text("Terms of Service")
                                .font(.caption)
                                .foregroundColor(.brandMint)
                                .underline()
                            
                            Text("and")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("Privacy Policy")
                                .font(.caption)
                                .foregroundColor(.brandMint)
                                .underline()
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .padding()
            }
            
            if isLoading {
                Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brandMint))
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError, actions: {
            Button("OK") { showError = false }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
        .onAppear {
            Task {
                await subscriptionService.requestProducts()
            }
        }
    }
    
    // Current subscription status view
    private var currentSubscriptionStatus: some View {
        VStack(spacing: 8) {
            if preferences.subscriptionTier != .free {
                Text("Current Plan: \(preferences.subscriptionTier.rawValue.capitalized)")
                    .font(.headline)
                    .foregroundColor(.brandMint)
                
                if let expiryDate = preferences.subscriptionExpiryDate {
                    Text("Renews on \(expiryDate, formatter: dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                Text("Current Plan: Free")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // Subscription plans view
    private var subscriptionPlans: some View {
        VStack(spacing: 16) {
            // Free plan
            subscriptionPlanCard(
                title: "Free",
                price: "Free",
                features: [
                    "Basic chatbot functionality",
                    "Limited content recommendations",
                    "Daily inspiration",
                    "Basic meditations"
                ],
                isCurrentPlan: preferences.subscriptionTier == .free,
                action: {}
            )
            
            // Premium plan
            if let premiumProduct = subscriptionService.product(for: .premium) {
                subscriptionPlanCard(
                    title: "Premium",
                    price: premiumProduct.displayPrice,
                    features: [
                        "Unlimited AI spiritual guidance",
                        "Personalized meditations",
                        "Full content library access",
                        "Priority community support",
                        "Virtual spiritual retreats"
                    ],
                    isCurrentPlan: preferences.subscriptionTier == .premium,
                    action: {
                        Task {
                            await purchaseProduct(premiumProduct)
                        }
                    }
                )
            }
            
            // Guided plan
            if let guidedProduct = subscriptionService.product(for: .guided) {
                subscriptionPlanCard(
                    title: "Guided",
                    price: guidedProduct.displayPrice,
                    features: [
                        "All Premium features",
                        "Monthly 1-on-1 spiritual advisor",
                        "Custom growth plan",
                        "AI-enhanced insights",
                        "Exclusive events access"
                    ],
                    isCurrentPlan: preferences.subscriptionTier == .guided,
                    action: {
                        Task {
                            await purchaseProduct(guidedProduct)
                        }
                    }
                )
            }
        }
    }
    
    // Subscription plan card
    private func subscriptionPlanCard(title: String, price: String, features: [String], isCurrentPlan: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brandMint)
                
                Text(price)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if title != "Free" {
                    Text("per month")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Features
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.brandMint)
                            .font(.system(size: 16))
                        
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            
            // Button
            Button(action: action) {
                Text(isCurrentPlan ? "Current Plan" : "Subscribe")
                    .font(.headline)
                    .foregroundColor(isCurrentPlan ? .gray : .black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCurrentPlan ? Color.gray.opacity(0.3) : Color.brandMint)
                    .cornerRadius(12)
            }
            .disabled(isCurrentPlan)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentPlan ? Color.brandMint : Color.clear, lineWidth: 2)
        )
    }
    
    // Purchase a product
    private func purchaseProduct(_ product: Product) async {
        isLoading = true
        do {
            let success = try await subscriptionService.purchase(product)
            isLoading = false
            
            if success {
                // Dismiss the view after successful purchase
                DispatchQueue.main.async {
                    dismiss()
                }
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // Restore purchases
    private func restorePurchases() async {
        isLoading = true
        do {
            try await subscriptionService.restorePurchases()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // Direct purchase method for testing
    private func purchaseDirectly() async {
        isLoading = true
        do {
            // Create a direct purchase for the premium product ID
            let productID = SubscriptionProduct.premium.rawValue
            
            // Try to find the product in the loaded products
            if let product = subscriptionService.products.first(where: { $0.id == productID }) {
                let success = try await subscriptionService.purchase(product)
                isLoading = false
                
                if success {
                    // Dismiss the view after successful purchase
                    DispatchQueue.main.async {
                        dismiss()
                    }
                }
            } else {
                // If product isn't loaded, try to load it directly
                let products = try await Product.products(for: [productID])
                if let product = products.first {
                    let success = try await subscriptionService.purchase(product)
                    isLoading = false
                    
                    if success {
                        // Dismiss the view after successful purchase
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    }
                } else {
                    isLoading = false
                    errorMessage = "Could not find premium product"
                    showError = true
                }
            }
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // Date formatter for subscription expiry date
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

// Preview
struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SubscriptionView()
                .environmentObject(UserPreferences())
        }
    }
} 