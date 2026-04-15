//
//  NudgeWatchApp.swift
//  NudgeWatch Watch App
//

import SwiftUI

@main
struct NudgeWatch_Watch_AppApp: App {
    // WCSession 활성화 (앱 실행 시점).
    @StateObject private var sync = NudgeSync.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sync)
        }
    }
}
