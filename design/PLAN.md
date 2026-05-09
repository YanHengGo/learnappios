# learnapp iOS版 実装計画

## アプリ概要

子どもの学習管理アプリ。保護者が子どもの学習タスクを登録し、毎日の学習記録をつけ、月次サマリーで振り返ることができる。

Androidアプリ（`/Users/yanheng/dev/learnapp`）と同一バックエンドAPIを利用する。

---

## 技術選定

| カテゴリ | 採用技術 | 理由 |
|---|---|---|
| UI | SwiftUI | 宣言的UIでAndroid Composeと対応が取りやすい |
| アーキテクチャ | MVVM + Observable | SwiftUI標準との親和性 |
| 非同期処理 | Swift Concurrency (async/await) | Kotlin coroutinesに対応する現代的な実装 |
| ネットワーク | URLSession | 追加依存なし、標準ライブラリで十分 |
| トークン保存 | Keychain (KeychainAccess相当をゼロ依存で実装) | セキュアなトークン永続化 |
| 状態管理 | `@Observable` / `@StateObject` | SwiftUI標準 |
| 依存注入 | コンストラクタDI（手動） | 小規模なので外部フレームワーク不要 |
| 最小iOS | iOS 17 | `@Observable` マクロ使用のため |

**外部パッケージはゼロ**（URLSession / Keychain / SwiftUI は標準ライブラリのみ）。
モジュール分割には **SPM ローカルパッケージ**を使用する。詳細は [`spm-modules.md`](./spm-modules.md) を参照。

---

## プロジェクト構成

```
learnappios/
├── Package.swift                    # SPM: 全モジュール定義（外部依存なし）
├── Sources/                         # SPM ライブラリターゲット群
│   ├── CoreModel/                   # ドメインモデル
│   ├── CoreCommon/                  # APIError, DateExtensions
│   ├── CoreNetwork/                 # APIClient + DTO + Requests
│   ├── CoreDataStore/               # KeychainStore
│   ├── CoreDomain/                  # Repository protocol + UseCase
│   ├── CoreData/                    # Repository実装 + Mapper
│   ├── CoreUI/                      # 共通コンポーネント + テーマ
│   ├── FeatureSplash/
│   ├── FeatureAuth/
│   ├── FeatureChildren/
│   ├── FeatureDaily/
│   ├── FeatureTasks/
│   ├── FeatureSummary/
│   └── FeatureHome/
├── Tests/                           # SPM テストターゲット群
│   ├── CoreNetworkTests/
│   ├── CoreDataTests/
│   ├── CoreDomainTests/
│   └── Feature*Tests/
└── learnappios/                     # Xcode アプリターゲット（App層）
    ├── learnappiosApp.swift         # @main
    ├── AppDependencies.swift        # DIコンテナ（CoreDataをワイヤリング）
    └── AppNavigator.swift           # ルートナビゲーション状態
```

---

## 実装フェーズ

### Phase 1: 基盤層（SPMモジュール骨格）
1. `Package.swift` 作成・Xcodeへのローカルパッケージ登録
2. `CoreModel` — 全ドメインモデル定義
3. `CoreCommon` — `APIError`, `DateExtensions`
4. `CoreNetwork` — `APIClient` (URLSession), `APIEndpoint`, 全DTO, 全Requestボディ
5. `CoreDataStore` — `KeychainStore` (Security.framework)
6. `CoreDomain` — 全 Repository プロトコル + 全 UseCase 実装
7. App層 — `AppDependencies`（DIコンテナ骨格）、`AppNavigator`

### Phase 2: 認証フロー
1. `CoreData` — `AuthRepositoryImpl` + `CoreUI` 基本テーマ
2. `FeatureAuth` — `AuthViewModel` + `AuthView`（ログイン／サインアップ切り替え）+ `PrivacyPolicyView`
3. `FeatureSplash` — `SplashViewModel` + `SplashView`（トークン有無で分岐）
4. App層 — ルートナビゲーション完成（`AppNavigator` + `RootView`）

### Phase 3: 子ども管理
1. `CoreData` — `ChildrenRepositoryImpl`
2. `FeatureChildren` — `ChildrenViewModel` + `ChildrenView`
   - 一覧表示、追加ダイアログ、編集ダイアログ、削除
   - ログアウト・アカウント削除確認ダイアログ

### Phase 4: 日々の記録
1. `CoreData` — `DailyRepositoryImpl`
2. `FeatureDaily` — `DailyViewModel` + `DailyView`
   - 日付ナビゲーション（前日・翌日）
   - タスク行（チェックボックス＋分入力）、合計分表示、保存

### Phase 5: タスク管理
1. `CoreData` — `TaskRepositoryImpl`
2. `FeatureTasks` — `TasksViewModel` + `TasksView`
   - 一覧（ドラッグ並び替え）
   - 追加・編集ダイアログ（名前、教科、標準時間、曜日、開始日・終了日）、アーカイブ

### Phase 6: 集計
1. `CoreData` — `SummaryRepositoryImpl`
2. `FeatureSummary` — `SummaryViewModel` + `SummaryView`
   - 月ナビゲーション、カレンダーグリッド（GREEN/YELLOW/RED/WHITE）
   - 凡例、期間合計・教科別・タスク別統計
   - 日付タップで `FeatureDaily` の `DailyView` へ遷移

### Phase 7: ホーム統合
1. `FeatureHome` — `HomeViewModel` + `HomeView`（TabView: 日々・タスク・集計）
2. 子ども切り替えダイアログ、ログアウト確認ダイアログ
3. App層 — `AppDependencies` 完成（全 Repository を ViewModel へ注入）

---

## ナビゲーション設計

```
AppNavigator (@Observable)
  ├── .splash
  ├── .auth
  │   └── sheet: .privacyPolicy
  ├── .children
  │   └── sheet: .privacyPolicy
  └── .home(childId:)
      ├── tab: .daily
      ├── tab: .tasks
      └── tab: .summary
          └── push: .dailyDetail(date:)
```

`NavigationStack` + `NavigationPath` を使い、全画面遷移を `AppNavigator` が一元管理する。

---

## データフロー

```
View
  │ Action（タップ等）
  ▼
ViewModel（@Observable）
  │ async/await
  ▼
UseCase（CoreDomain）        ← ビジネスロジックの境界
  │ async throws
  ▼
Repository protocol（CoreDomain）
  │
  ▼
Repository impl（CoreData）+ APIClient（URLSession）
  │ HTTP
  ▼
Backend API
```

- エラーは `APIError` でラップし、UseCase を通じて ViewModel の `errorMessage: String?` に伝搬
- View は `errorMessage` を `.alert()` やトーストで表示

---

## 対応表（Android → iOS）

| Android | iOS |
|---|---|
| `@Composable fun` | `struct View: View` |
| `ViewModel` (Hilt) | `@Observable class ViewModel` |
| `StateFlow<UiState>` | `@Observable` クラスのプロパティ（`@Published` 不要）|
| `XxxUseCase` (Hilt inject) | `XxxUseCase`（コンストラクタDI） |
| `LaunchedEffect` | `.task {}` / `.onChange(of:)` |
| `AlertDialog` | `.alert()` / `.confirmationDialog()` / `.sheet` |
| `Scaffold` + `BottomBar` | `TabView` |
| `LazyColumn` | `List` / `ScrollView + LazyVStack` |
| Retrofit | `URLSession` + `APIClient` |
| DataStore（token） | Keychain（`CoreDataStore`） |
| Hilt DI | 手動DI（`AppDependencies` で UseCase を生成・注入） |
| `daysMask` (Int bitmask) | `Int` bitmask（同一ロジック） |
