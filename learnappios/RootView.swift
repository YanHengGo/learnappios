import SwiftUI
import CoreDataStore
import FeatureSplash
import FeatureAuth
import FeatureChildren
import FeatureHome

struct RootView: View {
    let navigator: AppNavigator
    let deps: AppDependencies
    @State private var showPrivacyPolicyFromChildren = false

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
                ChildrenView(
                    viewModel: ChildrenViewModel(
                        getChildrenUseCase: deps.getChildrenUseCase,
                        createChildUseCase: deps.createChildUseCase,
                        updateChildUseCase: deps.updateChildUseCase,
                        deleteChildUseCase: deps.deleteChildUseCase,
                        logoutUseCase: deps.logoutUseCase,
                        deleteAccountUseCase: deps.deleteAccountUseCase
                    ),
                    onChildSelected: { childId in navigator.root = .home(childId: childId) },
                    onLoggedOut: { navigator.root = .auth },
                    onPrivacyPolicy: { showPrivacyPolicyFromChildren = true }
                )
                .sheet(isPresented: $showPrivacyPolicyFromChildren) {
                    PrivacyPolicyView()
                }

            case .home(let childId):
                HomeView(
                    childId: childId,
                    getDailyViewUseCase: deps.getDailyViewUseCase,
                    updateDailyLogUseCase: deps.updateDailyLogUseCase
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: navigator.root)
    }
}
