import CoreModel
import CoreDomain
import CoreNetwork

public final class ChildrenRepositoryImpl: ChildrenRepositoryProtocol {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func getChildren() async throws -> [Child] {
        let dtos: [ChildDTO] = try await apiClient.send(.children)
        return dtos.map { $0.toModel() }
    }

    public func createChild(name: String, grade: String?) async throws -> Child {
        let dto: ChildDTO = try await apiClient.send(.createChild(name: name, grade: grade))
        return dto.toModel()
    }

    public func updateChild(childId: String, name: String, grade: String?) async throws -> Child {
        let dto: ChildDTO = try await apiClient.send(.updateChild(id: childId, name: name, grade: grade))
        return dto.toModel()
    }

    public func deleteChild(childId: String) async throws {
        try await apiClient.sendEmpty(.deleteChild(id: childId))
    }
}
