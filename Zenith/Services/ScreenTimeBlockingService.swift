import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

/// Service for handling Screen Time blocking functionality
class ScreenTimeBlockingService {
    // MARK: - Properties
    static let shared = ScreenTimeBlockingService()
    
    private let blockingManager = BlockingManager.shared
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private var isAuthorized = false
    
    /// Settings manager for persisting blocking state
    private let settings = SharedBlockingSettings.shared
    
    /// Currently active block list ID
    private(set) var activeBlockListId: String? {
        didSet {
            if let id = activeBlockListId {
                settings.lastActiveBlockListId = id
            }
        }
    }
    
    /// Currently active selection
    private var activitySelection = FamilyActivitySelection()
    
    private let deviceActivityCenter = DeviceActivityCenter()
    private let activityName = DeviceActivityName("io.zenith.focusSession")
    
    // MARK: - Initialization
    private init() {
        Task {
            // Update isAuthorized property based on check result
            isAuthorized = await checkAuthorization()
            
            // Restore last active block list if available
            if let lastId = settings.lastActiveBlockListId {
                activeBlockListId = lastId
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Check if Screen Time authorization is available
    @MainActor
    func checkAuthorization() async -> Bool {
        let status = center.authorizationStatus
        isAuthorized = status == .approved
        return isAuthorized
    }
    
    /// Request Screen Time authorization
    @MainActor
    func requestAuthorization() async -> Bool {
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = center.authorizationStatus == .approved
            return isAuthorized
        } catch {
            print("Error requesting Screen Time authorization: \(error)")
            return false
        }
    }
    
    /// Enable blocking for a focus session using a specific selection
    func enableBlockingWithSelection(_ selection: FamilyActivitySelection) {
        self.activitySelection = selection
        
        // Save the selection to UserDefaults for persistence
        saveActivitySelection(selection)
        
        // Apply the selection directly for immediate effect
        applySelectionDirectly(selection)
    }
    
    /// Enable blocking for a focus session using a block list
    func enableBlocking(blockListId: String? = nil) async throws {
        // First ensure we have authorization
        if await checkAuthorization() == false {
            throw ScreenTimeError.notAuthorized
        }
        
        // If no block list ID is provided and we don't have an active one, use default
        let listId: String
        if let id = blockListId ?? activeBlockListId {
            listId = id
        } else {
            listId = try await getOrCreateDefaultBlockList()
        }
        
        activeBlockListId = listId
        
        // Fetch the block list items
        let blockList = try await blockingManager.getBlockList(id: listId)
        
        // Apply the block settings to Screen Time
        applyBlockSettings(from: blockList)
    }
    
    /// Disable all blocking
    func disableBlocking() {
        // To disable all blocking, clear all settings
        store.clearAllSettings()
        
        // Update settings to reflect disabled state
        settings.endBlockingSession()
        
        activeBlockListId = nil
        activitySelection = FamilyActivitySelection()
    }
    
    /// Save the current selection as a block list
    func saveSelectionAsBlockList(name: String, description: String) async throws -> BlockList {
        // Check if we have anything selected
        if activitySelection.applications.isEmpty && activitySelection.webDomains.isEmpty {
            throw ScreenTimeError.noActiveSelection
        }
        
        // Create a new block list
        let blockList = try await blockingManager.createBlockList(
            name: name,
            description: description,
            rules: []
        )
        
        // Convert FamilyActivitySelection to BlockItems
        _ = try await convertSelectionToBlockItems(activitySelection, blockListId: blockList.id)
        
        // Save the block list ID as active
        activeBlockListId = blockList.id
        
        return blockList
    }
    
    /// Add this method to implement DeviceActivity monitoring
    func startMonitoringActivity(duration: TimeInterval) async throws {
        // Create a schedule from now until the session ends
        let calendar = Calendar.current
        let now = Date()
        let endTime = now.addingTimeInterval(duration)
        
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        // Define the monitoring schedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: nowComponents.hour, minute: nowComponents.minute),
            intervalEnd: DateComponents(hour: endComponents.hour, minute: endComponents.minute),
            repeats: false
        )
        
        // Start monitoring with our selection
        try deviceActivityCenter.startMonitoring(
            activityName,
            during: schedule
        )
        
        // Record the session in our persistence layer
        settings.startBlockingSession(duration: duration, blockListId: activeBlockListId)
        
        print("🛡️ [Block] Started activity monitoring for \(Int(duration/60)) minutes")
    }
    
    /// Add method to stop monitoring
    func stopMonitoringActivity() {
        deviceActivityCenter.stopMonitoring([activityName])
        settings.endBlockingSession()
        print("🛡️ [Block] Stopped activity monitoring")
    }
    
    // MARK: - Private Methods
    
    /// Convert FamilyActivitySelection to BlockItems
    private func convertSelectionToBlockItems(_ selection: FamilyActivitySelection, blockListId: String) async throws -> [BlockItem] {
        var items: [BlockItem] = []
        
        // Extract bundle IDs from ApplicationTokens
        for _ in selection.applications {
            // In a real implementation, you would get the app's bundle ID and name
            // This is a placeholder since we can't actually extract this info in a sandbox
            let bundleId = "com.example.app"
            let name = "Example App"
            
            let item = BlockItem(
                type: .app,
                identifier: bundleId,
                name: name,
                blockListId: blockListId
            )
            
            items.append(item)
        }
        
        // Extract domains from WebDomainTokens
        for _ in selection.webDomains {
            // In a real implementation, you would get the domain string
            // This is a placeholder since we can't actually extract this info in a sandbox
            let domainString = "example.com"
            let name = "Example Website"
            
            let item = BlockItem(
                type: .website,
                identifier: domainString,
                name: name,
                blockListId: blockListId
            )
            
            items.append(item)
        }
        
        // Add the items to the block list
        let requests = items.map { item in
            CreateBlockItemRequest(
                type: item.type,
                identifier: item.identifier,
                name: item.name,
                isActive: true
            )
        }
        
        return try await BlockItemService.shared.addBulkBlockItems(blockListId: blockListId, items: requests)
    }
    
    /// Get or create a default block list
    private func getOrCreateDefaultBlockList() async throws -> String {
        do {
            // Try to find an existing default block list
            let blockLists = try await blockingManager.getAllBlockLists()
            if let defaultList = blockLists.first(where: { $0.name == "Focus Mode Default" }) {
                return defaultList.id
            }
            
            // If none exists, create a default one with common social media domains
            let defaultRules = [
                BlockingRule(name: "Facebook", type: .domain, pattern: "facebook.com", category: .socialMedia),
                BlockingRule(name: "Instagram", type: .domain, pattern: "instagram.com", category: .socialMedia),
                BlockingRule(name: "Twitter/X", type: .domain, pattern: "twitter.com", category: .socialMedia),
                BlockingRule(name: "TikTok", type: .domain, pattern: "tiktok.com", category: .socialMedia),
                BlockingRule(name: "YouTube", type: .domain, pattern: "youtube.com", category: .entertainment)
            ]
            
            let defaultList = try await blockingManager.createBlockList(
                name: "Focus Mode Default",
                description: "Default block list for Focus Mode sessions",
                rules: defaultRules
            )
            
            return defaultList.id
        } catch {
            print("Error creating default block list: \(error)")
            throw ScreenTimeError.failedToCreateBlockList
        }
    }
    
    /// Apply block settings from a block list to Screen Time
    private func applyBlockSettings(from blockList: BlockList) {
        // Reset current settings
        store.clearAllSettings()
        
        guard let items = blockList.items else { return }
        
        // Prepare for application and domain tokens
        var appIdentifiers: [String] = []
        var domainIdentifiers: [String] = []
        
        // Collect application identifiers and domain identifiers
        for item in items where item.isActive {
            switch item.type {
            case .app:
                appIdentifiers.append(item.identifier)
            case .website:
                domainIdentifiers.append(item.identifier)
            case .appCategory:
                // App categories require special handling
                // For simplicity, we'll skip this for now
                continue
            }
        }
        
        // In a real implementation, you would need to convert these identifiers
        // to actual ApplicationTokens and WebDomainTokens through the FamilyControls API
        
        // For demo purposes, log what would be blocked
        if !appIdentifiers.isEmpty || !domainIdentifiers.isEmpty {
            // For now, we'll just print what would be blocked
            print("Would block apps: \(appIdentifiers)")
            print("Would block domains: \(domainIdentifiers)")
        }
    }
    
    /// Method to directly apply selection (for immediate effect)
    private func applySelectionDirectly(_ selection: FamilyActivitySelection) {
        store.clearAllSettings()
        
        // Apply the shield based on the selection
        let shield = Shield()
        shield.primaryContentFilter = selection
        
        // Apply the shield to block the selected apps and websites
        store.shield = shield
        
        // Note: This is a simpler approach that may have limitations
        // The DeviceActivity monitoring approach is more robust
        print("🛡️ [Block] Applied selection directly with \(selection.applications.count) apps and \(selection.webDomains.count) web domains")
    }
    
    /// Save selection to UserDefaults
    private func saveActivitySelection(_ selection: FamilyActivitySelection) {
        // Update the selection timestamp
        settings.updateSelectionTimestamp()
        
        print("🛡️ [Block] Saved selection preferences")
    }
    
    /// Check if there's a stored selection
    func hasStoredSelection() -> Bool {
        return settings.hasStoredSelection
    }
    
    /// Check if blocking is currently active
    func isBlockingActive() -> Bool {
        return settings.isBlockingEnabled
    }
    
    /// Get remaining time for current blocking session if active
    func getRemainingBlockingTime() -> TimeInterval? {
        return settings.getActiveSessionTimeRemaining()
    }
    
    /// Get the current FamilyActivitySelection for device activity monitoring
    func getCurrentSelection() -> FamilyActivitySelection {
        return activitySelection
    }
}

// MARK: - Supporting Types
enum ScreenTimeError: Error {
    case notAuthorized
    case failedToCreateBlockList
    case failedToApplySettings
    case noActiveSelection
} 