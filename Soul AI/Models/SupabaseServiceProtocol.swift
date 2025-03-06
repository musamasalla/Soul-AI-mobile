import Foundation

protocol SupabaseServiceProtocol {
    // Authentication
    func signUp(email: String, password: String) async -> Result<User, Error>
    func signIn(email: String, password: String) async -> Result<User, Error>
    func signOut() async -> Result<Void, Error>
    func resetPassword(email: String) async -> Result<Void, Error>
    func getCurrentUser() async -> Result<User?, Error>
    func updateUser(user: User) async -> Result<User, Error>
    
    // Subscription
    func fetchSubscriptionStatus() async -> Result<SubscriptionStatus, Error>
    
    // Premium Podcasts
    func fetchPremiumPodcasts() async -> Result<[PremiumPodcast], Error>
    func generatePremiumPodcast(topic: String, duration: Int, voices: [String]) async -> Result<PremiumPodcast, Error>
} 