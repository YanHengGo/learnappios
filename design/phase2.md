# Phase 2 設計書: 認証フロー

## 概要

Phase 2 では認証に必要な全レイヤーを実装し、アプリが起動からログイン・サインアップまで動くことをゴールとする。

---

## Android 調査結果

| 調査項目 | Android 実装 | iOS 方針 |
|---|---|---|
| `SplashViewModel` | `TokenDataStore.token.first()` でトークン有無を確認し `.auth` / `.children` へ分岐 | `KeychainStore.load()` で同等の処理 |
| `AuthViewModel` | `LoginUseCase` / `SignupUseCase` を持つ。`isSuccess = true` で画面外へコールバック | `@Observable` で同等実装 |
| `AuthScreen` | ログイン／サインアップ切り替え。SIGNUP モード時のみプライバシーポリシーリンク表示 | 同じ UI 構成 |
| `PrivacyPolicyScreen` | TopAppBar + 戻るボタン付きのスクロール画面。本文は固定テキスト | NavigationStack で push |
| エラーメッセージ | `IOException` → ネットワークエラー、サーバーエラーコードはメッセージ文字列で判定 | `APIError` enum で判定（後述） |
| `NavGraph` | `splash → auth → children`、`privacy_policy` は auth からプッシュ | `AppNavigator.root` で top-level 遷移、PrivacyPolicy は auth 内の `NavigationStack` でプッシュ |

### エラーメッセージマッピング（iOS 版）

Android は例外メッセージ文字列でサーバーエラーを判定するが、iOS は `APIError` enum を使う。

| `APIError` | 認証画面でのメッセージ |
|---|---|
| `.networkError` | "ネットワークに接続できません。接続を確認してください。" |
| `.unauthorized` | "メールアドレスまたはパスワードが正しくありません" |
| `.httpError(409)` | "このメールアドレスは既に登録されています" |
| その他 `.httpError` | "エラーが発生しました。もう一度お試しください" |

> **注意:** ログイン中の `.unauthorized` (401) は「認証情報が誤っている」であり、グローバルな自動ログアウトとは別扱い。`AuthViewModel` 内でローカルに catch する。

---

## ファイル一覧

```
Sources/CoreUI/
└── Theme.swift                        ← AppColor / AppFont 定義

Sources/CoreData/
└── AuthRepositoryImpl.swift           ← Phase 1 で実装済み（変更なし）

Sources/FeatureAuth/
├── AuthView.swift
├── AuthViewModel.swift
├── PrivacyPolicyView.swift
└── Components/
    └── AuthTextField.swift            ← メール・パスワード入力共通コンポーネント

Sources/FeatureSplash/
├── SplashView.swift
└── SplashViewModel.swift

learnappios/
├── RootView.swift                     ← 新規作成
├── AppNavigator.swift                 ← Phase 1 から変更なし
├── AppDependencies.swift              ← Phase 1 から変更なし
└── learnappiosApp.swift               ← RootView を使うよう更新
```

---

## Step 1: CoreUI — Theme.swift

**パス:** `Sources/CoreUI/Theme.swift`

SwiftUI の `Color` / `Font` を拡張してアプリ共通テーマを定義する。
Android の `MaterialTheme.colorScheme` に相当するが、iOS は Material を使わず SwiftUI ネイティブスタイルを使う。

```swift
// Sources/CoreUI/Theme.swift

import SwiftUI

public extension Color {
    // アクセントカラー（Android: MaterialTheme.colorScheme.primary）
    static let appPrimary = Color.accentColor

    // エラー表示（Android: MaterialTheme.colorScheme.error）
    static let appError = Color.red

    // 補助テキスト（Android: MaterialTheme.colorScheme.onSurfaceVariant）
    static let appSecondaryText = Color(UIColor.secondaryLabel)
}

public extension Font {
    // 画面タイトル（Android: MaterialTheme.typography.headlineMedium）
    static let appHeadline = Font.title2.bold()

    // サブタイトル（Android: MaterialTheme.typography.titleMedium）
    static let appTitle = Font.headline

    // 本文（Android: MaterialTheme.typography.bodyMedium）
    static let appBody = Font.body

    // 補助テキスト（Android: MaterialTheme.typography.bodySmall）
    static let appCaption = Font.caption
}
```

---

## Step 2: FeatureSplash

### SplashViewModel.swift

Android の `SplashViewModel` はコルーチンで `tokenDataStore.token.first()` を確認する。iOS 版は `init` で非同期タスクを起動し、`KeychainStore.load()` でトークン有無を確認する。

`AppNavigator` を直接受け取る代わりに、遷移先を `onNavigate` クロージャで外部に伝える設計とする（ViewModel が App 層に依存しないよう）。

```swift
// Sources/FeatureSplash/SplashViewModel.swift

import CoreDataStore
import Observation

@Observable
public final class SplashViewModel {
    public enum Destination {
        case auth
        case children
    }

    public var destination: Destination? = nil

    private let keychain: KeychainStore

    public init(keychain: KeychainStore) {
        self.keychain = keychain
    }

    public func checkToken() {
        // 同期処理（Keychain は同期）
        destination = keychain.load() != nil ? .children : .auth
    }
}
```

> **設計メモ:** Android の `init` ブロックでコルーチン起動するパターンと異なり、iOS では `task { }` modifier から `checkToken()` を呼び出す。これにより View のライフサイクルと連動させる。

### SplashView.swift

```swift
// Sources/FeatureSplash/SplashView.swift

import SwiftUI
import CoreUI

public struct SplashView: View {
    @State private var viewModel: SplashViewModel
    let onNavigateToAuth: () -> Void
    let onNavigateToChildren: () -> Void

    public init(
        viewModel: SplashViewModel,
        onNavigateToAuth: @escaping () -> Void,
        onNavigateToChildren: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onNavigateToAuth = onNavigateToAuth
        self.onNavigateToChildren = onNavigateToChildren
    }

    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("学習管理アプリ")
                    .font(.appHeadline)
                ProgressView()
            }
        }
        .task {
            viewModel.checkToken()
        }
        .onChange(of: viewModel.destination) { _, destination in
            switch destination {
            case .auth:      onNavigateToAuth()
            case .children:  onNavigateToChildren()
            case nil:        break
            }
        }
    }
}
```

---

## Step 3: FeatureAuth

### AuthViewModel.swift

Android の `AuthViewModel` を `@Observable` で置き換え。
`isSuccess` フラグ方式は同一。エラーは `APIError` でキャッチして日本語メッセージに変換。

```swift
// Sources/FeatureAuth/AuthViewModel.swift

import CoreDomain
import CoreCommon
import Observation

public enum AuthMode {
    case login
    case signup
}

@Observable
public final class AuthViewModel {
    public var email: String = ""
    public var password: String = ""
    public var mode: AuthMode = .login
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    public var isSuccess: Bool = false

    private let loginUseCase: LoginUseCase
    private let signupUseCase: SignupUseCase

    public init(loginUseCase: LoginUseCase, signupUseCase: SignupUseCase) {
        self.loginUseCase = loginUseCase
        self.signupUseCase = signupUseCase
    }

    public func onEmailChange(_ value: String) {
        email = value
        errorMessage = nil
    }

    public func onPasswordChange(_ value: String) {
        password = value
        errorMessage = nil
    }

    public func onModeToggle() {
        mode = (mode == .login) ? .signup : .login
        errorMessage = nil
    }

    public func onSubmit() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            switch mode {
            case .login:
                try await loginUseCase.execute(email: trimmedEmail, password: password)
            case .signup:
                try await signupUseCase.execute(email: trimmedEmail, password: password)
            }
            isLoading = false
            isSuccess = true
        } catch let error as APIError {
            isLoading = false
            errorMessage = authErrorMessage(for: error)
        } catch {
            isLoading = false
            errorMessage = "エラーが発生しました。もう一度お試しください"
        }
    }

    // MARK: - Private

    private func authErrorMessage(for error: APIError) -> String {
        switch error {
        case .networkError:
            return "ネットワークに接続できません。接続を確認してください。"
        case .unauthorized:
            return "メールアドレスまたはパスワードが正しくありません"
        case .httpError(let code) where code == 409:
            return "このメールアドレスは既に登録されています"
        default:
            return "エラーが発生しました。もう一度お試しください"
        }
    }
}
```

### Components/AuthTextField.swift

メール／パスワード入力フィールドの共通コンポーネント。パスワードは表示切り替えアイコン付き。

```swift
// Sources/FeatureAuth/Components/AuthTextField.swift

import SwiftUI

struct AuthTextField: View {
    let label: String
    @Binding var text: String
    var isPassword: Bool = false
    var isEnabled: Bool = true
    var onSubmit: (() -> Void)? = nil

    @State private var isPasswordVisible = false

    var body: some View {
        Group {
            if isPassword && !isPasswordVisible {
                SecureField(label, text: $text)
            } else {
                TextField(label, text: $text)
                    .keyboardType(isPassword ? .default : .emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .overlay(alignment: .trailing) {
            if isPassword {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing, 8)
            }
        }
        .textFieldStyle(.roundedBorder)
        .disabled(!isEnabled)
        .onSubmit { onSubmit?() }
    }
}
```

### AuthView.swift

Android の `AuthScreen` / `AuthContent` を SwiftUI で再現。
`PrivacyPolicyView` は `NavigationStack` 内で `navigationDestination` を使って push する。

```swift
// Sources/FeatureAuth/AuthView.swift

import SwiftUI
import CoreUI

public struct AuthView: View {
    @State private var viewModel: AuthViewModel
    @State private var showPrivacyPolicy = false
    let onAuthSuccess: () -> Void

    public init(viewModel: AuthViewModel, onAuthSuccess: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onAuthSuccess = onAuthSuccess
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                AuthContent(viewModel: viewModel)
                    .padding(.horizontal, 32)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationDestination(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .onChange(of: viewModel.isSuccess) { _, success in
            if success { onAuthSuccess() }
        }
    }
}

// MARK: - AuthContent（内部コンポーネント）

private struct AuthContent: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // タイトル
            Text("学習管理アプリ")
                .font(.appHeadline)

            Spacer().frame(height: 8)

            Text(viewModel.mode == .login ? "ログイン" : "新規登録")
                .font(.appTitle)
                .foregroundStyle(.appSecondaryText)

            Spacer().frame(height: 40)

            // メールアドレス
            AuthTextField(
                label: "メールアドレス",
                text: $viewModel.email,
                isEnabled: !viewModel.isLoading,
                onSubmit: { focusedField = .password }
            )
            .focused($focusedField, equals: .email)

            Spacer().frame(height: 16)

            // パスワード
            AuthTextField(
                label: "パスワード",
                text: $viewModel.password,
                isPassword: true,
                isEnabled: !viewModel.isLoading,
                onSubmit: {
                    focusedField = nil
                    Task { await viewModel.onSubmit() }
                }
            )
            .focused($focusedField, equals: .password)

            Spacer().frame(height: 8)

            // エラーメッセージ
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.appCaption)
                    .foregroundStyle(.appError)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer().frame(height: 8)
            }

            Spacer().frame(height: 8)

            // 送信ボタン
            Button {
                focusedField = nil
                Task { await viewModel.onSubmit() }
            } label: {
                Text(viewModel.mode == .login ? "ログイン" : "新規登録")
                    .font(.appTitle)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            Spacer().frame(height: 16)

            // モード切り替え
            Button {
                viewModel.onModeToggle()
            } label: {
                Text(viewModel.mode == .login
                     ? "アカウントをお持ちでない方はこちら"
                     : "すでにアカウントをお持ちの方はこちら")
            }
            .disabled(viewModel.isLoading)

            // プライバシーポリシー（新規登録モードのみ）
            if viewModel.mode == .signup {
                Button {
                    showPrivacyPolicy = true
                } label: {
                    Text("プライバシーポリシーを確認する")
                        .font(.appCaption)
                        .foregroundStyle(.appSecondaryText)
                }
            }

            Spacer().frame(height: 40)
        }
    }

    // AuthView が @State で持っているため、AuthContent から制御するための workaround
    // showPrivacyPolicy は AuthView 側で @State として管理し、EnvironmentValue 経由で渡す
    // → 代替: AuthContent に Binding<Bool> を渡す
    @Binding private var showPrivacyPolicy: Bool

    init(viewModel: AuthViewModel, showPrivacyPolicy: Binding<Bool> = .constant(false)) {
        self.viewModel = viewModel
        self._showPrivacyPolicy = showPrivacyPolicy
    }
}
```

> **注意:** `AuthContent` は `AuthView` 内専用。`@Bindable` は `@Observable` クラスに対して `$` バインディングを使うための iOS 17 の仕組み。

実際の実装では `AuthView` から `showPrivacyPolicy` の `Binding` を `AuthContent` に渡す。上記コードはその構造を示す骨格であり、実装時に整合する。

### PrivacyPolicyView.swift

Android の `PrivacyPolicyScreen` と同じ内容。本文テキストは Android から流用。

```swift
// Sources/FeatureAuth/PrivacyPolicyView.swift

import SwiftUI
import CoreUI

public struct PrivacyPolicyView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(PolicySection.all, id: \.title) { section in
                    Text(section.title)
                        .font(.appTitle)
                        .foregroundStyle(.appPrimary)
                    Spacer().frame(height: 8)
                    Text(section.body)
                        .font(.appBody)
                    Spacer().frame(height: 24)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Policy Data

private struct PolicySection {
    let title: String
    let body: String

    static let all: [PolicySection] = [
        .init(title: "はじめに", body: """
            ゲンコウソフトウェア（以下「当社」）は、LearnApp（以下「本アプリ」）において、ユーザーの個人情報の取り扱いについて以下のとおりプライバシーポリシー（以下「本ポリシー」）を定めます。
            本アプリをご利用いただく前に、本ポリシーをよくお読みください。
            """),
        .init(title: "収集する情報", body: """
            本アプリでは、以下の情報を収集します。

            ・メールアドレス（アカウント登録・ログインに使用）
            ・お子さまの情報（お名前・学年）
            ・学習記録（タスク・学習時間・日々の記録）

            上記以外の情報（位置情報・連絡先・カメラ等）は一切収集しません。
            """),
        .init(title: "情報の利用目的", body: """
            収集した情報は、以下の目的にのみ使用します。

            ・本アプリのサービス提供および機能の実現
            ・ユーザーアカウントの管理・認証
            ・お問い合わせへの対応

            上記以外の目的には使用しません。
            """),
        .init(title: "第三者への提供", body: """
            当社は、以下の場合を除き、ユーザーの情報を第三者に提供・開示しません。

            ・ユーザー本人の同意がある場合
            ・法令に基づき開示が必要な場合

            本アプリは広告SDK・分析SDKを一切使用していないため、広告目的での情報提供は行いません。
            """),
        .init(title: "情報の管理", body: """
            収集した情報はサーバー上で適切に管理し、不正アクセス・紛失・漏洩の防止に努めます。
            不要になった情報はアカウント削除時に速やかに消去します。
            """),
        .init(title: "お問い合わせ", body: """
            本ポリシーに関するご質問・ご意見は、以下の連絡先までお問い合わせください。

            ゲンコウソフトウェア
            メール：genmanabu@gmail.com
            """),
        .init(title: "改定について", body: """
            本ポリシーは必要に応じて改定することがあります。
            重要な変更がある場合はアプリ内でお知らせします。
            """),
        .init(title: "制定日", body: "2026年4月16日"),
    ]
}
```

---

## Step 4: App 層 — RootView + learnappiosApp 更新

### RootView.swift

Android の `NavGraph` に相当。`AppNavigator.root` の値をスイッチして表示する View を切り替える。

遷移時のアニメーションは `animation(.easeInOut, value:)` で付与する。

```swift
// learnappios/RootView.swift

import SwiftUI
import FeatureSplash
import FeatureAuth
import FeatureChildren
import FeatureHome

struct RootView: View {
    @State var navigator: AppNavigator
    let deps: AppDependencies

    var body: some View {
        Group {
            switch navigator.root {
            case .splash:
                SplashView(
                    viewModel: SplashViewModel(keychain: deps.keychain),
                    onNavigateToAuth: {
                        navigator.root = .auth
                    },
                    onNavigateToChildren: {
                        navigator.root = .children
                    }
                )

            case .auth:
                AuthView(
                    viewModel: AuthViewModel(
                        loginUseCase: deps.loginUseCase,
                        signupUseCase: deps.signupUseCase
                    ),
                    onAuthSuccess: {
                        navigator.root = .children
                    }
                )

            case .children:
                // Phase 3 で実装
                Text("子ども選択画面（Phase 3）")

            case .home(let childId):
                // Phase 4 以降で実装
                Text("ホーム: \(childId)（Phase 4）")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: navigator.root)
    }
}
```

> **設計メモ:**
> - `SplashViewModel` の `keychain` は `deps.keychain` から渡す（DI）
> - `AuthViewModel` は `RootView` が生成し `@State` で保持（SplashView / AuthView はどちらも外部から VM を受け取る設計）
> - 401 自動ログアウトは将来 `AppNavigator` を `environment` 経由で子 ViewModel に渡して `navigator.root = .auth` で実現する（Phase 4 以降）

### learnappiosApp.swift 更新

Phase 1 の `Text("Phase 1: ビルド確認")` を `RootView` に置き換える。

```swift
// learnappios/learnappiosApp.swift

import SwiftUI

@main
struct learnappiosApp: App {
    @State private var deps = AppDependencies()
    @State private var navigator = AppNavigator()

    var body: some Scene {
        WindowGroup {
            RootView(navigator: navigator, deps: deps)
        }
    }
}
```

---

## ナビゲーションフロー（Phase 2 完成後）

```
起動
 └─ SplashView
       ├─ token あり  → AppNavigator.root = .children  （→ Phase 3 で実装）
       └─ token なし  → AppNavigator.root = .auth
                              └─ AuthView (NavigationStack)
                                    ├─ ログイン成功  → AppNavigator.root = .children
                                    └─ プライバシーポリシー → push PrivacyPolicyView
```

---

## Phase 2 完了チェックリスト

| # | 確認内容 |
|---|---|
| 1 | `SplashView` がトークンなし時に `AuthView` へ遷移する |
| 2 | `SplashView` がトークンあり時に（children プレースホルダへ）遷移する |
| 3 | `AuthView` でメール・パスワード入力 → ログインボタンで API リクエストが走る |
| 4 | ログイン成功後に `AppNavigator.root = .children` へ切り替わる |
| 5 | サインアップ切り替えボタンでフォームのモードが変わる |
| 6 | 入力空欄で送信時に「メールアドレスとパスワードを入力してください」が表示される |
| 7 | API エラー時に適切な日本語メッセージが表示される |
| 8 | サインアップモード時のみプライバシーポリシーリンクが表示される |
| 9 | プライバシーポリシーリンクタップで `PrivacyPolicyView` が push される |
| 10 | `PrivacyPolicyView` の戻るボタン（ナビゲーションバー）で `AuthView` に戻る |
| 11 | ビルドエラーなし |
