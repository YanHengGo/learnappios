import Observation

@Observable
final class AppNavigator {
    enum Root: Equatable {
        case splash
        case auth
        case children
        case home(childId: String)
    }

    var root: Root = .splash
}
