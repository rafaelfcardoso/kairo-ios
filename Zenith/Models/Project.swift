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
        case taskCount = "notStartedTasksCount"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        isSystem = try container.decode(Bool.self, forKey: .isSystem)
        color = try container.decode(String.self, forKey: .color)
        order = try container.decode(Int.self, forKey: .order)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        taskCount = try container.decodeIfPresent(Int.self, forKey: .taskCount)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Normalize system project name
        let rawName = try container.decode(String.self, forKey: .name)
        name = isSystem ? "Entrada" : rawName
    }
} 