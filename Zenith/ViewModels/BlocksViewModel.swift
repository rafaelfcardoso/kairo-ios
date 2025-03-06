import SwiftUI
import NetworkExtension
import Combine

class BlocksViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var focusScore: Double = 0.85
    @Published var focusTrend: Double = 0.12
    @Published var screenTime: TimeInterval = 14400 // 4 hours in seconds
    @Published var protectedTime: TimeInterval = 7200 // 2 hours in seconds
    @Published var timeDistribution: (focused: Double, neutral: Double, distracted: Double) = (0.6, 0.3, 0.1)
    
    @Published var currentMode: String = "Work Shield"
    @Published var isShieldActive: Bool = false
    @Published var activeBlockCount: Int = 0
    
    @Published var blocksToday: Int = 0
    @Published var blocksTrend: Double = 0.0
    @Published var savedTime: TimeInterval = 0
    @Published var savedTimeTrend: Double = 0.0
    
    @Published var vpnStatus: NEVPNStatus = .invalid
    @Published var vpnConfiguration: VPNConfiguration
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let vpnManager = NEVPNManager.shared()
    private let configurationKey = "vpn_configuration"
    
    // MARK: - Methods
    func toggleShield() {
        isLoading = true
        
        if isShieldActive {
            stopVPN { [weak self] success in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if success {
                        self?.isShieldActive = false
                        self?.vpnConfiguration.lastDeactivationDate = Date()
                        self?.saveConfiguration()
                    } else {
                        self?.errorMessage = "Failed to deactivate shield"
                    }
                }
            }
        } else {
            startVPN { [weak self] success in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if success {
                        self?.isShieldActive = true
                        self?.vpnConfiguration.lastActivationDate = Date()
                        self?.saveConfiguration()
                    } else {
                        self?.errorMessage = "Failed to activate shield"
                    }
                }
            }
        }
    }
    
    func openSettings() {
        // TODO: Implement settings navigation
    }
    
    @MainActor
    func refreshData() async {
        // Refresh VPN status
        loadVPNStatus()
        
        // Update statistics (in a real app, this might fetch from a service)
        updateUIFromConfiguration()
    }
    
    // MARK: - Helper Methods
    private func fetchLatestStats() {
        // TODO: Implement stats fetching from local storage or API
    }
    
    private func calculateTrends() {
        // TODO: Implement trend calculation logic
    }
    
    // MARK: - Initialization
    init() {
        // Load configuration from UserDefaults
        if let savedData = UserDefaults.standard.data(forKey: configurationKey),
           let savedConfig = try? JSONDecoder().decode(VPNConfiguration.self, from: savedData) {
            vpnConfiguration = savedConfig
        } else {
            // Create default configuration
            vpnConfiguration = VPNConfiguration()
            vpnConfiguration.profiles = VPNConfiguration.defaultProfiles()
            vpnConfiguration.defaultRules = VPNConfiguration.defaultRules()
            
            // Save the default configuration
            saveConfiguration()
        }
        
        // Set up VPN status observation
        observeVPNStatus()
        
        // Load VPN status
        loadVPNStatus()
        
        // Update UI based on configuration
        updateUIFromConfiguration()
    }
    
    // MARK: - VPN Management Methods
    
    /// Start the VPN connection
    private func startVPN(completion: @escaping (Bool) -> Void) {
        loadVPNManager { [weak self] success in
            guard success, let self = self else {
                completion(false)
                return
            }
            
            do {
                try self.vpnManager.connection.startVPNTunnel()
                completion(true)
            } catch {
                print("Error starting VPN: \(error.localizedDescription)")
                self.errorMessage = "Error starting VPN: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
    
    /// Stop the VPN connection
    private func stopVPN(completion: @escaping (Bool) -> Void) {
        self.vpnManager.connection.stopVPNTunnel()
        completion(true)
    }
    
    /// Load the VPN manager configuration
    private func loadVPNManager(completion: @escaping (Bool) -> Void) {
        vpnManager.loadFromPreferences { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading VPN preferences: \(error.localizedDescription)")
                self.errorMessage = "Error loading VPN preferences: \(error.localizedDescription)"
                completion(false)
                return
            }
            
            // Configure the VPN protocol
            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.providerBundleIdentifier = "com.zenith.ZenithVPNExtension"
            tunnelProtocol.serverAddress = "Zenith Distraction Blocker"
            
            self.vpnManager.protocolConfiguration = tunnelProtocol
            self.vpnManager.localizedDescription = "Zenith Distraction Blocker"
            self.vpnManager.isEnabled = true
            
            // Save the configuration
            self.vpnManager.saveToPreferences { error in
                if let error = error {
                    print("Error saving VPN preferences: \(error.localizedDescription)")
                    self.errorMessage = "Error saving VPN preferences: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                completion(true)
            }
        }
    }
    
    /// Observe changes in VPN status
    private func observeVPNStatus() {
        NotificationCenter.default.publisher(for: .NEVPNStatusDidChange)
            .sink { [weak self] _ in
                self?.loadVPNStatus()
            }
            .store(in: &cancellables)
    }
    
    /// Load the current VPN status
    private func loadVPNStatus() {
        let status = vpnManager.connection.status
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.vpnStatus = status
            
            // Update isShieldActive based on VPN status
            self.isShieldActive = (status == .connected || status == .connecting)
            
            // Update UI
            self.updateUIFromConfiguration()
        }
    }
    
    // MARK: - Configuration Management
    
    /// Save the current configuration to UserDefaults
    private func saveConfiguration() {
        if let encodedData = try? JSONEncoder().encode(vpnConfiguration) {
            UserDefaults.standard.set(encodedData, forKey: configurationKey)
        }
    }
    
    /// Update UI elements based on the current configuration
    private func updateUIFromConfiguration() {
        // Update active profile name
        if let activeProfileId = vpnConfiguration.activeProfileId,
           let activeProfile = vpnConfiguration.profiles.first(where: { $0.id == activeProfileId }) {
            currentMode = activeProfile.name
        } else {
            currentMode = "Default Shield"
        }
        
        // Count active blocking rules
        let activeProfileRules = vpnConfiguration.activeProfileId.flatMap { profileId in
            vpnConfiguration.profiles.first(where: { $0.id == profileId })?.rules.filter { $0.isActive } ?? []
        } ?? []
        
        let activeDefaultRules = vpnConfiguration.defaultRules.filter { $0.isActive }
        activeBlockCount = activeProfileRules.count + activeDefaultRules.count
        
        // Update statistics
        blocksToday = calculateBlocksToday()
        savedTime = vpnConfiguration.statistics.timeSavedSeconds
    }
    
    /// Calculate the number of blocks today
    private func calculateBlocksToday() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return vpnConfiguration.statistics.blockedByDay.filter { date, _ in
            calendar.isDate(date, inSameDayAs: today)
        }.values.reduce(0, +)
    }
    
    // MARK: - Profile Management
    
    /// Activate a specific blocking profile
    func activateProfile(_ profile: BlockingProfile) {
        // Update the active profile
        vpnConfiguration.activeProfileId = profile.id
        
        // Mark the profile as active and others as inactive
        for i in 0..<vpnConfiguration.profiles.count {
            vpnConfiguration.profiles[i].isActive = (vpnConfiguration.profiles[i].id == profile.id)
        }
        
        // Save the configuration
        saveConfiguration()
        
        // Update UI
        updateUIFromConfiguration()
        
        // Restart VPN if it's active
        if isShieldActive {
            stopVPN { [weak self] success in
                if success {
                    self?.startVPN { _ in }
                }
            }
        }
    }
    
    /// Add a new blocking profile
    func addProfile(_ profile: BlockingProfile) {
        vpnConfiguration.profiles.append(profile)
        saveConfiguration()
    }
    
    /// Update an existing blocking profile
    func updateProfile(_ profile: BlockingProfile) {
        if let index = vpnConfiguration.profiles.firstIndex(where: { $0.id == profile.id }) {
            vpnConfiguration.profiles[index] = profile
            saveConfiguration()
            updateUIFromConfiguration()
        }
    }
    
    /// Delete a blocking profile
    func deleteProfile(_ profile: BlockingProfile) {
        vpnConfiguration.profiles.removeAll { $0.id == profile.id }
        
        // If the deleted profile was active, deactivate it
        if vpnConfiguration.activeProfileId == profile.id {
            vpnConfiguration.activeProfileId = nil
        }
        
        saveConfiguration()
        updateUIFromConfiguration()
    }
    
    // MARK: - Rule Management
    
    /// Add a new blocking rule
    func addRule(_ rule: BlockingRule, toProfile profileId: UUID? = nil) {
        if let profileId = profileId {
            // Add to specific profile
            if let index = vpnConfiguration.profiles.firstIndex(where: { $0.id == profileId }) {
                vpnConfiguration.profiles[index].rules.append(rule)
            }
        } else {
            // Add to default rules
            vpnConfiguration.defaultRules.append(rule)
        }
        
        saveConfiguration()
        updateUIFromConfiguration()
    }
    
    /// Update an existing blocking rule
    func updateRule(_ rule: BlockingRule, inProfile profileId: UUID? = nil) {
        if let profileId = profileId {
            // Update in specific profile
            if let profileIndex = vpnConfiguration.profiles.firstIndex(where: { $0.id == profileId }),
               let ruleIndex = vpnConfiguration.profiles[profileIndex].rules.firstIndex(where: { $0.id == rule.id }) {
                vpnConfiguration.profiles[profileIndex].rules[ruleIndex] = rule
            }
        } else {
            // Update in default rules
            if let index = vpnConfiguration.defaultRules.firstIndex(where: { $0.id == rule.id }) {
                vpnConfiguration.defaultRules[index] = rule
            }
        }
        
        saveConfiguration()
        updateUIFromConfiguration()
    }
    
    /// Delete a blocking rule
    func deleteRule(_ rule: BlockingRule, fromProfile profileId: UUID? = nil) {
        if let profileId = profileId {
            // Delete from specific profile
            if let index = vpnConfiguration.profiles.firstIndex(where: { $0.id == profileId }) {
                vpnConfiguration.profiles[index].rules.removeAll { $0.id == rule.id }
            }
        } else {
            // Delete from default rules
            vpnConfiguration.defaultRules.removeAll { $0.id == rule.id }
        }
        
        saveConfiguration()
        updateUIFromConfiguration()
    }
} 