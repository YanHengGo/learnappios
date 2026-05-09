// Android: CreateChildRequest, UpdateChildRequest

struct CreateChildRequest: Encodable {
    let name: String
    let grade: String?
}
struct UpdateChildRequest: Encodable {
    let name: String
    let grade: String?
}
