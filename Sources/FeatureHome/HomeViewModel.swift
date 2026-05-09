import Observation
import CoreModel
import CoreCommon
import CoreDomain

@Observable
public final class HomeViewModel {
    public var children: [Child] = []
    public var selectedChildName: String = ""
    public var showSwitcher: Bool = false
    public var showLogoutConfirm: Bool = false
    public var errorMessage: String? = nil

    private let childId: String
    private let getChildrenUseCase: GetChildrenUseCase
    private let logoutUseCase: LogoutUseCase

    public init(
        childId: String,
        getChildrenUseCase: GetChildrenUseCase,
        logoutUseCase: LogoutUseCase
    ) {
        self.childId = childId
        self.getChildrenUseCase = getChildrenUseCase
        self.logoutUseCase = logoutUseCase
    }

    @MainActor
    public func loadChildren() {
        Swift.Task {
            do {
                let result = try await getChildrenUseCase.execute()
                children = result
                selectedChildName = result.first(where: { $0.id == childId })?.name ?? ""
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
        }
    }

    public func onShowSwitcher() { showSwitcher = true }
    public func onDismissSwitcher() { showSwitcher = false }
    public func onShowLogoutConfirm() { showLogoutConfirm = true }
    public func onDismissLogoutConfirm() { showLogoutConfirm = false }

    public func onLogout(onLoggedOut: () -> Void) {
        logoutUseCase.execute()
        onLoggedOut()
    }

    public func onErrorDismiss() { errorMessage = nil }

    private func makeErrorMessage(from error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.localizedDescription
        }
        return "データの取得に失敗しました。"
    }
}
