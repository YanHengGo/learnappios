import CoreModel

public protocol TaskRepositoryProtocol {
    func getTasks(childId: String) async throws -> [Task]
    func createTask(childId: String, task: Task) async throws -> Task
    func updateTask(childId: String, taskId: String, task: Task) async throws -> Task
    func archiveTask(taskId: String) async throws
    func reorderTasks(childId: String,
                      orders: [(taskId: String, sortOrder: Int)]) async throws
}
