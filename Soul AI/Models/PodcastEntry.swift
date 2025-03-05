import Foundation

struct PodcastEntry: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let chapter: String
    let audioUrl: String?
    let status: PodcastStatus
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case chapter
        case audioUrl = "audio_url"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: String, title: String, description: String, chapter: String, audioUrl: String?, status: PodcastStatus, createdAt: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.chapter = chapter
        self.audioUrl = audioUrl
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        
        // Handle potentially missing description
        if let desc = try? container.decode(String.self, forKey: .description) {
            description = desc
        } else {
            description = ""
        }
        
        chapter = try container.decode(String.self, forKey: .chapter)
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)
        
        // Handle potentially missing or invalid status
        if let statusString = try? container.decode(String.self, forKey: .status),
           let decodedStatus = PodcastStatus(rawValue: statusString) {
            status = decodedStatus
        } else {
            status = .failed
        }
        
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

enum PodcastStatus: String, Codable {
    case generating
    case ready
    case failed
}

struct BibleStructure {
    struct Testament {
        let name: String
        let books: [Book]
    }
    
    struct Book {
        let name: String
        let chapters: Int
    }
    
    static let structure: [Testament] = [
        Testament(
            name: "Old Testament",
            books: [
                Book(name: "Genesis", chapters: 50),
                Book(name: "Exodus", chapters: 40),
                Book(name: "Leviticus", chapters: 27),
                Book(name: "Numbers", chapters: 36),
                Book(name: "Deuteronomy", chapters: 34),
                Book(name: "Joshua", chapters: 24),
                Book(name: "Judges", chapters: 21),
                Book(name: "Ruth", chapters: 4),
                Book(name: "1 Samuel", chapters: 31),
                Book(name: "2 Samuel", chapters: 24),
                Book(name: "1 Kings", chapters: 22),
                Book(name: "2 Kings", chapters: 25),
                Book(name: "1 Chronicles", chapters: 29),
                Book(name: "2 Chronicles", chapters: 36),
                Book(name: "Ezra", chapters: 10),
                Book(name: "Nehemiah", chapters: 13),
                Book(name: "Esther", chapters: 10),
                Book(name: "Job", chapters: 42),
                Book(name: "Psalms", chapters: 150),
                Book(name: "Proverbs", chapters: 31),
                Book(name: "Ecclesiastes", chapters: 12),
                Book(name: "Song of Solomon", chapters: 8),
                Book(name: "Isaiah", chapters: 66),
                Book(name: "Jeremiah", chapters: 52),
                Book(name: "Lamentations", chapters: 5),
                Book(name: "Ezekiel", chapters: 48),
                Book(name: "Daniel", chapters: 12),
                Book(name: "Hosea", chapters: 14),
                Book(name: "Joel", chapters: 3),
                Book(name: "Amos", chapters: 9),
                Book(name: "Obadiah", chapters: 1),
                Book(name: "Jonah", chapters: 4),
                Book(name: "Micah", chapters: 7),
                Book(name: "Nahum", chapters: 3),
                Book(name: "Habakkuk", chapters: 3),
                Book(name: "Zephaniah", chapters: 3),
                Book(name: "Haggai", chapters: 2),
                Book(name: "Zechariah", chapters: 14),
                Book(name: "Malachi", chapters: 4)
            ]
        ),
        Testament(
            name: "New Testament",
            books: [
                Book(name: "Matthew", chapters: 28),
                Book(name: "Mark", chapters: 16),
                Book(name: "Luke", chapters: 24),
                Book(name: "John", chapters: 21),
                Book(name: "Acts", chapters: 28),
                Book(name: "Romans", chapters: 16),
                Book(name: "1 Corinthians", chapters: 16),
                Book(name: "2 Corinthians", chapters: 13),
                Book(name: "Galatians", chapters: 6),
                Book(name: "Ephesians", chapters: 6),
                Book(name: "Philippians", chapters: 4),
                Book(name: "Colossians", chapters: 4),
                Book(name: "1 Thessalonians", chapters: 5),
                Book(name: "2 Thessalonians", chapters: 3),
                Book(name: "1 Timothy", chapters: 6),
                Book(name: "2 Timothy", chapters: 4),
                Book(name: "Titus", chapters: 3),
                Book(name: "Philemon", chapters: 1),
                Book(name: "Hebrews", chapters: 13),
                Book(name: "James", chapters: 5),
                Book(name: "1 Peter", chapters: 5),
                Book(name: "2 Peter", chapters: 3),
                Book(name: "1 John", chapters: 5),
                Book(name: "2 John", chapters: 1),
                Book(name: "3 John", chapters: 1),
                Book(name: "Jude", chapters: 1),
                Book(name: "Revelation", chapters: 22)
            ]
        )
    ]
} 