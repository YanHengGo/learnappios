import CoreModel

// Android: TaskDto

public struct TaskDTO: Decodable {
    public let id: String
    public let name: String
    public let description: String?
    public let subject: String
    public let defaultMinutes: Int
    public let daysMask: Int
    public let isArchived: Bool
    public let startDate: String?
    public let endDate: String?
    public let sortOrder: Int?
}

extension TaskDTO {
    public func toModel() -> Task {
        Task(id: id, name: name, description: description,
             subject: subject, defaultMinutes: defaultMinutes,
             daysMask: daysMask, isArchived: isArchived,
             startDate: startDate, endDate: endDate, sortOrder: sortOrder ?? 0)
    }
}
