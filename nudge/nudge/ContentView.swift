//
//  ContentView.swift
//  nudge
//
//  메인 화면 — 활성 운동 선택 + 오늘 카운트 + 큰 +1 버튼
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var activeExercise: Exercise = SharedStore.activeExercise
    @State private var count: Int = 0

    // 앱이 foreground 로 돌아오면 위젯에서 찍힌 값이 반영되도록 tick 갱신
    @State private var tick: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            counter
            Spacer()
            plusButton
            minusButton
                .padding(.top, 12)
            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 24)
        .background(Color(uiColor: .systemBackground))
        .onAppear { refresh() }
        .onChange(of: activeExercise) { _, newValue in
            SharedStore.activeExercise = newValue
            refresh()
            WidgetCenter.shared.reloadAllTimelines()
            NudgeSync.shared.pushLocalChange()
        }
        // 앱이 다시 활성화될 때 (위젯에서 탭 후 앱 열었을 경우 등) 값 동기화
        // + 위젯 extension 에서 찍힌 값도 여기서 Watch 로 한번 push.
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            refresh()
            NudgeSync.shared.pushLocalChange()
        }
        // Watch 에서 원격 동기화로 값이 바뀌었을 때 UI 갱신
        .onReceive(NotificationCenter.default.publisher(for: .nudgeDataChangedRemote)) { _ in
            refresh()
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Nudge")
                    .font(.title2.weight(.bold))
                Spacer()
                Text(todayString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)

            Picker("운동 선택", selection: $activeExercise) {
                ForEach(Exercise.allCases) { ex in
                    Text(ex.displayName).tag(ex)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var counter: some View {
        VStack(spacing: 8) {
            Image(systemName: activeExercise.symbolName)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(activeExercise.accentColor)
                .padding(.bottom, 8)

            Text("\(count)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText(value: Double(count)))
                .animation(.snappy, value: count)

            Text("오늘 \(activeExercise.displayName)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var plusButton: some View {
        Button {
            let new = SharedStore.increment(activeExercise)
            count = new
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            WidgetCenter.shared.reloadAllTimelines()
            NudgeSync.shared.pushLocalChange()
        } label: {
            Text("+1")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .background(activeExercise.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var minusButton: some View {
        Button {
            let new = SharedStore.decrement(activeExercise)
            count = new
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            WidgetCenter.shared.reloadAllTimelines()
            NudgeSync.shared.pushLocalChange()
        } label: {
            Text("−1 취소")
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
        .opacity(count == 0 ? 0.4 : 1)
    }

    // MARK: Helpers

    private func refresh() {
        activeExercise = SharedStore.activeExercise
        count = SharedStore.count(for: activeExercise)
    }

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "M월 d일 (E)"
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: Date())
    }
}

#Preview {
    ContentView()
}
