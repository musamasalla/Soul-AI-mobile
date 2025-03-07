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
    let status: String?
    let expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
        case tier
        case status
        case expiresAt = "expires_at"
    }
    
    init(isActive: Bool, tier: String, status: String? = nil, expiresAt: Date? = nil) {
        self.isActive = isActive
        self.tier = tier
        self.status = status
        self.expiresAt = expiresAt
    }
} 