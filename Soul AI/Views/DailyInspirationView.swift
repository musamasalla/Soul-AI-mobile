import SwiftUI

struct DailyInspirationView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inspiration: String = "Loading today's inspiration..."
    @State private var isLoading: Bool = true
    @EnvironmentObject private var preferences: UserPreferences
    
    var body: some View {
        ZStack {
            // Background
            Color.brandBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                Text("Daily Inspiration")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.brandMint)
                    .padding(.top, 20)
                
                Spacer()
                
                // Inspiration card
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .brandMint))
                            .scaleEffect(1.5)
                    } else {
                        // Cross icon
                        Image(systemName: "cross.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.brandMint)
                        
                        // Inspiration text
                        Text(inspiration)
                            .font(.system(size: 20))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primaryText)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .background(Color.cardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Share button
                Button(action: {
                    // Share functionality
                    let activityVC = UIActivityViewController(activityItems: [inspiration], applicationActivities: nil)
                    
                    // Present the activity view controller
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(activityVC, animated: true, completion: nil)
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                        
                        Text("Share Inspiration")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.brandMint)
                    .cornerRadius(30)
                }
                .padding(.bottom, 30)
                
                Spacer()
            }
        }
        .preferredColorScheme(preferences.isDarkMode ? .dark : .light)
        .onAppear {
            // Simulate loading an inspiration
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                inspiration = "\"Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.\" - Proverbs 3:5-6"
                isLoading = false
            }
        }
    }
}

#Preview {
    DailyInspirationView()
        .environmentObject(UserPreferences())
} 