import SwiftUI
import CoreUI

public struct AuthView: View {
    @State private var viewModel: AuthViewModel
    @State private var showPrivacyPolicy = false
    let onAuthSuccess: () -> Void

    public init(viewModel: AuthViewModel, onAuthSuccess: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onAuthSuccess = onAuthSuccess
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                AuthContent(viewModel: viewModel, showPrivacyPolicy: $showPrivacyPolicy)
                    .padding(.horizontal, 32)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationDestination(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .onChange(of: viewModel.isSuccess) { _, success in
            if success { onAuthSuccess() }
        }
    }
}

// MARK: - AuthContent

private struct AuthContent: View {
    @Bindable var viewModel: AuthViewModel
    @Binding var showPrivacyPolicy: Bool
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    init(viewModel: AuthViewModel, showPrivacyPolicy: Binding<Bool>) {
        self.viewModel = viewModel
        self._showPrivacyPolicy = showPrivacyPolicy
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Text("学習管理アプリ")
                .font(.appHeadline)

            Spacer().frame(height: 8)

            Text(viewModel.mode == .login ? "ログイン" : "新規登録")
                .font(.appTitle)
                .foregroundStyle(Color.appSecondaryText)

            Spacer().frame(height: 40)

            // メールアドレス
            AuthTextField(
                label: "メールアドレス",
                text: $viewModel.email,
                isEnabled: !viewModel.isLoading,
                onSubmit: { focusedField = .password }
            )
            .focused($focusedField, equals: .email)

            Spacer().frame(height: 16)

            // パスワード
            AuthTextField(
                label: "パスワード",
                text: $viewModel.password,
                isPassword: true,
                isEnabled: !viewModel.isLoading,
                onSubmit: {
                    focusedField = nil
                    Task { await viewModel.onSubmit() }
                }
            )
            .focused($focusedField, equals: .password)

            Spacer().frame(height: 8)

            // エラーメッセージ
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.appCaption)
                    .foregroundStyle(Color.appError)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer().frame(height: 8)
            }

            Spacer().frame(height: 8)

            // 送信ボタン
            Button {
                focusedField = nil
                Task { await viewModel.onSubmit() }
            } label: {
                Text(viewModel.mode == .login ? "ログイン" : "新規登録")
                    .font(.appTitle)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            Spacer().frame(height: 16)

            // モード切り替え
            Button {
                viewModel.onModeToggle()
            } label: {
                Text(viewModel.mode == .login
                     ? "アカウントをお持ちでない方はこちら"
                     : "すでにアカウントをお持ちの方はこちら")
            }
            .disabled(viewModel.isLoading)

            // プライバシーポリシー（新規登録モードのみ）
            if viewModel.mode == .signup {
                Button {
                    showPrivacyPolicy = true
                } label: {
                    Text("プライバシーポリシーを確認する")
                        .font(.appCaption)
                        .foregroundStyle(Color.appSecondaryText)
                }
            }

            Spacer().frame(height: 40)
        }
    }
}
