import SwiftUI
import CoreDataStore
import FeatureSplash
import FeatureAuth

struct RootView: View {
    let navigator: AppNavigator
    let deps: AppDependencies

    var body: some View {
        Group {
            switch navigator.root {
            case .splash:
                SplashView(
                    viewModel: SplashViewModel(hasToken: { deps.keychain.load() != nil }),
                    onNavigateToAuth: { navigator.root = .auth },
                    onNavigateToChildren: { navigator.root = .children }
                )

            case .auth:
                AuthView(
                    viewModel: AuthViewModel(
                        loginUseCase: deps.loginUseCase,
                        signupUseCase: deps.signupUseCase
                    ),
                    onAuthSuccess: { navigator.root = .children }
                )

            case .children:
                // Phase 3 で実装
                Text("子ども選択画面（Phase 3）")

            case .home(let childId):
                // Phase 4 以降で実装
                Text("ホーム: \(childId)（Phase 4）")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: navigator.root)
    }
}
