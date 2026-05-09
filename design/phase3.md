# Phase 3: 子ども管理

## 概要

子ども一覧の表示・追加・編集・削除、ログアウト、アカウント削除を実装する。

**対象モジュール:**
- `CoreData` — `ChildrenRepositoryImpl`（Phase 1 で実装済み。変更不要）
- `FeatureChildren` — `ChildrenViewModel` + `ChildrenView`
- `learnappios` (App層) — `RootView` の `.children` ケース更新

---

## 1. CoreData（確認のみ）

`Sources/CoreData/ChildrenRepositoryImpl.swift` は Phase 1 で実装済み。追加作業なし。

```
getChildren()                  → GET  /api/v1/children       → [Child]
createChild(name:grade:)       → POST /api/v1/children       → Child
updateChild(childId:name:grade:) → PUT /api/v1/children/{id} → Child
deleteChild(childId:)          → DELETE /api/v1/children/{id} → Void
```

---

## 2. FeatureChildren

### 2-1. ChildrenViewModel

```
Sources/FeatureChildren/ChildrenViewModel.swift
```

#### 状態プロパティ

```swift
@Observable
public final class ChildrenViewModel {
    // 一覧
    public var children: [Child] = []
    public var isLoading: Bool = false
    public var isLoadError: Bool = false

    // 追加・編集ダイアログ
    public var showAddDialog: Bool = false
    public var editingChild: Child? = nil
    public var dialogName: String = ""
    public var dialogGrade: String = ""
    public var isSaving: Bool = false

    // エラー（Snackbar）
    public var errorMessage: String? = nil

    // ログアウト確認ダイアログ
    public var showLogoutConfirm: Bool = false

    // アカウント削除確認ダイアログ
    public var showDeleteAccountConfirm: Bool = false
    public var deleteAccountError: Bool = false
}
```

#### 依存 UseCase

```swift
private let getChildrenUseCase: GetChildrenUseCase
private let createChildUseCase: CreateChildUseCase
private let updateChildUseCase: UpdateChildUseCase
private let deleteChildUseCase: DeleteChildUseCase
private let logoutUseCase: LogoutUseCase
private let deleteAccountUseCase: DeleteAccountUseCase
```

#### メソッド

| メソッド | 説明 |
|---|---|
| `loadChildren()` | isLoading=true → API取得 → children更新。失敗時 isLoadError=true |
| `onShowAddDialog()` | dialogName="", dialogGrade="" → showAddDialog=true |
| `onShowEditDialog(_ child: Child)` | dialogName=child.name, dialogGrade=child.grade ?? "" → editingChild=child |
| `onDismissDialog()` | showAddDialog=false, editingChild=nil, dialogName="", dialogGrade="" |
| `onDialogNameChange(_ value: String)` | dialogName=value |
| `onDialogGradeChange(_ value: String)` | dialogGrade=value |
| `onSaveChild()` | editingChild があれば update、なければ create。isSaving=true/false。成功後 onDismissDialog + loadChildren |
| `onDeleteChild(_ child: Child)` | API呼び出し → 成功後 loadChildren。失敗時 errorMessage 設定 |
| `onShowLogoutConfirm()` | showLogoutConfirm=true |
| `onDismissLogoutConfirm()` | showLogoutConfirm=false |
| `onLogout(onLoggedOut:)` | logoutUseCase.execute() → onLoggedOut() コールバック呼び出し |
| `onShowDeleteAccountConfirm()` | showDeleteAccountConfirm=true |
| `onDismissDeleteAccountConfirm()` | showDeleteAccountConfirm=false |
| `onDeleteAccount(onLoggedOut:)` | deleteAccountUseCase.execute() → 成功: onLoggedOut()。失敗: deleteAccountError=true |
| `onDismissDeleteAccountError()` | deleteAccountError=false |
| `onErrorDismiss()` | errorMessage=nil |

#### エラーメッセージ

`APIError` を日本語文字列にマッピング：

| ケース | メッセージ |
|---|---|
| `.networkError` | "ネットワークに接続できません。接続を確認してください。" |
| `.unauthorized` | "セッションが切れました。再度ログインしてください。"（→ 将来的に自動ログアウト対応） |
| その他 | "エラーが発生しました。時間をおいて再度お試しください。" |

> `deleteChild` のエラーは `errorMessage`（Snackbar表示）
> `deleteAccount` のエラーは `deleteAccountError`（AlertDialog表示）

---

### 2-2. ChildrenView

```
Sources/FeatureChildren/ChildrenView.swift
Sources/FeatureChildren/Components/ChildCard.swift   （画面内専用）
Sources/FeatureChildren/Components/ChildDialog.swift （画面内専用）
```

#### ChildrenView（公開View）

```swift
public struct ChildrenView: View {
    @State private var viewModel: ChildrenViewModel
    let onChildSelected: (String) -> Void
    let onLoggedOut: () -> Void
    let onPrivacyPolicy: () -> Void

    public init(viewModel: ChildrenViewModel,
                onChildSelected: @escaping (String) -> Void,
                onLoggedOut: @escaping () -> Void,
                onPrivacyPolicy: @escaping () -> Void)
}
```

#### 画面構成

```
NavigationStack
└── ZStack（content area）
    ├── [isLoading]         ProgressView（中央）
    ├── [isLoadError && children.isEmpty]
    │       Text("データの取得に失敗しました") + Button("再読み込み")
    ├── [children.isEmpty]  Text("子どもが登録されていません\n右下のボタンから追加してください")（中央）
    └── [else]              List（各行 ChildCard）

    ナビゲーションバー（.navigationTitle("子ども一覧")）
    ├── ログアウトボタン（アイコン） → showLogoutConfirm=true
    └── MoreVertボタン（アイコン） → Menu
            ├── "プライバシーポリシー" → onPrivacyPolicy()
            └── "アカウントを削除"   → showDeleteAccountConfirm=true

    FAB（右下） → showAddDialog=true
```

#### ChildCard（内部コンポーネント）

```
Card（タップ → onChildSelected(child.id)）
└── HStack
    ├── VStack（left）
    │   ├── Text(child.name)  // .appTitle フォント
    │   └── Text(child.grade) // nil なら非表示、.appCaption フォント
    ├── Button（編集アイコン） → onShowEditDialog(child)
    └── Button（削除アイコン、赤） → onDeleteChild(child)
```

#### ChildDialog（内部コンポーネント）

```swift
// 追加・編集共用ダイアログ
Alert/Sheet スタイル：.alert または sheet は使わず SwiftUI の sheet + Form を使用

// 実装：.sheet(isPresented:) + Form
Form {
    TextField("名前", text: $viewModel.dialogName)
    TextField("学年（任意）", text: $viewModel.dialogGrade)
}
// ボタン：「保存」（name.isEmpty || isSaving で無効）、「キャンセル」
```

> Android は `AlertDialog` + `OutlinedTextField`。iOS では `sheet` + `Form` の方が UX が良いため変更する。

#### ダイアログ一覧

| 条件 | タイトル | 本文 | ボタン |
|---|---|---|---|
| `showAddDialog` | "子どもを追加" | フォーム | 保存 / キャンセル |
| `editingChild != nil` | "子どもを編集" | フォーム | 保存 / キャンセル |
| `showLogoutConfirm` | "ログアウト" | "ログアウトしますか？" | ログアウト / キャンセル |
| `showDeleteAccountConfirm` | "アカウントを削除" | "アカウントを削除すると、すべてのデータが削除され復元できません。" | 削除する / キャンセル |
| `deleteAccountError` | "エラー" | "削除に失敗しました。時間をおいて再度お試しください。" | 閉じる |

エラー（`errorMessage`）は `.overlay` または別途トースト相当の実装で画面下部に表示。

---

## 3. App層（RootView）

`learnappios/RootView.swift` の `.children` ケースを更新する。

### 変更前

```swift
case .children:
    Text("子ども選択画面（Phase 3）")
```

### 変更後

```swift
case .children:
    ChildrenView(
        viewModel: ChildrenViewModel(
            getChildrenUseCase: deps.getChildrenUseCase,
            createChildUseCase: deps.createChildUseCase,
            updateChildUseCase: deps.updateChildUseCase,
            deleteChildUseCase: deps.deleteChildUseCase,
            logoutUseCase: deps.logoutUseCase,
            deleteAccountUseCase: deps.deleteAccountUseCase
        ),
        onChildSelected: { childId in navigator.root = .home(childId: childId) },
        onLoggedOut: { navigator.root = .auth },
        onPrivacyPolicy: { /* Phase 3: NavigationStack push or sheet */ }
    )
```

> `onPrivacyPolicy` は `FeatureAuth` の `PrivacyPolicyView` を再利用する。
> `ChildrenView` 内で `NavigationStack` を持ち、`.navigationDestination` で push する。

---

## 4. Package.swift 変更

`FeatureChildren` に `CoreCommon` を追加（`APIError` のマッピングに使用）：

```swift
.target(name: "FeatureChildren", dependencies: ["CoreDomain", "CoreCommon", "CoreUI"]),
```

---

## 5. 実装順序

1. `ChildrenViewModel.swift` — 全メソッド実装
2. `Components/ChildCard.swift` — カードUI
3. `Components/ChildDialog.swift` — 追加・編集フォームsheet
4. `ChildrenView.swift` — メイン画面（ダイアログ制御含む）
5. `Package.swift` — FeatureChildren 依存追加
6. `RootView.swift` — `.children` ケース更新
7. ビルド確認
