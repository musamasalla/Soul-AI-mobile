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
        
        // Light mode specific colors
        static var lightModeBackground: Color {
            return Color(red: 0.95, green: 0.95, blue: 0.97)
        }
        
        static var lightModeCardBackground: Color {
            return Color.white
        }
        
        static var lightModeInputBackground: Color {
            return Color(red: 0.9, green: 0.9, blue: 0.92)
        }
        
        static var lightModePrimaryText: Color {
            return Color(red: 0.1, green: 0.1, blue: 0.12)
        }
        
        static var lightModeSecondaryText: Color {
            return Color(red: 0.3, green: 0.3, blue: 0.35)
        }
        
        // Dark mode specific colors
        static var darkModeBackground: Color {
            return Color(red: 0.1, green: 0.1, blue: 0.12)
        }
        
        static var darkModeCardBackground: Color {
            return Color(red: 0.15, green: 0.15, blue: 0.17)
        }
        
        static var darkModeInputBackground: Color {
            return Color(red: 0.2, green: 0.2, blue: 0.22)
        }
        
        static var darkModePrimaryText: Color {
            return Color.white
        }
        
        static var darkModeSecondaryText: Color {
            return Color(red: 0.7, green: 0.7, blue: 0.75)
        }
        
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
    
    // Adding brandBackground for backward compatibility - using dynamic color
    static var brandBackground: Color {
        @Environment(\.colorScheme) var colorScheme
        return colorScheme == .dark ? 
            Color(red: 0.1, green: 0.1, blue: 0.12) : 
            Color(red: 0.95, green: 0.95, blue: 0.97)
    }
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