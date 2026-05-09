# Phase 4: 日々の記録

## 概要

選択した子どもの「日々の記録」画面を実装する。日付ナビゲーション、タスク行（チェック＋分入力）、合計分表示、保存機能を含む。
あわせて Phase 4 で初めて `.home(childId:)` に遷移するため、`FeatureHome`（TabView）も最小実装する。

**対象モジュール:**
- `CoreData` — `DailyRepositoryImpl`（Phase 1 実装済み。変更不要）
- `FeatureDaily` — `DailyViewModel` + `DailyView`
- `FeatureHome` — `HomeView`（TabView、Tasks/Summary は Phase 5/6 スタブ）
- `learnappios` (App層) — `RootView` の `.home` ケース更新

---

## 1. CoreData（確認のみ）

`Sources/CoreData/DailyRepositoryImpl.swift` は Phase 1 で実装済み。追加作業なし。

```
getDailyView(childId:date:)   → GET /api/v1/children/{id}/daily-view?date=yyyy-MM-dd → DailyView
updateDailyLog(childId:date:items:) → PUT /api/v1/children/{id}/daily?date=yyyy-MM-dd → savedCount: Int
```

---

## 2. FeatureDaily

### 2-1. DailyTaskRow（ViewModel 内部型）

`DailyTask`（CoreModel）をそのまま View に渡すのではなく、分入力を `String` で保持する UI 用ラップ型を定義する。

```swift
struct DailyTaskRow: Identifiable, Equatable {
    var id: String { taskId }
    let taskId: String
    let name: String
    let subject: String
    let defaultMinutes: Int
    var isDone: Bool
    var minutes: String   // TextField 用文字列
}
```

### 2-2. DailyViewModel

```
Sources/FeatureDaily/DailyViewModel.swift
```

#### 状態プロパティ

```swift
@Observable
public final class DailyViewModel {
    public var date: String = ""          // "yyyy-MM-dd"（表示用）
    public var weekday: String = ""       // "月曜日" 等（サーバー返却値）
    public var taskRows: [DailyTaskRow] = []
    public var isLoading: Bool = false
    public var isSaving: Bool = false
    public var errorMessage: String? = nil
    public var saveSuccess: Bool = false

    private var currentDate: Date
}
```

#### init

```swift
public init(
    childId: String,
    initialDate: Date = .now,
    getDailyViewUseCase: GetDailyViewUseCase,
    updateDailyLogUseCase: UpdateDailyLogUseCase
)
```

- `initialDate` は通常 `.now`（Home タブ）。FeatureSummary からの日付指定（Phase 6）にも対応。

#### メソッド

| メソッド | 説明 |
|---|---|
| `loadDailyView()` | isLoading=true → API取得 → taskRows 構築。失敗時 errorMessage 設定 |
| `onPreviousDate()` | currentDate を -1日 → `loadDailyView()` |
| `onNextDate()` | currentDate を +1日 → `loadDailyView()` |
| `onToggleDone(taskId:)` | isDone 反転。ONにしたとき minutes = defaultMinutes、OFFのとき minutes = "0" |
| `onMinutesChange(taskId:, value:)` | 対象行の minutes を更新 |
| `onSave()` | isDone の行のみ抽出 → `DailyItem` 変換 → API保存。成功で saveSuccess=true |
| `onErrorDismiss()` | errorMessage = nil |
| `onSaveSuccessDismiss()` | saveSuccess = false |

#### `loadDailyView()` — taskRows 構築ロジック

```
task.isDone && task.minutes > 0  →  minutes = task.minutes.toString()
それ以外                           →  minutes = task.defaultMinutes.toString()
```

#### `onSave()` — DailyItem 変換ロジック

```
isDone = true の行のみ対象
minutes = Int(row.minutes) で変換
    変換失敗 or 0以下  →  defaultMinutes を使用
```

---

### 2-3. DailyView

```
Sources/FeatureDaily/DailyView.swift
Sources/FeatureDaily/Components/DateNavigationBar.swift  （内部コンポーネント）
Sources/FeatureDaily/Components/DailyTaskRowView.swift   （内部コンポーネント）
```

#### DailyView（公開View）

```swift
public struct DailyView: View {
    @State private var viewModel: DailyViewModel

    public init(viewModel: DailyViewModel)
}
```

> `DailyView` は TabView 内タブとして使用するため、NavigationStack は**持たない**。
> FeatureSummary からの push 表示（Phase 6）では、`HomeView` の NavigationStack でラップされる。

#### 画面構成

```
VStack
├── DateNavigationBar         ← ← [日付]  [曜日] →
├── [isLoading]               ProgressView（中央）
├── [!isLoading && taskRows.isEmpty]
│       Text("この日のタスクはありません")（中央）
└── [!isLoading && !taskRows.isEmpty]
    ├── ScrollView
    │   └── LazyVStack  DailyTaskRowView × n
    ├── HStack(Spacer + Text("合計: XX分"))（右寄せ）
    └── Button("保存する")（フル幅。isSaving中はProgressView表示）

エラー・成功: ErrorToastView（Phase 3 と同パターン）
```

#### DateNavigationBar（内部コンポーネント）

```
HStack
├── Button("＜")
├── VStack
│   ├── Text(date)     // .appTitle, bold
│   └── Text(weekday)  // .appCaption, 補助色
└── Button("＞")
```

#### DailyTaskRowView（内部コンポーネント）

```
Card（isDone → primaryContainer 背景、else → surface 背景）
└── HStack
    ├── Toggle（チェックボックス相当）  checked=row.isDone
    ├── VStack
    │   ├── Text(row.name)          // isDone → 取り消し線
    │   └── Text("\(row.subject)  ・  標準\(row.defaultMinutes)分")
    ├── TextField("分", text: $minutes)
    │   keyboardType: .numberPad / .decimalPad
    │   frame(width: 64)
    │   disabled: !row.isDone
    └── Text("分")
```

> `minutes` の Binding は `Bindable(viewModel).taskRows[index].minutes` ではなく、ViewModel のメソッド経由で更新:
> `onMinutesChange(taskId:, value:)` コールバックを使用する。

---

## 3. FeatureHome（TabView）

```
Sources/FeatureHome/HomeView.swift
```

### HomeView（公開View）

```swift
public struct HomeView: View {
    let childId: String
    // UseCases（各タブの ViewModel 生成に必要）
    let getDailyViewUseCase: GetDailyViewUseCase
    let updateDailyLogUseCase: UpdateDailyLogUseCase
    // Phase 5/6 用 UseCases は追加予定

    public init(childId: String, getDailyViewUseCase: GetDailyViewUseCase,
                updateDailyLogUseCase: UpdateDailyLogUseCase)
}
```

### 画面構成

```
NavigationStack
└── TabView
    ├── Tab "日々の記録" (house / calendar アイコン)
    │   └── DailyView(viewModel: DailyViewModel(childId: childId, ...))
    ├── Tab "タスク" (checkmark.circle アイコン)
    │   └── Text("タスク管理（Phase 5）")    ← スタブ
    └── Tab "集計" (chart.bar アイコン)
        └── Text("集計（Phase 6）")          ← スタブ
```

> `NavigationStack` は `HomeView` が持つ。FeatureSummary からの `DailyView` push（Phase 6）はここの NavigationStack で行う。

---

## 4. App層（RootView）

### 変更前

```swift
case .home(let childId):
    Text("ホーム: \(childId)（Phase 4）")
```

### 変更後

```swift
case .home(let childId):
    HomeView(
        childId: childId,
        getDailyViewUseCase: deps.getDailyViewUseCase,
        updateDailyLogUseCase: deps.updateDailyLogUseCase
    )
```

---

## 5. Package.swift 変更

`FeatureDaily` に `CoreCommon` を追加（`APIError` マッピングのため）：

```swift
.target(name: "FeatureDaily", dependencies: ["CoreDomain", "CoreCommon", "CoreUI"]),
```

---

## 6. 実装順序

1. `DailyViewModel.swift` — `DailyTaskRow` 型 + ViewModel 全メソッド
2. `Components/DateNavigationBar.swift` — 日付ナビゲーションバー
3. `Components/DailyTaskRowView.swift` — タスク行カード
4. `DailyView.swift` — メイン画面（トースト含む）
5. `HomeView.swift` — TabView（Daily タブのみ実装、残りスタブ）
6. `Package.swift` — FeatureDaily に CoreCommon 追加
7. `RootView.swift` — `.home` ケース更新（`import FeatureHome` 追加）
8. ビルド確認
