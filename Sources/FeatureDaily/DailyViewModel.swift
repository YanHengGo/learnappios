import Observation
import Foundation
import CoreModel
import CoreCommon
import CoreDomain

public struct DailyTaskRow: Identifiable, Equatable {
    public var id: String { taskId }
    public let taskId: String
    public let name: String
    public let subject: String
    public let defaultMinutes: Int
    public var isDone: Bool
    public var minutes: String
}

@Observable
public final class DailyViewModel {
    public var date: String = ""
    public var weekday: String = ""
    public var taskRows: [DailyTaskRow] = []
    public var isLoading: Bool = false
    public var isSaving: Bool = false
    public var errorMessage: String? = nil
    public var saveSuccess: Bool = false

    private var currentDate: Date
    private let childId: String
    private let getDailyViewUseCase: GetDailyViewUseCase
    private let updateDailyLogUseCase: UpdateDailyLogUseCase

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    public init(
        childId: String,
        initialDate: Date = .now,
        getDailyViewUseCase: GetDailyViewUseCase,
        updateDailyLogUseCase: UpdateDailyLogUseCase
    ) {
        self.childId = childId
        self.currentDate = initialDate
        self.getDailyViewUseCase = getDailyViewUseCase
        self.updateDailyLogUseCase = updateDailyLogUseCase
    }

    // MARK: - 読み込み

    @MainActor
    public func loadDailyView() {
        let dateStr = Self.dateFormatter.string(from: currentDate)
        Swift.Task {
            isLoading = true
            errorMessage = nil
            saveSuccess = false
            do {
                let view = try await getDailyViewUseCase.execute(childId: childId, date: dateStr)
                date = view.date
                weekday = view.weekday
                taskRows = view.tasks.map { task in
                    DailyTaskRow(
                        taskId: task.taskId,
                        name: task.name,
                        subject: task.subject,
                        defaultMinutes: task.defaultMinutes,
                        isDone: task.isDone,
                        minutes: (task.isDone && task.minutes > 0)
                            ? String(task.minutes)
                            : String(task.defaultMinutes)
                    )
                }
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
            isLoading = false
        }
    }

    // MARK: - 日付ナビゲーション

    @MainActor
    public func onPreviousDate() {
        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        loadDailyView()
    }

    @MainActor
    public func onNextDate() {
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        loadDailyView()
    }

    // MARK: - タスク行操作

    public func onToggleDone(taskId: String) {
        guard let index = taskRows.firstIndex(where: { $0.taskId == taskId }) else { return }
        let nowDone = !taskRows[index].isDone
        taskRows[index].isDone = nowDone
        taskRows[index].minutes = nowDone
            ? String(taskRows[index].defaultMinutes)
            : "0"
    }

    public func onMinutesChange(taskId: String, value: String) {
        guard let index = taskRows.firstIndex(where: { $0.taskId == taskId }) else { return }
        taskRows[index].minutes = value
    }

    // MARK: - 保存

    @MainActor
    public func onSave() {
        let items: [DailyItem] = taskRows
            .filter { $0.isDone }
            .map { row in
                let mins = Int(row.minutes).flatMap { $0 > 0 ? $0 : nil } ?? row.defaultMinutes
                return DailyItem(taskId: row.taskId, minutes: mins)
            }
        let dateStr = Self.dateFormatter.string(from: currentDate)
        Swift.Task {
            isSaving = true
            do {
                _ = try await updateDailyLogUseCase.execute(
                    childId: childId, date: dateStr, items: items
                )
                saveSuccess = true
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
            isSaving = false
        }
    }

    // MARK: - Dismiss

    public func onErrorDismiss() {
        errorMessage = nil
    }

    public func onSaveSuccessDismiss() {
        saveSuccess = false
    }

    // MARK: - Private

    private func makeErrorMessage(from error: Error) -> String {
        (error as? APIError)?.errorDescription
            ?? "エラーが発生しました。時間をおいて再度お試しください。"
    }
}
