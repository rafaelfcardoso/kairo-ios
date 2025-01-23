import Foundation

struct Task: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let status: String
    let priority: String
    let dueDate: String?
    let estimatedMinutes: Int
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let project: Project?
    let tags: [Tag]
    let focusSessions: [FocusSession]
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status, priority
        case dueDate, estimatedMinutes, isArchived
        case createdAt, updatedAt, project, tags, focusSessions
    }
}

struct Project: Codable {
    let id: String
    let name: String
    let description: String
    let isArchived: Bool
    let color: String
    let order: Int
    let createdAt: String
    let updatedAt: String
}

// Since the API shows empty arrays for tags and focusSessions, 
// we'll create placeholder structs that we can fill in later
struct Tag: Codable {
    // Add properties when needed
}

struct FocusSession: Codable {
    // Add properties when needed
} 