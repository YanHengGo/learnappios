import CoreModel

// Android: DailyViewDto, DailyTaskDto, UpdateDailyResponseDto

public struct DailyViewDTO: Decodable {
    public let date: String
    public let weekday: String
    public let tasks: [DailyTaskDTO]
}
public struct DailyTaskDTO: Decodable {
    public let taskId: String
    public let name: String
    public let subject: String
    public let defaultMinutes: Int
    public let daysMask: Int
    public let isDone: Bool
    public let minutes: Int
}
public struct UpdateDailyResponseDTO: Decodable {
    public let date: String
    public let savedCount: Int
}

extension DailyViewDTO {
    public func toModel() -> DailyView {
        DailyView(date: date, weekday: weekday,
                  tasks: tasks.map { $0.toModel() })
    }
}
extension DailyTaskDTO {
    public func toModel() -> DailyTask {
        DailyTask(taskId: taskId, name: name, subject: subject,
                  defaultMinutes: defaultMinutes, daysMask: daysMask,
                  isDone: isDone, minutes: minutes)
    }
}
