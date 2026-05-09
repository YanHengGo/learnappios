import CoreModel

public struct GetCalendarSummaryUseCase {
    private let repository: SummaryRepositoryProtocol
    public init(repository: SummaryRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, from: String, to: String) async throws -> CalendarSummary {
        try await repository.getCalendarSummary(childId: childId, from: from, to: to)
    }
}
