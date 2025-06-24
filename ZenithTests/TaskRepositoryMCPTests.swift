import XCTest
import MCP
@testable import Zenith

final class TaskRepositoryMCPTests: XCTestCase {
    var mockClient: MockClient!
    var repo: TaskRepositoryMCP!

    override func setUp() async throws {
        mockClient = MockClient()
        repo = TaskRepositoryMCP(mcpClient: mockClient)
    }

    override func tearDown() {
        mockClient = nil
        repo = nil
        super.tearDown()
    }

    func testCreateTaskSendsCorrectArguments() async throws {
        let title = "Test Title"
        let description = "Test Description"
        mockClient.expectedToolName = "create-task"
        mockClient.expectedArguments = [
            "title": .string(title),
            "description": .string(description)
        ]
        _ = try await repo.createTask(title: title, description: description)
        XCTAssertTrue(mockClient.didCallTool, "Should call tool with correct arguments")
    }

    func testCreateTaskOmitsDescriptionIfNil() async throws {
        let title = "Title Only"
        _ = try await repo.createTask(title: title, description: nil)

        XCTAssertTrue(mockClient.didCallTool, "Should call tool with only title argument")
        XCTAssertEqual(mockClient.lastArguments?["title"], .string(title))
        XCTAssertNil(mockClient.lastArguments?["description"])
    }

    func testCreateTask_Success_DecodesResponse() async throws {
        let expectedTask = TodoTask(id: "task123", title: "Decoded Task", description: "Description", status: "new", priority: "medium", dueDate: nil, hasTime: false, estimatedMinutes: 0, isArchived: false, createdAt: "", updatedAt: "", project: nil, tags: [], focusSessions: nil, isRecurring: nil, needsReminder: nil)

        // Simulate the server sending a JSON string representing the TodoTask
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // Optional: for readability if debugging
        let taskData = try encoder.encode(expectedTask)
        let jsonString = String(data: taskData, encoding: .utf8)!

        let toolContent = Tool.Content.text(jsonString)
        mockClient.toolCallResult = .success(([toolContent], false))

        let createdTask = try await repo.createTask(title: expectedTask.title, description: expectedTask.description)

        XCTAssertEqual(createdTask.id, expectedTask.id)
        XCTAssertEqual(createdTask.title, expectedTask.title)
        XCTAssertEqual(createdTask.description, expectedTask.description)
    }

    func testCreateTask_Error_MCPInvalidParams() async throws {
        let mcpError = MCP.MCPError(code: "InvalidParams", message: "Title is missing", data: nil, path: nil)
        mockClient.toolCallResult = .failure(mcpError)

        do {
            _ = try await repo.createTask(title: "Test", description: nil)
            XCTFail("Expected TaskRepoError.invalidArguments to be thrown")
        } catch let error as TaskRepoError {
            if case .invalidArguments(let msg) = error {
                XCTAssertEqual(msg, "Title is missing")
            } else {
                XCTFail("Thrown error \(error) was not the expected .invalidArguments")
            }
        } catch {
            XCTFail("An unexpected error type was thrown: \(error)")
        }
    }

    func testCreateTask_Error_MCPUnauthorized() async throws {
        let mcpError = MCP.MCPError(code: "Unauthorized", message: "Token expired", data: nil, path: nil)
        mockClient.toolCallResult = .failure(mcpError)

        do {
            _ = try await repo.createTask(title: "Test", description: nil)
            XCTFail("Expected TaskRepoError.authenticationFailed to be thrown")
        } catch let error as TaskRepoError {
            if case .authenticationFailed(let msg) = error {
                XCTAssertEqual(msg, "Token expired")
            } else {
                XCTFail("Thrown error \(error) was not the expected .authenticationFailed")
            }
        } catch {
            XCTFail("An unexpected error type was thrown: \(error)")
        }
    }

    func testCreateTask_Error_UnexpectedResponse() async throws {
        mockClient.toolCallResult = .success(([], false))

        do {
            _ = try await repo.createTask(title: "Test", description: nil)
            XCTFail("Expected TaskRepoError.unexpectedResponse to be thrown")
        } catch TaskRepoError.unexpectedResponse(let msg) {
            XCTAssertEqual(msg, "MCP 'create-task' did not return any content.")
        } catch {
            XCTFail("An unexpected error type was thrown: \(error) or wrong TaskRepoError case")
        }
    }

    func testCreateTask_Error_UnexpectedResponse_WrongContentType() async throws {
        // Test for when content is present but not .text
        let nonTextContent = Tool.Content.image(Data(), "image/png", nil)
        mockClient.toolCallResult = .success(([nonTextContent], false))

        do {
            _ = try await repo.createTask(title: "Test", description: nil)
            XCTFail("Expected TaskRepoError.unexpectedResponse to be thrown for wrong content type")
        } catch TaskRepoError.unexpectedResponse(let msg) {
            XCTAssertTrue(msg.contains("MCP 'create-task' response was not in the expected .text format"), "Error message should indicate wrong content type. Got: \(msg)")
        } catch {
            XCTFail("An unexpected error type was thrown: \(error) or wrong TaskRepoError case")
        }
    }

    func testCreateTask_Error_ResponseDecodingFailed() async throws {
        // Simulate a malformed JSON string that cannot be decoded into TodoTask
        let malformedJsonString = "{\"id\": \"taskMalformed\", \"title\": \"Malformed Task\", \"status\": " // Missing closing quote and bracket
        let malformedContent = Tool.Content.text(malformedJsonString)
        mockClient.toolCallResult = .success(([malformedContent], false))

        do {
            _ = try await repo.createTask(title: "Test", description: nil)
            XCTFail("Expected TaskRepoError.responseDecodingFailed to be thrown")
        } catch TaskRepoError.responseDecodingFailed(_) {
            // Success, correct error type thrown.
        } catch {
            XCTFail("An unexpected error type was thrown: \(error) or wrong TaskRepoError case")
        }
    }
}

final class MockClient: MCPClientProtocol {
    var didCallTool = false
    var expectedToolName: String?
    var expectedArguments: [String: Value]?
    var lastToolName: String?
    var lastArguments: [String: Value]?
    var toolCallResult: Result<([Tool.Content], Bool?), Error>?

    func callTool(name: String, arguments: [String : Value]) async throws -> ([Tool.Content], Bool?) {
        didCallTool = true
        lastToolName = name
        lastArguments = arguments

        if let result = toolCallResult {
            switch result {
            case .success(let successResult):
                return successResult
            case .failure(let error):
                throw error
            }
        }

        if let expectedName = expectedToolName {
            XCTAssertEqual(name, expectedName)
        }
        if let expectedArgs = expectedArguments {
            XCTAssertEqual(arguments.count, expectedArgs.count)
            for (key, value) in expectedArgs {
                XCTAssertEqual(arguments[key], value, "Argument for key '\(key)' did not match")
            }
        }
        return ([], false)
    }
}
