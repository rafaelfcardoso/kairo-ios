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

/// Represents a profile for blocking content
struct BlockingProfile: Codable, Identifiable, Equatable {
    /// Unique identifier for the profile
    var id: UUID = UUID()
    
    /// Name of the profile (e.g., "Work Mode", "Study Mode")
    var name: String
    
    /// Description of the profile
    var description: String
    
    /// Whether the profile is currently active
    var isActive: Bool = false
    
    /// Collection of rules associated with this profile
    var rules: [BlockingRule] = []
    
    /// Schedule for when this profile should be active
    var schedule: BlockingSchedule?
    
    /// Custom init with name and description
    init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}

/// Schedule for when a blocking profile should be active
struct BlockingSchedule: Codable, Equatable {
    /// Days of the week when the schedule is active
    var activeDays: Set<Weekday> = Set(Weekday.allCases)
    
    /// Start time in minutes from midnight
    var startTimeMinutes: Int = 9 * 60 // 9:00 AM
    
    /// End time in minutes from midnight
    var endTimeMinutes: Int = 17 * 60 // 5:00 PM
    
    /// Whether the schedule is enabled
    var isEnabled: Bool = false
}

/// Days of the week
enum Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    var shortName: String {
        String(name.prefix(3))
    }
}

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