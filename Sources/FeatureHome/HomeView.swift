import SwiftUI
import CoreDomain
import FeatureDaily

public struct HomeView: View {
    let childId: String
    let getDailyViewUseCase: GetDailyViewUseCase
    let updateDailyLogUseCase: UpdateDailyLogUseCase

    public init(
        childId: String,
        getDailyViewUseCase: GetDailyViewUseCase,
        updateDailyLogUseCase: UpdateDailyLogUseCase
    ) {
        self.childId = childId
        self.getDailyViewUseCase = getDailyViewUseCase
        self.updateDailyLogUseCase = updateDailyLogUseCase
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
                Text("タスク管理（Phase 5）")
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
