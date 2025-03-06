import SwiftUI

extension Color {
    struct AppTheme {
        // Main background colors
        static let background = Color(.systemBackground)
        static let cardBackground = Color(.secondarySystemBackground)
        static let inputBackground = Color(.tertiarySystemBackground)
        
        // Text colors
        static let primaryText = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        
        // Brand colors
        static let brandMint = Color(red: 0, green: 0.8, blue: 0.6)
        static let brandBlue = Color(red: 0, green: 0.5, blue: 1.0)
        static let brandPurple = Color(red: 0.5, green: 0, blue: 1.0)
        
        // Fallback colors if custom colors aren't defined
        static var fallbackBackground: Color {
            return Color(.systemBackground)
        }
        
        static var fallbackCardBackground: Color {
            return Color(.secondarySystemBackground)
        }
        
        static var fallbackInputBackground: Color {
            return Color(.tertiarySystemBackground)
        }
        
        static var fallbackPrimaryText: Color {
            return Color(.label)
        }
        
        static var fallbackSecondaryText: Color {
            return Color(.secondaryLabel)
        }
    }
    
    // Existing brand color for backward compatibility
    static let brandMint = Color(red: 0, green: 0.8, blue: 0.6)
    
    // Adding brandBackground for backward compatibility - using a dark color
    static let brandBackground = Color(red: 0.1, green: 0.1, blue: 0.12)
}

// Extension to provide fallback colors if custom colors aren't defined
extension Color {
    static func named(_ name: String, fallback: Color) -> Color {
        if UIColor(named: name) != nil {
            return Color(name)
        }
        return fallback
    }
} 