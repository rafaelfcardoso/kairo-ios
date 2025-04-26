import Foundation

/// Represents a category of applications
struct AppCategory: Codable, Identifiable, Equatable {
    /// Unique identifier for the category
    var id: String
    
    /// System identifier (for integration with platform APIs)
    var systemId: String
    
    /// Display name for the category
    var name: String
    
    /// Additional details about the category
    var description: String
    
    /// Whether the category is currently enabled
    var isActive: Bool
    
    /// Creates a fully initialized AppCategory
    init(id: String = UUID().uuidString,
         systemId: String,
         name: String,
         description: String = "",
         isActive: Bool = true) {
        self.id = id
        self.systemId = systemId
        self.name = name
        self.description = description
        self.isActive = isActive
    }
    
    /// Creates a BlockItem from this AppCategory
    func toBlockItem(blockListId: String) -> BlockItem {
        BlockItem(
            type: .appCategory,
            identifier: id,
            name: name,
            isActive: isActive,
            blockListId: blockListId
        )
    }
} 