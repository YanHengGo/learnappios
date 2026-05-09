import Foundation

public enum APIError: Error, LocalizedError, Equatable {
    case httpError(statusCode: Int)
    case decodingError
    case networkError
    case unauthorized       // 401: AppNavigator.root = .auth へリセット
    case unknown

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "セッションが切れました。再度ログインしてください。"
        case .httpError(let code) where code >= 500:
            return "サーバーエラーが発生しました。しばらくしてからお試しください。"
        case .httpError:
            return "リクエストに失敗しました。"
        case .networkError:
            return "ネットワークに接続できません。接続を確認してください。"
        case .decodingError:
            return "データの読み込みに失敗しました。"
        case .unknown:
            return "不明なエラーが発生しました。"
        }
    }
}
