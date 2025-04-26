import Foundation

/// Service for handling block item API operations
class BlockItemService {
    // MARK: - Properties
    static let shared = BlockItemService()
    
    private let apiService = APIService.shared
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - API Methods
    /// Fetch all items in a block list
    func getBlockItems(blockListId: String) async throws -> [BlockItem] {
        try await apiService.get(endpoint: "/block-lists/\(blockListId)/items")
    }
    
    /// Get a specific block item
    func getBlockItem(blockListId: String, itemId: String) async throws -> BlockItem {
        try await apiService.get(endpoint: "/block-lists/\(blockListId)/items/\(itemId)")
    }
    
    /// Add a new item to a block list
    func addBlockItem(blockListId: String, type: BlockType, identifier: String, name: String, isActive: Bool = true) async throws -> BlockItem {
        let body = CreateBlockItemRequest(
            type: type,
            identifier: identifier,
            name: name,
            isActive: isActive
        )
        
        return try await apiService.post(endpoint: "/block-lists/\(blockListId)/items", body: body)
    }
    
    /// Add multiple items at once
    func addBulkBlockItems(blockListId: String, items: [CreateBlockItemRequest]) async throws -> [BlockItem] {
        try await apiService.post(endpoint: "/block-lists/\(blockListId)/items/bulk", body: items)
    }
    
    /// Update a block item
    func updateBlockItem(blockListId: String, itemId: String, type: BlockType? = nil, identifier: String? = nil, name: String? = nil, isActive: Bool? = nil) async throws -> BlockItem {
        let body = UpdateBlockItemRequest(
            type: type,
            identifier: identifier,
            name: name,
            isActive: isActive
        )
        
        return try await apiService.patch(endpoint: "/block-lists/\(blockListId)/items/\(itemId)", body: body)
    }
    
    /// Remove an item from a block list
    func removeBlockItem(blockListId: String, itemId: String) async throws {
        try await apiService.delete(endpoint: "/block-lists/\(blockListId)/items/\(itemId)")
    }
}

// MARK: - Request Models
struct CreateBlockItemRequest: Codable {
    let type: BlockType
    let identifier: String
    let name: String
    let isActive: Bool
}

struct UpdateBlockItemRequest: Codable {
    let type: BlockType?
    let identifier: String?
    let name: String?
    let isActive: Bool?
} 