import CoreModel

// Android: TokenDto, SignupDto, MeDto / UserDto

public struct TokenDTO: Decodable {
    public let token: String
}

// signup は token を返さず user を返す（Android 実態）
public struct SignupDTO: Decodable {
    public let user: SignupUserDTO
}
public struct SignupUserDTO: Decodable {
    public let id: String
    public let email: String
}

public struct MeDTO: Decodable {
    public let user: UserDTO
}
public struct UserDTO: Decodable {
    public let id: String
    public let email: String
    public let displayName: String?
    public let avatarUrl: String?
    public let provider: String
}

extension UserDTO {
    public func toModel() -> User {
        User(id: id, email: email, displayName: displayName,
             avatarUrl: avatarUrl, provider: provider)
    }
}
