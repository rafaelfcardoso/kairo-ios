import XCTest
@testable import Zenith

// Mock implementation of TaskRepositoryProtocol for testing TaskService
class MockTaskRepository: TaskRepositoryProtocol {
    var createTaskResult: Result<TodoTask, Error>?
    var createTaskCalled: Bool = false
    var lastCreateTaskTitle: String?
    var lastCreateTaskDescription: String?

    func createTask(title: String, description: String?) async throws -> TodoTask {
        createTaskCalled = true
        lastCreateTaskTitle = title
        lastCreateTaskDescription = description

        guard let result = createTaskResult else {
            // Should not happen in a controlled test, but good to have a fallback.
            throw NSError(domain: "MockTaskRepositoryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "createTaskResult not set"])
        }
        return try result.get()
    }

    // Add other TaskRepositoryProtocol methods here if TaskService uses them in the future,
    // returning dummy data or throwing errors as needed for different test scenarios.
    // Example for a potential listTasks method:
    // func listTasks() async throws -> [TodoTask] { return [] }
}

final class TaskServiceTests: XCTestCase {
    var mockRepository: MockTaskRepository!
    var service: TaskService!

    override func setUp() {
        super.setUp()
        mockRepository = MockTaskRepository()
        service = TaskService(taskRepository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        service = nil
        super.tearDown()
    }

    // Test successful task creation
    func testCreateTask_Success() async throws {
        let expectedTitle = "New Test Task"
        let expectedDescription = "A description for the task"
        // Use a simplified TodoTask for testing if full complexity isn't needed for this test's assertions
        let expectedTask = TodoTask(
            id: "taskGeneratedId", 
            title: expectedTitle, 
            description: expectedDescription, 
            status: "new", 
            priority: "medium", 
            dueDate: nil, 
            hasTime: false, 
            estimatedMinutes: 0, 
            isArchived: false, 
            createdAt: "2023-01-01T00:00:00Z", 
            updatedAt: "2023-01-01T00:00:00Z", 
            project: nil, // Assuming Project is optional or mockable
            tags: [],       // Assuming Tag is mockable or an empty array is fine
            focusSessions: nil, // Assuming FocusSession is optional or mockable
            isRecurring: nil, 
            needsReminder: nil
        )
        mockRepository.createTaskResult = .success(expectedTask)

        let createdTask = try await service.createTask(title: expectedTitle, description: expectedDescription)

        XCTAssertTrue(mockRepository.createTaskCalled)
        XCTAssertEqual(mockRepository.lastCreateTaskTitle, expectedTitle)
        XCTAssertEqual(mockRepository.lastCreateTaskDescription, expectedDescription)
        XCTAssertEqual(createdTask.id, expectedTask.id)
        XCTAssertEqual(createdTask.title, expectedTask.title)
    }

    // Test task creation with empty title (validation failure)
    func testCreateTask_Failure_EmptyTitle() async {
        let title = "   " // Empty after trimming
        let description = "Some description"

        do {
            _ = try await service.createTask(title: title, description: description)
            XCTFail("Expected createTask to throw an error for empty title, but it succeeded.")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "TaskServiceError")
            XCTAssertEqual(error.code, 1)
            XCTAssertEqual(error.localizedDescription, "Task title cannot be empty.")
            XCTAssertFalse(mockRepository.createTaskCalled) // Repository should not be called
        } catch {
            XCTFail("Caught an unexpected error type: \(error)")
        }
    }

    // Test error propagation from repository
    func testCreateTask_Failure_RepositoryError() async {
        let title = "Valid Title"
        let description = "Valid Description"
        // Simulate a specific error from the repository
        let repositoryError = TaskRepoError.serverError("Simulated server down") 
        mockRepository.createTaskResult = .failure(repositoryError)

        do {
            _ = try await service.createTask(title: title, description: description)
            XCTFail("Expected createTask to re-throw the repository's error.")
        } catch let error as TaskRepoError {
            if case .serverError(let message) = error {
                XCTAssertEqual(message, "Simulated server down")
            } else {
                XCTFail("Caught TaskRepoError but not the expected .serverError case. Got: \(error)")
            }
            XCTAssertTrue(mockRepository.createTaskCalled)
        } catch {
            XCTFail("Caught an unexpected error type: \(error)")
        }
    }
}
