import Foundation

/// Represents an individual element to block (website, app, or app category)
struct BlockItem: Codable, Identifiable, Equatable {
    /// Unique identifier for the block item
    var id: String
    
    /// Type of the block item (website, app, or app category)
    var type: BlockType
    
    /// The identifier for the item (domain, bundle ID, or category ID)
    var identifier: String
    
    /// User-friendly name for the item
    var name: String
    
    /// Whether the item is currently enabled
    var isActive: Bool
    
    /// ID of the parent block list
    var blockListId: String
    
    /// Creates a fully initialized BlockItem
    init(id: String = UUID().uuidString, 
         type: BlockType, 
         identifier: String, 
         name: String, 
         isActive: Bool = true, 
         blockListId: String) {
        self.id = id
        self.type = type
        self.identifier = identifier
        self.name = name
        self.isActive = isActive
        self.blockListId = blockListId
    }
    
    /// Converts a BlockItem to a local BlockingRule
    func toBlockingRule() -> BlockingRule {
        let ruleType: BlockingRuleType
        var category: BlockingCategory = .custom
        
        switch type {
        case .website:
            ruleType = .domain
        case .app:
            ruleType = .app
        case .appCategory:
            ruleType = .app
            // Note: This is a simplification. You might want to create a mapping
            // between backend app categories and local blocking categories
            category = .custom
        }
        
        return BlockingRule(
            name: name,
            type: ruleType,
            pattern: identifier,
            category: category
        )
    }
} 