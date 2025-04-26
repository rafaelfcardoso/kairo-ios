import Foundation

/// Manager for handling blocking functionality, integrating API and local models
class BlockingManager {
    // MARK: - Properties
    static let shared = BlockingManager()
    
    private let blockListService = BlockListService.shared
    private let blockItemService = BlockItemService.shared
    private let appCategoryService = AppCategoryService.shared
    private let scheduleService = ScheduleService.shared
    private let blockSettingService = BlockSettingService.shared
    
    /// Local cached block lists
    private var cachedBlockLists: [BlockList] = []
    
    /// Local cached app categories
    private var cachedAppCategories: [AppCategory] = []
    
    /// Local cached schedules
    private var cachedSchedules: [Schedule] = []
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    /// Refresh all data from the API
    func refreshAllData() async throws {
        async let blockLists = blockListService.getAllBlockLists()
        async let appCategories = appCategoryService.getAllAppCategories()
        async let schedules = scheduleService.getAllSchedules()
        
        // Wait for all requests to complete
        let (fetchedBlockLists, fetchedAppCategories, fetchedSchedules) = try await (blockLists, appCategories, schedules)
        
        // Update local cache
        self.cachedBlockLists = fetchedBlockLists
        self.cachedAppCategories = fetchedAppCategories
        self.cachedSchedules = fetchedSchedules
    }
    
    /// Get all block lists
    func getAllBlockLists() async throws -> [BlockList] {
        // Try to use cached data first
        if !cachedBlockLists.isEmpty {
            return cachedBlockLists
        }
        
        // If cache is empty, fetch from API
        let blockLists = try await blockListService.getAllBlockLists()
        cachedBlockLists = blockLists
        return blockLists
    }
    
    /// Get a specific block list by ID
    func getBlockList(id: String) async throws -> BlockList {
        // Try to find in cache first
        if let cachedList = cachedBlockLists.first(where: { $0.id == id }) {
            return cachedList
        }
        
        // If not in cache, fetch from API
        let blockList = try await blockListService.getBlockList(id: id)
        
        // Add to cache if not already present
        if !cachedBlockLists.contains(where: { $0.id == id }) {
            cachedBlockLists.append(blockList)
        }
        
        return blockList
    }
    
    /// Convert API models to local models
    func convertToLocalModels() -> [BlockingProfile] {
        var profiles: [BlockingProfile] = []
        
        // Convert each block list to a blocking profile
        for blockList in cachedBlockLists {
            profiles.append(blockList.toBlockingProfile())
        }
        
        // Associate schedules with profiles
        for schedule in cachedSchedules where schedule.active {
            // Find the associated block lists
            let profileIds = schedule.blockListIds
            
            // Create the local schedule
            let blockingSchedule = schedule.toBlockingSchedule()
            
            // Update the profiles with the schedule
            for id in profileIds {
                if let index = profiles.firstIndex(where: { $0.name == getBlockListName(for: id) }) {
                    profiles[index].schedule = blockingSchedule
                }
            }
        }
        
        return profiles
    }
    
    /// Create a new block list and associated items
    func createBlockList(name: String, description: String, rules: [BlockingRule]) async throws -> BlockList {
        // First create the block list
        let blockList = try await blockListService.createBlockList(
            name: name,
            description: description,
            isActive: true
        )
        
        // Then create the items
        let blockItems = try await addBlockItems(to: blockList.id, from: rules)
        
        // Update the local cache
        var updatedBlockList = blockList
        updatedBlockList.items = blockItems
        cachedBlockLists.append(updatedBlockList)
        
        return updatedBlockList
    }
    
    /// Add existing rules to a block list
    private func addBlockItems(to blockListId: String, from rules: [BlockingRule]) async throws -> [BlockItem] {
        var requests: [CreateBlockItemRequest] = []
        
        // Convert each blocking rule to a create block item request
        for rule in rules {
            let type: BlockType
            
            switch rule.type {
            case .domain, .keyword:
                type = .website
            case .app, .ipAddress:
                type = .app
            }
            
            requests.append(CreateBlockItemRequest(
                type: type,
                identifier: rule.pattern,
                name: rule.name,
                isActive: rule.isActive
            ))
        }
        
        // Add the items in bulk
        return try await blockItemService.addBulkBlockItems(blockListId: blockListId, items: requests)
    }
    
    /// Create a new schedule
    func createSchedule(
        startTimeMinutes: Int,
        endTimeMinutes: Int,
        days: Set<Weekday>,
        blockListIds: [String]
    ) async throws -> Schedule {
        // Convert minutes to hours and minutes
        let startHour = startTimeMinutes / 60
        let startMinute = startTimeMinutes % 60
        let endHour = endTimeMinutes / 60
        let endMinute = endTimeMinutes % 60
        
        // Convert days
        let apiDays = days.map { $0.rawValue }
        
        // Create the schedule
        let schedule = try await scheduleService.createSchedule(
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            days: apiDays,
            active: true,
            blockListIds: blockListIds
        )
        
        // Update the local cache
        cachedSchedules.append(schedule)
        
        return schedule
    }
    
    // MARK: - Helper Methods
    /// Get the name of a block list by its ID
    private func getBlockListName(for id: String) -> String {
        if let blockList = cachedBlockLists.first(where: { $0.id == id }) {
            return blockList.name
        }
        return ""
    }
    
    /// Get the active blocking rules based on current time and schedules
    func getActiveBlockingRules() -> [BlockingRule] {
        var activeRules: [BlockingRule] = []
        
        // Get the current time and day
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: now)
        let currentTimeMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let currentWeekday = components.weekday ?? 1 // Default to Sunday if not available
        
        // Check each schedule
        for schedule in cachedSchedules where schedule.active {
            // Check if the current day is included in the schedule
            if schedule.days.contains(currentWeekday) {
                // Calculate schedule times in minutes
                let scheduleStartMinutes = schedule.startHour * 60 + schedule.startMinute
                let scheduleEndMinutes = schedule.endHour * 60 + schedule.endMinute
                
                // Check if current time is within the schedule
                if (scheduleEndMinutes > scheduleStartMinutes && 
                    currentTimeMinutes >= scheduleStartMinutes && 
                    currentTimeMinutes < scheduleEndMinutes) ||
                   (scheduleEndMinutes < scheduleStartMinutes && 
                    (currentTimeMinutes >= scheduleStartMinutes || 
                     currentTimeMinutes < scheduleEndMinutes)) {
                    
                    // Get the associated block lists
                    let blockListIds = schedule.blockListIds
                    
                    // Add rules from each associated block list
                    for id in blockListIds {
                        if let blockList = cachedBlockLists.first(where: { $0.id == id }),
                           let items = blockList.items {
                            for item in items where item.isActive {
                                activeRules.append(item.toBlockingRule())
                            }
                        }
                    }
                    
                    // Add direct block items if any
                    if let directItemIds = schedule.directBlockItemIds {
                        for blockList in cachedBlockLists {
                            if let items = blockList.items {
                                let directItems = items.filter { directItemIds.contains($0.id) }
                                activeRules.append(contentsOf: directItems.map { $0.toBlockingRule() })
                            }
                        }
                    }
                }
            }
        }
        
        // Remove duplicates
        return activeRules.uniqued()
    }
}

// MARK: - Helper Extensions
extension Array where Element: Equatable {
    /// Remove duplicates from an array
    func uniqued() -> [Element] {
        var result = [Element]()
        for item in self {
            if !result.contains(item) {
                result.append(item)
            }
        }
        return result
    }
} 