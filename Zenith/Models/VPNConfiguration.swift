import Foundation
import NetworkExtension

/// Represents the configuration for the VPN
struct VPNConfiguration: Codable {
    /// Whether the VPN is enabled
    var isEnabled: Bool = false
    
    /// The currently active profile
    var activeProfileId: UUID?
    
    /// All available profiles
    var profiles: [BlockingProfile] = []
    
    /// Default rules that apply regardless of profile
    var defaultRules: [BlockingRule] = []
    
    /// Last time the VPN was activated
    var lastActivationDate: Date?
    
    /// Last time the VPN was deactivated
    var lastDeactivationDate: Date?
    
    /// Statistics about blocked content
    var statistics: VPNStatistics = VPNStatistics()
    
    /// Predefined profiles for common use cases
    static func defaultProfiles() -> [BlockingProfile] {
        [
            BlockingProfile(
                name: "Work Mode",
                description: "Block distracting sites and apps during work hours"
            ),
            BlockingProfile(
                name: "Study Mode",
                description: "Block entertainment and social media for focused study"
            ),
            BlockingProfile(
                name: "Digital Wellbeing",
                description: "Limit screen time and promote healthy digital habits"
            )
        ]
    }
    
    /// Predefined rules for common distractions
    static func defaultRules() -> [BlockingRule] {
        [
            // Social Media
            BlockingRule(
                name: "Facebook",
                type: .domain,
                pattern: "facebook.com",
                category: .socialMedia
            ),
            BlockingRule(
                name: "Instagram",
                type: .domain,
                pattern: "instagram.com",
                category: .socialMedia
            ),
            BlockingRule(
                name: "Twitter",
                type: .domain,
                pattern: "twitter.com",
                category: .socialMedia
            ),
            
            // Entertainment
            BlockingRule(
                name: "YouTube",
                type: .domain,
                pattern: "youtube.com",
                category: .entertainment
            ),
            BlockingRule(
                name: "Netflix",
                type: .domain,
                pattern: "netflix.com",
                category: .entertainment
            ),
            
            // News
            BlockingRule(
                name: "CNN",
                type: .domain,
                pattern: "cnn.com",
                category: .news
            ),
            BlockingRule(
                name: "BBC",
                type: .domain,
                pattern: "bbc.com",
                category: .news
            )
        ]
    }
}

/// Statistics about blocked content
struct VPNStatistics: Codable {
    /// Number of blocked requests
    var blockedRequestsCount: Int = 0
    
    /// Time saved by blocking distractions (in seconds)
    var timeSavedSeconds: TimeInterval = 0
    
    /// Blocked requests by category
    var blockedByCategory: [BlockingCategory: Int] = [:]
    
    /// Blocked requests by day
    var blockedByDay: [Date: Int] = [:]
    
    /// Most blocked domain
    var mostBlockedDomain: String?
    
    /// Most blocked app
    var mostBlockedApp: String?
} 