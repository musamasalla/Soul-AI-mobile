import SwiftUI

struct WelcomeView: View {
    @Binding var hasSeenWelcome: Bool
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var preferences: UserPreferences
    @State private var username: String = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.brandBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App logo
                VStack(spacing: 10) {
                    Text("Soul AI")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.brandMint)
                    
                    Image(systemName: "cross.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.brandMint)
                }
                .padding()
                
                // App description
                Text("Your Christian companion for spiritual guidance, biblical wisdom, and faith-based conversations.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .foregroundColor(.brandMint)
                
                Spacer()
                
                // Features list
                VStack(alignment: .leading, spacing: 20) {
                    featureRow(icon: "book.fill", title: "Biblical Wisdom", description: "Access scripture and biblical teachings")
                    
                    featureRow(icon: "heart.fill", title: "Faith Support", description: "Get guidance for your spiritual journey")
                    
                    featureRow(icon: "person.2.fill", title: "Christian Community", description: "Connect with faith-based perspectives")
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Username input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.headline)
                        .foregroundColor(.brandMint)
                    
                    TextField("Enter your name", text: $username)
                        .padding()
                        .background(Color(.systemGray6).opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.brandMint, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
                
                // Dark mode toggle
                Toggle("Enable Dark Mode", isOn: $preferences.isDarkMode)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                    .foregroundColor(.brandMint)
                    .tint(.brandMint)
                
                // Get started button
                Button(action: {
                    if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        preferences.userName = username
                    }
                    withAnimation {
                        hasSeenWelcome = true
                    }
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandMint)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Force dark mode to match the brand aesthetic
            preferences.isDarkMode = true
            username = preferences.userName
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.brandMint)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.brandMint)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

#Preview {
    Group {
        WelcomeView(hasSeenWelcome: .constant(false))
            .environmentObject(UserPreferences())
    }
} 