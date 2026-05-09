import CoreModel

// Android: CalendarSummaryDto, CalendarDayDto, SummaryDto 等

public struct CalendarSummaryDTO: Decodable {
    public let from: String
    public let to: String
    public let days: [CalendarDayDTO]
}
public struct CalendarDayDTO: Decodable {
    public let date: String
    public let status: String   // "GREEN" | "YELLOW" | "RED" | "WHITE"
    public let total: Int
    public let done: Int
}
public struct SummaryDTO: Decodable {
    public let from: String
    public let to: String
    public let totalMinutes: Int
    public let byDay: [SummaryByDayDTO]
    public let bySubject: [SummaryBySubjectDTO]
    public let byTask: [SummaryByTaskDTO]
}
public struct SummaryByDayDTO: Decodable {
    public let date: String
    public let minutes: Int
}
public struct SummaryBySubjectDTO: Decodable {
    public let subject: String
    public let minutes: Int
}
public struct SummaryByTaskDTO: Decodable {
    public let taskId: String
    public let name: String
    public let subject: String
    public let minutes: Int
}

extension CalendarSummaryDTO {
    public func toModel() -> CalendarSummary {
        CalendarSummary(from: from, to: to, days: days.map { $0.toModel() })
    }
}
extension CalendarDayDTO {
    public func toModel() -> CalendarDay {
        CalendarDay(date: date,
                    status: CalendarStatus(rawValue: status) ?? .white,
                    total: total, done: done)
    }
}
extension SummaryDTO {
    public func toModel() -> Summary {
        Summary(
            from: from, to: to, totalMinutes: totalMinutes,
            byDay: byDay.map { SummaryByDay(date: $0.date, minutes: $0.minutes) },
            bySubject: bySubject.map { SummaryBySubject(subject: $0.subject, minutes: $0.minutes) },
            byTask: byTask.map {
                SummaryByTask(taskId: $0.taskId, name: $0.name,
                              subject: $0.subject, minutes: $0.minutes)
            }
        )
    }
}
