import CoreModel

public struct GetSummaryUseCase {
    private let repository: SummaryRepositoryProtocol
    public init(repository: SummaryRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, from: String, to: String) async throws -> Summary {
        try await repository.getSummary(childId: childId, from: from, to: to)
    }
}
