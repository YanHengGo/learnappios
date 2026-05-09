// Android: UpdateDailyRequest, DailyItemRequest

struct UpdateDailyRequest: Encodable {
    let items: [DailyItemRequest]
}
struct DailyItemRequest: Encodable {
    let taskId: String
    let minutes: Int
}
