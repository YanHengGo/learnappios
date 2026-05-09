import CoreModel

public struct GetDailyViewUseCase {
    private let repository: DailyRepositoryProtocol
    public init(repository: DailyRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, date: String) async throws -> DailyView {
        try await repository.getDailyView(childId: childId, date: date)
    }
}
