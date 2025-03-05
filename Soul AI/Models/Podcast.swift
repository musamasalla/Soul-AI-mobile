import Foundation

struct Podcast {
    let title: String
    let content: String
    let duration: Int
}

struct PodcastResponse: Codable {
    let title: String
    let content: String
    let duration: Int
} 