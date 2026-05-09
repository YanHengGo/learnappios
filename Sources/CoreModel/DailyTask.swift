public struct DailyTask: Identifiable, Equatable {
    public var id: String { taskId }
    public let taskId: String
    public let name: String
    public let subject: String
    public let defaultMinutes: Int
    public let daysMask: Int
    public let isDone: Bool
    public let minutes: Int

    public init(
        taskId: String,
        name: String,
        subject: String,
        defaultMinutes: Int,
        daysMask: Int,
        isDone: Bool,
        minutes: Int
    ) {
        self.taskId = taskId
        self.name = name
        self.subject = subject
        self.defaultMinutes = defaultMinutes
        self.daysMask = daysMask
        self.isDone = isDone
        self.minutes = minutes
    }
}
