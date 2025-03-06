import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    var name: String
    var profileImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case profileImageUrl = "profile_image_url"
    }
}

struct SubscriptionStatus: Codable {
    let isActive: Bool
    let tier: String
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
        case tier
        case expiresAt = "expires_at"
    }
} 