# Phase 1 設計書: 基盤層（SPMモジュール骨格）

## 概要

Phase 1 では実装の土台となる全モジュールの骨格を作る。
Feature は一切実装しない。ビルドが通ること・型が揃っていることがゴール。

---

## Android調査で判明した修正点

以降の設計には以下の修正を反映済み（`api.md` の記述と異なる）。

| 項目 | api.md の誤り | Android実態 |
|---|---|---|
| `SignupDTO` | `{ token: String }` | `{ user: { id, email } }` トークンなし |
| `ReorderRequest` | `{ ids: [String] }` | `{ orders: [{ task_id, sort_order }] }` |
| signup フロー | signup でトークン取得 | signup 後に login を別途呼ぶ |

---

## Step 1: Package.swift 作成 + Xcode 登録

### ファイル配置

```
learnappios/                         ← リポジトリルート
├── Package.swift                    ← ここに作成
├── Sources/
│   ├── CoreModel/
│   ├── CoreCommon/
│   ├── CoreNetwork/
│   ├── CoreDataStore/
│   ├── CoreDomain/
│   ├── CoreData/
│   ├── CoreUI/
│   ├── FeatureSplash/
│   ├── FeatureAuth/
│   ├── FeatureChildren/
│   ├── FeatureDaily/
│   ├── FeatureTasks/
│   ├── FeatureSummary/
│   └── FeatureHome/
├── Tests/
│   ├── CoreNetworkTests/
│   ├── CoreDataTests/
│   ├── CoreDomainTests/
│   └── FeatureAuthTests/
└── learnappios/                     ← 既存 Xcode アプリターゲット
```

### Package.swift

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
        // Core
        .target(name: "CoreModel"),
        .target(name: "CoreCommon"),
        .target(name: "CoreNetwork",   dependencies: ["CoreModel", "CoreCommon"]),
        .target(
            name: "CoreDataStore",
            linkerSettings: [.linkedFramework("Security")]
        ),
        .target(name: "CoreDomain",    dependencies: ["CoreModel", "CoreCommon"]),
        .target(name: "CoreData",      dependencies: ["CoreDomain", "CoreNetwork", "CoreDataStore"]),
        .target(name: "CoreUI",        dependencies: ["CoreModel"]),
        // Features
        .target(name: "FeatureSplash",   dependencies: ["CoreDomain", "CoreUI"]),
        .target(name: "FeatureAuth",     dependencies: ["CoreDomain", "CoreUI"]),
        .target(name: "FeatureChildren", dependencies: ["CoreDomain", "CoreUI"]),
        .target(name: "FeatureDaily",    dependencies: ["CoreDomain", "CoreUI"]),
        .target(name: "FeatureTasks",    dependencies: ["CoreDomain", "CoreUI"]),
        .target(name: "FeatureSummary",  dependencies: ["CoreDomain", "CoreUI", "FeatureDaily"]),
        .target(name: "FeatureHome",     dependencies: [
            "CoreDomain", "CoreUI",
            "FeatureDaily", "FeatureTasks", "FeatureSummary",
        ]),
        // Tests
        .testTarget(name: "CoreNetworkTests",  dependencies: ["CoreNetwork"]),
        .testTarget(name: "CoreDataTests",     dependencies: ["CoreData"]),
        .testTarget(name: "CoreDomainTests",   dependencies: ["CoreDomain"]),
        .testTarget(name: "FeatureAuthTests",  dependencies: ["FeatureAuth"]),
    ]
)
```

> **注意:** `CoreNetwork` は `CoreCommon` に依存追加（`APIError` を参照するため）

### Xcode への登録手順

1. `learnappios.xcodeproj` を Xcode で開く
2. **File → Add Package Dependencies...** → 「Add Local...」
3. `learnappios/`（`Package.swift` があるディレクトリ）を選択
4. アプリターゲット `learnappios` の **Link Binary With Libraries** に追加:
   - `CoreData`（DIコンテナで Repository 実装を生成するため）
   - `FeatureSplash`, `FeatureAuth`, `FeatureChildren`, `FeatureHome`

---

## Step 2: CoreModel

**パス:** `Sources/CoreModel/`
**依存:** なし
**Android対応:** `core:model`

### ファイル一覧

```
Sources/CoreModel/
├── User.swift
├── Child.swift
├── Task.swift
├── DailyView.swift
├── DailyTask.swift
├── DailyItem.swift
├── CalendarSummary.swift
└── Summary.swift
```

### 全型定義

```swift
// User.swift
public struct User: Equatable {
    public let id: String
    public let email: String
    public let displayName: String?
    public let avatarUrl: String?
    public let provider: String

    public init(id: String, email: String, displayName: String?,
                avatarUrl: String?, provider: String) { ... }
}

// Child.swift
public struct Child: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let grade: String?
    public let isActive: Bool

    public init(id: String, name: String, grade: String?, isActive: Bool) { ... }
}

// Task.swift
public struct Task: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String?
    public let subject: String
    public let defaultMinutes: Int
    public let daysMask: Int           // bit0=日,bit1=月...bit6=土
    public let isArchived: Bool
    public let startDate: String?      // "yyyy-MM-dd" or nil
    public let endDate: String?        // "yyyy-MM-dd" or nil
    public let sortOrder: Int

    public init(...) { ... }
}

// DailyView.swift
public struct DailyView: Equatable {
    public let date: String            // "yyyy-MM-dd"
    public let weekday: String         // "月曜日" 等（サーバーが返す文字列）
    public let tasks: [DailyTask]

    public init(date: String, weekday: String, tasks: [DailyTask]) { ... }
}

// DailyTask.swift
public struct DailyTask: Identifiable, Equatable {
    public var id: String { taskId }
    public let taskId: String
    public let name: String
    public let subject: String
    public let defaultMinutes: Int
    public let daysMask: Int
    public let isDone: Bool
    public let minutes: Int

    public init(...) { ... }
}

// DailyItem.swift  （保存リクエスト用の最小モデル）
public struct DailyItem: Equatable {
    public let taskId: String
    public let minutes: Int

    public init(taskId: String, minutes: Int) { ... }
}

// CalendarSummary.swift
public struct CalendarSummary: Equatable {
    public let from: String
    public let to: String
    public let days: [CalendarDay]

    public init(from: String, to: String, days: [CalendarDay]) { ... }
}

public struct CalendarDay: Equatable {
    public let date: String
    public let status: CalendarStatus
    public let total: Int
    public let done: Int

    public init(date: String, status: CalendarStatus, total: Int, done: Int) { ... }
}

public enum CalendarStatus: String {
    case green  = "GREEN"
    case yellow = "YELLOW"
    case red    = "RED"
    case white  = "WHITE"
}

// Summary.swift
public struct Summary: Equatable {
    public let from: String
    public let to: String
    public let totalMinutes: Int
    public let byDay: [SummaryByDay]
    public let bySubject: [SummaryBySubject]
    public let byTask: [SummaryByTask]

    public init(...) { ... }
}

public struct SummaryByDay: Equatable {
    public let date: String
    public let minutes: Int
    public init(date: String, minutes: Int) { ... }
}

public struct SummaryBySubject: Equatable {
    public let subject: String
    public let minutes: Int
    public init(subject: String, minutes: Int) { ... }
}

public struct SummaryByTask: Equatable {
    public let taskId: String
    public let name: String
    public let subject: String
    public let minutes: Int
    public init(...) { ... }
}
```

---

## Step 3: CoreCommon

**パス:** `Sources/CoreCommon/`
**依存:** なし
**Android対応:** `core:common`（`ThrowableExt.kt`, `Result.kt`）

> Swift は標準で `Result<T, E>` を持つため、Android の `sealed class Result` は不要。

### ファイル一覧

```
Sources/CoreCommon/
├── APIError.swift
└── YearMonth.swift
```

### APIError.swift

Android の `ThrowableExt.toErrorMessage()` に相当するエラーメッセージを内包する。

```swift
// Sources/CoreCommon/APIError.swift

public enum APIError: Error, LocalizedError, Equatable {
    case httpError(statusCode: Int)
    case decodingError                  // デコード失敗（詳細はログ）
    case networkError                   // ネットワーク接続不可
    case unauthorized                   // 401: AppNavigator.root = .auth へリセット
    case unknown

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "セッションが切れました。再度ログインしてください。"
        case .httpError(let code) where code >= 500:
            return "サーバーエラーが発生しました。しばらくしてからお試しください。"
        case .httpError:
            return "リクエストに失敗しました。"
        case .networkError:
            return "ネットワークに接続できません。接続を確認してください。"
        case .decodingError:
            return "データの読み込みに失敗しました。"
        case .unknown:
            return "不明なエラーが発生しました。"
        }
    }
}
```

### YearMonth.swift

Android の `java.time.YearMonth` 相当。`SummaryViewModel` で月ナビゲーションに使用。

```swift
// Sources/CoreCommon/YearMonth.swift

public struct YearMonth: Equatable, Comparable {
    public let year: Int
    public let month: Int              // 1–12

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    /// 今月
    public static var now: YearMonth {
        let c = Calendar.current
        let d = Date()
        return YearMonth(year: c.component(.year, from: d),
                         month: c.component(.month, from: d))
    }

    /// 月初日を "yyyy-MM-dd" で返す（Android: yearMonth.atDay(1).toString()）
    public func firstDayString() -> String {
        String(format: "%04d-%02d-01", year, month)
    }

    /// 月末日を "yyyy-MM-dd" で返す（Android: yearMonth.atEndOfMonth().toString()）
    public func lastDayString() -> String {
        var components = DateComponents(year: year, month: month + 1, day: 0)
        let lastDay = Calendar.current.date(from: components)!
        let day = Calendar.current.component(.day, from: lastDay)
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// 月を加算（Android: yearMonth.plusMonths(n) / minusMonths(n)）
    public func adding(months: Int) -> YearMonth {
        var m = month - 1 + months
        var y = year + m / 12
        m = m % 12
        if m < 0 { m += 12; y -= 1 }
        return YearMonth(year: y, month: m + 1)
    }

    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        lhs.year != rhs.year ? lhs.year < rhs.year : lhs.month < rhs.month
    }
}
```

---

## Step 4: CoreNetwork

**パス:** `Sources/CoreNetwork/`
**依存:** `CoreModel`, `CoreCommon`（`APIError` 参照）
**Android対応:** `core:network`

### ファイル一覧

```
Sources/CoreNetwork/
├── HTTPMethod.swift
├── APIEndpoint.swift
├── APIClient.swift
├── DTO/
│   ├── AuthDTO.swift
│   ├── ChildDTO.swift
│   ├── TaskDTO.swift
│   ├── DailyDTO.swift
│   └── SummaryDTO.swift
└── Requests/
    ├── AuthRequest.swift
    ├── ChildRequest.swift
    ├── TaskRequest.swift
    └── DailyRequest.swift
```

### HTTPMethod.swift

```swift
public enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}
```

### APIEndpoint.swift

Android の `LearnApiService.kt` のアノテーション（`@POST`, `@GET` 等）に相当。
struct + static factory で全エンドポイントを宣言する。

```swift
public struct APIEndpoint {
    public let method: HTTPMethod
    public let path: String
    public let queryItems: [URLQueryItem]?
    public let body: (any Encodable)?

    public init(method: HTTPMethod, path: String,
                queryItems: [URLQueryItem]? = nil,
                body: (any Encodable)? = nil) { ... }
}

// ── Auth ──────────────────────────────────────────────────────────────
public extension APIEndpoint {
    static func login(email: String, password: String) -> APIEndpoint {
        .init(method: .post, path: "/api/v1/auth/login",
              body: LoginRequest(email: email, password: password))
    }
    static func signup(email: String, password: String) -> APIEndpoint {
        .init(method: .post, path: "/api/v1/auth/signup",
              body: SignupRequest(email: email, password: password))
    }
    static var me: APIEndpoint {
        .init(method: .get, path: "/api/v1/me")
    }
    static var deleteMe: APIEndpoint {
        .init(method: .delete, path: "/api/v1/me")
    }
}

// ── Children ──────────────────────────────────────────────────────────
public extension APIEndpoint {
    static var children: APIEndpoint {
        .init(method: .get, path: "/api/v1/children")
    }
    static func createChild(_ req: CreateChildRequest) -> APIEndpoint {
        .init(method: .post, path: "/api/v1/children", body: req)
    }
    static func updateChild(id: String, _ req: UpdateChildRequest) -> APIEndpoint {
        .init(method: .put, path: "/api/v1/children/\(id)", body: req)
    }
    static func deleteChild(id: String) -> APIEndpoint {
        .init(method: .delete, path: "/api/v1/children/\(id)")
    }
}

// ── Tasks ─────────────────────────────────────────────────────────────
public extension APIEndpoint {
    static func tasks(childId: String) -> APIEndpoint {
        .init(method: .get, path: "/api/v1/children/\(childId)/tasks",
              queryItems: [.init(name: "archived", value: "false")])
    }
    static func createTask(childId: String, _ req: CreateTaskRequest) -> APIEndpoint {
        .init(method: .post, path: "/api/v1/children/\(childId)/tasks", body: req)
    }
    static func updateTask(childId: String, taskId: String, _ req: UpdateTaskRequest) -> APIEndpoint {
        .init(method: .put, path: "/api/v1/children/\(childId)/tasks/\(taskId)", body: req)
    }
    static func reorderTasks(childId: String, _ req: ReorderRequest) -> APIEndpoint {
        .init(method: .put, path: "/api/v1/children/\(childId)/tasks/reorder", body: req)
    }
    static func archiveTask(taskId: String) -> APIEndpoint {
        .init(method: .patch, path: "/api/v1/tasks/\(taskId)",
              body: ArchiveTaskRequest(isArchived: true))
    }
}

// ── Daily ─────────────────────────────────────────────────────────────
public extension APIEndpoint {
    static func dailyView(childId: String, date: String) -> APIEndpoint {
        .init(method: .get, path: "/api/v1/children/\(childId)/daily-view",
              queryItems: [.init(name: "date", value: date)])
    }
    static func updateDaily(childId: String, date: String,
                            _ req: UpdateDailyRequest) -> APIEndpoint {
        .init(method: .put, path: "/api/v1/children/\(childId)/daily",
              queryItems: [.init(name: "date", value: date)], body: req)
    }
}

// ── Summary ───────────────────────────────────────────────────────────
public extension APIEndpoint {
    static func calendarSummary(childId: String, from: String, to: String) -> APIEndpoint {
        .init(method: .get,
              path: "/api/v1/children/\(childId)/calendar-summary",
              queryItems: [.init(name: "from", value: from),
                           .init(name: "to", value: to)])
    }
    static func summary(childId: String, from: String, to: String) -> APIEndpoint {
        .init(method: .get,
              path: "/api/v1/children/\(childId)/summary",
              queryItems: [.init(name: "from", value: from),
                           .init(name: "to", value: to)])
    }
}
```

### APIClient.swift

```swift
public final class APIClient {
    private let baseURL: URL
    private let tokenProvider: () -> String?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let session: URLSession

    public init(baseURL: URL,
                tokenProvider: @escaping () -> String?,
                session: URLSession = .shared) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.session = session

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    /// レスポンスボディあり
    public func send<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let req = try buildRequest(endpoint)
        let (data, response) = try await session.data(for: req)
        try validate(response)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    /// レスポンスボディなし（204 等）
    public func sendEmpty(_ endpoint: APIEndpoint) async throws {
        let req = try buildRequest(endpoint)
        let (_, response) = try await session.data(for: req)
        try validate(response)
    }

    // MARK: - Private

    private func buildRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = endpoint.queryItems

        var req = URLRequest(url: components.url!)
        req.httpMethod = endpoint.method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = tokenProvider() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }
        return req
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }
        switch http.statusCode {
        case 200..<300: return
        case 401:       throw APIError.unauthorized
        default:        throw APIError.httpError(statusCode: http.statusCode)
        }
    }
}

// any Encodable を型消去して JSONEncoder に渡すヘルパー
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: any Encodable) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
```

> `session` をイニシャライザで受け取ることで、テスト時に `MockURLSession` を差し込める。

### DTO定義（Android DTO との対応）

#### AuthDTO.swift

```swift
// Android: TokenDto, SignupDto, MeDto / UserDto

public struct TokenDTO: Decodable {
    public let token: String
}

// signup は token を返さず user を返す（Android 実態に合わせた修正）
public struct SignupDTO: Decodable {
    public let user: SignupUserDTO
}
public struct SignupUserDTO: Decodable {
    public let id: String
    public let email: String
}

public struct MeDTO: Decodable {
    public let user: UserDTO
}
public struct UserDTO: Decodable {
    public let id: String
    public let email: String
    public let displayName: String?
    public let avatarUrl: String?
    public let provider: String
}

// DTO → Model
extension UserDTO {
    func toModel() -> User {
        User(id: id, email: email, displayName: displayName,
             avatarUrl: avatarUrl, provider: provider)
    }
}
```

#### ChildDTO.swift

```swift
// Android: ChildDto
public struct ChildDTO: Decodable {
    public let id: String
    public let name: String
    public let grade: String?
    public let isActive: Bool
}

extension ChildDTO {
    func toModel() -> Child {
        Child(id: id, name: name, grade: grade, isActive: isActive)
    }
}
```

#### TaskDTO.swift

```swift
// Android: TaskDto
public struct TaskDTO: Decodable {
    public let id: String
    public let name: String
    public let description: String?
    public let subject: String
    public let defaultMinutes: Int
    public let daysMask: Int
    public let isArchived: Bool
    public let startDate: String?
    public let endDate: String?
    public let sortOrder: Int
}

extension TaskDTO {
    func toModel() -> Task {
        Task(id: id, name: name, description: description,
             subject: subject, defaultMinutes: defaultMinutes,
             daysMask: daysMask, isArchived: isArchived,
             startDate: startDate, endDate: endDate, sortOrder: sortOrder)
    }
}
```

#### DailyDTO.swift

```swift
// Android: DailyViewDto, DailyTaskDto, DailyLogDto, DailyItemDto, UpdateDailyResponseDto

public struct DailyViewDTO: Decodable {
    public let date: String
    public let weekday: String
    public let tasks: [DailyTaskDTO]
}
public struct DailyTaskDTO: Decodable {
    public let taskId: String
    public let name: String
    public let subject: String
    public let defaultMinutes: Int
    public let daysMask: Int
    public let isDone: Bool
    public let minutes: Int
}
public struct UpdateDailyResponseDTO: Decodable {
    public let date: String
    public let savedCount: Int
}

extension DailyViewDTO {
    func toModel() -> DailyView {
        DailyView(date: date, weekday: weekday,
                  tasks: tasks.map { $0.toModel() })
    }
}
extension DailyTaskDTO {
    func toModel() -> DailyTask {
        DailyTask(taskId: taskId, name: name, subject: subject,
                  defaultMinutes: defaultMinutes, daysMask: daysMask,
                  isDone: isDone, minutes: minutes)
    }
}
```

#### SummaryDTO.swift

```swift
// Android: CalendarSummaryDto, CalendarDayDto, SummaryDto 等

public struct CalendarSummaryDTO: Decodable {
    public let from: String
    public let to: String
    public let days: [CalendarDayDTO]
}
public struct CalendarDayDTO: Decodable {
    public let date: String
    public let status: String           // "GREEN" | "YELLOW" | "RED" | "WHITE"
    public let total: Int
    public let done: Int
}
public struct SummaryDTO: Decodable {
    public let from: String
    public let to: String
    public let totalMinutes: Int
    public let byDay: [SummaryByDayDTO]
    public let bySubject: [SummaryBySubjectDTO]
    public let byTask: [SummaryByTaskDTO]
}
public struct SummaryByDayDTO: Decodable {
    public let date: String
    public let minutes: Int
}
public struct SummaryBySubjectDTO: Decodable {
    public let subject: String
    public let minutes: Int
}
public struct SummaryByTaskDTO: Decodable {
    public let taskId: String
    public let name: String
    public let subject: String
    public let minutes: Int
}

extension CalendarSummaryDTO {
    func toModel() -> CalendarSummary {
        CalendarSummary(from: from, to: to, days: days.map { $0.toModel() })
    }
}
extension CalendarDayDTO {
    func toModel() -> CalendarDay {
        CalendarDay(date: date,
                    status: CalendarStatus(rawValue: status) ?? .white,
                    total: total, done: done)
    }
}
extension SummaryDTO {
    func toModel() -> Summary {
        Summary(from: from, to: to, totalMinutes: totalMinutes,
                byDay: byDay.map { SummaryByDay(date: $0.date, minutes: $0.minutes) },
                bySubject: bySubject.map { SummaryBySubject(subject: $0.subject, minutes: $0.minutes) },
                byTask: byTask.map { SummaryByTask(taskId: $0.taskId, name: $0.name,
                                                   subject: $0.subject, minutes: $0.minutes) })
    }
}
```

### Requestボディ定義

#### AuthRequest.swift

```swift
// Android: LoginRequest, SignupRequest
struct LoginRequest: Encodable {
    let email: String
    let password: String
}
struct SignupRequest: Encodable {
    let email: String
    let password: String
}
```

#### ChildRequest.swift

```swift
// Android: CreateChildRequest, UpdateChildRequest
struct CreateChildRequest: Encodable {
    let name: String
    let grade: String?
}
struct UpdateChildRequest: Encodable {
    let name: String
    let grade: String?
}
```

#### TaskRequest.swift

```swift
// Android: CreateTaskRequest, UpdateTaskRequest, ReorderRequest / ReorderItem
struct CreateTaskRequest: Encodable {
    let name: String
    let description: String?
    let subject: String
    let defaultMinutes: Int
    let daysMask: Int
    let startDate: String?
    let endDate: String?
}
struct UpdateTaskRequest: Encodable {
    let name: String
    let description: String?
    let subject: String
    let defaultMinutes: Int
    let daysMask: Int
    let isArchived: Bool
    let startDate: String?
    let endDate: String?
}
// Android: ReorderRequest { orders: List<ReorderItem { task_id, sort_order }> }
struct ReorderRequest: Encodable {
    let orders: [ReorderItem]
}
struct ReorderItem: Encodable {
    let taskId: String
    let sortOrder: Int
}
// archive 専用パッチボディ
struct ArchiveTaskRequest: Encodable {
    let isArchived: Bool
}
```

#### DailyRequest.swift

```swift
// Android: UpdateDailyRequest, DailyItemRequest
struct UpdateDailyRequest: Encodable {
    let items: [DailyItemRequest]
}
struct DailyItemRequest: Encodable {
    let taskId: String
    let minutes: Int
}
```

---

## Step 5: CoreDataStore

**パス:** `Sources/CoreDataStore/`
**依存:** なし（Security.framework のみ）
**Android対応:** `core:datastore`（DataStore Preferences → Keychain）

### KeychainStore.swift

```swift
// Sources/CoreDataStore/KeychainStore.swift

public final class KeychainStore {
    private let service: String
    private let account: String

    public init(service: String = "com.learn.app",
                account: String = "jwt_token") {
        self.service = service
        self.account = account
    }

    public func save(token: String) {
        let data = Data(token.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    public func load() -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else { return nil }
        return token
    }

    public func delete() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

---

## Step 6: CoreDomain

**パス:** `Sources/CoreDomain/`
**依存:** `CoreModel`, `CoreCommon`
**Android対応:** `core:domain`

### ファイル一覧

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

### Repository プロトコル

Android の `interface` に対応。`suspend fun` → `async throws`。

```swift
// AuthRepositoryProtocol.swift
public protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws  // token は内部で保存
    func signup(email: String, password: String) async throws // token なし → login を別途呼ぶ
    func getMe() async throws -> User
    func logout()                                              // 同期（Keychain削除のみ）
    func deleteAccount() async throws
}

// ChildrenRepositoryProtocol.swift
public protocol ChildrenRepositoryProtocol {
    func getChildren() async throws -> [Child]
    func createChild(name: String, grade: String?) async throws -> Child
    func updateChild(childId: String, name: String, grade: String?) async throws -> Child
    func deleteChild(childId: String) async throws
}

// TaskRepositoryProtocol.swift
public protocol TaskRepositoryProtocol {
    func getTasks(childId: String) async throws -> [Task]
    func createTask(childId: String, task: Task) async throws -> Task
    func updateTask(childId: String, taskId: String, task: Task) async throws -> Task
    func archiveTask(taskId: String) async throws               // PATCH is_archived: true
    func reorderTasks(childId: String,
                      orders: [(taskId: String, sortOrder: Int)]) async throws
}

// DailyRepositoryProtocol.swift
public protocol DailyRepositoryProtocol {
    func getDailyView(childId: String, date: String) async throws -> DailyView
    func updateDailyLog(childId: String, date: String,
                        items: [DailyItem]) async throws -> Int  // savedCount
}

// SummaryRepositoryProtocol.swift
public protocol SummaryRepositoryProtocol {
    func getCalendarSummary(childId: String, from: String, to: String) async throws -> CalendarSummary
    func getSummary(childId: String, from: String, to: String) async throws -> Summary
}
```

### UseCase 実装

Android の `runCatching { ... }` → Swift の `async throws`（エラーはそのまま伝搬）。

UseCase はビジネスロジックの境界。現状は Repository の薄いラッパーだが、
将来的なロジック追加の置き場として維持する。

```swift
// Auth UseCases

public struct LoginUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    public func execute(email: String, password: String) async throws {
        try await repository.login(email: email, password: password)
    }
}

public struct SignupUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    // signup → login の2ステップ（Android の AuthRepositoryImpl と同じ挙動）
    public func execute(email: String, password: String) async throws {
        try await repository.signup(email: email, password: password)
        try await repository.login(email: email, password: password)
    }
}

public struct GetMeUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    public func execute() async throws -> User {
        try await repository.getMe()
    }
}

public struct LogoutUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    public func execute() { repository.logout() }  // 同期
}

public struct DeleteAccountUseCase {
    private let repository: AuthRepositoryProtocol
    public init(repository: AuthRepositoryProtocol) { self.repository = repository }
    public func execute() async throws {
        try await repository.deleteAccount()
    }
}

// Children UseCases（パターンは LoginUseCase と同様）

public struct GetChildrenUseCase {
    private let repository: ChildrenRepositoryProtocol
    public init(repository: ChildrenRepositoryProtocol) { self.repository = repository }
    public func execute() async throws -> [Child] {
        try await repository.getChildren()
    }
}

public struct CreateChildUseCase {
    private let repository: ChildrenRepositoryProtocol
    public init(repository: ChildrenRepositoryProtocol) { self.repository = repository }
    public func execute(name: String, grade: String?) async throws -> Child {
        try await repository.createChild(name: name, grade: grade)
    }
}

public struct UpdateChildUseCase {
    private let repository: ChildrenRepositoryProtocol
    public init(repository: ChildrenRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, name: String, grade: String?) async throws -> Child {
        try await repository.updateChild(childId: childId, name: name, grade: grade)
    }
}

public struct DeleteChildUseCase {
    private let repository: ChildrenRepositoryProtocol
    public init(repository: ChildrenRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String) async throws {
        try await repository.deleteChild(childId: childId)
    }
}

// Tasks UseCases

public struct GetTasksUseCase {
    private let repository: TaskRepositoryProtocol
    public init(repository: TaskRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String) async throws -> [Task] {
        try await repository.getTasks(childId: childId)
    }
}

public struct CreateTaskUseCase {
    private let repository: TaskRepositoryProtocol
    public init(repository: TaskRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, task: Task) async throws -> Task {
        try await repository.createTask(childId: childId, task: task)
    }
}

public struct UpdateTaskUseCase {
    private let repository: TaskRepositoryProtocol
    public init(repository: TaskRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, taskId: String, task: Task) async throws -> Task {
        try await repository.updateTask(childId: childId, taskId: taskId, task: task)
    }
}

public struct ArchiveTaskUseCase {
    private let repository: TaskRepositoryProtocol
    public init(repository: TaskRepositoryProtocol) { self.repository = repository }
    public func execute(taskId: String) async throws {
        try await repository.archiveTask(taskId: taskId)
    }
}

// Android: orders: List<Pair<String, Int>> に対応
public struct ReorderTasksUseCase {
    private let repository: TaskRepositoryProtocol
    public init(repository: TaskRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String,
                        orders: [(taskId: String, sortOrder: Int)]) async throws {
        try await repository.reorderTasks(childId: childId, orders: orders)
    }
}

// Daily UseCases

public struct GetDailyViewUseCase {
    private let repository: DailyRepositoryProtocol
    public init(repository: DailyRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, date: String) async throws -> DailyView {
        try await repository.getDailyView(childId: childId, date: date)
    }
}

public struct UpdateDailyLogUseCase {
    private let repository: DailyRepositoryProtocol
    public init(repository: DailyRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, date: String,
                        items: [DailyItem]) async throws -> Int {  // savedCount
        try await repository.updateDailyLog(childId: childId, date: date, items: items)
    }
}

// Summary UseCases

public struct GetCalendarSummaryUseCase {
    private let repository: SummaryRepositoryProtocol
    public init(repository: SummaryRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, from: String, to: String) async throws -> CalendarSummary {
        try await repository.getCalendarSummary(childId: childId, from: from, to: to)
    }
}

public struct GetSummaryUseCase {
    private let repository: SummaryRepositoryProtocol
    public init(repository: SummaryRepositoryProtocol) { self.repository = repository }
    public func execute(childId: String, from: String, to: String) async throws -> Summary {
        try await repository.getSummary(childId: childId, from: from, to: to)
    }
}
```

---

## Step 7: App層（骨格）

**パス:** `learnappios/`（既存 Xcode ターゲット）

### AppDependencies.swift（骨格）

Phase 1 では Repository 実装（`CoreData`）がまだないため、
DIコンテナは `APIClient` + `KeychainStore` の生成のみを行うスタブとして作成する。

```swift
// learnappios/AppDependencies.swift

import CoreData        // Repository 実装
import CoreDataStore   // KeychainStore
import CoreNetwork     // APIClient
import CoreDomain      // UseCase, Protocol

final class AppDependencies {
    let keychain = KeychainStore()

    lazy var apiClient = APIClient(
        baseURL: URL(string: "https://YOUR_API_HOST")!,   // TODO: 環境設定で差し替え
        tokenProvider: { [keychain] in keychain.load() }
    )

    // ── Repository 実装（Phase 2 以降で順次実装）────────────────────
    lazy var authRepo: AuthRepositoryProtocol =
        AuthRepositoryImpl(apiClient: apiClient, keychain: keychain)
    lazy var childrenRepo: ChildrenRepositoryProtocol =
        ChildrenRepositoryImpl(apiClient: apiClient)
    lazy var taskRepo: TaskRepositoryProtocol =
        TaskRepositoryImpl(apiClient: apiClient)
    lazy var dailyRepo: DailyRepositoryProtocol =
        DailyRepositoryImpl(apiClient: apiClient)
    lazy var summaryRepo: SummaryRepositoryProtocol =
        SummaryRepositoryImpl(apiClient: apiClient)

    // ── UseCase ───────────────────────────────────────────────────
    // Auth
    lazy var loginUseCase         = LoginUseCase(repository: authRepo)
    lazy var signupUseCase        = SignupUseCase(repository: authRepo)
    lazy var getMeUseCase         = GetMeUseCase(repository: authRepo)
    lazy var logoutUseCase        = LogoutUseCase(repository: authRepo)
    lazy var deleteAccountUseCase = DeleteAccountUseCase(repository: authRepo)
    // Children
    lazy var getChildrenUseCase   = GetChildrenUseCase(repository: childrenRepo)
    lazy var createChildUseCase   = CreateChildUseCase(repository: childrenRepo)
    lazy var updateChildUseCase   = UpdateChildUseCase(repository: childrenRepo)
    lazy var deleteChildUseCase   = DeleteChildUseCase(repository: childrenRepo)
    // Tasks
    lazy var getTasksUseCase      = GetTasksUseCase(repository: taskRepo)
    lazy var createTaskUseCase    = CreateTaskUseCase(repository: taskRepo)
    lazy var updateTaskUseCase    = UpdateTaskUseCase(repository: taskRepo)
    lazy var archiveTaskUseCase   = ArchiveTaskUseCase(repository: taskRepo)
    lazy var reorderTasksUseCase  = ReorderTasksUseCase(repository: taskRepo)
    // Daily
    lazy var getDailyViewUseCase   = GetDailyViewUseCase(repository: dailyRepo)
    lazy var updateDailyLogUseCase = UpdateDailyLogUseCase(repository: dailyRepo)
    // Summary
    lazy var getCalendarSummaryUseCase = GetCalendarSummaryUseCase(repository: summaryRepo)
    lazy var getSummaryUseCase         = GetSummaryUseCase(repository: summaryRepo)
}
```

### AppNavigator.swift（骨格）

```swift
// learnappios/AppNavigator.swift

import Observation

@Observable
final class AppNavigator {
    enum Root: Equatable {
        case splash
        case auth
        case children
        case home(childId: String)
    }

    var root: Root = .splash
}
```

### learnappiosApp.swift（更新）

```swift
// learnappios/learnappiosApp.swift

import SwiftUI
import FeatureSplash
import FeatureAuth
import FeatureChildren
import FeatureHome

@main
struct LearnAppIOSApp: App {
    @State private var deps = AppDependencies()
    @State private var navigator = AppNavigator()

    var body: some Scene {
        WindowGroup {
            // Phase 2 以降で RootView を実装する
            // Phase 1 では ContentView（デフォルト）のままでよい
            Text("Phase 1: ビルド確認")
        }
    }
}
```

---

## Phase 1 完了チェックリスト

| # | 確認内容 |
|---|---|
| 1 | `Package.swift` が存在し、Xcode でローカルパッケージとして認識される |
| 2 | 全15ターゲット（Core×7 + Feature×7 + App×1）がビルドエラーなし |
| 3 | `CoreModel` の全型に `public init` が定義されている |
| 4 | `CoreCommon.YearMonth` の `firstDayString()` / `lastDayString()` が正しい日付を返す |
| 5 | `CoreNetwork.APIClient` が `send<T>()` / `sendEmpty()` を持つ |
| 6 | `CoreDataStore.KeychainStore` が `save` / `load` / `delete` を持つ |
| 7 | `CoreDomain` の Repository プロトコル 5 つが定義されている |
| 8 | `CoreDomain` の UseCase 17 個がすべてコンパイルを通る |
| 9 | `AppDependencies` の lazy var がすべて型エラーなし（※CoreData は stub でよい） |
| 10 | `AppNavigator.Root` が `.splash` / `.auth` / `.children` / `.home(childId:)` を持つ |

---

## 備考

### CoreData（Repository実装）について
Phase 1 では `CoreData` モジュールの実装は**スタブ**でよい。
`AppDependencies` がコンパイルを通すために必要な最低限（空の `class XxxRepositoryImpl` など）だけ用意し、Phase 2 以降で順次実装する。

### Feature モジュールについて
Phase 1 では各 Feature モジュールに空ファイルを置くだけでよい。

```swift
// Sources/FeatureAuth/FeatureAuth.swift（Phase 1 は空 enum で型として存在させる）
import CoreDomain
import CoreUI
public enum FeatureAuth {}  // namespace として使用
```

### ベースURL の管理
`AppDependencies` の `"https://YOUR_API_HOST"` は、後続フェーズで `xcconfig` / `Info.plist` 経由の環境変数に差し替える。Phase 1 は直書きで問題なし。
