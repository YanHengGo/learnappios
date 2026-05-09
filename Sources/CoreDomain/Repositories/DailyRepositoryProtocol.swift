import CoreModel

public protocol DailyRepositoryProtocol {
    func getDailyView(childId: String, date: String) async throws -> DailyView
    func updateDailyLog(childId: String, date: String,
                        items: [DailyItem]) async throws -> Int  // savedCount
}
