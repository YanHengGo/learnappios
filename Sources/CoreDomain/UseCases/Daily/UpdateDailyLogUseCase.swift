import CoreModel

public struct UpdateDailyLogUseCase {
    private let repository: DailyRepositoryProtocol
    public init(repository: DailyRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, date: String,
                        items: [DailyItem]) async throws -> Int {  // savedCount
        try await repository.updateDailyLog(childId: childId, date: date, items: items)
    }
}
