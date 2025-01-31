import Foundation

struct Project: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let isArchived: Bool
    let color: String
    let order: Int
    let createdAt: String
    let updatedAt: String
} 