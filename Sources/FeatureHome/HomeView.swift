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
        getSummaryUseCase: GetSummaryUseCase
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
                SummaryView(
                    viewModel: SummaryViewModel(
                        childId: childId,
                        getCalendarSummaryUseCase: getCalendarSummaryUseCase,
                        getSummaryUseCase: getSummaryUseCase
                    ),
                    getDailyViewUseCase: getDailyViewUseCase,
                    updateDailyLogUseCase: updateDailyLogUseCase
                )
            }
            .tabItem {
                Label("集計", systemImage: "chart.bar")
            }
        }
    }
}
