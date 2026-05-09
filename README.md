# learnappios

子どもの学習を管理するiOSアプリケーションです。複数の子どもの学習タスク・日々の記録・成績サマリーを一元管理できます。

[Android版](https://github.com/YanHengGo/learnapp) と同一バックエンドAPIを共有しています。

## 機能

- **認証** — サインアップ / ログイン / ログアウト
- **子ども管理** — 複数の子どもの登録・編集・削除、切り替え
- **タスク管理** — 曜日・期間指定のタスク作成・編集・アーカイブ・並び替え（ドラッグ＆ドロップ）
- **日々の記録** — 日別の学習ログ記録・チェック
- **集計** — カレンダー形式の学習成績サマリー・科目別統計
- **アカウント削除** — App Store 審査要件に対応したアカウント完全削除機能
- **プライバシーポリシー** — ログイン前・ログイン後どちらからでも閲覧可能

## スクリーンショット

<!-- スクリーンショットを追加してください -->

## 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | Swift |
| UI | SwiftUI |
| 状態管理 | `@Observable`（iOS 17+） |
| ナビゲーション | `AppNavigator`（`@Observable`） |
| ネットワーク | URLSession |
| ローカルストレージ | Keychain（Security.framework） |
| 非同期処理 | Swift Concurrency（async/await） |
| 外部ライブラリ | なし（ゼロ依存） |

## アーキテクチャ

Clean Architecture + MVVM パターンを採用した SPM マルチモジュール構成です。

```
learnappios（App層）
├── AppDependencies.swift   DIコンテナ（全 Repository・UseCase を生成・ワイヤリング）
├── AppNavigator.swift      ルートナビゲーション状態（@Observable）
└── learnappiosApp.swift    @main

Sources/
├── CoreModel/      ドメインモデル（依存なし）
├── CoreCommon/     APIError, DateExtensions（依存なし）
├── CoreNetwork/    APIClient + APIEndpoint + DTO
├── CoreDataStore/  KeychainStore（Security.framework）
├── CoreDomain/     Repository プロトコル + UseCase 実装
├── CoreData/       Repository 実装 + Mapper
├── CoreUI/         共通コンポーネント + テーマ
├── FeatureSplash/
├── FeatureAuth/
├── FeatureChildren/
├── FeatureDaily/
├── FeatureTasks/
├── FeatureSummary/
└── FeatureHome/    FeatureDaily / FeatureTasks / FeatureSummary を統合する TabView
```

### データフロー

```
View → ViewModel(@Observable) → UseCase(CoreDomain) → Repository protocol → Repository impl(CoreData) → APIClient → Backend API
```

## 動作環境

- iOS 17 以上（`@Observable` マクロ使用のため）
- Xcode 15 以上

## セットアップ

### 1. リポジトリをクローン

```bash
git clone https://github.com/YanHengGo/learnappios.git
cd learnappios
```

### 2. Xcode でプロジェクトを開く

```bash
open learnappios.xcodeproj
```

### 3. ビルド・実行

Xcode でシミュレーターまたは実機を選択してビルドしてください。

CLI でビルドする場合：

```bash
xcodebuild -project learnappios.xcodeproj -scheme learnappios -sdk iphonesimulator build
```

## API

バックエンドAPIとの通信には JWT 認証を使用します。

| メソッド | エンドポイント | 概要 |
|---|---|---|
| POST | `/api/v1/auth/signup` | ユーザー登録 |
| POST | `/api/v1/auth/login` | ログイン |
| GET | `/api/v1/me` | ログインユーザー情報取得 |
| DELETE | `/api/v1/me` | アカウント削除 |
| GET | `/api/v1/children` | 子ども一覧取得 |
| POST | `/api/v1/children` | 子ども作成 |
| PUT | `/api/v1/children/{id}` | 子ども更新 |
| DELETE | `/api/v1/children/{id}` | 子ども削除 |
| GET | `/api/v1/children/{childId}/tasks` | タスク一覧取得 |
| POST | `/api/v1/children/{childId}/tasks` | タスク作成 |
| PUT | `/api/v1/children/{childId}/tasks/{taskId}` | タスク更新 |
| PUT | `/api/v1/children/{childId}/tasks/reorder` | タスク並び替え |
| PATCH | `/api/v1/tasks/{taskId}` | タスクアーカイブ |
| GET | `/api/v1/children/{childId}/daily-view` | 日次ビュー取得 |
| PUT | `/api/v1/children/{childId}/daily` | 日次ログ更新 |
| GET | `/api/v1/children/{childId}/calendar-summary` | カレンダーサマリー取得 |
| GET | `/api/v1/children/{childId}/summary` | 学習サマリー取得 |

## テスト

```bash
# 全テスト実行
xcodebuild test -project learnappios.xcodeproj -scheme learnappios -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16'

# SPM ターゲット単体
xcodebuild test -project learnappios.xcodeproj -scheme learnappios -only-testing:CoreNetworkTests
```

## 設計ドキュメント

設計資料は `design/` フォルダに格納しています。

| ファイル | 内容 |
|---|---|
| `phase1.md` | 基盤層設計（全 SPM モジュールの骨格） |
| `phase2.md` | 認証フロー設計 |
| `phase3.md` | 子ども管理画面設計 |
| `phase4.md` | 日々の記録画面設計 |
| `phase5.md` | タスク管理画面設計 |
| `phase6.md` | 集計画面設計 |
| `phase7.md` | ホーム統合設計（子ども切り替え・ログアウト） |

## ライセンス

MIT
