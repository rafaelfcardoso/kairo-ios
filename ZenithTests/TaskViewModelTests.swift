import XCTest
@testable import Zenith

@MainActor
final class TaskViewModelTests: XCTestCase {
    var viewModel: TaskViewModel!
    
    override func setUp() async throws {
        viewModel = TaskViewModel()
        APIConfig.isTestEnvironment = true
        APIConfig.testBaseURL = "http://localhost:3001"
    }
    
    override func tearDown() {
        viewModel = nil
        APIConfig.isTestEnvironment = false
        APIConfig.testBaseURL = nil
    }
    
    func testLoadTasksForTodayIncludesCorrectParameters() async throws {
        // Attempt to load tasks
        try await viewModel.loadTasks(forToday: true)
        
        // Verify URL components
        let url = try XCTUnwrap(URLComponents(string: APIConfig.baseURL + APIConfig.apiPath + "/tasks"))
        XCTAssertEqual(url.path, "/api/v1/tasks", "Path should be /api/v1/tasks")
        
        // Verify query parameters
        let queryItems = url.queryItems
        XCTAssertNotNil(queryItems?.first(where: { $0.name == "includeArchived" && $0.value == "false" }))
        XCTAssertNotNil(queryItems?.first(where: { $0.name == "status" && $0.value == "not_started" }))
    }
} 
