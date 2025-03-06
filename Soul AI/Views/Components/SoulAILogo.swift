import SwiftUI

struct SoulAILogo: View {
    var size: CGFloat
    var color: Color = Color.AppTheme.brandMint
    
    var body: some View {
        ZStack {
            // Black background
            Rectangle()
                .fill(Color.black)
                .frame(width: size, height: size)
            
            // Turquoise cross
            Group {
                // Vertical bar
                Rectangle()
                    .fill(color)
                    .frame(width: size * 0.25, height: size * 0.75)
                
                // Horizontal bar
                Rectangle()
                    .fill(color)
                    .frame(width: size * 0.75, height: size * 0.25)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        SoulAILogo(size: 100)
        SoulAILogo(size: 60)
        SoulAILogo(size: 40)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
} 