import SwiftUI
import CoreDomain
import FeatureDaily
import FeatureTasks
import FeatureSummary

public struct HomeView: View {
    let childId: String
    // Daily
    let getDailyViewUseCase: GetDailyViewUseCase
    let updateDailyLogUseCase: UpdateDailyLogUseCase
    // Tasks
    let getTasksUseCase: GetTasksUseCase
    let createTaskUseCase: CreateTaskUseCase
    let updateTaskUseCase: UpdateTaskUseCase
    let archiveTaskUseCase: ArchiveTaskUseCase
    let reorderTasksUseCase: ReorderTasksUseCase
    // Summary
    let getCalendarSummaryUseCase: GetCalendarSummaryUseCase
    let getSummaryUseCase: GetSummaryUseCase
    // Home
    let getChildrenUseCase: GetChildrenUseCase
    let logoutUseCase: LogoutUseCase
    let onChildSwitch: (String) -> Void
    let onManageChildren: () -> Void
    let onLoggedOut: () -> Void
    let onPrivacyPolicy: () -> Void

    @State private var homeViewModel: HomeViewModel

    public init(
        childId: String,
        getDailyViewUseCase: GetDailyViewUseCase,
        updateDailyLogUseCase: UpdateDailyLogUseCase,
        getTasksUseCase: GetTasksUseCase,
        createTaskUseCase: CreateTaskUseCase,
        updateTaskUseCase: UpdateTaskUseCase,
        archiveTaskUseCase: ArchiveTaskUseCase,
        reorderTasksUseCase: ReorderTasksUseCase,
        getCalendarSummaryUseCase: GetCalendarSummaryUseCase,
        getSummaryUseCase: GetSummaryUseCase,
        getChildrenUseCase: GetChildrenUseCase,
        logoutUseCase: LogoutUseCase,
        onChildSwitch: @escaping (String) -> Void,
        onManageChildren: @escaping () -> Void,
        onLoggedOut: @escaping () -> Void,
        onPrivacyPolicy: @escaping () -> Void
    ) {
        self.childId = childId
        self.getDailyViewUseCase = getDailyViewUseCase
        self.updateDailyLogUseCase = updateDailyLogUseCase
        self.getTasksUseCase = getTasksUseCase
        self.createTaskUseCase = createTaskUseCase
        self.updateTaskUseCase = updateTaskUseCase
        self.archiveTaskUseCase = archiveTaskUseCase
        self.reorderTasksUseCase = reorderTasksUseCase
        self.getCalendarSummaryUseCase = getCalendarSummaryUseCase
        self.getSummaryUseCase = getSummaryUseCase
        self.getChildrenUseCase = getChildrenUseCase
        self.logoutUseCase = logoutUseCase
        self.onChildSwitch = onChildSwitch
        self.onManageChildren = onManageChildren
        self.onLoggedOut = onLoggedOut
        self.onPrivacyPolicy = onPrivacyPolicy
        _homeViewModel = State(initialValue: HomeViewModel(
            childId: childId,
            getChildrenUseCase: getChildrenUseCase,
            logoutUseCase: logoutUseCase
        ))
    }

    public var body: some View {
        let homeToolbar = HomeToolbar(
            childName: homeViewModel.selectedChildName,
            onSwitchChild: { homeViewModel.onShowSwitcher() },
            onLogout: { homeViewModel.onShowLogoutConfirm() },
            onPrivacyPolicy: onPrivacyPolicy
        )

        TabView {
            NavigationStack {
                DailyView(
                    viewModel: DailyViewModel(
                        childId: childId,
                        getDailyViewUseCase: getDailyViewUseCase,
                        updateDailyLogUseCase: updateDailyLogUseCase
                    )
                )
                .modifier(homeToolbar)
            }
            .tabItem {
                Label("日々の記録", systemImage: "calendar")
            }

            NavigationStack {
                TasksView(
                    viewModel: TasksViewModel(
                        childId: childId,
                        getTasksUseCase: getTasksUseCase,
                        createTaskUseCase: createTaskUseCase,
                        updateTaskUseCase: updateTaskUseCase,
                        archiveTaskUseCase: archiveTaskUseCase,
                        reorderTasksUseCase: reorderTasksUseCase
                    )
                )
                .modifier(homeToolbar)
            }
            .tabItem {
                Label("タスク", systemImage: "checkmark.circle")
            }

            NavigationStack {
                SummaryView(
                    viewModel: SummaryViewModel(
                        childId: childId,
                        getCalendarSummaryUseCase: getCalendarSummaryUseCase,
                        getSummaryUseCase: getSummaryUseCase
                    ),
                    getDailyViewUseCase: getDailyViewUseCase,
                    updateDailyLogUseCase: updateDailyLogUseCase
                )
                .modifier(homeToolbar)
            }
            .tabItem {
                Label("集計", systemImage: "chart.bar")
            }
        }
        .task { homeViewModel.loadChildren() }
        .confirmationDialog(
            "子どもを切り替え",
            isPresented: $homeViewModel.showSwitcher,
            titleVisibility: .visible
        ) {
            ForEach(homeViewModel.children) { child in
                Button(child.id == childId ? "✓ \(child.name)" : child.name) {
                    if child.id != childId {
                        onChildSwitch(child.id)
                    }
                }
            }
            Button("子どもを管理する") { onManageChildren() }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("ログアウト", isPresented: $homeViewModel.showLogoutConfirm) {
            Button("キャンセル", role: .cancel) { homeViewModel.onDismissLogoutConfirm() }
            Button("ログアウト") { homeViewModel.onLogout(onLoggedOut: onLoggedOut) }
        } message: {
            Text("ログアウトしますか？")
        }
        .overlay(alignment: .bottom) {
            homeErrorToast
        }
        .animation(.easeInOut(duration: 0.3), value: homeViewModel.errorMessage)
    }

    @ViewBuilder
    private var homeErrorToast: some View {
        if let message = homeViewModel.errorMessage {
            HomeToastView(message: message, onDismiss: homeViewModel.onErrorDismiss)
        }
    }
}

private struct HomeToolbar: ViewModifier {
    let childName: String
    let onSwitchChild: () -> Void
    let onLogout: () -> Void
    let onPrivacyPolicy: () -> Void

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onSwitchChild) {
                    HStack(spacing: 4) {
                        Text(childName.isEmpty ? "…" : childName)
                        Image(systemName: "chevron.down")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onLogout) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("プライバシーポリシー", action: onPrivacyPolicy)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

private struct HomeToastView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onTapGesture { onDismiss() }
            .task {
                try? await Swift.Task.sleep(for: .seconds(3))
                onDismiss()
            }
    }
}
