import Foundation

enum PodcastStatus: String, Codable {
    case generating
    case generating_script
    case generating_audio
    case uploading
    case ready
    case failed
} 