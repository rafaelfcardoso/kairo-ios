import Foundation

/// Service for handling schedule API operations
class ScheduleService {
    // MARK: - Properties
    static let shared = ScheduleService()
    
    private let apiService = APIService.shared
    private let endpoint = "/schedules"
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - API Methods
    /// Fetch all schedules
    func getAllSchedules() async throws -> [Schedule] {
        try await apiService.get(endpoint: endpoint)
    }
    
    /// Get a specific schedule
    func getSchedule(id: String) async throws -> Schedule {
        try await apiService.get(endpoint: "\(endpoint)/\(id)")
    }
    
    /// Create a new schedule
    func createSchedule(
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        days: [Int],
        active: Bool = true,
        blockListIds: [String] = [],
        directBlockItemIds: [String]? = nil
    ) async throws -> Schedule {
        let body = CreateScheduleRequest(
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            days: days,
            active: active,
            blockListIds: blockListIds,
            directBlockItemIds: directBlockItemIds
        )
        
        return try await apiService.post(endpoint: endpoint, body: body)
    }
    
    /// Update a schedule
    func updateSchedule(
        id: String,
        startHour: Int? = nil,
        startMinute: Int? = nil,
        endHour: Int? = nil,
        endMinute: Int? = nil,
        days: [Int]? = nil,
        active: Bool? = nil,
        blockListIds: [String]? = nil,
        directBlockItemIds: [String]? = nil
    ) async throws -> Schedule {
        let body = UpdateScheduleRequest(
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            days: days,
            active: active,
            blockListIds: blockListIds,
            directBlockItemIds: directBlockItemIds
        )
        
        return try await apiService.patch(endpoint: "\(endpoint)/\(id)", body: body)
    }
    
    /// Delete a schedule
    func deleteSchedule(id: String) async throws {
        try await apiService.delete(endpoint: "\(endpoint)/\(id)")
    }
}

// MARK: - Request Models
struct CreateScheduleRequest: Codable {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let days: [Int]
    let active: Bool
    let blockListIds: [String]
    let directBlockItemIds: [String]?
}

struct UpdateScheduleRequest: Codable {
    let startHour: Int?
    let startMinute: Int?
    let endHour: Int?
    let endMinute: Int?
    let days: [Int]?
    let active: Bool?
    let blockListIds: [String]?
    let directBlockItemIds: [String]?
} 