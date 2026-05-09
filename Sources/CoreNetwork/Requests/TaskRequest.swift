// Android: CreateTaskRequest, UpdateTaskRequest, ReorderRequest / ReorderItem

struct CreateTaskRequest: Encodable {
    let name: String
    let description: String?
    let subject: String
    let defaultMinutes: Int
    let daysMask: Int
    let startDate: String?
    let endDate: String?
}
struct UpdateTaskRequest: Encodable {
    let name: String
    let description: String?
    let subject: String
    let defaultMinutes: Int
    let daysMask: Int
    let isArchived: Bool
    let startDate: String?
    let endDate: String?
}
// Android: ReorderRequest { orders: List<ReorderItem { task_id, sort_order }> }
struct ReorderRequest: Encodable {
    let orders: [ReorderItem]
}
struct ReorderItem: Encodable {
    let taskId: String
    let sortOrder: Int
}
// archive 専用パッチボディ
struct ArchiveTaskRequest: Encodable {
    let isArchived: Bool
}
