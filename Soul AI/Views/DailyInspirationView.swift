import SwiftUI

struct DailyInspirationView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inspiration: String = "Loading today's inspiration..."
    @State private var isLoading: Bool = true
    
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
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
                .background(Color(.systemGray6).opacity(0.2))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Share button
                Button(action: {
                    shareInspiration()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 30)
                    .background(Color.brandMint)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1.0)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadDailyInspiration()
        }
    }
    
    private func loadDailyInspiration() {
        isLoading = true
        viewModel.getDailyInspiration { receivedInspiration in
            inspiration = receivedInspiration
            isLoading = false
        }
    }
    
    private func shareInspiration() {
        let activityVC = UIActivityViewController(
            activityItems: ["Today's Christian Inspiration from Soul AI: \(inspiration)"],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

#Preview {
    DailyInspirationView()
} 