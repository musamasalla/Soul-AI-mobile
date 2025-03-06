import Foundation
import SwiftUI

enum SubscriptionTier: String, Codable {
    case free = "free"
    case premium = "premium"
    case guided = "guided"
}

class UserPreferences: ObservableObject, UserPreferencesProtocol {
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
    
    @Published var subscriptionTier: SubscriptionTier {
        didSet {
            UserDefaults.standard.set(subscriptionTier.rawValue, forKey: "subscriptionTier")
        }
    }
    
    @Published var subscriptionExpiryDate: Date? {
        didSet {
            UserDefaults.standard.set(subscriptionExpiryDate, forKey: "subscriptionExpiryDate")
        }
    }
    
    @Published var characterUsage: CharacterUsage {
        didSet {
            if let encodedData = try? JSONEncoder().encode(characterUsage) {
                UserDefaults.standard.set(encodedData, forKey: "characterUsage")
            }
        }
    }
    
    // Add notification preferences
    @Published var dailyInspirationNotifications: Bool {
        didSet {
            UserDefaults.standard.set(dailyInspirationNotifications, forKey: "dailyInspirationNotifications")
        }
    }
    
    @Published var prayerReminderNotifications: Bool {
        didSet {
            UserDefaults.standard.set(prayerReminderNotifications, forKey: "prayerReminderNotifications")
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
        
        if let subscriptionTierRawValue = UserDefaults.standard.string(forKey: "subscriptionTier"),
           let tier = SubscriptionTier(rawValue: subscriptionTierRawValue) {
            self.subscriptionTier = tier
        } else {
            self.subscriptionTier = .free
        }
        
        self.subscriptionExpiryDate = UserDefaults.standard.object(forKey: "subscriptionExpiryDate") as? Date
        
        // Load character usage or create default
        if let savedUsageData = UserDefaults.standard.data(forKey: "characterUsage"),
           let savedUsage = try? JSONDecoder().decode(CharacterUsage.self, from: savedUsageData) {
            var usage = savedUsage
            usage.checkAndResetIfNeeded() // Check if we need to reset based on date
            self.characterUsage = usage
        } else {
            self.characterUsage = CharacterUsage()
        }
        
        // Initialize notification preferences
        self.dailyInspirationNotifications = UserDefaults.standard.bool(forKey: "dailyInspirationNotifications")
        self.prayerReminderNotifications = UserDefaults.standard.bool(forKey: "prayerReminderNotifications")
    }
    
    var isSubscriptionActive: Bool {
        if subscriptionTier == .free {
            return false
        }
        
        if let expiryDate = subscriptionExpiryDate {
            return expiryDate > Date()
        }
        
        return false
    }
    
    // Add character usage and save
    func addCharacterUsage(_ characters: Int) {
        characterUsage.addUsage(characters)
    }
    
    // Check if user has enough characters for a podcast of given duration
    func hasEnoughCharactersFor(duration: Int) -> Bool {
        return characterUsage.hasEnoughCharactersFor(duration: duration)
    }
    
    // Get remaining characters
    var remainingCharacters: Int {
        return characterUsage.remainingCharacters
    }
    
    // Get remaining minutes
    var remainingPodcastMinutes: Int {
        return characterUsage.remainingMinutes
    }
    
    // MARK: - UserPreferencesProtocol
    
    func isUserLoggedIn() -> Bool {
        return isSubscriptionActive
    }
    
    func getCurrentUser() -> User? {
        // This would typically come from a user object stored in UserDefaults or Keychain
        // For now, we'll return a mock user if the subscription is active
        if isSubscriptionActive {
            return User(id: UUID().uuidString, email: "user@example.com", name: userName)
        }
        return nil
    }
    
    func getSubscriptionStatus() -> SubscriptionStatus {
        return SubscriptionStatus(
            isActive: isSubscriptionActive,
            tier: subscriptionTier.rawValue,
            expiresAt: subscriptionExpiryDate
        )
    }
    
    func clearUserData() {
        subscriptionTier = .free
        subscriptionExpiryDate = nil
        characterUsage = CharacterUsage()
    }
    
    func getCharacterUsage() -> Int {
        return characterUsage.totalCharactersUsed
    }
    
    func getCharacterLimit() -> Int {
        return characterUsage.monthlyLimit
    }
    
    func updateCharacterUsage(newUsage: Int) {
        characterUsage.totalCharactersUsed = newUsage
    }
    
    // MARK: - UserPreferencesProtocol Properties
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