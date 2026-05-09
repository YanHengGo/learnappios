public struct CalendarSummary: Equatable {
    public let from: String
    public let to: String
    public let days: [CalendarDay]

    public init(from: String, to: String, days: [CalendarDay]) {
        self.from = from
        self.to = to
        self.days = days
    }
}

public struct CalendarDay: Equatable {
    public let date: String
    public let status: CalendarStatus
    public let total: Int
    public let done: Int

    public init(date: String, status: CalendarStatus, total: Int, done: Int) {
        self.date = date
        self.status = status
        self.total = total
        self.done = done
    }
}

public enum CalendarStatus: String {
    case green  = "GREEN"
    case yellow = "YELLOW"
    case red    = "RED"
    case white  = "WHITE"
}
