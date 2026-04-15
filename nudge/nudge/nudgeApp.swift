//
//  nudgeApp.swift
//  nudge
//

import SwiftUI

@main
struct nudgeApp: App {
    // NudgeSync singleton 을 앱 생성 시점에 활성화 (WCSession.activate).
    @StateObject private var sync = NudgeSync.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sync)
        }
    }
}
