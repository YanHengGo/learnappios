import Observation

@Observable
public final class SplashViewModel {
    public enum Destination {
        case auth
        case children
    }

    public var destination: Destination? = nil

    // APIClient の tokenProvider と同パターン：CoreDataStore への直接依存を排除
    private let hasToken: () -> Bool

    public init(hasToken: @escaping () -> Bool) {
        self.hasToken = hasToken
    }

    public func checkToken() {
        destination = hasToken() ? .children : .auth
    }
}
