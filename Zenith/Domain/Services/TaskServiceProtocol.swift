import Foundation

/// A protocol defining the service layer for task management operations.
protocol TaskServiceProtocol {
    /// Creates a new task with the given title and optional description.
    ///
    /// - Parameters:
    ///   - title: The title of the task. Must not be empty.
    ///   - description: An optional description for the task.
    /// - Returns: The created `TodoTask` object.
    /// - Throws: An error if task creation fails (e.g., validation error, repository error).
    func createTask(title: String, description: String?) async throws -> TodoTask
}
