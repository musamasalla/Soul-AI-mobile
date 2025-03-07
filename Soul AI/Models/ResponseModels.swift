import Foundation

// MARK: - Chat Response
struct ChatResponse: Codable {
    let response: String
}

// MARK: - Meditation Response
struct MeditationResponse: Codable {
    let title: String
    let content: String
    let duration: Int
    
    enum CodingKeys: String, CodingKey {
        case title, content, duration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        
        // Duration might be a string or an int, handle both cases
        if let durationInt = try? container.decode(Int.self, forKey: .duration) {
            duration = durationInt
        } else if let durationString = try? container.decode(String.self, forKey: .duration),
                  let durationInt = Int(durationString) {
            duration = durationInt
        } else {
            duration = 5 // Default to 5 minutes if not specified
        }
    }
}

// MARK: - Inspiration Response
struct InspirationResponse: Codable {
    let verse: String
    let reflection: String
    let prayer: String
} 