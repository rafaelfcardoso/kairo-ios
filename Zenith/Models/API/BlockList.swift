import Foundation

/// Represents a collection of items to block
struct BlockList: Codable, Identifiable, Equatable {
    /// Unique identifier for the block list
    var id: String
    
    /// User-friendly name for the list
    var name: String
    
    /// Optional details about the list
    var description: String
    
    /// Whether the list is currently enabled
    var isActive: Bool
    
    /// Whether it's a pre-defined system list
    var isDefault: Bool
    
    /// User ID of the list owner
    var userId: String
    
    /// Related BlockItems in this list
    var items: [BlockItem]?
    
    /// Creates a fully initialized BlockList
    init(id: String = UUID().uuidString,
         name: String,
         description: String = "",
         isActive: Bool = true,
         isDefault: Bool = false,
         userId: String,
         items: [BlockItem]? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.isActive = isActive
        self.isDefault = isDefault
        self.userId = userId
        self.items = items
    }
    
    /// Converts a BlockList to a local BlockingProfile
    func toBlockingProfile() -> BlockingProfile {
        let rules = items?.map { $0.toBlockingRule() } ?? []
        
        return BlockingProfile(
            name: name,
            description: description
        ).with(\.isActive, isActive)
         .with(\.rules, rules)
    }
}

/// Helper function to modify structs
extension BlockingProfile {
    func with<T>(_ keyPath: WritableKeyPath<BlockingProfile, T>, _ value: T) -> BlockingProfile {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
} 