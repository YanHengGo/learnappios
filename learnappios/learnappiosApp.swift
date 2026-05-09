//
//  learnappiosApp.swift
//  learnappios
//
//  Created by 厳恒 on 2026/05/08.
//

import SwiftUI

@main
struct learnappiosApp: App {
    @State private var deps = AppDependencies()
    @State private var navigator = AppNavigator()

    var body: some Scene {
        WindowGroup {
            // Phase 2 以降で RootView を実装する
            Text("Phase 1: ビルド確認")
        }
    }
}
