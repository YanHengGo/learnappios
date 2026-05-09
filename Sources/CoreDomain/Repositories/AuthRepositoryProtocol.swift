import CoreModel

public protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws  // token は内部で保存
    func signup(email: String, password: String) async throws // token なし → login を別途呼ぶ
    func getMe() async throws -> User
    func logout()                                              // 同期（Keychain削除のみ）
    func deleteAccount() async throws
}
