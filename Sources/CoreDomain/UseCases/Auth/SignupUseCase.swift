// signup → login の2ステップ（Android の AuthRepositoryImpl と同じ挙動）
public struct SignupUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    public func execute(email: String, password: String) async throws {
        try await repository.signup(email: email, password: password)
        try await repository.login(email: email, password: password)
    }
}
