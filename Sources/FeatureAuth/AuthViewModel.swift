import CoreDomain
import CoreCommon
import Observation

public enum AuthMode {
    case login
    case signup
}

@Observable
public final class AuthViewModel {
    public var email: String = ""
    public var password: String = ""
    public var mode: AuthMode = .login
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    public var isSuccess: Bool = false

    private let loginUseCase: LoginUseCase
    private let signupUseCase: SignupUseCase

    public init(loginUseCase: LoginUseCase, signupUseCase: SignupUseCase) {
        self.loginUseCase = loginUseCase
        self.signupUseCase = signupUseCase
    }

    public func onEmailChange(_ value: String) {
        email = value
        errorMessage = nil
    }

    public func onPasswordChange(_ value: String) {
        password = value
        errorMessage = nil
    }

    public func onModeToggle() {
        mode = (mode == .login) ? .signup : .login
        errorMessage = nil
    }

    @MainActor
    public func onSubmit() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            switch mode {
            case .login:
                try await loginUseCase.execute(email: trimmedEmail, password: password)
            case .signup:
                try await signupUseCase.execute(email: trimmedEmail, password: password)
            }
            isLoading = false
            isSuccess = true
        } catch let error as APIError {
            isLoading = false
            errorMessage = authErrorMessage(for: error)
        } catch {
            isLoading = false
            errorMessage = "エラーが発生しました。もう一度お試しください"
        }
    }

    // MARK: - Private

    private func authErrorMessage(for error: APIError) -> String {
        switch error {
        case .networkError:
            return "ネットワークに接続できません。接続を確認してください。"
        case .unauthorized:
            return "メールアドレスまたはパスワードが正しくありません"
        case .httpError(let code) where code == 409:
            return "このメールアドレスは既に登録されています"
        default:
            return "エラーが発生しました。もう一度お試しください"
        }
    }
}
