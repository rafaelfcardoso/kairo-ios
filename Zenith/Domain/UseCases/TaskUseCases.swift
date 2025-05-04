import Foundation

// Protocol for listing tasks
protocol ListTasksUseCase {
    func execute() async throws -> [TodoTask]
}

// Protocol for creating a task
protocol CreateTaskUseCase {
    func execute(task: TodoTask) async throws
}
