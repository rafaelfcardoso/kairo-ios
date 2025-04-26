import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

// This extension must be added to handle Device Activity monitoring events
extension DeviceActivityMonitor {
    // Called when the monitoring starts - apply the shields
    public func intervalDidStart(for activity: DeviceActivityName) {
        print("🛡️ [DeviceActivity] Interval did start for: \(activity)")
        
        // Check if this is our focus session activity
        if activity == DeviceActivityName("io.zenith.focusSession") {
            // Get shared selection if available
            guard let service = ScreenTimeBlockingService.shared else { return }
            
            // Create and apply shield with the current selection
            let shield = Shield()
            let store = ManagedSettingsStore()
            
            // Apply the content filter from the stored selection
            shield.primaryContentFilter = service.getCurrentSelection()
            
            // Apply the shield
            store.shield = shield
            
            print("🛡️ [DeviceActivity] Applied shield for focus session")
        }
    }
    
    // Called when the monitoring ends - remove the shields
    public func intervalDidEnd(for activity: DeviceActivityName) {
        print("🛡️ [DeviceActivity] Interval did end for: \(activity)")
        
        // Check if this is our focus session activity
        if activity == DeviceActivityName("io.zenith.focusSession") {
            // Clear all shields
            let store = ManagedSettingsStore()
            store.clearAllSettings()
            
            // Update settings to reflect disabled state
            SharedBlockingSettings.shared.endBlockingSession()
            
            print("🛡️ [DeviceActivity] Removed shield for focus session")
        }
    }
} 