public struct Child: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let grade: String?
    public let isActive: Bool

    public init(id: String, name: String, grade: String?, isActive: Bool) {
        self.id = id
        self.name = name
        self.grade = grade
        self.isActive = isActive
    }
}
