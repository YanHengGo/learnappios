import SwiftUI
import CoreModel
import CoreCommon
import CoreDomain
import CoreUI
import FeatureDaily

public struct SummaryView: View {
    @State private var viewModel: SummaryViewModel
    @State private var selectedDate: String? = nil

    let getDailyViewUseCase: GetDailyViewUseCase
    let updateDailyLogUseCase: UpdateDailyLogUseCase

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    public init(
        viewModel: SummaryViewModel,
        getDailyViewUseCase: GetDailyViewUseCase,
        updateDailyLogUseCase: UpdateDailyLogUseCase
    ) {
        _viewModel = State(initialValue: viewModel)
        self.getDailyViewUseCase = getDailyViewUseCase
        self.updateDailyLogUseCase = updateDailyLogUseCase
    }

    public var body: some View {
        ZStack {
            Color.clear

            if viewModel.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        MonthNavigationBar(
                            yearMonth: viewModel.yearMonth,
                            onPrevious: { viewModel.onPreviousMonth() },
                            onNext: { viewModel.onNextMonth() }
                        )

                        CalendarGrid(
                            yearMonth: viewModel.yearMonth,
                            dayMap: Dictionary(
                                uniqueKeysWithValues: (viewModel.calendarSummary?.days ?? [])
                                    .map { ($0.date, $0) }
                            ),
                            onDayTap: { selectedDate = $0 }
                        )

                        LegendRow()

                        if let summary = viewModel.summary {
                            Divider()
                                .padding(.vertical, 8)
                            SummaryStats(summary: summary)
                                .padding(.bottom, 24)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            summaryErrorToast
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        .navigationTitle("集計")
        .navigationDestination(item: $selectedDate) { dateStr in
            DailyView(
                viewModel: DailyViewModel(
                    childId: viewModel.childId,
                    initialDate: Self.dateFormatter.date(from: dateStr) ?? .now,
                    getDailyViewUseCase: getDailyViewUseCase,
                    updateDailyLogUseCase: updateDailyLogUseCase
                )
            )
        }
        .task {
            viewModel.loadMonth()
        }
    }

    @ViewBuilder
    private var summaryErrorToast: some View {
        if let message = viewModel.errorMessage {
            SummaryToastView(message: message, onDismiss: viewModel.onErrorDismiss)
        }
    }
}

private struct SummaryToastView: View {
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
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onTapGesture { onDismiss() }
            .task {
                try? await Swift.Task.sleep(for: .seconds(3))
                onDismiss()
            }
    }
}
