import CoreModel

public struct UpdateChildUseCase {
    private let repository: ChildrenRepositoryProtocol
    public init(repository: ChildrenRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, name: String, grade: String?) async throws -> Child {
        try await repository.updateChild(childId: childId, name: name, grade: grade)
    }
}
