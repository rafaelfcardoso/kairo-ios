import Foundation
import NetworkExtension

/// Service for managing the VPN connection and configuration
class VPNService {
    /// Shared instance for singleton access
    static let shared = VPNService()
    
    /// The VPN manager
    private let vpnManager = NEVPNManager.shared()
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Load the VPN configuration
    func loadVPNConfiguration(completion: @escaping (Result<Void, Error>) -> Void) {
        vpnManager.loadFromPreferences { error in
            if let error = error {
                print("Error loading VPN preferences: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    /// Save the VPN configuration
    func saveVPNConfiguration(completion: @escaping (Result<Void, Error>) -> Void) {
        vpnManager.saveToPreferences { error in
            if let error = error {
                print("Error saving VPN preferences: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    /// Configure the VPN with the App Proxy Provider
    func configureVPN(bundleIdentifier: String, completion: @escaping (Result<Void, Error>) -> Void) {
        loadVPNConfiguration { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Configure the VPN protocol
                let tunnelProtocol = NETunnelProviderProtocol()
                tunnelProtocol.providerBundleIdentifier = bundleIdentifier
                tunnelProtocol.serverAddress = "Zenith Distraction Blocker"
                
                self.vpnManager.protocolConfiguration = tunnelProtocol
                self.vpnManager.localizedDescription = "Zenith Distraction Blocker"
                self.vpnManager.isEnabled = true
                
                // Save the configuration
                self.saveVPNConfiguration(completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Start the VPN connection
    func startVPN() throws {
        try vpnManager.connection.startVPNTunnel()
    }
    
    /// Stop the VPN connection
    func stopVPN() {
        vpnManager.connection.stopVPNTunnel()
    }
    
    /// Get the current VPN status
    var status: NEVPNStatus {
        return vpnManager.connection.status
    }
    
    /// Check if the VPN is connected
    var isConnected: Bool {
        return status == .connected
    }
    
    /// Check if the VPN is connecting
    var isConnecting: Bool {
        return status == .connecting
    }
    
    /// Check if the VPN is disconnecting
    var isDisconnecting: Bool {
        return status == .disconnecting
    }
    
    /// Check if the VPN is disconnected
    var isDisconnected: Bool {
        return status == .disconnected || status == .invalid
    }
    
    /// Pass the current blocking configuration to the VPN extension
    func updateBlockingConfiguration(_ configuration: VPNConfiguration) {
        guard let tunnelProtocol = vpnManager.protocolConfiguration as? NETunnelProviderProtocol else {
            print("Error: Protocol configuration is not a Tunnel Provider Protocol")
            return
        }
        
        // Encode the configuration to JSON
        guard let configData = try? JSONEncoder().encode(configuration) else {
            print("Error encoding VPN configuration")
            return
        }
        
        // Convert to a dictionary that can be stored in providerConfiguration
        guard let configDict = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] else {
            print("Error converting configuration to dictionary")
            return
        }
        
        // Update the provider configuration
        tunnelProtocol.providerConfiguration = configDict
        vpnManager.protocolConfiguration = tunnelProtocol
        
        // Save the configuration
        saveVPNConfiguration { result in
            switch result {
            case .success:
                print("Successfully updated blocking configuration")
            case .failure(let error):
                print("Error updating blocking configuration: \(error.localizedDescription)")
            }
        }
    }
} 