import Foundation

struct ChatSession: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    let createdAt: Date
    
    init(title: String, messages: [ChatMessage] = [], createdAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
