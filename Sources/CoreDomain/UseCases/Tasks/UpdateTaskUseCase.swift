import CoreModel

public struct UpdateTaskUseCase {
    private let repository: TaskRepositoryProtocol
    public init(repository: TaskRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, taskId: String, task: Task) async throws -> Task {
        try await repository.updateTask(childId: childId, taskId: taskId, task: task)
    }
}
