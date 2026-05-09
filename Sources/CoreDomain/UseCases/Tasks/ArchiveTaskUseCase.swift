public struct ArchiveTaskUseCase {
    private let repository: TaskRepositoryProtocol
    public init(repository: TaskRepositoryProtocol) { self.repository = repository }
    public func execute(taskId: String) async throws {
        try await repository.archiveTask(taskId: taskId)
    }
}
