//
//  ContentView.swift
//  NudgeWatch Watch App
//
//  워치 메인 화면 — 활성 운동 이름 + 오늘 카운트 + 큰 +1 버튼.
//  활성 운동은 iPhone 쪽에서 고른 걸 읽기만 함 (워치에선 전환 UI 없음).
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @State private var activeExercise: Exercise = SharedStore.activeExercise
    @State private var count: Int = SharedStore.count(for: SharedStore.activeExercise)

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                // 상단: 활성 운동 이름
                Text(activeExercise.displayName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                // 중앙: 큰 숫자
                Text("\(count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(value: Double(count)))
                    .animation(.snappy, value: count)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                // +1 큰 버튼
                Button {
                    let new = SharedStore.increment(activeExercise)
                    count = new
                    WKInterfaceDevice.current().play(.click)
                    NudgeSync.shared.pushLocalChange()
                } label: {
                    Text("+1")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(activeExercise.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)

                // 디버그 log 진입 (개발 중에만)
                NavigationLink("🐞 Debug") { DebugLogView() }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            .onAppear { refresh() }
            // iPhone 에서 동기화로 데이터가 들어왔을 때
            .onReceive(NotificationCenter.default.publisher(for: .nudgeDataChangedRemote)) { _ in
                refresh()
            }
        }
    }

    private func refresh() {
        activeExercise = SharedStore.activeExercise
        count = SharedStore.count(for: activeExercise)
    }
}

#Preview {
    ContentView()
}
