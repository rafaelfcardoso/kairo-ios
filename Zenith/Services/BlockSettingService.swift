import Foundation

/// Service for handling legacy block setting API operations
class BlockSettingService {
    // MARK: - Properties
    static let shared = BlockSettingService()
    
    private let apiService = APIService.shared
    private let endpoint = "/block-settings"
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - API Methods
    /// Fetch all individual block settings
    func getAllBlockSettings() async throws -> [BlockSetting] {
        try await apiService.get(endpoint: endpoint)
    }
    
    /// Get a specific block setting
    func getBlockSetting(id: String) async throws -> BlockSetting {
        try await apiService.get(endpoint: "\(endpoint)/\(id)")
    }
    
    /// Create a new block setting
    func createBlockSetting(type: BlockType, identifier: String, isActive: Bool = true) async throws -> BlockSetting {
        let body = CreateBlockSettingRequest(
            type: type,
            identifier: identifier,
            isActive: isActive
        )
        
        return try await apiService.post(endpoint: endpoint, body: body)
    }
    
    /// Update a block setting
    func updateBlockSetting(id: String, type: BlockType? = nil, identifier: String? = nil, isActive: Bool? = nil) async throws -> BlockSetting {
        let body = UpdateBlockSettingRequest(
            type: type,
            identifier: identifier,
            isActive: isActive
        )
        
        return try await apiService.patch(endpoint: "\(endpoint)/\(id)", body: body)
    }
    
    /// Delete a block setting
    func deleteBlockSetting(id: String) async throws {
        try await apiService.delete(endpoint: "\(endpoint)/\(id)")
    }
}

// MARK: - Request Models
struct CreateBlockSettingRequest: Codable {
    let type: BlockType
    let identifier: String
    let isActive: Bool
}

struct UpdateBlockSettingRequest: Codable {
    let type: BlockType?
    let identifier: String?
    let isActive: Bool?
} 