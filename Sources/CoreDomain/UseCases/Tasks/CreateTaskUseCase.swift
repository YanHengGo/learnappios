import CoreModel

public struct CreateTaskUseCase {
    private let repository: TaskRepositoryProtocol
    public init(repository: TaskRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, task: Task) async throws -> Task {
        try await repository.createTask(childId: childId, task: task)
    }
}
