import Foundation

protocol TaskRepositoryProtocol {
    func listTasks() async throws -> [TodoTask]
    func createTask(_ task: TodoTask) async throws
}
