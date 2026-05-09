import CoreModel

// Android: ChildDto

public struct ChildDTO: Decodable {
    public let id: String
    public let name: String
    public let grade: String?
    public let isActive: Bool
}

extension ChildDTO {
    public func toModel() -> Child {
        Child(id: id, name: name, grade: grade, isActive: isActive)
    }
}
