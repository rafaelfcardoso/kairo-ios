import Foundation

struct Project: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let isArchived: Bool
    let isSystem: Bool
    let color: String
    let order: Int
    let createdAt: String
    let updatedAt: String
    let taskCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case isArchived
        case isSystem
        case color
        case order
        case createdAt
        case updatedAt
        case taskCount = "pendingTasksCount"
    }
} 