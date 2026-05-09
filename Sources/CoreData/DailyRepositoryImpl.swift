import CoreModel
import CoreDomain
import CoreNetwork

public final class DailyRepositoryImpl: DailyRepositoryProtocol {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func getDailyView(childId: String, date: String) async throws -> DailyView {
        let dto: DailyViewDTO = try await apiClient.send(.dailyView(childId: childId, date: date))
        return dto.toModel()
    }

    public func updateDailyLog(childId: String, date: String,
                               items: [DailyItem]) async throws -> Int {
        let dto: UpdateDailyResponseDTO = try await apiClient.send(
            .updateDaily(childId: childId, date: date,
                         items: items.map { (taskId: $0.taskId, minutes: $0.minutes) })
        )
        return dto.savedCount
    }
}
