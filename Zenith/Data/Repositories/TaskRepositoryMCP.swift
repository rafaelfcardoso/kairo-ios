import Foundation
import MCP

final class TaskRepositoryMCP: TaskRepositoryProtocol {
    private let mcpClient: Client
    
    init(mcpClient: Client = ZenithMCP.shared.client) {
        self.mcpClient = mcpClient
    }

    func listTasks() async throws -> [TodoTask] {
        let (content, isError) = try await mcpClient.callTool(name: "list-tasks", arguments: [:])
        guard !content.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: content, options: []),
              let tasks = try? JSONDecoder().decode([TodoTask].self, from: data) else {
            throw TaskRepoError.decodingFailed
        }
        return tasks
    }

    func createTask(_ task: TodoTask) async throws {
        let data = try JSONEncoder().encode(task)

        // Convert the encoded JSON back into the `[String: Value]` dictionary
        // that `callTool(name:arguments:)` expects.
        let arguments = try JSONDecoder().decode([String: Value].self, from: data)

        try await mcpClient.callTool(
            name: "create-task",
            arguments: arguments
        )
    }
}

enum TaskRepoError: Swift.Error {
    case decodingFailed
    case encodingFailed
}
