public struct DeleteAccountUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    public func execute() async throws {
        try await repository.deleteAccount()
    }
}
