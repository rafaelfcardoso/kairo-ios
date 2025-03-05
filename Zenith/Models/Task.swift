import Foundation

struct TodoTask: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let status: String
    let priority: String
    let dueDate: String?
    let hasTime: Bool
    let estimatedMinutes: Int
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let project: Project?
    let tags: [Tag]
    let focusSessions: [FocusSession]
    let isRecurring: Bool?
    let needsReminder: Bool?
}

// Since the API shows empty arrays for tags and focusSessions, 
// we'll create placeholder structs that we can fill in later
struct Tag: Codable {
    // Add properties when needed
}

struct FocusSession: Codable {
    let id: String?
    let startTime: String
    let endTime: String?
    let taskIds: [String]?
    let duration: Int?
    let isCompleted: Bool?
    
    // For creating a new focus session
    init(taskIds: [String]) {
        self.id = nil
        self.startTime = ISO8601DateFormatter().string(from: Date())
        self.endTime = nil
        self.taskIds = taskIds
        self.duration = nil
        self.isCompleted = nil
    }
} 