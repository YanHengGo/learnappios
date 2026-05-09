import CoreModel
import CoreDomain
import CoreNetwork

public final class TaskRepositoryImpl: TaskRepositoryProtocol {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func getTasks(childId: String) async throws -> [Task] {
        let dtos: [TaskDTO] = try await apiClient.send(.tasks(childId: childId))
        return dtos.map { $0.toModel() }
    }

    public func createTask(childId: String, task: Task) async throws -> Task {
        let dto: TaskDTO = try await apiClient.send(
            .createTask(childId: childId, name: task.name, description: task.description,
                        subject: task.subject, defaultMinutes: task.defaultMinutes,
                        daysMask: task.daysMask, startDate: task.startDate, endDate: task.endDate)
        )
        return dto.toModel()
    }

    public func updateTask(childId: String, taskId: String, task: Task) async throws -> Task {
        let dto: TaskDTO = try await apiClient.send(
            .updateTask(childId: childId, taskId: taskId, name: task.name,
                        description: task.description, subject: task.subject,
                        defaultMinutes: task.defaultMinutes, daysMask: task.daysMask,
                        isArchived: task.isArchived, startDate: task.startDate, endDate: task.endDate)
        )
        return dto.toModel()
    }

    public func archiveTask(taskId: String) async throws {
        try await apiClient.sendEmpty(.archiveTask(taskId: taskId))
    }

    public func reorderTasks(childId: String,
                             orders: [(taskId: String, sortOrder: Int)]) async throws {
        try await apiClient.sendEmpty(.reorderTasks(childId: childId, orders: orders))
    }
}
