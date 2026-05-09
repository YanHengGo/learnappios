public struct DailyView: Equatable {
    public let date: String       // "yyyy-MM-dd"
    public let weekday: String    // "月曜日" 等（サーバーが返す文字列）
    public let tasks: [DailyTask]

    public init(date: String, weekday: String, tasks: [DailyTask]) {
        self.date = date
        self.weekday = weekday
        self.tasks = tasks
    }
}
