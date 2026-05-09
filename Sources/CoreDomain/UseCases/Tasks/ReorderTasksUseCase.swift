// Android: orders: List<Pair<String, Int>> に対応
public struct ReorderTasksUseCase {
    private let repository: TaskRepositoryProtocol
    public init(repository: TaskRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String,
                        orders: [(taskId: String, sortOrder: Int)]) async throws {
        try await repository.reorderTasks(childId: childId, orders: orders)
    }
}
