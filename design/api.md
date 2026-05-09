# API仕様

AndroidアプリのRetrofit定義（`LearnApiService.kt`）を元にiOS向けに整理した仕様。

## ベースURL

環境変数またはビルド設定で管理。開発時は直接定数として定義。

```swift
// Core/Network/APIEndpoint.swift
static let baseURL = URL(string: "https://<api-host>")!
```

## 認証

全リクエストに `Authorization: Bearer <token>` ヘッダーを付与（`APIClient` が自動処理）。

---

## エンドポイント一覧

### Auth

| Method | Path | Request Body | Response |
|---|---|---|---|
| POST | `/api/v1/auth/signup` | `SignupRequest` | `SignupDTO` |
| POST | `/api/v1/auth/login` | `LoginRequest` | `TokenDTO` |
| GET | `/api/v1/me` | - | `MeDTO` |
| DELETE | `/api/v1/me` | - | 204 No Content |

```swift
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct SignupRequest: Encodable {
    let email: String
    let password: String
}

struct TokenDTO: Decodable {
    let token: String
}

struct SignupDTO: Decodable {
    let token: String
}

struct MeDTO: Decodable {
    let id: String
    let email: String
    let displayName: String?
    let avatarUrl: String?
    let provider: String
}
```

---

### Children

| Method | Path | Request | Response |
|---|---|---|---|
| GET | `/api/v1/children` | - | `[ChildDTO]` |
| POST | `/api/v1/children` | `CreateChildRequest` | `ChildDTO` |
| PUT | `/api/v1/children/{id}` | `UpdateChildRequest` | `ChildDTO` |
| PATCH | `/api/v1/children/{childId}` | `[String: Any?]` | `ChildDTO` |
| DELETE | `/api/v1/children/{childId}` | - | 204 |

```swift
struct ChildDTO: Decodable {
    let id: String
    let name: String
    let grade: String?
    let isActive: Bool
}

struct CreateChildRequest: Encodable {
    let name: String
    let grade: String?
}

struct UpdateChildRequest: Encodable {
    let name: String
    let grade: String?
}
```

---

### Tasks

| Method | Path | Query | Request | Response |
|---|---|---|---|---|
| GET | `/api/v1/children/{childId}/tasks` | `archived=false` | - | `[TaskDTO]` |
| POST | `/api/v1/children/{childId}/tasks` | - | `CreateTaskRequest` | `TaskDTO` |
| PUT | `/api/v1/children/{childId}/tasks/reorder` | - | `ReorderRequest` | 204 |
| PUT | `/api/v1/children/{childId}/tasks/{taskId}` | - | `UpdateTaskRequest` | `TaskDTO` |
| PATCH | `/api/v1/tasks/{taskId}` | - | `[String: Any?]` | `TaskDTO` |

```swift
struct TaskDTO: Decodable {
    let id: String
    let name: String
    let description: String?
    let subject: String
    let defaultMinutes: Int
    let daysMask: Int
    let isArchived: Bool
    let startDate: String?
    let endDate: String?
    let sortOrder: Int
}

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
    let startDate: String?
    let endDate: String?
}

struct ReorderRequest: Encodable {
    let ids: [String]
}
```

**アーカイブ操作:**
```swift
// PATCH /api/v1/tasks/{taskId}  body: {"isArchived": true}
```

---

### Daily

| Method | Path | Query | Request | Response |
|---|---|---|---|---|
| GET | `/api/v1/children/{childId}/daily-view` | `date=yyyy-MM-dd` | - | `DailyViewDTO` |
| GET | `/api/v1/children/{childId}/daily` | `date=yyyy-MM-dd` | - | `DailyLogDTO` |
| PUT | `/api/v1/children/{childId}/daily` | `date=yyyy-MM-dd` | `UpdateDailyRequest` | `UpdateDailyResponseDTO` |

```swift
struct DailyViewDTO: Decodable {
    let date: String
    let weekday: String
    let tasks: [DailyTaskDTO]
}

struct DailyTaskDTO: Decodable {
    let taskId: String
    let name: String
    let subject: String
    let defaultMinutes: Int
    let daysMask: Int
    let isDone: Bool
    let minutes: Int
}

struct DailyLogDTO: Decodable {
    // サーバー仕様に従う（daily-viewで代替可能）
}

struct UpdateDailyRequest: Encodable {
    let items: [DailyItemRequest]
}

struct DailyItemRequest: Encodable {
    let taskId: String
    let minutes: Int
}

struct UpdateDailyResponseDTO: Decodable {
    // サーバー仕様に従う
}
```

---

### Summary

| Method | Path | Query | Response |
|---|---|---|---|
| GET | `/api/v1/children/{childId}/calendar-summary` | `from`, `to` | `CalendarSummaryDTO` |
| GET | `/api/v1/children/{childId}/summary` | `from`, `to` | `SummaryDTO` |

`from` / `to` は `"yyyy-MM-dd"` 形式。月の場合は `月初〜月末` を渡す。

```swift
struct CalendarSummaryDTO: Decodable {
    let from: String
    let to: String
    let days: [CalendarDayDTO]
}

struct CalendarDayDTO: Decodable {
    let date: String
    let status: String   // "GREEN" | "YELLOW" | "RED" | "WHITE"
    let total: Int
    let done: Int
}

struct SummaryDTO: Decodable {
    let from: String
    let to: String
    let totalMinutes: Int
    let byDay: [SummaryByDayDTO]
    let bySubject: [SummaryBySubjectDTO]
    let byTask: [SummaryByTaskDTO]
}

struct SummaryByDayDTO: Decodable {
    let date: String
    let minutes: Int
}

struct SummaryBySubjectDTO: Decodable {
    let subject: String
    let minutes: Int
}

struct SummaryByTaskDTO: Decodable {
    let taskId: String
    let name: String
    let subject: String
    let minutes: Int
}
```

---

## JSONDecoder 設定

```swift
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
// 例: "is_active" → isActive, "days_mask" → daysMask
```

## JSONEncoder 設定

```swift
let encoder = JSONEncoder()
encoder.keyEncodingStrategy = .convertToSnakeCase
// 例: isActive → "is_active"
```

---

## エラーレスポンス

HTTPステータスコード別の処理方針:

| Status | 処理 |
|---|---|
| 2xx | 正常処理 |
| 401 | `APIError.unauthorized` → 自動ログアウト |
| 4xx | `APIError.httpError(statusCode:)` → errorMessage表示 |
| 5xx | `APIError.httpError(statusCode:)` → 「サーバーエラーが発生しました」 |
| ネットワークエラー | `APIError.networkError` → 「通信エラーが発生しました」 |
