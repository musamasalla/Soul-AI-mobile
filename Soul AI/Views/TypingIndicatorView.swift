import SwiftUI

struct TypingIndicatorView: View {
    @State private var showCircle1 = false
    @State private var showCircle2 = false
    @State private var showCircle3 = false
    @EnvironmentObject private var preferences: UserPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: "cross.fill")
                    .foregroundColor(Color.brandMint)
                    .font(.system(size: 16))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.AppTheme.background))
                    .overlay(
                        Circle()
                            .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Soul AI")
                        .font(.caption)
                        .foregroundColor(Color.brandMint.opacity(0.7))
                    
                    HStack(spacing: 4) {
                        Circle()
                            .frame(width: 6, height: 6)
                            .foregroundColor(Color.brandMint.opacity(0.7))
                            .scaleEffect(showCircle1 ? 1.0 : 0.5)
                            .opacity(showCircle1 ? 1.0 : 0.5)
                        
                        Circle()
                            .frame(width: 6, height: 6)
                            .foregroundColor(Color.brandMint.opacity(0.7))
                            .scaleEffect(showCircle2 ? 1.0 : 0.5)
                            .opacity(showCircle2 ? 1.0 : 0.5)
                        
                        Circle()
                            .frame(width: 6, height: 6)
                            .foregroundColor(Color.brandMint.opacity(0.7))
                            .scaleEffect(showCircle3 ? 1.0 : 0.5)
                            .opacity(showCircle3 ? 1.0 : 0.5)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color.AppTheme.background)
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        let animation = Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)
        
        withAnimation(animation) {
            showCircle1 = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(animation) {
                showCircle2 = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(animation) {
                showCircle3 = true
            }
        }
    }
}

#Preview {
    TypingIndicatorView()
        .background(Color.AppTheme.background)
        .environmentObject(UserPreferences())
} 