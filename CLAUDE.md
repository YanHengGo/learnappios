# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

子どもの学習管理iOSアプリ。保護者が子どもの学習タスクを登録・記録・集計できる。
Androidアプリ（`/Users/yanheng/dev/learnapp`）と同一バックエンドAPIを共有する。

- **最小iOS**: iOS 17（`@Observable` マクロ使用のため）
- **外部パッケージ**: ゼロ（URLSession / Keychain / SwiftUI は標準ライブラリのみ）

## ビルド・テスト

Xcodeで開発するプロジェクト。CLIでの操作は `xcodebuild` を使用。

```bash
# ビルド
xcodebuild -project learnappios.xcodeproj -scheme learnappios -sdk iphonesimulator build

# テスト（全体）
xcodebuild test -project learnappios.xcodeproj -scheme learnappios -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16'

# SPMテストのみ（特定ターゲット）
xcodebuild test -project learnappios.xcodeproj -scheme learnappios -only-testing:CoreNetworkTests
```

## アーキテクチャ

### モジュール構成（SPMローカルパッケージ）

`Package.swift` でルートに定義。`Sources/` 以下がSPMライブラリターゲット、`learnappios/` がXcodeアプリターゲット（App層）。

```
App（learnappios/）
├── AppDependencies.swift   ← DIコンテナ（全Repositoryとユースケースを生成・ワイヤリング）
├── AppNavigator.swift      ← ルートナビゲーション状態 (@Observable)
└── learnappiosApp.swift    ← @main

Sources/
├── CoreModel/      ← ドメインモデル（依存なし）
├── CoreCommon/     ← APIError, DateExtensions（依存なし）
├── CoreNetwork/    ← APIClient + APIEndpoint + DTO（CoreModelに依存）
├── CoreDataStore/  ← KeychainStore（Security.framework、依存なし）
├── CoreDomain/     ← Repositoryプロトコル + UseCase実装（CoreModel, CoreCommonに依存）
├── CoreData/       ← Repository実装 + Mapper（CoreDomain, CoreNetwork, CoreDataStoreに依存）
├── CoreUI/         ← 共通コンポーネント + テーマ（CoreModelに依存）
├── FeatureSplash/
├── FeatureAuth/
├── FeatureChildren/
├── FeatureDaily/
├── FeatureTasks/
├── FeatureSummary/ ← FeatureDailyにも依存（日付タップでDailyViewへ遷移）
└── FeatureHome/    ← FeatureDaily, FeatureTasks, FeatureSummaryを統合するTabView
```

### 禁止依存（サイクル防止）

- Feature → CoreData（実装詳細への直接依存禁止）
- CoreDomain → CoreNetwork（Domain層はネットワークを知らない）
- Feature間の依存はFeatureHome→各Feature、FeatureSummary→FeatureDailyのみ許可

### データフロー

```
View → ViewModel(@Observable) → UseCase(CoreDomain) → Repository protocol → Repository impl(CoreData) + APIClient → Backend API
```

- ViewModel は UseCase のみを依存として受け取る（Repository実装には直接依存しない）
- エラーは `APIError` でラップし、ViewModel の `errorMessage: String?` に伝搬
- 401エラーは `AppNavigator.root = .auth` へリセット（自動ログアウト）

### ナビゲーション

`AppNavigator`（`@Observable`）が全画面遷移を一元管理：

```
.splash → .auth → .children → .home(childId:)
                                ├── tab: .daily
                                ├── tab: .tasks
                                └── tab: .summary → push: .dailyDetail(date:)
```

### DIパターン

`AppDependencies`（App層のみ）が全Repository実装とUseCaseを`lazy var`で生成。ViewModelのinitにUseCaseを手動注入。ViewはViewModelを`@State`で保持。

```swift
// View側
@State private var viewModel: ChildrenViewModel

init(viewModel: ChildrenViewModel) {
    _viewModel = State(initialValue: viewModel)
}
```

### APIClient設計

- `APIEndpoint`（struct + static factory）がHTTPリクエストを宣言（enumは使わない）
- `APIClient`はトークンを`tokenProvider: () -> String?`クロージャで受け取る（CoreDataStoreへの直接依存を排除）
- JSON: encode時は`convertToSnakeCase`、decode時は`convertFromSnakeCase`

### KeychainStore

`Security.framework`使用。SPMターゲットに`linkerSettings: [.linkedFramework("Security")]`が必要。

### 曜日ビットマスク

`daysMask: Int`（bit0=日、bit1=月、...、bit6=土）。Androidと同一ロジック。

```swift
extension Int {
    func hasDayBit(_ dayIndex: Int) -> Bool { (self & (1 << dayIndex)) != 0 }
    func toggleDayBit(_ dayIndex: Int) -> Int { self ^ (1 << dayIndex) }
}
```

## 各モジュールのファイルパターン

### Feature モジュール

```
Sources/FeatureXxx/
├── XxxView.swift          ← struct XxxView: View
├── XxxViewModel.swift     ← @Observable final class XxxViewModel
└── Components/            ← 画面内専用サブビュー（他モジュール非公開）
```

### UseCase（CoreDomain）

```swift
public struct LoginUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    public func execute(email: String, password: String) async throws { ... }
}
```

### Repository実装（CoreData）

```swift
// DTO → ドメインモデル変換はMapper（extension）で行う
extension ChildDTO {
    func toModel() -> Child { Child(id: id, name: name, ...) }
}
```

## アクセス制御

| `public` | モデル型、Repositoryプロトコル、UseCase、View型、ViewModel型 |
|---|---|
| `internal`（省略） | 各モジュール内の実装詳細（Mapper, DTO変換, コンポーネント等） |
