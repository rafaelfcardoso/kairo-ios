import Foundation

/// Service for handling app category API operations
class AppCategoryService {
    // MARK: - Properties
    static let shared = AppCategoryService()
    
    private let apiService = APIService.shared
    private let endpoint = "/app-categories"
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - API Methods
    /// Fetch all app categories
    func getAllAppCategories() async throws -> [AppCategory] {
        try await apiService.get(endpoint: endpoint)
    }
    
    /// Get a specific app category
    func getAppCategory(id: String) async throws -> AppCategory {
        try await apiService.get(endpoint: "\(endpoint)/\(id)")
    }
    
    /// Create a new app category
    func createAppCategory(systemId: String, name: String, description: String, isActive: Bool = true) async throws -> AppCategory {
        let body = CreateAppCategoryRequest(
            systemId: systemId,
            name: name,
            description: description,
            isActive: isActive
        )
        
        return try await apiService.post(endpoint: endpoint, body: body)
    }
    
    /// Update an app category
    func updateAppCategory(id: String, systemId: String? = nil, name: String? = nil, description: String? = nil, isActive: Bool? = nil) async throws -> AppCategory {
        let body = UpdateAppCategoryRequest(
            systemId: systemId,
            name: name,
            description: description,
            isActive: isActive
        )
        
        return try await apiService.patch(endpoint: "\(endpoint)/\(id)", body: body)
    }
    
    /// Delete an app category
    func deleteAppCategory(id: String) async throws {
        try await apiService.delete(endpoint: "\(endpoint)/\(id)")
    }
    
    /// Seed default app categories
    func seedDefaultCategories() async throws -> [AppCategory] {
        try await apiService.post(endpoint: "\(endpoint)/seed", body: EmptyRequest())
    }
}

// MARK: - Request Models
struct CreateAppCategoryRequest: Codable {
    let systemId: String
    let name: String
    let description: String
    let isActive: Bool
}

struct UpdateAppCategoryRequest: Codable {
    let systemId: String?
    let name: String?
    let description: String?
    let isActive: Bool?
}

struct EmptyRequest: Codable {} 