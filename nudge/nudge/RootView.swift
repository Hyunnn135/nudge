//
//  RootView.swift
//  nudge
//
//  최상위 TabView — 오늘(카운터) / 통계
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("오늘", systemImage: "plus.circle.fill")
                }

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("통계", systemImage: "chart.bar.fill")
            }
        }
    }
}

#Preview {
    RootView()
}
