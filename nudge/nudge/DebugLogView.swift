//
//  DebugLogView.swift
//  nudge
//
//  App Group UserDefaults 에 쌓인 sync debug trace 확인용.
//  iPhone 쪽 수신 trace 를 iPhone 앱에서 읽어서 표시.
//

import SwiftUI

struct DebugLogView: View {
    @State private var entries: [String] = SharedStore.debugLog

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if entries.isEmpty {
                        Text("(empty)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(entries.reversed().indices, id: \.self) { i in
                        Text(entries.reversed()[i])
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                    }
                }
                .padding()
            }
            .navigationTitle("Debug Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        SharedStore.clearDebugLog()
                        entries = []
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Refresh") { entries = SharedStore.debugLog }
                }
            }
            .onAppear { entries = SharedStore.debugLog }
        }
    }
}
