import Foundation

public struct APIEndpoint {
    public let method: HTTPMethod
    public let path: String
    public let queryItems: [URLQueryItem]?
    public let body: (any Encodable)?

    public init(
        method: HTTPMethod,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.body = body
    }
}

// MARK: - Auth

public extension APIEndpoint {
    static func login(email: String, password: String) -> APIEndpoint {
        .init(method: .post, path: "/api/v1/auth/login",
              body: LoginRequest(email: email, password: password))
    }
    static func signup(email: String, password: String) -> APIEndpoint {
        .init(method: .post, path: "/api/v1/auth/signup",
              body: SignupRequest(email: email, password: password))
    }
    static var me: APIEndpoint {
        .init(method: .get, path: "/api/v1/me")
    }
    static var deleteMe: APIEndpoint {
        .init(method: .delete, path: "/api/v1/me")
    }
}

// MARK: - Children

public extension APIEndpoint {
    static var children: APIEndpoint {
        .init(method: .get, path: "/api/v1/children")
    }
    static func createChild(name: String, grade: String?) -> APIEndpoint {
        .init(method: .post, path: "/api/v1/children",
              body: CreateChildRequest(name: name, grade: grade))
    }
    static func updateChild(id: String, name: String, grade: String?) -> APIEndpoint {
        .init(method: .put, path: "/api/v1/children/\(id)",
              body: UpdateChildRequest(name: name, grade: grade))
    }
    static func deleteChild(id: String) -> APIEndpoint {
        .init(method: .delete, path: "/api/v1/children/\(id)")
    }
}

// MARK: - Tasks

public extension APIEndpoint {
    static func tasks(childId: String) -> APIEndpoint {
        .init(method: .get, path: "/api/v1/children/\(childId)/tasks",
              queryItems: [.init(name: "archived", value: "false")])
    }
    static func createTask(childId: String, name: String, description: String?,
                           subject: String, defaultMinutes: Int, daysMask: Int,
                           startDate: String?, endDate: String?) -> APIEndpoint {
        .init(method: .post, path: "/api/v1/children/\(childId)/tasks",
              body: CreateTaskRequest(name: name, description: description,
                                     subject: subject, defaultMinutes: defaultMinutes,
                                     daysMask: daysMask, startDate: startDate, endDate: endDate))
    }
    static func updateTask(childId: String, taskId: String, name: String,
                           description: String?, subject: String, defaultMinutes: Int,
                           daysMask: Int, isArchived: Bool,
                           startDate: String?, endDate: String?) -> APIEndpoint {
        .init(method: .put, path: "/api/v1/children/\(childId)/tasks/\(taskId)",
              body: UpdateTaskRequest(name: name, description: description,
                                     subject: subject, defaultMinutes: defaultMinutes,
                                     daysMask: daysMask, isArchived: isArchived,
                                     startDate: startDate, endDate: endDate))
    }
    static func reorderTasks(childId: String,
                             orders: [(taskId: String, sortOrder: Int)]) -> APIEndpoint {
        .init(method: .put, path: "/api/v1/children/\(childId)/tasks/reorder",
              body: ReorderRequest(orders: orders.map {
                  ReorderItem(taskId: $0.taskId, sortOrder: $0.sortOrder)
              }))
    }
    static func archiveTask(taskId: String) -> APIEndpoint {
        .init(method: .patch, path: "/api/v1/tasks/\(taskId)",
              body: ArchiveTaskRequest(isArchived: true))
    }
}

// MARK: - Daily

public extension APIEndpoint {
    static func dailyView(childId: String, date: String) -> APIEndpoint {
        .init(method: .get, path: "/api/v1/children/\(childId)/daily-view",
              queryItems: [.init(name: "date", value: date)])
    }
    static func updateDaily(childId: String, date: String,
                            items: [(taskId: String, minutes: Int)]) -> APIEndpoint {
        .init(method: .put, path: "/api/v1/children/\(childId)/daily",
              queryItems: [.init(name: "date", value: date)],
              body: UpdateDailyRequest(items: items.map {
                  DailyItemRequest(taskId: $0.taskId, minutes: $0.minutes)
              }))
    }
}

// MARK: - Summary

public extension APIEndpoint {
    static func calendarSummary(childId: String, from: String, to: String) -> APIEndpoint {
        .init(method: .get,
              path: "/api/v1/children/\(childId)/calendar-summary",
              queryItems: [.init(name: "from", value: from),
                           .init(name: "to", value: to)])
    }
    static func summary(childId: String, from: String, to: String) -> APIEndpoint {
        .init(method: .get,
              path: "/api/v1/children/\(childId)/summary",
              queryItems: [.init(name: "from", value: from),
                           .init(name: "to", value: to)])
    }
}
