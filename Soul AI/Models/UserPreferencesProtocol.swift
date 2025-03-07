import Foundation

protocol UserPreferencesProtocol {
    // User state
    func isUserLoggedIn() -> Bool
    func getCurrentUser() -> User?
    func getSubscriptionStatus() -> UserSubscriptionStatus
    func clearUserData()
    
    // Character usage
    func getCharacterUsage() -> Int
    func getCharacterLimit() -> Int
    func updateCharacterUsage(newUsage: Int)
    func hasEnoughCharactersFor(duration: Int) -> Bool
    
    // Properties
    var remainingCharacters: Int { get }
    var remainingPodcastMinutes: Int { get }
} 