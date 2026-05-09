import CoreModel
import CoreDomain
import CoreNetwork
import CoreDataStore

public final class AuthRepositoryImpl: AuthRepositoryProtocol {
    private let apiClient: APIClient
    private let keychain: KeychainStore

    public init(apiClient: APIClient, keychain: KeychainStore) {
        self.apiClient = apiClient
        self.keychain = keychain
    }

    public func login(email: String, password: String) async throws {
        let dto: TokenDTO = try await apiClient.send(.login(email: email, password: password))
        keychain.save(token: dto.token)
    }

    public func signup(email: String, password: String) async throws {
        let _: SignupDTO = try await apiClient.send(.signup(email: email, password: password))
    }

    public func getMe() async throws -> User {
        let dto: MeDTO = try await apiClient.send(.me)
        return dto.user.toModel()
    }

    public func logout() {
        keychain.delete()
    }

    public func deleteAccount() async throws {
        try await apiClient.sendEmpty(.deleteMe)
        keychain.delete()
    }
}
