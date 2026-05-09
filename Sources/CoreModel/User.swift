public struct User: Equatable {
    public let id: String
    public let email: String
    public let displayName: String?
    public let avatarUrl: String?
    public let provider: String

    public init(
        id: String,
        email: String,
        displayName: String?,
        avatarUrl: String?,
        provider: String
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.provider = provider
    }
}
