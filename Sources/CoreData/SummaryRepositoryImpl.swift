import CoreModel
import CoreDomain
import CoreNetwork

public final class SummaryRepositoryImpl: SummaryRepositoryProtocol {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func getCalendarSummary(childId: String, from: String, to: String) async throws -> CalendarSummary {
        let dto: CalendarSummaryDTO = try await apiClient.send(
            .calendarSummary(childId: childId, from: from, to: to)
        )
        return dto.toModel()
    }

    public func getSummary(childId: String, from: String, to: String) async throws -> Summary {
        let dto: SummaryDTO = try await apiClient.send(
            .summary(childId: childId, from: from, to: to)
        )
        return dto.toModel()
    }
}
