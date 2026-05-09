// Android: LoginRequest, SignupRequest

struct LoginRequest: Encodable {
    let email: String
    let password: String
}
struct SignupRequest: Encodable {
    let email: String
    let password: String
}
