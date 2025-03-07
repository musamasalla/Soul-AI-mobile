import Foundation

struct PremiumPodcast: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let audioUrl: String?
    let duration: Int
    let createdAt: Date
    let updatedAt: Date?
    let topic: String
    let voices: [String]
    let status: PodcastStatus
    let characterCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case audioUrl = "audio_url"
        case duration
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case topic
        case voices
        case status
        case characterCount = "character_count"
    }
}

// Voice options for premium podcasts
enum PodcastVoice: String, CaseIterable, Identifiable {
    case alloy = "alloy"
    case echo = "echo"
    case fable = "fable"
    case onyx = "onyx"
    case nova = "nova"
    case shimmer = "shimmer"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .alloy: return "Alloy (Female)"
        case .echo: return "Echo (Male)"
        case .fable: return "Fable (Male)"
        case .onyx: return "Onyx (Male)"
        case .nova: return "Nova (Female)"
        case .shimmer: return "Shimmer (Female)"
        }
    }
    
    var description: String {
        switch self {
        case .alloy: return "A versatile female voice with a natural, balanced tone"
        case .echo: return "A deep, resonant male voice with a warm quality"
        case .fable: return "A male voice with a storytelling quality and gentle pace"
        case .onyx: return "A powerful, authoritative male voice with clear articulation"
        case .nova: return "A bright, energetic female voice with a youthful quality"
        case .shimmer: return "A soft, melodic female voice with a soothing presence"
        }
    }
}

// Premium podcast topics
struct PremiumPodcastTopics {
    static let topics = [
        "Faith and Spirituality",
        "Christian Living",
        "Prayer and Meditation",
        "Bible Study",
        "Worship and Praise",
        "Family and Relationships",
        "Personal Growth",
        "Church and Community",
        "Missions and Outreach",
        "Christian History",
        "Theology and Doctrine",
        "Apologetics",
        "Discipleship",
        "Leadership",
        "Evangelism"
    ]
} 