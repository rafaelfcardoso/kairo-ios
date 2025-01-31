import Foundation

struct TodoTask: Identifiable, Codable {
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
}

// Since the API shows empty arrays for tags and focusSessions, 
// we'll create placeholder structs that we can fill in later
struct Tag: Codable {
    // Add properties when needed
}

struct FocusSession: Codable {
    // Add properties when needed
} 