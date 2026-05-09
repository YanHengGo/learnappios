public struct LogoutUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    public func execute() { repository.logout() }
}
