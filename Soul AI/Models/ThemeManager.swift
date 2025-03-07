import SwiftUI

class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme
    
    init(isDarkMode: Bool) {
        self.colorScheme = isDarkMode ? .dark : .light
        print("DEBUG: ThemeManager initialized with colorScheme: \(colorScheme)")
    }
    
    func toggleColorScheme() {
        colorScheme = colorScheme == .dark ? .light : .dark
        print("DEBUG: ThemeManager toggled colorScheme to: \(colorScheme)")
    }
    
    func updateColorScheme(isDarkMode: Bool) {
        colorScheme = isDarkMode ? .dark : .light
        print("DEBUG: ThemeManager updated colorScheme to: \(colorScheme)")
    }
} 