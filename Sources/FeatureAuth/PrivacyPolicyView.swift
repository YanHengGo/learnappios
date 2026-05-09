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
                        .foregroundStyle(Color.appPrimary)
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
