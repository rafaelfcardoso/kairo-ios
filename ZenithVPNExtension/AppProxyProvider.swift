import NetworkExtension

class PacketTunnelProvider: NETunnelProvider {
    
    // MARK: - Properties
    
    /// Configuration for blocking rules
    private var blockingConfiguration: VPNConfiguration?
    
    /// Dictionary to track blocked domains
    private var blockedDomains = [String: Int]()
    
    /// Dictionary to track blocked apps
    private var blockedApps = [String: Int]()
    
    /// Date when the provider started
    private var startDate: Date?
    
    // MARK: - NETunnelProvider Methods
    
    override func startTunnel(options: [String: NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        // Log start of proxy
        NSLog("Starting Zenith Tunnel Provider")
        
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
        
        // Set up the tunnel
        setupTunnel(completionHandler: completionHandler)
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Log stop reason
        NSLog("Stopping Zenith Tunnel Provider with reason: \(reason.rawValue)")
        
        // Save statistics before stopping
        saveStatistics()
        
        // Complete shutdown
        completionHandler()
    }
    
    // MARK: - Helper Methods
    
    /// Set up the tunnel interface
    private func setupTunnel(completionHandler: @escaping (Error?) -> Void) {
        // Create a network settings object
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        
        // Configure DNS settings to block domains
        let dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        
        // Add blocked domains if available
        if let config = blockingConfiguration {
            var matchDomains = [String: [String]]()
            
            // Get active rules
            let activeProfileRules = config.activeProfileId.flatMap { profileId in
                config.profiles.first(where: { $0.id == profileId })?.rules.filter { $0.isActive } ?? []
            } ?? []
            
            let activeDefaultRules = config.defaultRules.filter { $0.isActive }
            let allActiveRules = activeProfileRules + activeDefaultRules
            
            // Add domain rules to DNS block list
            for rule in allActiveRules where rule.type == .domain {
                matchDomains[rule.pattern] = ["127.0.0.1"]
            }
            
            if !matchDomains.isEmpty {
                dnsSettings.matchDomains = Array(matchDomains.keys)
                dnsSettings.matchDomainsNoSearch = true
            }
        }
        
        networkSettings.dnsSettings = dnsSettings
        
        // Apply the network settings
        setTunnelNetworkSettings(networkSettings) { error in
            if let error = error {
                NSLog("Error setting tunnel network settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            
            NSLog("Successfully set up tunnel network settings")
            completionHandler(nil)
        }
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
            guard let configDict = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] else {
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