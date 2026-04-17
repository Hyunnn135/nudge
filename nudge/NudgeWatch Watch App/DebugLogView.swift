//
//  DebugLogView.swift
//  NudgeWatch Watch App
//
//  App Group UserDefaults 에 쌓인 sync debug trace 확인용.
//  위젯 프로세스 trace 를 Watch 앱에서 읽어서 표시.
//

import SwiftUI

struct DebugLogView: View {
    @State private var entries: [String] = SharedStore.debugLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                if entries.isEmpty {
                    Text("(empty)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ForEach(entries.reversed().indices, id: \.self) { i in
                    Text(entries.reversed()[i])
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Debug")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") {
                    SharedStore.clearDebugLog()
                    entries = []
                }
                .font(.caption2)
            }
        }
        .onAppear { entries = SharedStore.debugLog }
    }
}
