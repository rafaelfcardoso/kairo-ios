import Foundation

/// Represents a legacy individual block setting
struct BlockSetting: Codable, Identifiable, Equatable {
    /// Unique identifier for the block setting
    var id: String
    
    /// Type of block (app, website, or app_category)
    var type: BlockType
    
    /// The identifier for the item (domain, bundle ID, or category ID)
    var identifier: String
    
    /// Whether the block is active
    var isActive: Bool
    
    /// Creates a fully initialized BlockSetting
    init(id: String = UUID().uuidString,
         type: BlockType,
         identifier: String,
         isActive: Bool = true) {
        self.id = id
        self.type = type
        self.identifier = identifier
        self.isActive = isActive
    }
    
    /// Converts a BlockSetting to a BlockItem
    func toBlockItem(name: String, blockListId: String) -> BlockItem {
        BlockItem(
            id: id,
            type: type,
            identifier: identifier,
            name: name,
            isActive: isActive,
            blockListId: blockListId
        )
    }
    
    /// Converts a BlockSetting to a local BlockingRule
    func toBlockingRule(name: String, category: BlockingCategory = .custom) -> BlockingRule {
        let ruleType: BlockingRuleType
        
        switch type {
        case .website:
            ruleType = .domain
        case .app:
            ruleType = .app
        case .appCategory:
            ruleType = .app
        }
        
        return BlockingRule(
            name: name,
            type: ruleType,
            pattern: identifier,
            category: category
        ).with(\.isActive, isActive)
    }
}

/// Helper function to modify structs
extension BlockingRule {
    func with<T>(_ keyPath: WritableKeyPath<BlockingRule, T>, _ value: T) -> BlockingRule {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
} 