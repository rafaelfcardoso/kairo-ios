import Foundation
import MCP

protocol MCPClientProtocol: AnyObject, Sendable {
    func callTool(name: String, arguments: [String: Value]) async throws -> ([Tool.Content], Bool?)
}

final class MCPClientAdapter: MCPClientProtocol {
    private let client: Client
    init(client: Client) { self.client = client }
    func callTool(name: String, arguments: [String: Value]) async throws -> ([Tool.Content], Bool?) {
        try await client.callTool(name: name, arguments: arguments)
    }
}

final class TaskRepositoryMCP: TaskRepositoryProtocol {
    private let mcpClient: MCPClientProtocol
    
    init(mcpClient: MCPClientProtocol = MCPClientAdapter(client: ZenithMCP.shared.client)) {
        self.mcpClient = mcpClient
    }

    func listTasks() async throws -> [TodoTask] {
        let (content, _) = try await mcpClient.callTool(name: "list-tasks", arguments: [:]).0
        
        guard let firstContent = content.first else {
            throw TaskRepoError.unexpectedResponse("Expected content for listTasks, got empty array")
        }

        do {
            let jsonData = try firstContent.jsonData()
            let tasks = try JSONDecoder().decode([TodoTask].self, from: jsonData)
            return tasks
        } catch {
            throw TaskRepoError.responseDecodingFailed(error)
        }
    }

    func createTask(_ task: TodoTask) async throws -> TodoTask {
        return try await createTask(title: task.title, description: task.description)
    }

    func createTask(title: String, description: String?) async throws -> TodoTask {
        var arguments: [String: Value] = ["title": .string(title)]
        if let desc = description, !desc.isEmpty {
            arguments["description"] = .string(desc)
        }
        
        do {
            let (content, _) = try await mcpClient.callTool(
                name: "create-task",
                arguments: arguments
            )
            
            guard let firstToolContent = content.first else {
                throw TaskRepoError.unexpectedResponse("MCP 'create-task' did not return any content.")
            }
            
            if case .text(let jsonString) = firstToolContent {
                guard let taskData = jsonString.data(using: .utf8) else {
                    throw TaskRepoError.encodingFailed("Could not convert response string to Data for TodoTask decoding.")
                }
                let createdTask = try JSONDecoder().decode(TodoTask.self, from: taskData)
                return createdTask
            } else {
                throw TaskRepoError.unexpectedResponse("MCP 'create-task' response was not in the expected .text format containing JSON. Received: \(firstToolContent)")
            }
            
        } catch let mcpError as MCP.MCPError {
            switch mcpError.code {
                case "InvalidParams":
                    throw TaskRepoError.invalidArguments(mcpError.message ?? "Invalid parameters")
                case "Unauthorized":
                    throw TaskRepoError.authenticationFailed(mcpError.message ?? "Authentication failed")
                case "Forbidden":
                    throw TaskRepoError.accessDenied(mcpError.message ?? "Access denied")
                case "NotFound":
                    throw TaskRepoError.notFound(mcpError.message ?? "Resource not found")
                case "RateLimited":
                    throw TaskRepoError.rateLimited(mcpError.message ?? "Rate limited")
                case "ServerError":
                    throw TaskRepoError.serverError(mcpError.message ?? "Server error")
                case "IncompatibleVersion":
                    throw TaskRepoError.incompatibleVersion(mcpError.message ?? "Incompatible client/server version")
                default:
                    throw TaskRepoError.mcpError("Code: \(mcpError.code), Message: \(mcpError.message ?? "Unknown MCP Error")")
            }
        } catch {
            throw TaskRepoError.mcpError("An unexpected error occurred: \(error.localizedDescription)")
        }
    }
}

extension MCP.Value {
    func jsonData() throws -> Data {
        switch self {
        case .string(let s):
            guard let data = s.data(using: .utf8) else { throw TaskRepoError.encodingFailed("Could not convert string to data") }
            return data
        case .object(let dict):
            let serializableDict = try dict.mapValues { try $0.toSerializableValue() }
            return try JSONSerialization.data(withJSONObject: serializableDict, options: [])
        default:
            throw TaskRepoError.encodingFailed("MCP.Value type not directly convertible to JSON data for TodoTask decoding: \(self)")
        }
    }

    func toSerializableValue() throws -> Any {
        switch self {
        case .string(let s): return s
        case .int(let i): return i
        case .double(let d): return d
        case .bool(let b): return b
        case .array(let arr): return try arr.map { try $0.toSerializableValue() }
        case .object(let obj): return try obj.mapValues { try $0.toSerializableValue() }
        case .null: return NSNull()
        }
    }
}

enum TaskRepoError: Swift.Error {
    case decodingFailed
    case encodingFailed(String)
    case mcpError(String)
    case invalidArguments(String?)
    case authenticationFailed(String?)
    case accessDenied(String?)
    case serverError(String?)
    case responseDecodingFailed(Swift.Error)
    case unexpectedResponse(String)
    case notFound(String?)
    case rateLimited(String?)
    case incompatibleVersion(String?)
}
