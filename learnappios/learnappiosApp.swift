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
            RootView(navigator: navigator, deps: deps)
        }
    }
}
