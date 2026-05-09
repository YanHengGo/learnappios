import Observation
import CoreModel
import CoreCommon
import CoreDomain

@Observable
public final class TasksViewModel {
    // MARK: - 一覧
    public var tasks: [Task] = []
    public var isLoading: Bool = false

    // MARK: - エラー
    public var errorMessage: String? = nil

    // MARK: - ダイアログ
    public var showDialog: Bool = false
    public var editingTask: Task? = nil
    public var dialogName: String = ""
    public var dialogDescription: String = ""
    public var dialogSubject: String = ""
    public var dialogMinutes: String = "30"
    public var dialogDaysMask: Int = 0b0111110   // 月〜金
    public var dialogStartDate: String = ""
    public var dialogEndDate: String = ""
    public var isSaving: Bool = false

    // MARK: - UseCases
    private let childId: String
    private let getTasksUseCase: GetTasksUseCase
    private let createTaskUseCase: CreateTaskUseCase
    private let updateTaskUseCase: UpdateTaskUseCase
    private let archiveTaskUseCase: ArchiveTaskUseCase
    private let reorderTasksUseCase: ReorderTasksUseCase

    public init(
        childId: String,
        getTasksUseCase: GetTasksUseCase,
        createTaskUseCase: CreateTaskUseCase,
        updateTaskUseCase: UpdateTaskUseCase,
        archiveTaskUseCase: ArchiveTaskUseCase,
        reorderTasksUseCase: ReorderTasksUseCase
    ) {
        self.childId = childId
        self.getTasksUseCase = getTasksUseCase
        self.createTaskUseCase = createTaskUseCase
        self.updateTaskUseCase = updateTaskUseCase
        self.archiveTaskUseCase = archiveTaskUseCase
        self.reorderTasksUseCase = reorderTasksUseCase
    }

    // MARK: - 一覧取得

    @MainActor
    public func loadTasks() {
        Swift.Task {
            isLoading = true
            errorMessage = nil
            do {
                tasks = try await getTasksUseCase.execute(childId: childId)
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
            isLoading = false
        }
    }

    // MARK: - ダイアログ操作

    public func onShowAddDialog() {
        dialogName = ""
        dialogDescription = ""
        dialogSubject = ""
        dialogMinutes = "30"
        dialogDaysMask = 0b0111110
        dialogStartDate = ""
        dialogEndDate = ""
        editingTask = nil
        showDialog = true
    }

    public func onShowEditDialog(_ task: Task) {
        dialogName = task.name
        dialogDescription = task.description ?? ""
        dialogSubject = task.subject
        dialogMinutes = String(task.defaultMinutes)
        dialogDaysMask = task.daysMask
        dialogStartDate = task.startDate ?? ""
        dialogEndDate = task.endDate ?? ""
        editingTask = task
        showDialog = true
    }

    public func onDismissDialog() {
        showDialog = false
        editingTask = nil
    }

    public func onNameChange(_ v: String)        { dialogName = v }
    public func onDescriptionChange(_ v: String) { dialogDescription = v }
    public func onSubjectChange(_ v: String)     { dialogSubject = v }
    public func onMinutesChange(_ v: String)     { dialogMinutes = v }
    public func onStartDateChange(_ v: String)   { dialogStartDate = v }
    public func onEndDateChange(_ v: String)     { dialogEndDate = v }

    public func onDayToggle(_ dayIndex: Int) {
        dialogDaysMask = dialogDaysMask.toggleDayBit(dayIndex)
    }

    // MARK: - 保存

    @MainActor
    public func onSaveTask() {
        let name = dialogName.trimmingCharacters(in: .whitespaces)
        let subject = dialogSubject.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !subject.isEmpty,
              let minutes = Int(dialogMinutes), minutes > 0 else { return }

        let description = dialogDescription.trimmingCharacters(in: .whitespaces)
        let startDate = dialogStartDate.trimmingCharacters(in: .whitespaces)
        let endDate = dialogEndDate.trimmingCharacters(in: .whitespaces)

        let taskData = Task(
            id: editingTask?.id ?? "",
            name: name,
            description: description.isEmpty ? nil : description,
            subject: subject,
            defaultMinutes: minutes,
            daysMask: dialogDaysMask,
            isArchived: false,
            startDate: startDate.isEmpty ? nil : startDate,
            endDate: endDate.isEmpty ? nil : endDate,
            sortOrder: editingTask?.sortOrder ?? 0
        )

        let editing = editingTask
        Swift.Task {
            isSaving = true
            do {
                if let editing {
                    _ = try await updateTaskUseCase.execute(
                        childId: childId, taskId: editing.id, task: taskData
                    )
                } else {
                    _ = try await createTaskUseCase.execute(
                        childId: childId, task: taskData
                    )
                }
                showDialog = false
                editingTask = nil
                loadTasks()
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
            isSaving = false
        }
    }

    // MARK: - アーカイブ

    @MainActor
    public func onArchiveTask(_ task: Task) {
        Swift.Task {
            do {
                try await archiveTaskUseCase.execute(taskId: task.id)
                loadTasks()
            } catch {
                errorMessage = makeErrorMessage(from: error)
            }
        }
    }

    // MARK: - 並び替え

    @MainActor
    public func onMove(from: Int, to: Int) {
        var reordered = tasks
        let moved = reordered.remove(at: from)
        reordered.insert(moved, at: to)
        tasks = reordered

        let orders = reordered.enumerated().map { (taskId: $0.element.id, sortOrder: $0.offset) }
        Swift.Task {
            do {
                try await reorderTasksUseCase.execute(childId: childId, orders: orders)
            } catch {
                loadTasks()
                errorMessage = makeErrorMessage(from: error)
            }
        }
    }

    // MARK: - Dismiss

    public func onErrorDismiss() {
        errorMessage = nil
    }

    // MARK: - Private

    private func makeErrorMessage(from error: Error) -> String {
        (error as? APIError)?.errorDescription
            ?? "エラーが発生しました。時間をおいて再度お試しください。"
    }
}
