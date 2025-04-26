import Foundation

/// Types of items that can be blocked
enum BlockType: String, Codable, CaseIterable {
    /// Specific website domains
    case website
    
    /// Specific applications
    case app
    
    /// Categories of applications
    case appCategory = "app_category"
} 