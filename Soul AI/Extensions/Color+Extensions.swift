import SwiftUI

extension Color {
    struct AppTheme {
        static let mint = Color("AppColors")
        
        // Dynamic background color based on color scheme
        static let background = Color("BackgroundColor")
        
        // Dynamic text colors
        static let primaryText = Color("PrimaryText")
        static let secondaryText = Color("SecondaryText")
        
        // Dynamic UI element colors
        static let cardBackground = Color("CardBackground")
        static let inputBackground = Color("InputBackground")
    }
    
    // For backward compatibility
    static let brandMint = AppTheme.mint
} 