import Foundation

final class ListTasksUseCaseImpl: ListTasksUseCase {
    private let repository: TaskRepositoryProtocol
    
    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute() async throws -> [TodoTask] {
        return try await repository.listTasks()
    }
}
