import SwiftUI
import CoreDomain
import FeatureDaily
import FeatureTasks

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

    public init(
        childId: String,
        getDailyViewUseCase: GetDailyViewUseCase,
        updateDailyLogUseCase: UpdateDailyLogUseCase,
        getTasksUseCase: GetTasksUseCase,
        createTaskUseCase: CreateTaskUseCase,
        updateTaskUseCase: UpdateTaskUseCase,
        archiveTaskUseCase: ArchiveTaskUseCase,
        reorderTasksUseCase: ReorderTasksUseCase
    ) {
        self.childId = childId
        self.getDailyViewUseCase = getDailyViewUseCase
        self.updateDailyLogUseCase = updateDailyLogUseCase
        self.getTasksUseCase = getTasksUseCase
        self.createTaskUseCase = createTaskUseCase
        self.updateTaskUseCase = updateTaskUseCase
        self.archiveTaskUseCase = archiveTaskUseCase
        self.reorderTasksUseCase = reorderTasksUseCase
    }

    public var body: some View {
        TabView {
            NavigationStack {
                DailyView(
                    viewModel: DailyViewModel(
                        childId: childId,
                        getDailyViewUseCase: getDailyViewUseCase,
                        updateDailyLogUseCase: updateDailyLogUseCase
                    )
                )
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
            }
            .tabItem {
                Label("タスク", systemImage: "checkmark.circle")
            }

            NavigationStack {
                Text("集計（Phase 6）")
            }
            .tabItem {
                Label("集計", systemImage: "chart.bar")
            }
        }
    }
}
