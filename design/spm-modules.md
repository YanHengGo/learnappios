# SPM マルチモジュール設計

## 方針

- **外部パッケージはゼロ**（URLSession / Keychain / SwiftUI は標準ライブラリのみ）
- ローカルモジュールをSPMライブラリターゲットとして定義（ビルド分離・テスト独立を実現）
- Androidの Gradle マルチモジュール構成と1対1で対応させる
- 単一の `Package.swift` でモジュール全体を管理（複数のローカルパッケージに分割しない）

---

## ディレクトリ構成

```
learnappios/
├── Package.swift                        # 全モジュールを定義するルートマニフェスト
├── Sources/
│   ├── CoreModel/                       # ドメインモデル（依存なし）
│   ├── CoreCommon/                      # 共通ユーティリティ（依存なし）
│   ├── CoreNetwork/                     # APIClient + DTO（CoreModelに依存）
│   ├── CoreDataStore/                   # Keychainトークン永続化（依存なし）
│   ├── CoreDomain/                      # Repositoryプロトコル + UseCase（CoreModel, CoreCommonに依存）
│   ├── CoreData/                        # Repository実装 + Mapper（CoreDomain, CoreNetwork, CoreDataStoreに依存）
│   ├── CoreUI/                          # 共通SwiftUIコンポーネント + テーマ（CoreModelに依存）
│   ├── FeatureSplash/                   # スプラッシュ（CoreDomain, CoreUIに依存）
│   ├── FeatureAuth/                     # 認証（CoreDomain, CoreUIに依存）
│   ├── FeatureChildren/                 # 子ども管理（CoreDomain, CoreUIに依存）
│   ├── FeatureDaily/                    # 日々の記録（CoreDomain, CoreUIに依存）
│   ├── FeatureTasks/                    # タスク管理（CoreDomain, CoreUIに依存）
│   ├── FeatureSummary/                  # 集計（CoreDomain, CoreUIに依存）
│   └── FeatureHome/                     # ホーム（CoreDomain, CoreUI + 各Featureに依存）
├── Tests/
│   ├── CoreNetworkTests/
│   ├── CoreDataTests/
│   ├── CoreDomainTests/
│   ├── FeatureAuthTests/
│   ├── FeatureDailyTests/
│   ├── FeatureTasksTests/
│   └── FeatureSummaryTests/
└── learnappios/                         # Xcodeアプリターゲット（App層）
    ├── learnappiosApp.swift             # @main
    ├── AppDependencies.swift            # DIコンテナ（全モジュールをワイヤリング）
    └── AppNavigator.swift              # ルートナビゲーション
```

---

## Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LearnModules",
    platforms: [.iOS(.v17)],
    products: [
        // Core
        .library(name: "CoreModel",     targets: ["CoreModel"]),
        .library(name: "CoreCommon",    targets: ["CoreCommon"]),
        .library(name: "CoreNetwork",   targets: ["CoreNetwork"]),
        .library(name: "CoreDataStore", targets: ["CoreDataStore"]),
        .library(name: "CoreDomain",    targets: ["CoreDomain"]),
        .library(name: "CoreData",      targets: ["CoreData"]),
        .library(name: "CoreUI",        targets: ["CoreUI"]),
        // Features
        .library(name: "FeatureSplash",   targets: ["FeatureSplash"]),
        .library(name: "FeatureAuth",     targets: ["FeatureAuth"]),
        .library(name: "FeatureChildren", targets: ["FeatureChildren"]),
        .library(name: "FeatureDaily",    targets: ["FeatureDaily"]),
        .library(name: "FeatureTasks",    targets: ["FeatureTasks"]),
        .library(name: "FeatureSummary",  targets: ["FeatureSummary"]),
        .library(name: "FeatureHome",     targets: ["FeatureHome"]),
    ],
    targets: [
        // ── Core ─────────────────────────────────────────────────────
        .target(
            name: "CoreModel"
            // 依存なし: 純粋なSwift struct群
        ),
        .target(
            name: "CoreCommon"
            // 依存なし: APIError, DateExtensions等
        ),
        .target(
            name: "CoreNetwork",
            dependencies: ["CoreModel"]
            // APIClient は tokenProvider: () -> String? クロージャで受け取る
            // → CoreDataStore（KeychainStore）を import しないため依存なし
            // APIEndpoint は struct + static factory（enum は使わない）
        ),
        .target(
            name: "CoreDataStore"
            // 依存なし: KeychainStore（Security.framework はリンクフラグで追加）
        ),
        .target(
            name: "CoreDomain",
            dependencies: ["CoreModel", "CoreCommon"]
            // Repositoryプロトコル + UseCase実装（純粋Swift、UI非依存）
        ),
        .target(
            name: "CoreData",
            dependencies: ["CoreDomain", "CoreNetwork", "CoreDataStore"]
            // Repository実装 + Mapper
            // Appターゲットからのみ依存される（Feature群は依存しない）
        ),
        .target(
            name: "CoreUI",
            dependencies: ["CoreModel"]
            // 共通UIコンポーネント + AppTheme
        ),

        // ── Features ─────────────────────────────────────────────────
        .target(
            name: "FeatureSplash",
            dependencies: ["CoreDomain", "CoreUI"]
        ),
        .target(
            name: "FeatureAuth",
            dependencies: ["CoreDomain", "CoreUI"]
        ),
        .target(
            name: "FeatureChildren",
            dependencies: ["CoreDomain", "CoreUI"]
        ),
        .target(
            name: "FeatureDaily",
            dependencies: ["CoreDomain", "CoreUI"]
        ),
        .target(
            name: "FeatureTasks",
            dependencies: ["CoreDomain", "CoreUI"]
        ),
        .target(
            name: "FeatureSummary",
            dependencies: ["CoreDomain", "CoreUI", "FeatureDaily"]
            // SummaryからDailyDetailへ遷移するため FeatureDaily に依存
        ),
        .target(
            name: "FeatureHome",
            dependencies: [
                "CoreDomain", "CoreUI",
                "FeatureDaily", "FeatureTasks", "FeatureSummary",
            ]
            // ホームはタブコンテナとしてFeatureを組み合わせる
        ),

        // ── Tests ────────────────────────────────────────────────────
        .testTarget(name: "CoreNetworkTests",  dependencies: ["CoreNetwork"]),
        .testTarget(name: "CoreDataTests",     dependencies: ["CoreData"]),
        .testTarget(name: "CoreDomainTests",   dependencies: ["CoreDomain"]),
        .testTarget(name: "FeatureAuthTests",  dependencies: ["FeatureAuth"]),
        .testTarget(name: "FeatureDailyTests", dependencies: ["FeatureDaily"]),
        .testTarget(name: "FeatureTasksTests", dependencies: ["FeatureTasks"]),
        .testTarget(name: "FeatureSummaryTests", dependencies: ["FeatureSummary"]),
    ]
)
```

---

## モジュール依存グラフ

```
App（Xcodeターゲット）
├── CoreData          ← DI配線のため App のみが依存
├── FeatureSplash
├── FeatureAuth
├── FeatureChildren
└── FeatureHome
      ├── FeatureDaily
      ├── FeatureTasks
      └── FeatureSummary
            └── FeatureDaily（再利用）

各 Feature ←── CoreDomain ←── CoreModel
                    ↑               ↑
               CoreCommon      CoreNetwork ←── CoreModel

CoreData ←── CoreDomain + CoreNetwork + CoreDataStore
CoreUI   ←── CoreModel
```

**禁止依存（サイクル防止）:**
- Feature → CoreData（実装詳細への直接依存禁止）
- Feature → Feature（FeatureHome→FeatureDaily等、ホスト役のみ許可）
- CoreDomain → CoreNetwork（Domain層はネットワークを知らない）

---

## モジュール別ファイル構成

### CoreModel

```
Sources/CoreModel/
├── User.swift
├── Child.swift
├── Task.swift
├── DailyView.swift
├── DailyTask.swift
├── DailyItem.swift
├── CalendarSummary.swift   # CalendarDay, CalendarStatus も同ファイル
└── Summary.swift           # SummaryByDay, SummaryBySubject, SummaryByTask も同ファイル
```

### CoreCommon

```
Sources/CoreCommon/
├── APIError.swift          # enum APIError: Error
└── DateExtensions.swift    # Date ↔ "yyyy-MM-dd" 変換
```

### CoreNetwork

```
Sources/CoreNetwork/
├── APIClient.swift         # URLSession ラッパー（tokenはinitで注入）
├── APIEndpoint.swift       # enum でパス・クエリを定義
├── DTO/
│   ├── AuthDTO.swift       # TokenDTO, SignupDTO, MeDTO
│   ├── ChildDTO.swift
│   ├── TaskDTO.swift
│   ├── DailyDTO.swift      # DailyViewDTO, DailyTaskDTO, DailyLogDTO 等
│   └── SummaryDTO.swift    # CalendarSummaryDTO, SummaryDTO 等
└── Requests/
    ├── AuthRequest.swift   # LoginRequest, SignupRequest
    ├── ChildRequest.swift  # CreateChildRequest, UpdateChildRequest
    ├── TaskRequest.swift   # CreateTaskRequest, UpdateTaskRequest, ReorderRequest
    └── DailyRequest.swift  # UpdateDailyRequest, DailyItemRequest
```

### CoreDataStore

```
Sources/CoreDataStore/
└── KeychainStore.swift     # SecItemAdd / SecItemCopyMatching / SecItemDelete
```

> **注意:** `Security.framework` は Xcode プロジェクトで自動リンクされるが、
> SPMターゲットでは `linkerSettings: [.linkedFramework("Security")]` を追加する。

### CoreDomain

```
Sources/CoreDomain/
├── Repositories/
│   ├── AuthRepositoryProtocol.swift
│   ├── ChildrenRepositoryProtocol.swift
│   ├── TaskRepositoryProtocol.swift
│   ├── DailyRepositoryProtocol.swift
│   └── SummaryRepositoryProtocol.swift
└── UseCases/
    ├── Auth/
    │   ├── LoginUseCase.swift
    │   ├── SignupUseCase.swift
    │   ├── GetMeUseCase.swift
    │   ├── LogoutUseCase.swift
    │   └── DeleteAccountUseCase.swift
    ├── Children/
    │   ├── GetChildrenUseCase.swift
    │   ├── CreateChildUseCase.swift
    │   ├── UpdateChildUseCase.swift
    │   └── DeleteChildUseCase.swift
    ├── Tasks/
    │   ├── GetTasksUseCase.swift
    │   ├── CreateTaskUseCase.swift
    │   ├── UpdateTaskUseCase.swift
    │   ├── ArchiveTaskUseCase.swift
    │   └── ReorderTasksUseCase.swift
    ├── Daily/
    │   ├── GetDailyViewUseCase.swift
    │   └── UpdateDailyLogUseCase.swift
    └── Summary/
        ├── GetCalendarSummaryUseCase.swift
        └── GetSummaryUseCase.swift
```

UseCase はプロトコルに依存するため、CoreDomain 内に実装まで含める（Android と同様）:

```swift
// 例: LoginUseCase.swift
public struct LoginUseCase {
    private let repository: AuthRepositoryProtocol

    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(email: String, password: String) async throws {
        try await repository.login(email: email, password: password)
    }
}
```

### CoreData

```
Sources/CoreData/
├── Repositories/
│   ├── AuthRepositoryImpl.swift
│   ├── ChildrenRepositoryImpl.swift
│   ├── TaskRepositoryImpl.swift
│   ├── DailyRepositoryImpl.swift
│   └── SummaryRepositoryImpl.swift
└── Mappers/
    ├── ChildMapper.swift     # ChildDTO → Child
    ├── TaskMapper.swift      # TaskDTO → Task
    ├── DailyMapper.swift     # DailyViewDTO → DailyView 等
    └── SummaryMapper.swift   # CalendarSummaryDTO → CalendarSummary 等
```

### CoreUI

```
Sources/CoreUI/
├── Theme/
│   ├── AppTheme.swift        # Color, Font 定数
│   └── CalendarColors.swift  # GREEN/YELLOW/RED/WHITEの色定義
└── Components/
    ├── ToastView.swift       # 保存成功等のオーバーレイトースト
    ├── LoadingOverlay.swift  # ローディング中の半透明オーバーレイ
    └── DayChipView.swift     # 曜日選択チップ（TasksFeatureで使用）
```

### Feature モジュール構成（各共通パターン）

```
Sources/FeatureXxx/
├── XxxView.swift
├── XxxViewModel.swift      # @Observable final class
├── XxxUiState.swift        # UiStateはViewModelのプロパティとして分散 or 専用型
└── Components/             # 画面内専用のサブビュー（他モジュール非公開）
    └── XxxRowView.swift
```

---

## アクセス制御方針

| スコープ | 対象 |
|---|---|
| `public` | モデル型、Repositoryプロトコル、UseCase、View型、ViewModel型 |
| `internal`（省略可） | 各モジュール内の実装詳細（Mapper, DTO変換, コンポーネント等） |
| `package`（Swift 5.9+） | 同パッケージ内モジュール間の共有（必要に応じて） |

---

## Xcode プロジェクトとの統合

1. Xcodeプロジェクトで「Add Local Package...」→ `learnappios/` ルートを選択
2. アプリターゲット（`learnappios`）の "Link Binary With Libraries" に以下を追加:
   - `CoreData`（DI配線用）
   - `FeatureSplash`, `FeatureAuth`, `FeatureChildren`, `FeatureHome`
3. アプリターゲットのソース（`learnappios/` ディレクトリ）:

```swift
// learnappios/AppDependencies.swift
import CoreData          // Repository実装
import CoreDataStore     // KeychainStore
import CoreNetwork       // APIClient

public final class AppDependencies {
    public let keychain = KeychainStore()
    public lazy var apiClient = APIClient(
        baseURL: URL(string: Env.apiBaseURL)!,
        tokenProvider: { [weak self] in self?.keychain.load() }
    )
    public lazy var authRepo: AuthRepositoryProtocol    = AuthRepositoryImpl(apiClient: apiClient, keychain: keychain)
    public lazy var childrenRepo: ChildrenRepositoryProtocol = ChildrenRepositoryImpl(apiClient: apiClient)
    public lazy var taskRepo: TaskRepositoryProtocol    = TaskRepositoryImpl(apiClient: apiClient)
    public lazy var dailyRepo: DailyRepositoryProtocol  = DailyRepositoryImpl(apiClient: apiClient)
    public lazy var summaryRepo: SummaryRepositoryProtocol = SummaryRepositoryImpl(apiClient: apiClient)
}
```

---

## Android ↔ iOS モジュール対応表

| Android モジュール | iOS SPM ターゲット | 備考 |
|---|---|---|
| `core:model` | `CoreModel` | 完全対応 |
| `core:common` | `CoreCommon` | `Result` は Swift 標準にあるため `APIError` 等のみ |
| `core:network` | `CoreNetwork` | Retrofit → URLSession |
| `core:datastore` | `CoreDataStore` | DataStore(Proto) → Keychain |
| `core:domain` | `CoreDomain` | Repository protocol + UseCase（同構成） |
| `core:data` | `CoreData` | Repository実装 + Mapper（同構成） |
| `core:ui` | `CoreUI` | Material3 Theme → SwiftUI Theme |
| `feature:splash` | `FeatureSplash` | 完全対応 |
| `feature:auth` | `FeatureAuth` | 完全対応 |
| `feature:children` | `FeatureChildren` | 完全対応 |
| `feature:home` | `FeatureHome` | 完全対応 |
| `feature:daily` | `FeatureDaily` | 完全対応 |
| `feature:tasks` | `FeatureTasks` | 完全対応 |
| `feature:summary` | `FeatureSummary` | 完全対応 |
| `app` | `learnappios`（Xcodeターゲット） | DI配線・ナビゲーションルート |

---

## テスト戦略

| ターゲット | テスト種別 | 内容 |
|---|---|---|
| `CoreNetworkTests` | ユニット | DTO の JSONDecoding 検証 |
| `CoreDataTests` | ユニット | MockAPIClient を使った Repository実装テスト |
| `CoreDomainTests` | ユニット | Mock Repository を使った UseCase テスト |
| `FeatureAuthTests` | ユニット + Preview | ViewModel の状態遷移、Viewのプレビュー確認 |
| `FeatureDailyTests` | ユニット | DailyViewModel の計算ロジック（合計分等） |
| `FeatureTasksTests` | ユニット | daysMask ビット演算ロジック |
| `FeatureSummaryTests` | ユニット | `formatMinutes` 等の変換ロジック |

各テストターゲットは **実装モジュールのみ**に依存し、他Featureへの依存は持たない。

---

## ビルド時間の最適化効果

SPMマルチモジュール化により期待できる効果:

- **並列コンパイル:** 依存関係のないモジュール（CoreModel / CoreCommon / CoreDataStore 等）は並列ビルド
- **差分ビルド:** 変更のあったモジュールとその依存先のみ再ビルド
- **インクリメンタルビルド:** Feature単位の変更がCoreには波及しない
- **型チェック分離:** CoreDomain変更時にFeature群のViewは再コンパイルされない（プロトコル境界）
