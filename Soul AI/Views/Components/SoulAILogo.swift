import SwiftUI

struct SoulAILogo: View {
    var size: CGFloat
    var color: Color = Color.AppTheme.brandMint
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Dynamic background based on color scheme
            Rectangle()
                .fill(colorScheme == .dark ? Color.AppTheme.darkModeCardBackground : Color.AppTheme.lightModeCardBackground)
                .frame(width: size, height: size)
                .overlay(
                    Rectangle()
                        .stroke(color.opacity(0.3), lineWidth: colorScheme == .light ? 1 : 0)
                )
            
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