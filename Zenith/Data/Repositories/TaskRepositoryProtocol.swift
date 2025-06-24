import Foundation

protocol TaskRepositoryProtocol {
    func listTasks() async throws -> [TodoTask]
    func createTask(title: String, description: String?) async throws -> TodoTask
}
