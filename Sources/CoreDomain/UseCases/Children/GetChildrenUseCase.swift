import CoreModel

public struct GetChildrenUseCase {
    private let repository: ChildrenRepositoryProtocol
    public init(repository: ChildrenRepositoryProtocol) { self.repository = repository }
    public func execute() async throws -> [Child] {
        try await repository.getChildren()
    }
}
