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
        // Initialize all stored properties with default values first
        // This ensures all properties are initialized before any didSet is triggered
        self.hasSeenWelcome = false
        self.isDarkMode = false // Temporary value, will be set correctly below
        self.fontSize = .medium
        self.userName = "User"
        self.subscriptionTier = .free
        self.subscriptionExpiryDate = nil
        self.characterUsage = CharacterUsage()
        self.dailyInspirationNotifications = false
        self.prayerReminderNotifications = false
        self.currentUser = nil
        
        // Batch read from UserDefaults to improve performance
        let defaults = UserDefaults.standard
        let allKeys = [
            "hasSeenWelcome", "isDarkMode", "fontSize", "userName", 
            "subscriptionTier", "subscriptionExpiryDate", "characterUsage",
            "dailyInspirationNotifications", "prayerReminderNotifications", "currentUser"
        ]
        let userDefaultsDict = defaults.dictionaryRepresentation().filter { allKeys.contains($0.key) }
        
        // Load hasSeenWelcome
        self.hasSeenWelcome = userDefaultsDict["hasSeenWelcome"] as? Bool ?? false
        
        // Load isDarkMode
        if let isDarkMode = userDefaultsDict["isDarkMode"] as? Bool {
            self.isDarkMode = isDarkMode
        } else {
            // Use system appearance as default
            let systemAppearance = UITraitCollection.current.userInterfaceStyle
            self.isDarkMode = systemAppearance == .dark
            // Save the initial value
            defaults.set(self.isDarkMode, forKey: "isDarkMode")
        }
        
        // Load fontSize
        if let fontSizeRawValue = userDefaultsDict["fontSize"] as? String,
           let fontSize = FontSize(rawValue: fontSizeRawValue) {
            self.fontSize = fontSize
        }
        
        // Load userName
        if let savedUserName = userDefaultsDict["userName"] as? String, !savedUserName.isEmpty {
            self.userName = savedUserName
        }
        
        // Load subscriptionTier
        if let subscriptionTierRawValue = userDefaultsDict["subscriptionTier"] as? String,
           let tier = SubscriptionTier(rawValue: subscriptionTierRawValue) {
            self.subscriptionTier = tier
        }
        
        // Load subscriptionExpiryDate
        self.subscriptionExpiryDate = userDefaultsDict["subscriptionExpiryDate"] as? Date
        
        // Load character usage
        if let savedUsageData = userDefaultsDict["characterUsage"] as? Data,
           let savedUsage = try? JSONDecoder().decode(CharacterUsage.self, from: savedUsageData) {
            savedUsage.checkAndResetIfNeeded() // Check if we need to reset based on date
            self.characterUsage = savedUsage
        }
        
        // Load notification preferences
        self.dailyInspirationNotifications = userDefaultsDict["dailyInspirationNotifications"] as? Bool ?? false
        self.prayerReminderNotifications = userDefaultsDict["prayerReminderNotifications"] as? Bool ?? false
        
        // Load current user
        if let userData = userDefaultsDict["currentUser"] as? Data,
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        }
        
        // Defer subscription status fetch to happen after app is visible
        // This improves initial launch time
        Task {
            // Add a small delay to prioritize UI rendering
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
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
        
        // No need to extract anything here, we'll handle it in the switch statement
        
        await MainActor.run {
            switch result {
            case .success(let status):
                if status.isActive {
                    if let tier = SubscriptionTier(rawValue: status.tier) {
                        self.subscriptionTier = tier
                    } else {
                        self.subscriptionTier = .free
                    }
                    
                    // Set expiry date if available
                    if let expiryDate = status.expiresAt {
                        self.subscriptionExpiryDate = expiryDate
                    }
                } else {
                    self.subscriptionTier = .free
                    self.subscriptionExpiryDate = nil
                }
            case .failure(let error):
                print("Failed to fetch subscription status: \(error.localizedDescription)")
                // Default to free tier on error
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