import CoreModel

public protocol SummaryRepositoryProtocol {
    func getCalendarSummary(childId: String, from: String, to: String) async throws -> CalendarSummary
    func getSummary(childId: String, from: String, to: String) async throws -> Summary
}
