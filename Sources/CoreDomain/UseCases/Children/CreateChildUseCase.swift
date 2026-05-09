import CoreModel

public struct CreateChildUseCase {
    private let repository: ChildrenRepositoryProtocol
    public init(repository: ChildrenRepositoryProtocol) { self.repository = repository }
    public func execute(name: String, grade: String?) async throws -> Child {
        try await repository.createChild(name: name, grade: grade)
    }
}
