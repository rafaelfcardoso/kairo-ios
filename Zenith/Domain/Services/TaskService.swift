import Foundation

/// Service layer implementation for task management operations.
final class TaskService: TaskServiceProtocol {
    private let taskRepository: TaskRepositoryProtocol

    /// Initializes a new instance of the task service.
    /// - Parameter taskRepository: The task repository to be used for data operations.
    init(taskRepository: TaskRepositoryProtocol) {
        self.taskRepository = taskRepository
    }

    func createTask(title: String, description: String?) async throws -> TodoTask {
        // Basic validation (can be expanded)
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Define a more specific error type for service layer errors if needed
            throw NSError(domain: "TaskServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Task title cannot be empty."])
        }

        // Call the repository to create the task
        // The TodoTask from the repository is returned directly as it serves as our domain model here.
        return try await taskRepository.createTask(title: title, description: description)
    }
}
