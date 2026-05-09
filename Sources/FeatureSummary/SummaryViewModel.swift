import Observation
import CoreModel
import CoreCommon
import CoreDomain

@Observable
public final class SummaryViewModel {
    public var calendarSummary: CalendarSummary? = nil
    public var summary: Summary? = nil
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    public var yearMonth: YearMonth = .now

    public let childId: String
    private let getCalendarSummaryUseCase: GetCalendarSummaryUseCase
    private let getSummaryUseCase: GetSummaryUseCase

    public init(
        childId: String,
        getCalendarSummaryUseCase: GetCalendarSummaryUseCase,
        getSummaryUseCase: GetSummaryUseCase
    ) {
        self.childId = childId
        self.getCalendarSummaryUseCase = getCalendarSummaryUseCase
        self.getSummaryUseCase = getSummaryUseCase
    }

    // MARK: - 月ナビゲーション

    @MainActor
    public func onPreviousMonth() {
        yearMonth = yearMonth.adding(months: -1)
        loadMonth()
    }

    @MainActor
    public func onNextMonth() {
        yearMonth = yearMonth.adding(months: 1)
        loadMonth()
    }

    // MARK: - データ取得

    @MainActor
    public func loadMonth() {
        let from = yearMonth.firstDayString()
        let to   = yearMonth.lastDayString()
        let cid  = childId

        Swift.Task {
            isLoading = true
            errorMessage = nil

            async let calendarResult = getCalendarSummaryUseCase.execute(
                childId: cid, from: from, to: to
            )
            async let summaryResult = getSummaryUseCase.execute(
                childId: cid, from: from, to: to
            )

            let cal = try? await calendarResult
            let sum = try? await summaryResult

            calendarSummary = cal
            summary = sum
            if cal == nil && sum == nil {
                errorMessage = "データの取得に失敗しました。時間をおいて再度お試しください。"
            }
            isLoading = false
        }
    }

    // MARK: - Dismiss

    public func onErrorDismiss() {
        errorMessage = nil
    }
}
