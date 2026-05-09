import SwiftUI
import CoreModel
import CoreUI

public struct ChildrenView: View {
    @State private var viewModel: ChildrenViewModel
    let onChildSelected: (String) -> Void
    let onLoggedOut: () -> Void
    let onPrivacyPolicy: () -> Void

    @State private var menuExpanded = false

    public init(
        viewModel: ChildrenViewModel,
        onChildSelected: @escaping (String) -> Void,
        onLoggedOut: @escaping () -> Void,
        onPrivacyPolicy: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onChildSelected = onChildSelected
        self.onLoggedOut = onLoggedOut
        self.onPrivacyPolicy = onPrivacyPolicy
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.clear
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.isLoadError && viewModel.children.isEmpty {
                    VStack(spacing: 16) {
                        Text("データの取得に失敗しました")
                            .font(.appBody)
                            .foregroundStyle(Color.red)
                        Button("再読み込み") {
                            viewModel.loadChildren()
                        }
                    }
                    .padding(32)
                } else if viewModel.children.isEmpty {
                    Text("子どもが登録されていません\n右下のボタンから追加してください")
                        .font(.appBody)
                        .foregroundStyle(Color.appSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(32)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.children) { child in
                                ChildCard(
                                    child: child,
                                    onClick: { onChildSelected(child.id) },
                                    onEdit: { viewModel.onShowEditDialog(child) },
                                    onDelete: { viewModel.onDeleteChild(child) }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("子ども一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.onShowLogoutConfirm()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("プライバシーポリシー") {
                            onPrivacyPolicy()
                        }
                        Button("アカウントを削除", role: .destructive) {
                            viewModel.onShowDeleteAccountConfirm()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .overlay(alignment: .bottom) {
                errorToast
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    viewModel.onShowAddDialog()
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.appPrimary)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(24)
            }
        }
        .task {
            viewModel.loadChildren()
        }
        // MARK: - ダイアログ
        .sheet(isPresented: Binding(
            get: { viewModel.showAddDialog || viewModel.editingChild != nil },
            set: { if !$0 { viewModel.onDismissDialog() } }
        )) {
            ChildDialog(
                title: viewModel.editingChild != nil ? "子どもを編集" : "子どもを追加",
                name: Binding(get: { viewModel.dialogName }, set: { viewModel.onDialogNameChange($0) }),
                grade: Binding(get: { viewModel.dialogGrade }, set: { viewModel.onDialogGradeChange($0) }),
                isSaving: viewModel.isSaving,
                onConfirm: { viewModel.onSaveChild() },
                onDismiss: { viewModel.onDismissDialog() }
            )
        }
        .alert("ログアウト", isPresented: Binding(
            get: { viewModel.showLogoutConfirm },
            set: { if !$0 { viewModel.onDismissLogoutConfirm() } }
        )) {
            Button("キャンセル", role: .cancel) { viewModel.onDismissLogoutConfirm() }
            Button("ログアウト") { viewModel.onLogout(onLoggedOut: onLoggedOut) }
        } message: {
            Text("ログアウトしますか？")
        }
        .alert("アカウントを削除", isPresented: Binding(
            get: { viewModel.showDeleteAccountConfirm },
            set: { if !$0 { viewModel.onDismissDeleteAccountConfirm() } }
        )) {
            Button("キャンセル", role: .cancel) { viewModel.onDismissDeleteAccountConfirm() }
            Button("削除する", role: .destructive) {
                viewModel.onDeleteAccount(onLoggedOut: onLoggedOut)
            }
        } message: {
            Text("アカウントを削除すると、すべてのデータが削除され復元できません。")
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.deleteAccountError },
            set: { if !$0 { viewModel.onDismissDeleteAccountError() } }
        )) {
            Button("閉じる") { viewModel.onDismissDeleteAccountError() }
        } message: {
            Text("削除に失敗しました。時間をおいて再度お試しください。")
        }
    }

    @ViewBuilder
    private var errorToast: some View {
        if let message = viewModel.errorMessage {
            ErrorToastView(message: message, onDismiss: viewModel.onErrorDismiss)
        }
    }
}

private struct ErrorToastView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        Text(message)
            .font(.appCaption)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 80)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onTapGesture { onDismiss() }
            .task {
                try? await Swift.Task.sleep(for: .seconds(3))
                onDismiss()
            }
    }
}
