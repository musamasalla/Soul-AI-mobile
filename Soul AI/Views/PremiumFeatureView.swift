import SwiftUI

struct PremiumFeatureView<Content: View>: View {
    @EnvironmentObject private var preferences: UserPreferences
    @State private var showSubscriptionView = false
    let content: Content
    let featureName: String
    let featureDescription: String
    let featureIcon: String
    
    init(featureName: String, featureDescription: String, featureIcon: String, @ViewBuilder content: () -> Content) {
        self.featureName = featureName
        self.featureDescription = featureDescription
        self.featureIcon = featureIcon
        self.content = content()
    }
    
    var body: some View {
        Group {
            if preferences.subscriptionTier != .free {
                // Show the actual content if user is premium
                content
            } else {
                // Show paywall if user is not premium
                paywallView
            }
        }
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView()
        }
    }
    
    private var paywallView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Feature icon
            Image(systemName: featureIcon)
                .font(.system(size: 60))
                .foregroundColor(.brandMint)
                .padding()
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                )
            
            // Feature name and description
            VStack(spacing: 8) {
                Text(featureName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.brandMint)
                
                Text(featureDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 32)
            }
            
            // Premium features list
            VStack(alignment: .leading, spacing: 12) {
                Text("Premium Features Include:")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                featureRow(icon: "infinity", text: "Unlimited AI spiritual guidance")
                featureRow(icon: "heart.fill", text: "Personalized meditations")
                featureRow(icon: "book.fill", text: "Full content library access")
                featureRow(icon: "person.fill.checkmark", text: "Priority community support")
                featureRow(icon: "sparkles", text: "Virtual spiritual retreats")
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(16)
            
            // Upgrade button
            Button(action: {
                showSubscriptionView = true
            }) {
                Text("Upgrade to Premium")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandMint)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            
            Spacer()
        }
        .padding()
        .background(Color.black)
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.brandMint)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

// Preview
struct PremiumFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumFeatureView(
            featureName: "Advanced Meditation",
            featureDescription: "Access personalized guided meditations tailored to your spiritual journey",
            featureIcon: "heart.fill"
        ) {
            Text("This is premium content")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
        .environmentObject(UserPreferences())
    }
} 