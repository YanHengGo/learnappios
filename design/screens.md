# 画面仕様

## 画面一覧

| 画面 | View名 | Android対応 |
|---|---|---|
| スプラッシュ | `SplashView` | `SplashScreen` |
| 認証（ログイン/サインアップ） | `AuthView` | `AuthScreen` |
| プライバシーポリシー | `PrivacyPolicyView` | `PrivacyPolicyScreen` |
| 子ども一覧 | `ChildrenView` | `ChildrenScreen` |
| ホーム（タブコンテナ） | `HomeView` | `HomeScreen` |
| 日々の記録 | `DailyView` | `DailyScreen` |
| タスク管理 | `TasksView` | `TasksScreen` |
| 集計 | `SummaryView` | `SummaryScreen` |

---

## SplashView

**役割:** トークン有無を確認し、次画面へ自動遷移。

**ViewModel処理:**
```
init時に KeychainStore.load() を確認
  → token あり → getMe() 呼び出し
      → 成功 → navigator.root = .children
      → 失敗（401等） → navigator.root = .auth
  → token なし → navigator.root = .auth
```

**UI:**
- 中央にアプリロゴ or アプリ名テキスト
- `ProgressView`（スピナー）

---

## AuthView

**役割:** ログイン / サインアップを切り替えて認証。

**State（AuthViewModel）:**
```swift
var email: String
var password: String
var mode: AuthMode  // .login / .signup
var isLoading: Bool
var errorMessage: String?
```

**UI:**
- メールアドレス入力（`TextField`）
- パスワード入力（`SecureField`）
- ログイン/サインアップ ボタン（`isLoading` 中は `ProgressView`）
- モード切り替えリンク（「アカウントをお持ちでない方はこちら」）
- プライバシーポリシーリンク
- エラーメッセージ表示（`.alert`）

**遷移:**
- 認証成功 → `navigator.root = .children`
- プライバシーポリシー → `.sheet` で `PrivacyPolicyView`

---

## PrivacyPolicyView

**UI:**
- NavigationBarTitle: 「プライバシーポリシー」
- `ScrollView` + `Text` でポリシー本文
- 閉じるボタン（`dismiss()`）

---

## ChildrenView

**役割:** 登録した子ども一覧を管理。子どもを選択してホームへ。

**State（ChildrenViewModel）:**
```swift
var children: [Child]
var isLoading: Bool
var isLoadError: Bool
var errorMessage: String?
var showAddDialog: Bool
var editingChild: Child?
var dialogName: String
var dialogGrade: String
var isSaving: Bool
var showLogoutConfirm: Bool
var showDeleteAccountConfirm: Bool
var deleteAccountError: Bool
```

**UI:**
- NavigationBar タイトル: 「子ども一覧」
- 右上: ログアウトボタン、メニューボタン（プライバシーポリシー・アカウント削除）
- 右下: `+` FAB（FloatingActionButton → iOS では `.toolbar` にボタンか右下に `overlay`）
- 子どもカード一覧（`List`）:
  - 名前（太字）
  - 学年（任意、サブテキスト）
  - 編集ボタン、削除ボタン
  - `isActive` で背景色変更（primaryContainer相当 ↔ secondaryContainer）
- 空状態: 「子どもが登録されていません」
- ロードエラー: 再読み込みボタン

**ダイアログ:**
- 追加/編集ダイアログ: 名前（必須）、学年（任意）、保存/キャンセル
- ログアウト確認: 「ログアウトしますか？」
- アカウント削除確認: 「すべてのデータが削除されます」
- アカウント削除エラー: 「削除に失敗しました」

**遷移:**
- 子どもカードタップ → `navigator.root = .home(childId:)`

---

## HomeView

**役割:** 選択した子どものデータを3タブで管理。

**State（HomeViewModel）:**
```swift
var children: [Child]
var selectedChildName: String
var showSwitcher: Bool
var showLogoutConfirm: Bool
var errorMessage: String?
```

**UI:**
- `TabView` 3タブ:
  1. **日々**（CalendarMonth アイコン） → `DailyView`
  2. **タスク**（Assignment アイコン） → `TasksView`
  3. **集計**（BarChart アイコン） → `SummaryView`
- NavigationBar タイトル: `TextButton`（子ども名 + 下矢印）→ 子ども切り替えダイアログ
- 右上: ログアウトボタン、メニューボタン（プライバシーポリシー）

**ダイアログ:**
- 子ども切り替えダイアログ: 子ども一覧をリスト表示、現在選択中は ✓ 付き・無効化
- ログアウト確認

---

## DailyView

**役割:** 特定日の学習タスクを記録・保存。

**State（DailyViewModel）:**
```swift
var date: String            // "yyyy-MM-dd"
var weekday: String         // "月曜日" 等
var taskRows: [DailyTaskRow]
var isLoading: Bool
var isSaving: Bool
var errorMessage: String?
var saveSuccess: Bool
```

```swift
struct DailyTaskRow {
    let taskId: String
    let name: String
    let subject: String
    let defaultMinutes: Int
    var isDone: Bool
    var minutes: String   // 入力中文字列
}
```

**UI:**
- 日付ナビゲーションバー（前日 ‹ | yyyy-MM-dd（曜日） | 翌日 ›）
- タスク行リスト（`List` or `ScrollView + LazyVStack`）:
  - チェックボックス（`Toggle` / カスタムチェックボックス）
  - タスク名（チェック済みは取り消し線）
  - 教科・標準時間（サブテキスト）
  - 分入力フィールド（`TextField`、数字キーボード、isDone=false で無効化）
- 合計分表示（完了タスクのみ）
- 「保存する」ボタン（`isSaving` 中は `ProgressView`）
- 空状態: 「この日のタスクはありません」

**Snackbar的UI:** 保存成功・エラーは `.overlay` でトースト or `Alert`

---

## TasksView

**役割:** 子どもに紐づくタスクの CRUD ＋ 並び替え ＋ アーカイブ。

**State（TasksViewModel）:**
```swift
var tasks: [Task]
var isLoading: Bool
var errorMessage: String?
var showDialog: Bool
var editingTask: Task?
var dialogName: String
var dialogDescription: String
var dialogSubject: String
var dialogMinutes: String       // "30"
var dialogDaysMask: Int         // 0b0111110 デフォルト（月〜金）
var dialogStartDate: String
var dialogEndDate: String
var isSaving: Bool
```

**UI:**
- タイトル: 「タスク管理」
- 右下: `+` ボタン（`overlay` or `.toolbar`）
- タスクカード一覧（ドラッグ並び替え対応）:
  - ドラッグハンドル（≡ アイコン）
  - タスク名（太字）
  - 教科・標準時間・対象曜日（サブテキスト）
  - 開始日〜終了日（設定時のみ）
  - 編集ボタン、アーカイブボタン
- 空状態: 「タスクが登録されていません」

**ドラッグ並び替え:**
SwiftUIの `.onMove(perform:)` を使用（`List` の `EditMode` を活用、またはカスタム実装）

**追加/編集ダイアログ（Sheet形式）:**
| フィールド | 型 | 備考 |
|---|---|---|
| タスク名 | TextField | 必須 |
| 教科 | TextField | 必須 |
| 標準時間（分） | TextField（数字） | 必須、>0 |
| メモ | TextEditor | 任意 |
| 曜日 | 7つのトグルボタン | 日・月・火・水・木・金・土 |
| 開始日 | TextField or DatePicker | 任意、yyyy-MM-dd |
| 終了日 | TextField or DatePicker | 任意、yyyy-MM-dd |

保存ボタン: 名前・教科・分が有効な場合のみ有効

---

## SummaryView

**役割:** 月次カレンダーで学習状況を色分け表示し、集計統計を確認。

**State（SummaryViewModel）:**
```swift
var yearMonth: YearMonth    // (year: Int, month: Int)
var calendarSummary: CalendarSummary?
var summary: Summary?
var isLoading: Bool
var errorMessage: String?
```

**UI（縦スクロール）:**

1. **月ナビゲーションバー**
   - `‹ yyyy年MM月 ›`

2. **カレンダーグリッド**
   - 曜日ヘッダー（日・月・火・水・木・金・土）
   - 日セル: 7列グリッド
     - 背景色: GREEN=#C8E6C9、YELLOW=#FFF9C4、RED=#FFCDD2、WHITE=透明
     - 日曜: 赤テキスト、土曜: 青テキスト
     - 今日: プライマリカラーの薄い円背景＋太字
     - タップ → DailyView（日付指定）へ遷移（SummaryタブのNavigationStack）

3. **凡例**
   - 緑丸「全完了」、黄丸「一部完了」、赤丸「未完了」

4. **統計カード**（Summaryがある場合）
   - 期間合計: xx時間xx分
   - 教科別: 教科名 | xx時間xx分（降順）
   - タスク別: タスク名（教科）| xx時間xx分（降順）

**formatMinutes:**
```swift
func formatMinutes(_ minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    return h > 0 ? "\(h)時間\(m)分" : "\(m)分"
}
```

---

## 共通UIコンポーネント

### LoadingOverlay
ロード中に画面を半透明でブロックし、中央に `ProgressView` を表示。

### ErrorAlert
```swift
.alert("エラー", isPresented: $showError) {
    Button("閉じる") { viewModel.clearError() }
} message: {
    Text(viewModel.errorMessage ?? "")
}
```

### ToastView（保存成功等）
`withAnimation` で下部からスライドイン→数秒後に自動消去する overlay。

### DayChip（曜日選択）
```swift
// 押すたびに選択/解除
Button(dayLabels[i]) { viewModel.toggleDay(i) }
    .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
    .clipShape(Capsule())
```
