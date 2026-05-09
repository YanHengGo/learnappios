import Foundation
import CoreCommon

public final class APIClient {
    private let baseURL: URL
    private let tokenProvider: () -> String?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let session: URLSession

    public init(
        baseURL: URL,
        tokenProvider: @escaping () -> String?,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.session = session

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    /// レスポンスボディあり
    public func send<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let req = try buildRequest(endpoint)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError
        }
        try validate(response)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    /// レスポンスボディなし（204 等）
    public func sendEmpty(_ endpoint: APIEndpoint) async throws {
        let req = try buildRequest(endpoint)
        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError
        }
        try validate(response)
    }

    // MARK: - Private

    private func buildRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = endpoint.queryItems

        var req = URLRequest(url: components.url!)
        req.httpMethod = endpoint.method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = tokenProvider() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }
        return req
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }
        switch http.statusCode {
        case 200..<300: return
        case 401:       throw APIError.unauthorized
        default:        throw APIError.httpError(statusCode: http.statusCode)
        }
    }
}

// any Encodable を型消去して JSONEncoder に渡すヘルパー
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: any Encodable) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
