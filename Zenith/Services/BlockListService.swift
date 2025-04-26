import Foundation

/// Service for handling block list API operations
class BlockListService {
    // MARK: - Properties
    static let shared = BlockListService()
    
    private let apiService = APIService.shared
    private let endpoint = "/block-lists"
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - API Methods
    /// Fetch all block lists for the user
    func getAllBlockLists() async throws -> [BlockList] {
        try await apiService.get(endpoint: endpoint)
    }
    
    /// Fetch a specific block list by ID
    func getBlockList(id: String) async throws -> BlockList {
        try await apiService.get(endpoint: "\(endpoint)/\(id)")
    }
    
    /// Create a new block list
    func createBlockList(name: String, description: String, isActive: Bool, items: [BlockItem]? = nil) async throws -> BlockList {
        let body = CreateBlockListRequest(
            name: name,
            description: description,
            isActive: isActive,
            items: items
        )
        
        return try await apiService.post(endpoint: endpoint, body: body)
    }
    
    /// Update an existing block list
    func updateBlockList(id: String, name: String? = nil, description: String? = nil, isActive: Bool? = nil) async throws -> BlockList {
        let body = UpdateBlockListRequest(
            name: name,
            description: description,
            isActive: isActive
        )
        
        return try await apiService.patch(endpoint: "\(endpoint)/\(id)", body: body)
    }
    
    /// Delete a block list
    func deleteBlockList(id: String) async throws {
        try await apiService.delete(endpoint: "\(endpoint)/\(id)")
    }
    
    /// Add existing items to a block list
    func addItemsToBlockList(blockListId: String, itemIds: [String]) async throws -> BlockList {
        let body = BlockListItemsRequest(itemIds: itemIds)
        
        return try await apiService.post(endpoint: "\(endpoint)/\(blockListId)/items", body: body)
    }
    
    /// Remove items from a block list
    func removeItemsFromBlockList(blockListId: String, itemIds: [String]) async throws -> BlockList {
        let body = BlockListItemsRequest(itemIds: itemIds)
        
        // For DELETE requests that need to return data, we need to create a custom request
        // that includes a body and returns a response
        return try await apiService.request(
            endpoint: "\(endpoint)/\(blockListId)/items/remove",  // Using a different endpoint for a POST that removes items
            method: .post,
            body: body
        )
    }
}

// MARK: - Request Models
struct CreateBlockListRequest: Codable {
    let name: String
    let description: String
    let isActive: Bool
    let items: [BlockItem]?
}

struct UpdateBlockListRequest: Codable {
    let name: String?
    let description: String?
    let isActive: Bool?
}

struct BlockListItemsRequest: Codable {
    let itemIds: [String]
} 