import Foundation

/// Service for managing blocking settings persistence using shared App Group storage
class SharedBlockingSettings {
    // MARK: - Properties
    static let shared = SharedBlockingSettings()
    
    private let defaults: UserDefaults?
    
    // Keys for UserDefaults
    private enum Keys {
        static let isBlockingEnabled = "isBlockingEnabled"
        static let sessionStartTime = "sessionStartTime"
        static let sessionDuration = "sessionDuration"
        static let hasStoredSelection = "hasStoredSelection"
        static let selectionTimestamp = "selectionTimestamp"
        static let lastActiveBlockListId = "lastActiveBlockListId"
    }
    
    // MARK: - Initialization
    private init() {
        defaults = UserDefaults(suiteName: "group.io.zenith.app")
    }
    
    // MARK: - Public Methods
    
    /// Check if blocking is currently enabled
    var isBlockingEnabled: Bool {
        get { defaults?.bool(forKey: Keys.isBlockingEnabled) ?? false }
        set { 
            defaults?.set(newValue, forKey: Keys.isBlockingEnabled)
            defaults?.synchronize() 
        }
    }
    
    /// Get/set last used block list ID
    var lastActiveBlockListId: String? {
        get { defaults?.string(forKey: Keys.lastActiveBlockListId) }
        set {
            if let newValue = newValue {
                defaults?.set(newValue, forKey: Keys.lastActiveBlockListId)
            } else {
                defaults?.removeObject(forKey: Keys.lastActiveBlockListId)
            }
            defaults?.synchronize()
        }
    }
    
    /// Check if we have a stored selection
    var hasStoredSelection: Bool {
        get { defaults?.bool(forKey: Keys.hasStoredSelection) ?? false }
        set {
            defaults?.set(newValue, forKey: Keys.hasStoredSelection)
            defaults?.synchronize()
        }
    }
    
    /// Record the start of a blocking session
    func startBlockingSession(duration: TimeInterval, blockListId: String? = nil) {
        isBlockingEnabled = true
        defaults?.set(Date(), forKey: Keys.sessionStartTime)
        defaults?.set(duration, forKey: Keys.sessionDuration)
        
        if let blockListId = blockListId {
            lastActiveBlockListId = blockListId
        }
        
        defaults?.synchronize()
        
        print("💾 [Settings] Started blocking session: \(Int(duration/60)) minutes")
    }
    
    /// End the current blocking session
    func endBlockingSession() {
        isBlockingEnabled = false
        defaults?.removeObject(forKey: Keys.sessionStartTime)
        defaults?.removeObject(forKey: Keys.sessionDuration)
        defaults?.synchronize()
        
        print("💾 [Settings] Ended blocking session")
    }
    
    /// Check if a session is in progress and how much time remains
    func getActiveSessionTimeRemaining() -> TimeInterval? {
        guard isBlockingEnabled,
              let startTime = defaults?.object(forKey: Keys.sessionStartTime) as? Date,
              let duration = defaults?.double(forKey: Keys.sessionDuration) else {
            return nil
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let remainingTime = duration - elapsedTime
        
        return remainingTime > 0 ? remainingTime : nil
    }
    
    /// Save selection timestamp
    func updateSelectionTimestamp() {
        hasStoredSelection = true
        defaults?.set(Date(), forKey: Keys.selectionTimestamp)
        defaults?.synchronize()
    }
    
    /// Get last selection timestamp
    func getSelectionTimestamp() -> Date? {
        return defaults?.object(forKey: Keys.selectionTimestamp) as? Date
    }
    
    /// Clear all settings (useful for debugging/testing)
    func clearAllSettings() {
        isBlockingEnabled = false
        hasStoredSelection = false
        lastActiveBlockListId = nil
        defaults?.removeObject(forKey: Keys.sessionStartTime)
        defaults?.removeObject(forKey: Keys.sessionDuration)
        defaults?.removeObject(forKey: Keys.selectionTimestamp)
        defaults?.synchronize()
        
        print("💾 [Settings] Cleared all settings")
    }
} 