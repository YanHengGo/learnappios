public struct DeleteChildUseCase {
    private let repository: ChildrenRepositoryProtocol
    public init(repository: ChildrenRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String) async throws {
        try await repository.deleteChild(childId: childId)
    }
}
