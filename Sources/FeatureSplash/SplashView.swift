import SwiftUI
import CoreUI

public struct SplashView: View {
    @State private var viewModel: SplashViewModel
    let onNavigateToAuth: () -> Void
    let onNavigateToChildren: () -> Void

    public init(
        viewModel: SplashViewModel,
        onNavigateToAuth: @escaping () -> Void,
        onNavigateToChildren: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigateToAuth = onNavigateToAuth
        self.onNavigateToChildren = onNavigateToChildren
    }

    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("学習管理アプリ")
                    .font(.appHeadline)
                ProgressView()
            }
        }
        .task {
            viewModel.checkToken()
        }
        .onChange(of: viewModel.destination) { _, destination in
            switch destination {
            case .auth:      onNavigateToAuth()
            case .children:  onNavigateToChildren()
            case nil:        break
            }
        }
    }
}
