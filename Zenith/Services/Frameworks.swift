import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

/// This file ensures that the necessary frameworks are included in the build
struct ScreenTimeFrameworks {
    static func registerFrameworks() {
        // This function doesn't actually do anything, but it ensures that
        // the compiler includes the required frameworks in the build
        let _ = AuthorizationCenter.shared
        let _ = ManagedSettingsStore()
        let _ = DeviceActivityName("")
    }
} 