/// 保存リクエスト用の最小モデル
public struct DailyItem: Equatable {
    public let taskId: String
    public let minutes: Int

    public init(taskId: String, minutes: Int) {
        self.taskId = taskId
        self.minutes = minutes
    }
}
