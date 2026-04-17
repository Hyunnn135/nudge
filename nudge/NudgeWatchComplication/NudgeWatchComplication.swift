//
//  NudgeWatchComplication.swift
//  NudgeWatchComplication
//
//  Apple Watch 시계 화면 컴플리케이션.
//  지원 패밀리:
//  - .accessoryCircular     : 원형 — 아이콘 + 카운트
//  - .accessoryInline       : 상단 텍스트 — "푸시업 12"
//  - .accessoryRectangular  : 직사각형 — 3종 운동 카운트 한눈에
//
//  사용자가 원하는 운동을 선택(NudgeComplicationConfigIntent)하면
//  circular/inline 에서 해당 운동 표시. rectangular 는 3종 모두 표시.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Entry

struct NudgeWatchEntry: TimelineEntry {
    let date: Date
    let counts: [Exercise: Int]
    let selectedExercise: Exercise

    static let placeholder = NudgeWatchEntry(
        date: .now,
        counts: [.pushup: 12, .pullup: 4, .squat: 20],
        selectedExercise: .pushup
    )
}

// MARK: - Timeline Provider

struct NudgeWatchProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> NudgeWatchEntry { .placeholder }

    func snapshot(for configuration: NudgeComplicationConfigIntent, in context: Context) async -> NudgeWatchEntry {
        entry(for: configuration.exercise.exercise)
    }

    func timeline(for configuration: NudgeComplicationConfigIntent, in context: Context) async -> Timeline<NudgeWatchEntry> {
        Timeline(
            entries: [entry(for: configuration.exercise.exercise)],
            policy: .after(nextMidnight())
        )
    }

    /// 컴플리케이션 추천 프리셋 — 시계 화면 꾸미기 시 상단에 바로 보이는 기본값 3종.
    func recommendations() -> [AppIntentRecommendation<NudgeComplicationConfigIntent>] {
        [
            AppIntentRecommendation(intent: NudgeComplicationConfigIntent(exercise: .pushup), description: "푸시업"),
            AppIntentRecommendation(intent: NudgeComplicationConfigIntent(exercise: .pullup), description: "풀업"),
            AppIntentRecommendation(intent: NudgeComplicationConfigIntent(exercise: .squat),  description: "스쿼트")
        ]
    }

    // MARK: Helpers

    private func entry(for exercise: Exercise) -> NudgeWatchEntry {
        var counts: [Exercise: Int] = [:]
        for ex in Exercise.allCases {
            counts[ex] = SharedStore.count(for: ex, on: .now)
        }
        return NudgeWatchEntry(date: .now, counts: counts, selectedExercise: exercise)
    }

    private func nextMidnight() -> Date {
        Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(3600)
    }
}

// MARK: - Entry View

struct NudgeWatchComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: NudgeWatchEntry

    private var selectedCount: Int {
        entry.counts[entry.selectedExercise] ?? 0
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryInline:
            inlineView
        case .accessoryRectangular:
            rectangularView
        default:
            circularView
        }
    }

    // MARK: Circular

    /// 원형 슬롯 — 아이콘 + 숫자.
    /// 탭 = 선택된 운동 +1 (앱 안 열림).
    private var circularView: some View {
        Button(intent: IncrementExerciseIntent(exercise: entry.selectedExercise)) {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: -1) {
                    Image(systemName: entry.selectedExercise.symbolName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("\(selectedCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .buttonStyle(.plain)
        .widgetAccentable()
    }

    // MARK: Inline

    /// 시계 화면 상단 한 줄 텍스트 — "푸시업 12".
    /// 인라인은 Button 래핑 불가(시스템 제약) → 탭 시 앱 열림.
    private var inlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: entry.selectedExercise.symbolName)
            Text("\(entry.selectedExercise.displayName) \(selectedCount)")
        }
    }

    // MARK: Rectangular

    /// 직사각형 슬롯 — 3종 운동 카드 각각 +1 버튼.
    private var rectangularView: some View {
        HStack(spacing: 6) {
            ForEach(Exercise.allCases) { ex in
                Button(intent: IncrementExerciseIntent(exercise: ex)) {
                    VStack(spacing: 1) {
                        Image(systemName: ex.symbolName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("\(entry.counts[ex] ?? 0)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .minimumScaleFactor(0.6)
                        Text(ex.displayName)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .widgetAccentable()
    }
}

// MARK: - Widget

struct NudgeWatchComplication: Widget {
    let kind: String = "NudgeWatchComplication"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: NudgeComplicationConfigIntent.self,
            provider: NudgeWatchProvider()
        ) { entry in
            NudgeWatchComplicationEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Nudge")
        .description("오늘 운동 횟수를 시계 화면에 표시합니다.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    NudgeWatchComplication()
} timeline: {
    NudgeWatchEntry.placeholder
    NudgeWatchEntry(date: .now, counts: [.pushup: 47, .pullup: 12, .squat: 30], selectedExercise: .pushup)
}

#Preview("Inline", as: .accessoryInline) {
    NudgeWatchComplication()
} timeline: {
    NudgeWatchEntry.placeholder
}

#Preview("Rectangular", as: .accessoryRectangular) {
    NudgeWatchComplication()
} timeline: {
    NudgeWatchEntry.placeholder
}
