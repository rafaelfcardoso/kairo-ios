import NetworkExtension

class AppProxyProvider: NEAppProxyProvider {
    
    // MARK: - Properties
    
    /// Configuration for blocking rules
    private var blockingConfiguration: VPNConfiguration?
    
    /// Dictionary to track blocked domains
    private var blockedDomains = [String: Int]()
    
    /// Dictionary to track blocked apps
    private var blockedApps = [String: Int]()
    
    /// Date when the provider started
    private var startDate: Date?
    
    // MARK: - NEAppProxyProvider Methods
    
    override func startProxy(options: [String: Any]? = nil, completionHandler: @escaping (Error?) -> Void) {
        // Log start of proxy
        NSLog("Starting Zenith App Proxy Provider")
        
        // Record start time
        startDate = Date()
        
        // Load configuration from options
        if let providerConfiguration = protocolConfiguration.providerConfiguration {
            do {
                let configData = try JSONSerialization.data(withJSONObject: providerConfiguration)
                blockingConfiguration = try JSONDecoder().decode(VPNConfiguration.self, from: configData)
                NSLog("Successfully loaded blocking configuration with \(blockingConfiguration?.defaultRules.count ?? 0) default rules")
            } catch {
                NSLog("Error decoding blocking configuration: \(error.localizedDescription)")
            }
        } else {
            NSLog("No provider configuration available")
        }
        
        // Complete startup
        completionHandler(nil)
    }
    
    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Log stop reason
        NSLog("Stopping Zenith App Proxy Provider with reason: \(reason.rawValue)")
        
        // Save statistics before stopping
        saveStatistics()
        
        // Complete shutdown
        completionHandler()
    }
    
    override func handleAppProxyFlow(_ flow: NEAppProxyFlow) -> Bool {
        // Check if this is a TCP flow
        guard let tcpFlow = flow as? NEAppProxyTCPFlow else {
            NSLog("Received non-TCP flow, ignoring")
            return false
        }
        
        // Get the remote endpoint
        guard let remoteEndpoint = tcpFlow.remoteEndpoint as? NWHostEndpoint else {
            NSLog("Could not determine remote endpoint")
            return false
        }
        
        // Get the app info
        let appInfo = getAppInfo(from: flow)
        
        // Check if we should block this flow
        if shouldBlockFlow(remoteEndpoint: remoteEndpoint, appInfo: appInfo) {
            // Block the flow by not handling it
            NSLog("Blocking flow to \(remoteEndpoint.hostname):\(remoteEndpoint.port) from app \(appInfo?.bundleIdentifier ?? "unknown")")
            
            // Update statistics
            updateBlockedStatistics(domain: remoteEndpoint.hostname, appBundleId: appInfo?.bundleIdentifier)
            
            return false
        }
        
        // Allow the flow by handling it
        NSLog("Allowing flow to \(remoteEndpoint.hostname):\(remoteEndpoint.port) from app \(appInfo?.bundleIdentifier ?? "unknown")")
        
        // Set up the connection
        tcpFlow.open(withLocalEndpoint: nil) { error in
            if let error = error {
                NSLog("Error opening TCP flow: \(error.localizedDescription)")
                return
            }
            
            // Start reading and writing data
            self.handleTCPFlow(tcpFlow)
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    
    /// Handle TCP flow by reading and writing data
    private func handleTCPFlow(_ flow: NEAppProxyTCPFlow) {
        // Read data from the flow
        flow.readData { data, error in
            if let error = error {
                NSLog("Error reading data: \(error.localizedDescription)")
                flow.closeReadWithError(error)
                return
            }
            
            guard let data = data else {
                NSLog("No data received, closing flow")
                flow.closeReadWithError(nil)
                return
            }
            
            // Write data back to the flow
            flow.write(data) { error in
                if let error = error {
                    NSLog("Error writing data: \(error.localizedDescription)")
                    flow.closeWriteWithError(error)
                    return
                }
                
                // Continue reading data
                self.handleTCPFlow(flow)
            }
        }
    }
    
    /// Get app information from the flow
    private func getAppInfo(from flow: NEAppProxyFlow) -> NEAppInfo? {
        return flow.metaData?[NEFlowMetaDataKey.appInfo] as? NEAppInfo
    }
    
    /// Determine if a flow should be blocked based on rules
    private func shouldBlockFlow(remoteEndpoint: NWHostEndpoint, appInfo: NEAppInfo?) -> Bool {
        guard let config = blockingConfiguration else {
            return false
        }
        
        // Get active rules
        let activeProfileRules = config.activeProfileId.flatMap { profileId in
            config.profiles.first(where: { $0.id == profileId })?.rules.filter { $0.isActive } ?? []
        } ?? []
        
        let activeDefaultRules = config.defaultRules.filter { $0.isActive }
        let allActiveRules = activeProfileRules + activeDefaultRules
        
        // Check domain rules
        for rule in allActiveRules where rule.type == .domain {
            if remoteEndpoint.hostname.contains(rule.pattern) {
                return true
            }
        }
        
        // Check app rules if app info is available
        if let appInfo = appInfo {
            for rule in allActiveRules where rule.type == .app {
                if appInfo.bundleIdentifier == rule.pattern {
                    return true
                }
            }
        }
        
        // Check keyword rules
        for rule in allActiveRules where rule.type == .keyword {
            if remoteEndpoint.hostname.contains(rule.pattern) {
                return true
            }
        }
        
        // Check IP address rules
        for rule in allActiveRules where rule.type == .ipAddress {
            if remoteEndpoint.hostname == rule.pattern {
                return true
            }
        }
        
        return false
    }
    
    /// Update statistics for blocked content
    private func updateBlockedStatistics(domain: String, appBundleId: String?) {
        // Update blocked domains count
        blockedDomains[domain] = (blockedDomains[domain] ?? 0) + 1
        
        // Update blocked apps count if available
        if let appBundleId = appBundleId {
            blockedApps[appBundleId] = (blockedApps[appBundleId] ?? 0) + 1
        }
        
        // Update configuration statistics
        guard var config = blockingConfiguration else { return }
        
        // Increment blocked requests count
        config.statistics.blockedRequestsCount += 1
        
        // Update most blocked domain
        if let mostBlockedDomain = blockedDomains.max(by: { $0.value < $1.value }) {
            config.statistics.mostBlockedDomain = mostBlockedDomain.key
        }
        
        // Update most blocked app
        if let mostBlockedApp = blockedApps.max(by: { $0.value < $1.value }) {
            config.statistics.mostBlockedApp = mostBlockedApp.key
        }
        
        // Update blocked by day
        let today = Calendar.current.startOfDay(for: Date())
        config.statistics.blockedByDay[today] = (config.statistics.blockedByDay[today] ?? 0) + 1
        
        // Update time saved (assume 30 seconds saved per blocked request)
        config.statistics.timeSavedSeconds += 30
        
        // Save updated configuration
        blockingConfiguration = config
    }
    
    /// Save statistics back to the main app
    private func saveStatistics() {
        guard let config = blockingConfiguration else { return }
        
        // Convert configuration to JSON
        do {
            let configData = try JSONEncoder().encode(config)
            guard let configDict = try JSONSerialization.jsonObject(with: configData) as? [String: Any] else {
                NSLog("Error converting configuration to dictionary")
                return
            }
            
            // Save to UserDefaults shared with the main app
            let sharedDefaults = UserDefaults(suiteName: "group.com.zenith.ZenithApp")
            sharedDefaults?.set(configDict, forKey: "vpn_statistics")
            sharedDefaults?.synchronize()
            
            NSLog("Successfully saved VPN statistics")
        } catch {
            NSLog("Error saving VPN statistics: \(error.localizedDescription)")
        }
    }
} 