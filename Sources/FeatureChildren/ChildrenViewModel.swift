import Observation
import CoreModel
import CoreCommon
import CoreDomain

@Observable
public final class ChildrenViewModel {
    // MARK: - 一覧
    public var children: [Child] = []
    public var isLoading: Bool = false
    public var isLoadError: Bool = false

    // MARK: - 追加・編集ダイアログ
    public var showAddDialog: Bool = false
    public var editingChild: Child? = nil
    public var dialogName: String = ""
    public var dialogGrade: String = ""
    public var isSaving: Bool = false

    // MARK: - エラー（Snackbar相当）
    public var errorMessage: String? = nil

    // MARK: - ログアウト確認
    public var showLogoutConfirm: Bool = false

    // MARK: - アカウント削除確認
    public var showDeleteAccountConfirm: Bool = false
    public var deleteAccountError: Bool = false

    // MARK: - UseCases
    private let getChildrenUseCase: GetChildrenUseCase
    private let createChildUseCase: CreateChildUseCase
    private let updateChildUseCase: UpdateChildUseCase
    private let deleteChildUseCase: DeleteChildUseCase
    private let logoutUseCase: LogoutUseCase
    private let deleteAccountUseCase: DeleteAccountUseCase

    public init(
        getChildrenUseCase: GetChildrenUseCase,
        createChildUseCase: CreateChildUseCase,
        updateChildUseCase: UpdateChildUseCase,
        deleteChildUseCase: DeleteChildUseCase,
        logoutUseCase: LogoutUseCase,
        deleteAccountUseCase: DeleteAccountUseCase
    ) {
        self.getChildrenUseCase = getChildrenUseCase
        self.createChildUseCase = createChildUseCase
        self.updateChildUseCase = updateChildUseCase
        self.deleteChildUseCase = deleteChildUseCase
        self.logoutUseCase = logoutUseCase
        self.deleteAccountUseCase = deleteAccountUseCase
    }

    // MARK: - 一覧取得

    @MainActor
    public func loadChildren() {
        Swift.Task {
            isLoading = true
            isLoadError = false
            do {
                children = try await getChildrenUseCase.execute()
            } catch {
                isLoadError = true
                errorMessage = makeErrorMessage(from: error)
            }
            isLoading = false
        }
    }

    // MARK: - ダイアログ操作

    public func onShowAddDialog() {
        dialogName = ""
        dialogGrade = ""
        showAddDialog = true
    }

    public func onShowEditDialog(_ child: Child) {
        dialogName = child.name
        dialogGrade = child.grade ?? ""
        editingChild = child
    }

    public func onDismissDialog() {
        showAddDialog = false
        editingChild = nil
        dialogName = ""
        dialogGrade = ""
    }

    public func onDialogNameChange(_ value: String) {
        dialogName = value
    }

    public func onDialogGradeChange(_ value: String) {
        dialogGrade = value
    }

    @MainActor
    public func onSaveChild() {
        let name = dialogName
        let grade = dialogGrade.isEmpty ? nil : dialogGrade
        Swift.Task {
            isSaving = true
            do {
                if let child = editingChild {
                    let updated = try await updateChildUseCase.execute(childId: child.id, name: name, grade: grade)
                    if let index = children.firstIndex(where: { $0.id == updated.id }) {
                        children[index] = updated
                    }
                } else {
                    let created = try await createChildUseCase.execute(name: name, grade: grade)
                    children.append(created)
                }
                onDismissDialog()
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
            isSaving = false
        }
    }

    @MainActor
    public func onDeleteChild(_ child: Child) {
        Swift.Task {
            do {
                try await deleteChildUseCase.execute(childId: child.id)
                children.removeAll { $0.id == child.id }
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
        }
    }

    // MARK: - ログアウト

    public func onShowLogoutConfirm() {
        showLogoutConfirm = true
    }

    public func onDismissLogoutConfirm() {
        showLogoutConfirm = false
    }

    public func onLogout(onLoggedOut: @escaping () -> Void) {
        logoutUseCase.execute()
        onLoggedOut()
    }

    // MARK: - アカウント削除

    public func onShowDeleteAccountConfirm() {
        showDeleteAccountConfirm = true
    }

    public func onDismissDeleteAccountConfirm() {
        showDeleteAccountConfirm = false
    }

    @MainActor
    public func onDeleteAccount(onLoggedOut: @escaping () -> Void) {
        Swift.Task {
            do {
                try await deleteAccountUseCase.execute()
                onLoggedOut()
            } catch {
                showDeleteAccountConfirm = false
                deleteAccountError = true
            }
        }
    }

    public func onDismissDeleteAccountError() {
        deleteAccountError = false
    }

    public func onErrorDismiss() {
        errorMessage = nil
    }

    // MARK: - Private

    private func makeErrorMessage(from error: Error) -> String {
        (error as? APIError)?.errorDescription
            ?? "エラーが発生しました。時間をおいて再度お試しください。"
    }
}
