import Foundation

final class CreateTaskUseCaseImpl: CreateTaskUseCase {
    private let repository: TaskRepositoryProtocol
    
    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(task: TodoTask) async throws {
        try await repository.createTask(task)
    }
}
