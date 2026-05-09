public struct Summary: Equatable {
    public let from: String
    public let to: String
    public let totalMinutes: Int
    public let byDay: [SummaryByDay]
    public let bySubject: [SummaryBySubject]
    public let byTask: [SummaryByTask]

    public init(
        from: String,
        to: String,
        totalMinutes: Int,
        byDay: [SummaryByDay],
        bySubject: [SummaryBySubject],
        byTask: [SummaryByTask]
    ) {
        self.from = from
        self.to = to
        self.totalMinutes = totalMinutes
        self.byDay = byDay
        self.bySubject = bySubject
        self.byTask = byTask
    }
}

public struct SummaryByDay: Equatable {
    public let date: String
    public let minutes: Int
    public init(date: String, minutes: Int) { self.date = date; self.minutes = minutes }
}

public struct SummaryBySubject: Equatable {
    public let subject: String
    public let minutes: Int
    public init(subject: String, minutes: Int) { self.subject = subject; self.minutes = minutes }
}

public struct SummaryByTask: Equatable {
    public let taskId: String
    public let name: String
    public let subject: String
    public let minutes: Int
    public init(taskId: String, name: String, subject: String, minutes: Int) {
        self.taskId = taskId; self.name = name
        self.subject = subject; self.minutes = minutes
    }
}
