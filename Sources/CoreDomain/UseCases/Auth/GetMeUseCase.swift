import CoreModel

public struct GetMeUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    public func execute() async throws -> User {
        try await repository.getMe()
    }
}
