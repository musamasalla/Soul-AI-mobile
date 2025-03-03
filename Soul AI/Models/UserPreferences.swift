import Foundation
import SwiftUI

class UserPreferences: ObservableObject {
    @Published var hasSeenWelcome: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenWelcome, forKey: "hasSeenWelcome")
        }
    }
    
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    @Published var fontSize: FontSize {
        didSet {
            UserDefaults.standard.set(fontSize.rawValue, forKey: "fontSize")
        }
    }
    
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }
    
    init() {
        self.hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
        if let fontSizeRawValue = UserDefaults.standard.string(forKey: "fontSize"),
           let fontSize = FontSize(rawValue: fontSizeRawValue) {
            self.fontSize = fontSize
        } else {
            self.fontSize = .medium
        }
        
        if let savedUserName = UserDefaults.standard.string(forKey: "userName"), !savedUserName.isEmpty {
            self.userName = savedUserName
        } else {
            self.userName = "User"
        }
    }
}

enum FontSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var id: String { self.rawValue }
    
    var textSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
} 