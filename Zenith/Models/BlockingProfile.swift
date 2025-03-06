import Foundation

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