# Phase 5: タスク管理

## 概要

タスク一覧の表示・追加・編集・アーカイブ・ドラッグ並び替えを実装する。

**対象モジュール:**
- `CoreData` — `TaskRepositoryImpl`（Phase 1 実装済み。変更不要）
- `FeatureTasks` — `TasksViewModel` + `TasksView`
- `FeatureHome` — `HomeView` の Tasks タブ更新
- `learnappios` (App層) — `AppDependencies` から `HomeView` へ UseCase 追加注入

---

## 1. CoreData（確認のみ）

`Sources/CoreData/TaskRepositoryImpl.swift` は Phase 1 で実装済み。追加作業なし。

```
getTasks(childId:)          → GET    /api/v1/children/{id}/tasks?archived=false → [Task]
createTask(childId:task:)   → POST   /api/v1/children/{id}/tasks               → Task
updateTask(childId:taskId:task:) → PUT /api/v1/children/{id}/tasks/{tid}       → Task
archiveTask(taskId:)        → PATCH  /api/v1/tasks/{taskId}                    → 204
reorderTasks(childId:orders:) → PUT  /api/v1/children/{id}/tasks/reorder       → 204
```

---

## 2. FeatureTasks

### 2-1. TasksViewModel

```
Sources/FeatureTasks/TasksViewModel.swift
```

#### 状態プロパティ

```swift
@Observable
public final class TasksViewModel {
    // 一覧
    public var tasks: [Task] = []
    public var isLoading: Bool = false

    // エラー
    public var errorMessage: String? = nil

    // 追加・編集ダイアログ
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
}
```

#### 依存 UseCase

```swift
private let childId: String
private let getTasksUseCase: GetTasksUseCase
private let createTaskUseCase: CreateTaskUseCase
private let updateTaskUseCase: UpdateTaskUseCase
private let archiveTaskUseCase: ArchiveTaskUseCase
private let reorderTasksUseCase: ReorderTasksUseCase
```

#### メソッド

| メソッド | 説明 |
|---|---|
| `loadTasks()` | isLoading=true → API取得 → tasks更新。失敗時 errorMessage 設定 |
| `onShowAddDialog()` | ダイアログフィールドを初期値にリセット → showDialog=true |
| `onShowEditDialog(_ task: Task)` | task の値でフィールドを設定 → showDialog=true, editingTask=task |
| `onDismissDialog()` | showDialog=false, editingTask=nil |
| `onNameChange(_:)` 等 | ダイアログフィールド更新（各フィールド 1 メソッド） |
| `onDayToggle(_ dayIndex: Int)` | `dialogDaysMask = dialogDaysMask.toggleDayBit(dayIndex)` |
| `onSaveTask()` | バリデーション → 編集: updateTask / 新規: createTask → 成功後 loadTasks |
| `onArchiveTask(_ task: Task)` | archiveTask API → 成功後 loadTasks。失敗時 errorMessage 設定 |
| `onMove(from:to:)` | tasks をローカルで並び替え → reorderTasks API（失敗時 loadTasks で巻き戻し） |
| `onErrorDismiss()` | errorMessage = nil |

#### バリデーション（`onSaveTask`）

```
name.trimmingCharacters(in: .whitespaces).isEmpty → 保存不可
subject.trimmingCharacters(in: .whitespaces).isEmpty → 保存不可
Int(dialogMinutes) == nil || Int(dialogMinutes)! <= 0 → 保存不可
```

#### `onSaveTask` — Task モデル構築

```swift
Task(
    id: editingTask?.id ?? "",
    name: dialogName.trimmingCharacters(in: .whitespaces),
    description: dialogDescription.trimmingCharacters(in: .whitespaces).isEmpty
        ? nil : dialogDescription.trimmingCharacters(in: .whitespaces),
    subject: dialogSubject.trimmingCharacters(in: .whitespaces),
    defaultMinutes: Int(dialogMinutes)!,
    daysMask: dialogDaysMask,
    isArchived: false,
    startDate: dialogStartDate.trimmingCharacters(in: .whitespaces).isEmpty
        ? nil : dialogStartDate.trimmingCharacters(in: .whitespaces),
    endDate: dialogEndDate.trimmingCharacters(in: .whitespaces).isEmpty
        ? nil : dialogEndDate.trimmingCharacters(in: .whitespaces),
    sortOrder: editingTask?.sortOrder ?? 0
)
```

#### `onMove` — 並び替えロジック

```swift
// 1. ローカル即時反映
var reordered = tasks
let moved = reordered.remove(at: from)
reordered.insert(moved, at: to)
tasks = reordered

// 2. API 送信（失敗時は loadTasks で巻き戻し）
let orders = reordered.enumerated().map { (taskId: $0.element.id, sortOrder: $0.offset) }
```

---

### 2-2. TasksView

```
Sources/FeatureTasks/TasksView.swift
Sources/FeatureTasks/Components/TaskCard.swift    （内部コンポーネント）
Sources/FeatureTasks/Components/TaskDialog.swift  （内部コンポーネント）
```

#### TasksView（公開 View）

```swift
public struct TasksView: View {
    @State private var viewModel: TasksViewModel

    public init(viewModel: TasksViewModel)
}
```

#### 画面構成

```
ZStack（Color.clear でフル幅確保）
├── [isLoading]         ProgressView（中央）
├── [tasks.isEmpty]     Text("タスクが登録されていません\n右下のボタンから追加してください")（中央）
└── [else]              List（.onMove で並び替え対応）
                            各行: TaskCard

FAB（右下 overlay） → onShowAddDialog()
エラートースト      → errorMessage が非 nil 時（Phase 3/4 と同パターン）

.navigationTitle("タスク管理")
```

#### ドラッグ並び替え（iOS ネイティブ）

Android は `sh.calvin.reorderable` 外部ライブラリを使用しているが、iOS は `List` + `.onMove` で外部依存なしに実現可能。

```swift
List {
    ForEach(viewModel.tasks) { task in
        TaskCard(...)
    }
    .onMove { indices, newOffset in
        guard let from = indices.first else { return }
        viewModel.onMove(from: from, to: newOffset > from ? newOffset - 1 : newOffset)
    }
}
```

> `.onMove` を実装するだけで iOS が長押しドラッグを自動的に有効化する。`editMode` の固定は不要。

#### TaskCard（内部コンポーネント）

```
HStack
├── VStack（left、weight=1）
│   ├── Text(task.name)                                    // .appTitle, bold
│   ├── Text("\(task.subject)  ・  \(task.defaultMinutes)分  ・  \(daysLabel(task.daysMask))")
│   │                                                       // .appCaption, 補助色
│   └── Text("\(task.startDate ?? "") 〜 \(task.endDate ?? "")")  // 両方 nil なら非表示
├── Button（編集アイコン） → onShowEditDialog(task)
└── Button（アーカイブアイコン） → onArchiveTask(task)
```

`daysLabel(daysMask: Int) -> String`:
```swift
dayLabels.indices.filter { daysMask.hasDayBit($0) }.map { dayLabels[$0] }.joined()
// 例: 0b0111110 → "月火水木金"
```

#### TaskDialog（内部コンポーネント）

`sheet` + `Form` 形式（Phase 3 と同パターン）。

```swift
struct TaskDialog: View {
    // Binding 経由でダイアログフィールドを受け取る
    // または @Bindable var viewModel を利用
}
```

**フォーム構成:**

```
Form
├── Section "基本情報"
│   ├── TextField("タスク名", ...)          必須
│   ├── TextField("教科", ...)              必須
│   ├── TextField("標準時間（分）", ...)     必須、keyboardType: .numberPad
│   └── TextField("メモ（任意）", ...)
├── Section "曜日"
│   └── HStack（日〜土 7ボタン、selected=primaryContainer 色）
└── Section "期間（任意）"
    ├── TextField("開始日 yyyy-MM-dd", ...)
    └── TextField("終了日 yyyy-MM-dd", ...)

Toolbar:
├── キャンセル（leading）
└── 保存（trailing）— バリデーション不通過または isSaving 中は disabled
```

> 曜日ボタンはトグル動作。選択中は `Color.appPrimary` 背景、未選択は border スタイル。

---

## 3. FeatureHome 更新

`HomeView` の Tasks タブスタブを `TasksView` に差し替える。

### 追加する init パラメータ

```swift
let getTasksUseCase: GetTasksUseCase
let createTaskUseCase: CreateTaskUseCase
let updateTaskUseCase: UpdateTaskUseCase
let archiveTaskUseCase: ArchiveTaskUseCase
let reorderTasksUseCase: ReorderTasksUseCase
```

### TabView 変更

```swift
// Before
NavigationStack { Text("タスク管理（Phase 5）") }
    .tabItem { Label("タスク", systemImage: "checkmark.circle") }

// After
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
.tabItem { Label("タスク", systemImage: "checkmark.circle") }
```

---

## 4. App層（RootView / AppDependencies）

`RootView.swift` の `HomeView` 呼び出しに Tasks 系 UseCase を追加注入する。

```swift
case .home(let childId):
    HomeView(
        childId: childId,
        getDailyViewUseCase: deps.getDailyViewUseCase,
        updateDailyLogUseCase: deps.updateDailyLogUseCase,
        getTasksUseCase: deps.getTasksUseCase,
        createTaskUseCase: deps.createTaskUseCase,
        updateTaskUseCase: deps.updateTaskUseCase,
        archiveTaskUseCase: deps.archiveTaskUseCase,
        reorderTasksUseCase: deps.reorderTasksUseCase
    )
```

---

## 5. Package.swift 変更

`FeatureTasks` に `CoreCommon` を追加（`APIError` マッピングのため）：

```swift
.target(name: "FeatureTasks", dependencies: ["CoreDomain", "CoreCommon", "CoreUI"]),
```

---

## 6. 実装順序

1. `TasksViewModel.swift`
2. `Components/TaskCard.swift`
3. `Components/TaskDialog.swift`
4. `TasksView.swift`
5. `Package.swift` — FeatureTasks に CoreCommon 追加
6. `HomeView.swift` — Tasks タブ更新（init 拡張）
7. `RootView.swift` — HomeView に Tasks UseCase 追加注入
8. ビルド確認
