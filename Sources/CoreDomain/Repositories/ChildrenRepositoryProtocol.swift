import CoreModel

public protocol ChildrenRepositoryProtocol {
    func getChildren() async throws -> [Child]
    func createChild(name: String, grade: String?) async throws -> Child
    func updateChild(childId: String, name: String, grade: String?) async throws -> Child
    func deleteChild(childId: String) async throws
}
