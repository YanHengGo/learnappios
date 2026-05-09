# Phase 7: ホーム統合

## 概要

`HomeView` に子ども名表示・子ども切り替え・ログアウト・プライバシーポリシーメニューを追加する。
`HomeViewModel` を新規作成し、子ども一覧取得とダイアログ状態を管理する。

**対象モジュール:**
- `FeatureHome` — `HomeViewModel` 新規作成 + `HomeView` 拡張
- `learnappios` (App層) — `RootView` の Home ケース更新

---

## 1. HomeViewModel

```
Sources/FeatureHome/HomeViewModel.swift
```

### 状態プロパティ

```swift
@Observable
public final class HomeViewModel {
    public var children: [Child] = []
    public var selectedChildName: String = ""
    public var showSwitcher: Bool = false
    public var showLogoutConfirm: Bool = false
    public var errorMessage: String? = nil

    private let childId: String
    private let getChildrenUseCase: GetChildrenUseCase
    private let logoutUseCase: LogoutUseCase
}
```

### メソッド

| メソッド | 説明 |
|---|---|
| `loadChildren()` | children 取得 → `selectedChildName` を childId から特定。失敗時 errorMessage 設定 |
| `onShowSwitcher()` | showSwitcher = true |
| `onDismissSwitcher()` | showSwitcher = false |
| `onShowLogoutConfirm()` | showLogoutConfirm = true |
| `onDismissLogoutConfirm()` | showLogoutConfirm = false |
| `onLogout(onLoggedOut:)` | logoutUseCase.execute() → onLoggedOut() |
| `onErrorDismiss()` | errorMessage = nil |

---

## 2. HomeView 拡張

### 追加する init パラメータ

```swift
// 既存: childId, 各 UseCase
// 追加:
let getChildrenUseCase: GetChildrenUseCase
let logoutUseCase: LogoutUseCase
let onChildSwitch: (String) -> Void    // 子ども切り替え時に呼ぶ
let onLoggedOut: () -> Void
let onPrivacyPolicy: () -> Void
```

### HomeViewModel の保持

```swift
@State private var homeViewModel: HomeViewModel
```

`HomeViewModel` は `childId`, `getChildrenUseCase`, `logoutUseCase` で初期化。

### ツールバー設計

Android の Scaffold TopAppBar に相当する要素を、iOS では各タブの root view の `.toolbar` として設定する（各 NavigationStack の NavigationBar に反映）。

```
toolbar (leading):
  Button { homeViewModel.onShowSwitcher() } label:
    HStack { Text(selectedChildName または "…"); Image("chevron.down") }

toolbar (trailing):
  Button(ログアウトアイコン) { homeViewModel.onShowLogoutConfirm() }
  Menu(ellipsis.circle) {
    Button("プライバシーポリシー") { onPrivacyPolicy() }
  }
```

> ツールバー項目を各タブ root view に付与することで、Summary → DailyDetail へ push したとき、pushed な DailyView にはツールバー項目が引き継がれない（正しい iOS 挙動）。

### ツールバーの付与方法

各タブ root view に `.modifier(HomeToolbar(...))` を適用する（内部 `ViewModifier`）。

```swift
// HomeView.swift 内 private struct
private struct HomeToolbar: ViewModifier {
    let childName: String
    let onSwitchChild: () -> Void
    let onLogout: () -> Void
    let onPrivacyPolicy: () -> Void

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onSwitchChild) {
                    HStack(spacing: 4) {
                        Text(childName.isEmpty ? "…" : childName)
                        Image(systemName: "chevron.down")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onLogout) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("プライバシーポリシー", action: onPrivacyPolicy)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
```

### TabView 変更（ツールバー付与）

```swift
TabView {
    NavigationStack {
        DailyView(...)
            .modifier(homeToolbar)
    }
    .tabItem { ... }

    NavigationStack {
        TasksView(...)
            .modifier(homeToolbar)
    }
    .tabItem { ... }

    NavigationStack {
        SummaryView(...)
            .modifier(homeToolbar)
    }
    .tabItem { ... }
}
.task { homeViewModel.loadChildren() }
```

### ダイアログ

#### 子ども切り替えダイアログ

```
.alert("子どもを切り替え", isPresented: $homeViewModel.showSwitcher)
```

> iOS の `.alert` はリストを表示できないため、`.confirmationDialog`（ActionSheet）を使用する。
> または `.sheet` で `List` を表示する方が UX として適切。

**実装: `.confirmationDialog`**

```swift
.confirmationDialog(
    "子どもを切り替え",
    isPresented: $homeViewModel.showSwitcher,
    titleVisibility: .visible
) {
    ForEach(homeViewModel.children) { child in
        Button(child.id == childId ? "✓ \(child.name)" : child.name) {
            if child.id != childId {
                onChildSwitch(child.id)
            }
        }
    }
    Button("キャンセル", role: .cancel) {}
}
```

#### ログアウト確認ダイアログ

```swift
.alert("ログアウト", isPresented: $homeViewModel.showLogoutConfirm) {
    Button("キャンセル", role: .cancel) { homeViewModel.onDismissLogoutConfirm() }
    Button("ログアウト") { homeViewModel.onLogout(onLoggedOut: onLoggedOut) }
} message: {
    Text("ログアウトしますか？")
}
```

#### エラートースト

Phase 3〜6 と同パターン（3秒後自動消滅）。

---

## 3. App層（RootView）

### 追加する `@State`

```swift
@State private var showPrivacyPolicyFromHome = false
```

### `.home` ケース更新

```swift
case .home(let childId):
    HomeView(
        childId: childId,
        // 既存 UseCases（Daily/Tasks/Summary）
        getDailyViewUseCase: deps.getDailyViewUseCase,
        updateDailyLogUseCase: deps.updateDailyLogUseCase,
        getTasksUseCase: deps.getTasksUseCase,
        createTaskUseCase: deps.createTaskUseCase,
        updateTaskUseCase: deps.updateTaskUseCase,
        archiveTaskUseCase: deps.archiveTaskUseCase,
        reorderTasksUseCase: deps.reorderTasksUseCase,
        getCalendarSummaryUseCase: deps.getCalendarSummaryUseCase,
        getSummaryUseCase: deps.getSummaryUseCase,
        // Phase 7 追加
        getChildrenUseCase: deps.getChildrenUseCase,
        logoutUseCase: deps.logoutUseCase,
        onChildSwitch: { childId in navigator.root = .home(childId: childId) },
        onLoggedOut: { navigator.root = .auth },
        onPrivacyPolicy: { showPrivacyPolicyFromHome = true }
    )
    .sheet(isPresented: $showPrivacyPolicyFromHome) {
        PrivacyPolicyView()  // FeatureAuth から import
    }
```

---

## 4. Package.swift 変更

`FeatureHome` に `CoreModel`・`CoreCommon` を追加（`Child` 型と `APIError` 使用のため）：

```swift
.target(
    name: "FeatureHome",
    dependencies: [
        "CoreDomain", "CoreModel", "CoreCommon", "CoreUI",
        "FeatureDaily", "FeatureTasks", "FeatureSummary",
    ]
),
```

---

## 5. 実装順序

1. `HomeViewModel.swift`
2. `HomeView.swift` — HomeViewModel 保持・HomeToolbar ViewModifier・ダイアログ追加・init 拡張
3. `Package.swift` — FeatureHome に CoreModel・CoreCommon 追加
4. `RootView.swift` — `.home` ケース更新（追加パラメータ注入・privacy policy sheet）
5. ビルド確認
