# アーキテクチャ詳細

## レイヤー構成

```
┌─────────────────────────────────────┐
│             Features                 │  SwiftUI View + @Observable ViewModel
├─────────────────────────────────────┤
│            Data Layer                │  Repository + DTO
├─────────────────────────────────────┤
│            Core Layer                │  APIClient / Keychain / Models
└─────────────────────────────────────┘
```

---

## Core Layer

### 責務分担の原則

```
APIEndpoint  ─── 「何をリクエストするか」を宣言する value type
                  (method / path / query / body を保持)

APIClient    ─── 「どうやってHTTPを送るか」を実行するエンジン
                  (URL構築 / Auth付与 / encode / 送信 / decode / エラー変換)

Repository   ─── 「ドメイン操作を呼び出す」層
                  (.login(email:password:) のようにエンドポイントを組み立てて send)
```

| 責務 | APIEndpoint | APIClient | Repository |
|---|:---:|:---:|:---:|
| HTTPメソッド | ✅ | - | - |
| URLパス | ✅ | - | - |
| クエリパラメータ | ✅ | - | - |
| リクエストボディ | ✅ | - | - |
| ベースURL結合 | - | ✅ | - |
| Authorization ヘッダー付与 | - | ✅ | - |
| JSON encode (snake_case) | - | ✅ | - |
| URLSession 実行 | - | ✅ | - |
| ステータスコード検査 | - | ✅ | - |
| JSON decode (camelCase変換) | - | ✅ | - |
| APIError 変換 | - | ✅ | - |
| DTO → ドメインモデル変換 | - | - | ✅ |
| Keychain アクセス | - | ❌ 直接依存しない | - |

---

### APIEndpoint

HTTPリクエストの**宣言**。struct + static ファクトリメソッドで定義する。
enum は使わない（case が増えるたびに switch が必要になり、呼び出し側への変更伝搬を抑えられないため）。

```swift
// Sources/CoreNetwork/APIEndpoint.swift

public enum HTTPMethod: String {
    case get = "GET", post = "POST", put = "PUT"
    case patch = "PATCH", delete = "DELETE"
}

public struct APIEndpoint {
    public let method: HTTPMethod
    public let path: String
    public let queryItems: [URLQueryItem]?
    public let body: (any Encodable)?

    public init(
        method: HTTPMethod,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.body = body
    }
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
    static var me: APIEndpoint        { .init(method: .get,    path: "/api/v1/me") }
    static var deleteMe: APIEndpoint  { .init(method: .delete, path: "/api/v1/me") }
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
              body: ["isArchived": true] as [String: Bool])  // 最小パッチ
    }
}

// ── Daily ─────────────────────────────────────────────────────────────
public extension APIEndpoint {
    static func dailyView(childId: String, date: String) -> APIEndpoint {
        .init(method: .get, path: "/api/v1/children/\(childId)/daily-view",
              queryItems: [.init(name: "date", value: date)])
    }
    static func updateDaily(childId: String, date: String, _ req: UpdateDailyRequest) -> APIEndpoint {
        .init(method: .put, path: "/api/v1/children/\(childId)/daily",
              queryItems: [.init(name: "date", value: date)], body: req)
    }
}

// ── Summary ───────────────────────────────────────────────────────────
public extension APIEndpoint {
    static func calendarSummary(childId: String, from: String, to: String) -> APIEndpoint {
        .init(method: .get, path: "/api/v1/children/\(childId)/calendar-summary",
              queryItems: [.init(name: "from", value: from), .init(name: "to", value: to)])
    }
    static func summary(childId: String, from: String, to: String) -> APIEndpoint {
        .init(method: .get, path: "/api/v1/children/\(childId)/summary",
              queryItems: [.init(name: "from", value: from), .init(name: "to", value: to)])
    }
}
```

---

### APIClient

HTTPリクエストの**実行エンジン**。`KeychainStore` には直接依存せず、トークンをクロージャで受け取る。
これにより `CoreNetwork` が `CoreDataStore` に依存せず、SPMの依存グラフを保つ。

```swift
// Sources/CoreNetwork/APIClient.swift

public final class APIClient {
    private let baseURL: URL
    private let tokenProvider: () -> String?   // Keychainへの直接依存を排除
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(baseURL: URL, tokenProvider: @escaping () -> String?) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    /// レスポンスボディありのリクエスト
    public func send<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let request = try buildRequest(endpoint)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// レスポンスボディなし（204 等）のリクエスト
    public func sendEmpty(_ endpoint: APIEndpoint) async throws {
        let request = try buildRequest(endpoint)
        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response)
    }

    // MARK: - Private

    private func buildRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        // URL + クエリ組み立て
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = endpoint.queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Auth ヘッダー（tokenがあれば付与）
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // ボディ encode
        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
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

// any Encodable を型消去して JSONEncoder.encode に渡すためのラッパー
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: any Encodable) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
```

---

### APIError

```swift
// Sources/CoreCommon/APIError.swift  ← CoreCommon に配置（CoreNetworkに依存させない）

public enum APIError: Error, LocalizedError {
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized          // 401: AppNavigator.root = .auth へリセット
    case unknown

    public var errorDescription: String? {
        switch self {
        case .unauthorized:             return "セッションが切れました。再度ログインしてください。"
        case .httpError(let code):      return "サーバーエラーが発生しました（\(code)）"
        case .networkError:             return "通信エラーが発生しました"
        case .decodingError:            return "データの読み込みに失敗しました"
        case .unknown:                  return "不明なエラーが発生しました"
        }
    }
}
```

---

### KeychainStore

```swift
// Sources/CoreDataStore/KeychainStore.swift

public final class KeychainStore {
    private let service = "com.learn.app.token"

    public func save(token: String) { ... }   // SecItemAdd / SecItemUpdate
    public func load() -> String?  { ... }    // SecItemCopyMatching
    public func delete()           { ... }    // SecItemDelete
}
```

`Security.framework` を使用（SPMターゲットに `linkerSettings: [.linkedFramework("Security")]` を追加）。

---

### 呼び出し例（Repository実装）

```swift
// Sources/CoreData/Repositories/AuthRepositoryImpl.swift

func login(email: String, password: String) async throws {
    // APIEndpoint がすべての HTTP セマンティクスを持つ
    // APIClient は send() を呼ぶだけ
    let dto: TokenDTO = try await apiClient.send(.login(email: email, password: password))
    keychain.save(token: dto.token)
}

func getMe() async throws -> User {
    let dto: MeDTO = try await apiClient.send(.me)
    return dto.toModel()
}

func deleteAccount() async throws {
    try await apiClient.sendEmpty(.deleteMe)
}
```

---

## Data Layer

### Repository プロトコル

```swift
protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> String  // token
    func signup(email: String, password: String) async throws
    func getMe() async throws -> User
    func logout()   // Keychainからtoken削除（ローカル処理）
    func deleteAccount() async throws
}

protocol ChildrenRepositoryProtocol {
    func getChildren() async throws -> [Child]
    func createChild(name: String, grade: String?) async throws -> Child
    func updateChild(id: String, name: String, grade: String?) async throws -> Child
    func deleteChild(id: String) async throws
}

protocol TaskRepositoryProtocol {
    func getTasks(childId: String) async throws -> [Task]
    func createTask(childId: String, params: CreateTaskParams) async throws -> Task
    func updateTask(childId: String, taskId: String, params: UpdateTaskParams) async throws -> Task
    func archiveTask(taskId: String) async throws -> Task
    func reorderTasks(childId: String, ids: [String]) async throws
}

protocol DailyRepositoryProtocol {
    func getDailyView(childId: String, date: String) async throws -> DailyView
    func updateDailyLog(childId: String, date: String, items: [DailyItem]) async throws
}

protocol SummaryRepositoryProtocol {
    func getCalendarSummary(childId: String, from: String, to: String) async throws -> CalendarSummary
    func getSummary(childId: String, from: String, to: String) async throws -> Summary
}
```

### DTO → Model マッピング

DTO（Codable）はネットワーク専用。Repository実装内でドメインモデルに変換する。

```swift
// DTO例
struct ChildDTO: Decodable {
    let id: String
    let name: String
    let grade: String?
    let isActive: Bool
}

// 変換
extension ChildDTO {
    func toModel() -> Child {
        Child(id: id, name: name, grade: grade, isActive: isActive)
    }
}
```

---

## Feature Layer (MVVM)

### ViewModel パターン

ViewModel は **UseCase のみ**を依存として受け取る。Repository プロトコルは直接保持しない。

```swift
@Observable
final class ChildrenViewModel {
    // State
    var children: [Child] = []
    var isLoading = false
    var errorMessage: String?
    var showAddDialog = false
    var editingChild: Child?
    var dialogName = ""
    var dialogGrade = ""
    var isSaving = false
    var showLogoutConfirm = false
    var showDeleteAccountConfirm = false

    // Dependencies（Repository ではなく UseCase を受け取る）
    private let getChildrenUseCase: GetChildrenUseCase
    private let createChildUseCase: CreateChildUseCase
    private let updateChildUseCase: UpdateChildUseCase
    private let deleteChildUseCase: DeleteChildUseCase
    private let logoutUseCase: LogoutUseCase
    private let deleteAccountUseCase: DeleteAccountUseCase

    init(
        getChildrenUseCase: GetChildrenUseCase,
        createChildUseCase: CreateChildUseCase,
        updateChildUseCase: UpdateChildUseCase,
        deleteChildUseCase: DeleteChildUseCase,
        logoutUseCase: LogoutUseCase,
        deleteAccountUseCase: DeleteAccountUseCase
    ) { ... }

    // Actions
    func loadChildren() async {
        isLoading = true
        defer { isLoading = false }
        do {
            children = try await getChildrenUseCase.execute()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func onSaveChild() async {
        isSaving = true
        defer { isSaving = false }
        do {
            if let editing = editingChild {
                let updated = try await updateChildUseCase.execute(id: editing.id, name: dialogName, grade: dialogGrade.isEmpty ? nil : dialogGrade)
                children = children.map { $0.id == updated.id ? updated : $0 }
            } else {
                let created = try await createChildUseCase.execute(name: dialogName, grade: dialogGrade.isEmpty ? nil : dialogGrade)
                children.append(created)
            }
            showAddDialog = false
            editingChild = nil
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func onLogout() { logoutUseCase.execute() }
    // ...
}
```

### View パターン

ViewModel は `@State` で保持し、`AppDependencies` から UseCase を注入して生成する。

```swift
// FeatureChildren/ChildrenView.swift
struct ChildrenView: View {
    @State private var viewModel: ChildrenViewModel

    init(viewModel: ChildrenViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View { ... }
}

// learnappios/AppNavigator.swift（または RootView）での生成例
ChildrenView(
    viewModel: ChildrenViewModel(
        getChildrenUseCase:   deps.getChildrenUseCase,
        createChildUseCase:   deps.createChildUseCase,
        updateChildUseCase:   deps.updateChildUseCase,
        deleteChildUseCase:   deps.deleteChildUseCase,
        logoutUseCase:        deps.logoutUseCase,
        deleteAccountUseCase: deps.deleteAccountUseCase
    )
)
```

---

## DIコンテナ

```swift
// learnappios/AppDependencies.swift

final class AppDependencies {
    let keychain = KeychainStore()

    lazy var apiClient = APIClient(
        baseURL: URL(string: Env.apiBaseURL)!,
        tokenProvider: { [keychain] in keychain.load() }
    )

    // ── Repository 実装（CoreData）────────────────────────────────────
    // App 層のみが知る。Feature / UseCase からは Protocol 越しにしか見えない。

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

    // ── UseCase（CoreDomain）─────────────────────────────────────────
    // ViewModel はこれらを受け取る。Repository 実装には依存しない。

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
    lazy var getDailyViewUseCase  = GetDailyViewUseCase(repository: dailyRepo)
    lazy var updateDailyLogUseCase = UpdateDailyLogUseCase(repository: dailyRepo)

    // Summary
    lazy var getCalendarSummaryUseCase = GetCalendarSummaryUseCase(repository: summaryRepo)
    lazy var getSummaryUseCase         = GetSummaryUseCase(repository: summaryRepo)
}
```

`learnappiosApp` で `AppDependencies` を生成し、各 `View` のイニシャライザに UseCase を注入する。

```
AppDependencies
  └── UseCase（CoreDomain）を生成・保持
        │  Repository protocol に依存
        ▼
  Repository 実装（CoreData）← App 層のみが知る
```

---

## ナビゲーション

```swift
// Navigation/AppNavigator.swift

@Observable
final class AppNavigator {
    enum Root {
        case splash, auth, children, home(childId: String)
    }
    var root: Root = .splash
}
```

`learnappiosApp.swift` で `AppNavigator` を `@State` として持ち、`root` の値に応じて最上位Viewを切り替える。

```swift
@main
struct LearnAppIOSApp: App {
    @State private var deps = AppDependencies()
    @State private var navigator = AppNavigator()

    var body: some Scene {
        WindowGroup {
            RootView(deps: deps, navigator: navigator)
        }
    }
}
```

HomeView内のタブは SwiftUI `TabView` を使用し、SummaryからDailyDetailへの遷移は `NavigationStack` で管理。

---

## 曜日ビットマスク

Androidと同一ロジックをSwiftで実装：

```swift
// bit0=日, bit1=月, bit2=火, bit3=水, bit4=木, bit5=金, bit6=土
let dayLabels = ["日", "月", "火", "水", "木", "金", "土"]

extension Int {
    func hasDayBit(_ dayIndex: Int) -> Bool {
        (self & (1 << dayIndex)) != 0
    }
    func toggleDayBit(_ dayIndex: Int) -> Int {
        self ^ (1 << dayIndex)
    }
}
```

---

## エラーハンドリング方針

- ViewModel の `errorMessage: String?` にセット
- View 側は `.alert(item:)` または `.overlay` でトーストUIとして表示
- 401エラーは `AppNavigator.root = .auth` へリセット（自動ログアウト）
- ローディング中のUI無効化は `isLoading` / `isSaving` フラグで制御
