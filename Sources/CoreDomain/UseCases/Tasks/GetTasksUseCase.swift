import CoreModel

public struct GetTasksUseCase {
    private let repository: TaskRepositoryProtocol
    public init(repository: TaskRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String) async throws -> [Task] {
        try await repository.getTasks(childId: childId)
    }
}
