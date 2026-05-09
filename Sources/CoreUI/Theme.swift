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
