import Foundation

/// Represents a time period to apply blocks
struct Schedule: Codable, Identifiable, Equatable {
    /// Unique identifier for the schedule
    var id: String
    
    /// Hour component of the start time (0-23)
    var startHour: Int
    
    /// Minute component of the start time (0-59)
    var startMinute: Int
    
    /// Hour component of the end time (0-23)
    var endHour: Int
    
    /// Minute component of the end time (0-59)
    var endMinute: Int
    
    /// Days of the week when the schedule is active (1-7, where 1 is Sunday)
    var days: [Int]
    
    /// Whether the schedule is enabled
    var active: Bool
    
    /// IDs of associated block lists
    var blockListIds: [String]
    
    /// IDs of individual items directly attached to the schedule
    var directBlockItemIds: [String]?
    
    /// Associated block lists (populated when fetched from API)
    var blockLists: [BlockList]?
    
    /// Creates a fully initialized Schedule
    init(id: String = UUID().uuidString,
         startHour: Int,
         startMinute: Int,
         endHour: Int,
         endMinute: Int,
         days: [Int],
         active: Bool = true,
         blockListIds: [String] = [],
         directBlockItemIds: [String]? = nil,
         blockLists: [BlockList]? = nil) {
        self.id = id
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.days = days
        self.active = active
        self.blockListIds = blockListIds
        self.directBlockItemIds = directBlockItemIds
        self.blockLists = blockLists
    }
    
    /// Converts a Schedule to a local BlockingSchedule
    func toBlockingSchedule() -> BlockingSchedule {
        // Convert days array to Set<Weekday>
        let activeDays = Set(days.compactMap { day in
            if day >= 1 && day <= 7 {
                return Weekday(rawValue: day)
            }
            return nil
        })
        
        // Convert hours and minutes to minutes from midnight
        let startTimeMinutes = startHour * 60 + startMinute
        let endTimeMinutes = endHour * 60 + endMinute
        
        var schedule = BlockingSchedule()
        schedule.activeDays = activeDays
        schedule.startTimeMinutes = startTimeMinutes
        schedule.endTimeMinutes = endTimeMinutes
        schedule.isEnabled = active
        
        return schedule
    }
} 