import Foundation

enum MessageRole {
    case user
    case assistant
}

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let role: MessageRole
    let timestamp: Date
    
    init(content: String, role: MessageRole, timestamp: Date = Date()) {
        self.content = content
        self.role = role
        self.timestamp = timestamp
    }
} 