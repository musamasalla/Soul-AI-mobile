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
            print("DEBUG: Dark mode preference changed to \(isDarkMode)")
            // Force UI update by posting a notification
            NotificationCenter.default.post(name: Notification.Name("DarkModeChanged"), object: nil)
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
    
    // Store the current user
    @Published var currentUser: User? {
        didSet {
            if let user = currentUser, let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            } else {
                UserDefaults.standard.removeObject(forKey: "currentUser")
            }
        }
    }
    
    init() {
        self.hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
        
        // Check if dark mode preference exists, otherwise use system appearance
        if UserDefaults.standard.object(forKey: "isDarkMode") != nil {
            self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        } else {
            // Use system appearance as default
            let systemAppearance = UITraitCollection.current.userInterfaceStyle
            self.isDarkMode = systemAppearance == .dark
            // Save the initial value
            UserDefaults.standard.set(self.isDarkMode, forKey: "isDarkMode")
        }
        
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
        
        // Load current user
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        } else {
            self.currentUser = nil
        }
        
        // Fetch subscription status from Supabase
        Task {
            await fetchSubscriptionStatus()
        }
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
    
    // Fetch subscription status from Supabase
    func fetchSubscriptionStatus() async {
        let result = await SupabaseService.shared.fetchSubscriptionStatus()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch result {
            case .success(let status):
                if status.isActive {
                    if let tier = SubscriptionTier(rawValue: status.tier) {
                        self.subscriptionTier = tier
                    } else {
                        self.subscriptionTier = .free
                    }
                    self.subscriptionExpiryDate = status.expiresAt
                } else {
                    self.subscriptionTier = .free
                    self.subscriptionExpiryDate = nil
                }
            case .failure:
                // In case of error, default to free tier
                self.subscriptionTier = .free
                self.subscriptionExpiryDate = nil
            }
        }
    }
    
    // MARK: - UserPreferencesProtocol
    
    func isUserLoggedIn() -> Bool {
        return currentUser != nil
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func getSubscriptionStatus() -> UserSubscriptionStatus {
        return UserSubscriptionStatus(
            isActive: isSubscriptionActive,
            tier: subscriptionTier.rawValue,
            expiresAt: subscriptionExpiryDate
        )
    }
    
    func clearUserData() {
        currentUser = nil
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