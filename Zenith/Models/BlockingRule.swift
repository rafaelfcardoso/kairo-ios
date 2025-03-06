import Foundation

/// Represents a rule for blocking content
struct BlockingRule: Codable, Identifiable, Equatable {
    /// Unique identifier for the rule
    var id: UUID = UUID()
    
    /// Name of the rule (e.g., "Social Media", "News Sites")
    var name: String
    
    /// Type of rule (domain, app, etc.)
    var type: BlockingRuleType
    
    /// The pattern to match (domain name, app bundle ID, etc.)
    var pattern: String
    
    /// Whether the rule is currently active
    var isActive: Bool = true
    
    /// Category of the rule
    var category: BlockingCategory
    
    /// Custom init with name and pattern
    init(name: String, type: BlockingRuleType, pattern: String, category: BlockingCategory) {
        self.name = name
        self.type = type
        self.pattern = pattern
        self.category = category
    }
}

/// Types of blocking rules
enum BlockingRuleType: String, Codable, CaseIterable {
    /// Block specific domain names
    case domain
    
    /// Block specific apps by bundle ID
    case app
    
    /// Block based on keywords in URL
    case keyword
    
    /// Block based on IP address
    case ipAddress
}

/// Categories for blocking rules
enum BlockingCategory: String, Codable, CaseIterable {
    case socialMedia = "Social Media"
    case entertainment = "Entertainment"
    case news = "News"
    case shopping = "Shopping"
    case productivity = "Productivity"
    case custom = "Custom"
} 