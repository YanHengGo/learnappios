# Phase 6: 集計

## 概要

月単位の学習集計画面を実装する。カレンダーグリッド（GREEN/YELLOW/RED）、教科別・タスク別統計、日付タップで `DailyView` へ遷移する機能を含む。

**対象モジュール:**
- `CoreData` — `SummaryRepositoryImpl`（Phase 1 実装済み。変更不要）
- `FeatureSummary` — `SummaryViewModel` + `SummaryView`
- `FeatureHome` — `HomeView` の Summary タブ更新

---

## 1. CoreData（確認のみ）

`Sources/CoreData/SummaryRepositoryImpl.swift` は Phase 1 で実装済み。追加作業なし。

```
getCalendarSummary(childId:from:to:) → GET /api/v1/children/{id}/calendar-summary?from=...&to=... → CalendarSummary
getSummary(childId:from:to:)         → GET /api/v1/children/{id}/summary?from=...&to=...         → Summary
```

---

## 2. FeatureSummary

### 2-1. SummaryViewModel

```
Sources/FeatureSummary/SummaryViewModel.swift
```

#### 状態プロパティ

```swift
@Observable
public final class SummaryViewModel {
    public var calendarSummary: CalendarSummary? = nil
    public var summary: Summary? = nil
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    public var yearMonth: YearMonth = .now   // CoreCommon.YearMonth（Phase 1 定義済み）

    private let childId: String
    private let getCalendarSummaryUseCase: GetCalendarSummaryUseCase
    private let getSummaryUseCase: GetSummaryUseCase
}
```

> `CoreCommon.YearMonth`（`YearMonth.swift`）が Phase 1 で実装済み。Android の `java.time.YearMonth` と同等の API を持つ（`now`, `firstDayString()`, `lastDayString()`, `adding(months:)`）。

#### init

```swift
public init(
    childId: String,
    getCalendarSummaryUseCase: GetCalendarSummaryUseCase,
    getSummaryUseCase: GetSummaryUseCase
)
// 初期値: currentMonthStart = 本日の月初
```

#### メソッド

| メソッド | 説明 |
|---|---|
| `loadMonth()` | calendar と summary を `async let` で並行取得。両方失敗時のみ errorMessage 設定。個別失敗は nil のまま |
| `onPreviousMonth()` | `yearMonth = yearMonth.adding(months: -1)` → `loadMonth()` |
| `onNextMonth()` | `yearMonth = yearMonth.adding(months: 1)` → `loadMonth()` |
| `onErrorDismiss()` | errorMessage = nil |

#### `loadMonth()` — 日付範囲算出

```swift
let from = yearMonth.firstDayString()   // "yyyy-MM-01"
let to   = yearMonth.lastDayString()    // "yyyy-MM-dd"
```

#### `loadMonth()` — 並行取得

```swift
// Android の並行実行と同等
async let calendarResult = getCalendarSummaryUseCase.execute(childId: childId, from: from, to: to)
async let summaryResult  = getSummaryUseCase.execute(childId: childId, from: from, to: to)

let cal = try? await calendarResult
let sum = try? await summaryResult
calendarSummary = cal
summary = sum
if cal == nil && sum == nil {
    errorMessage = makeErrorMessage(from: ...)
}
```

---

### 2-2. SummaryView

```
Sources/FeatureSummary/SummaryView.swift
Sources/FeatureSummary/Components/MonthNavigationBar.swift （内部コンポーネント）
Sources/FeatureSummary/Components/CalendarGrid.swift       （内部コンポーネント）
Sources/FeatureSummary/Components/SummaryStats.swift       （内部コンポーネント）
```

#### SummaryView（公開 View）

```swift
public struct SummaryView: View {
    @State private var viewModel: SummaryViewModel
    @State private var selectedDate: String? = nil
    // DailyView 生成に必要（FeatureSummary → FeatureDaily は許可依存）
    let getDailyViewUseCase: GetDailyViewUseCase
    let updateDailyLogUseCase: UpdateDailyLogUseCase

    public init(
        viewModel: SummaryViewModel,
        getDailyViewUseCase: GetDailyViewUseCase,
        updateDailyLogUseCase: UpdateDailyLogUseCase
    )
}
```

#### 画面構成

```
ScrollView（isLoading 中は ZStack で ProgressView を中央表示）
├── MonthNavigationBar        ← [yyyy年MM月] →
├── CalendarGrid              （日付タップ → selectedDate 更新）
├── LegendRow                 （凡例: ●全完了 ●一部完了 ●未完了）
├── Divider
└── SummaryStats(summary:)    （summary が nil なら非表示）

エラートースト（Phase 3/4/5 と同パターン）

.navigationTitle("集計")
.navigationDestination(item: $selectedDate) { dateStr in
    DailyView(viewModel: DailyViewModel(
        childId: viewModel.childId,
        initialDate: parseDate(dateStr) ?? .now,
        getDailyViewUseCase: getDailyViewUseCase,
        updateDailyLogUseCase: updateDailyLogUseCase
    ))
}
```

> `SummaryView` は `HomeView` の `NavigationStack` の中に配置されるため、自身では `NavigationStack` を持たない。
> `selectedDate` を `String?` で保持し、`.navigationDestination(item:)` で DailyView を push する。

#### MonthNavigationBar（内部コンポーネント）

```
HStack
├── Button("＜") → onPreviousMonth
├── Text("\(yearMonth.year)年\(yearMonth.month)月")  // .appTitle, bold
└── Button("＞") → onNextMonth
```

#### CalendarGrid（内部コンポーネント）

**入力:**
```swift
struct CalendarGrid: View {
    let yearMonth: YearMonth
    let dayMap: [String: CalendarDay]   // "yyyy-MM-dd" → CalendarDay
    let onDayTap: (String) -> Void
}
```

**曜日ヘッダー（日〜土）:**
- 日: 赤 `Color(0xFFE53935)`
- 土: 青 `Color(0xFF1E88E5)`
- 平日: `Color.primary`

**グリッドセル計算（iOS）:**
```swift
// yearMonth.firstDayString() → DateFormatter でDate変換
let firstDay: Date = ...   // yyyy-MM-01 をパース
// weekday: 1=日, 2=月, ..., 7=土 → offset: 0=日, 1=月, ..., 6=土
let startOffset: Int = Calendar.current.component(.weekday, from: firstDay) - 1
let daysInMonth: Int = Calendar.current.range(of: .day, in: .month, for: firstDay)!.count
```

**各セルの背景色:**
```
CalendarStatus.green  → Color(0xFFC8E6C9)
CalendarStatus.yellow → Color(0xFFFFF9C4)
CalendarStatus.red    → Color(0xFFFFCDD2)
nil / white           → Color.clear
```

**今日の強調:** `date == today` のとき、数字の周囲に `Color.appPrimary.opacity(0.15)` の円背景。

**タップ:** データがある日もない日も全セルタップ可能。タップで `onDayTap(dateStr)` 呼び出し。

#### LegendRow（CalendarGrid.swift 内 private）

```
HStack(spacing: 12)
├── ●(green)  "全完了"
├── ●(yellow) "一部完了"
└── ●(red)    "未完了"
```

#### SummaryStats（内部コンポーネント）

```swift
struct SummaryStats: View {
    let summary: Summary
}
```

**構成:**
```
VStack(spacing: 16)
├── Card: 期間合計
│   └── Text(formatMinutes(summary.totalMinutes))  // "X時間Y分" or "Y分"
├── Card: 教科別（summary.bySubject が空なら非表示）
│   └── bySubject.sorted(by: minutes 降順).forEach:
│       HStack { Text(subject)  Spacer  Text(formatMinutes(minutes)) }
│       Divider
└── Card: タスク別（summary.byTask が空なら非表示）
    └── byTask.sorted(by: minutes 降順).forEach:
        HStack {
            VStack { Text(name); Text(subject) }
            Spacer
            Text(formatMinutes(minutes))
        }
        Divider
```

**`formatMinutes`:**
```swift
func formatMinutes(_ minutes: Int) -> String {
    let h = minutes / 60, m = minutes % 60
    return h > 0 ? "\(h)時間\(m)分" : "\(m)分"
}
```

---

## 3. FeatureHome 更新

### 追加する init パラメータ

```swift
let getCalendarSummaryUseCase: GetCalendarSummaryUseCase
let getSummaryUseCase: GetSummaryUseCase
```

> `getDailyViewUseCase` / `updateDailyLogUseCase` は既存。Summary タブ → DailyView 遷移でも再利用する。

### TabView 変更

```swift
// Before
NavigationStack { Text("集計（Phase 6）") }
    .tabItem { ... }

// After
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
.tabItem { Label("集計", systemImage: "chart.bar") }
```

---

## 4. App層（RootView）

HomeView の呼び出しに Summary 系 UseCase を追加注入する。

```swift
HomeView(
    childId: childId,
    getDailyViewUseCase: deps.getDailyViewUseCase,
    updateDailyLogUseCase: deps.updateDailyLogUseCase,
    getTasksUseCase: deps.getTasksUseCase,
    createTaskUseCase: deps.createTaskUseCase,
    updateTaskUseCase: deps.updateTaskUseCase,
    archiveTaskUseCase: deps.archiveTaskUseCase,
    reorderTasksUseCase: deps.reorderTasksUseCase,
    getCalendarSummaryUseCase: deps.getCalendarSummaryUseCase,
    getSummaryUseCase: deps.getSummaryUseCase
)
```

---

## 5. Package.swift 変更

`FeatureSummary` に `CoreCommon` を追加（`APIError` マッピング）。
`FeatureDaily` はすでに `FeatureSummary` の依存に含まれているため追加不要。

```swift
.target(
    name: "FeatureSummary",
    dependencies: ["CoreDomain", "CoreCommon", "CoreUI", "FeatureDaily"]
),
```

---

## 6. 実装順序

1. `SummaryViewModel.swift`
2. `Components/MonthNavigationBar.swift`
3. `Components/CalendarGrid.swift`（`LegendRow` も同ファイル内 private）
4. `Components/SummaryStats.swift`
5. `SummaryView.swift`
6. `Package.swift` — FeatureSummary に CoreCommon 追加
7. `HomeView.swift` — Summary タブ更新（init 拡張）
8. `RootView.swift` — HomeView に Summary UseCase 追加注入
9. ビルド確認
