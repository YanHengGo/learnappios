public struct LoginUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    public func execute(email: String, password: String) async throws {
        try await repository.login(email: email, password: password)
    }
}
