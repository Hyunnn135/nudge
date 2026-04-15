//
//  NudgeWidget.swift
//  NudgeWidget
//
//  두 종류의 위젯:
//  - NudgeSingleWidget : 소형, 구성 가능(운동 선택). 전체 탭 = 해당 운동 +1
//  - NudgeTriWidget    : 중형, 구성 없음. 3개 운동 카드 각각 탭 = +1
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Entry

struct NudgeEntry: TimelineEntry {
    let date: Date
    let counts: [Exercise: Int]
    let exercise: Exercise // 소형 위젯에서 보여줄 운동 (중형에서는 무시)

    static let placeholder = NudgeEntry(
        date: Date(),
        counts: [.pushup: 12, .pullup: 4, .squat: 20],
        exercise: .pushup
    )
}

// MARK: - Helpers

private func currentCounts(at date: Date = Date()) -> [Exercise: Int] {
    Exercise.allCases.reduce(into: [:]) { acc, ex in
        acc[ex] = SharedStore.count(for: ex, on: date)
    }
}

private func nextMidnight(from date: Date = Date()) -> Date {
    Calendar.current.nextDate(
        after: date,
        matching: DateComponents(hour: 0, minute: 0, second: 0),
        matchingPolicy: .nextTime
    ) ?? date.addingTimeInterval(60 * 60)
}

// MARK: - Providers

/// 소형 위젯 Provider — Intent 로 사용자가 선택한 운동을 받음.
struct NudgeSingleProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> NudgeEntry { .placeholder }

    func snapshot(for configuration: NudgeSingleConfigIntent, in context: Context) async -> NudgeEntry {
        entry(for: configuration.exercise.exercise)
    }

    func timeline(for configuration: NudgeSingleConfigIntent, in context: Context) async -> Timeline<NudgeEntry> {
        let e = entry(for: configuration.exercise.exercise)
        return Timeline(entries: [e], policy: .after(nextMidnight()))
    }

    private func entry(for ex: Exercise) -> NudgeEntry {
        NudgeEntry(date: Date(), counts: currentCounts(), exercise: ex)
    }
}

/// 중형 위젯 Provider — 구성 없음. 3종 모두 표시.
struct NudgeTriProvider: TimelineProvider {
    func placeholder(in context: Context) -> NudgeEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (NudgeEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NudgeEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .after(nextMidnight())))
    }

    private func currentEntry() -> NudgeEntry {
        NudgeEntry(date: Date(), counts: currentCounts(), exercise: .pushup)
    }
}

// MARK: - Views

/// 소형 위젯 — 1개 운동 크게, 위젯 전체 탭 = +1.
struct NudgeSingleView: View {
    let entry: NudgeEntry

    private var count: Int { entry.counts[entry.exercise] ?? 0 }

    var body: some View {
        Button(intent: IncrementExerciseIntent(exercise: entry.exercise)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: entry.exercise.symbolName)
                        .font(.title3)
                        .foregroundStyle(entry.exercise.accentColor)
                    Spacer()
                    Text("+1")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(entry.exercise.accentColor.opacity(0.15))
                        .foregroundStyle(entry.exercise.accentColor)
                        .clipShape(Capsule())
                }

                Spacer()

                Text("\(count)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(entry.exercise.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }
}

/// 중형 위젯 — 3개 운동 카드 병렬. 각 카드 탭 = 해당 운동 +1.
struct NudgeTriView: View {
    let entry: NudgeEntry

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Exercise.allCases) { ex in
                Button(intent: IncrementExerciseIntent(exercise: ex)) {
                    VStack(spacing: 6) {
                        Image(systemName: ex.symbolName)
                            .font(.title3)
                            .foregroundStyle(ex.accentColor)

                        Text("\(entry.counts[ex] ?? 0)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)

                        Text(ex.displayName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ex.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Widgets

struct NudgeSingleWidget: Widget {
    let kind: String = "NudgeSingleWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: NudgeSingleConfigIntent.self,
            provider: NudgeSingleProvider()
        ) { entry in
            NudgeSingleView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Nudge")
        .description("운동 1종 — 탭 한 번으로 +1. 꾹 눌러 운동 변경.")
        .supportedFamilies([.systemSmall])
    }
}

struct NudgeTriWidget: Widget {
    let kind: String = "NudgeTriWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NudgeTriProvider()) { entry in
            NudgeTriView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Nudge 3종")
        .description("푸시업 · 풀업 · 스쿼트 — 각 버튼 탭 = +1.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Previews

#Preview("Single (small)", as: .systemSmall) {
    NudgeSingleWidget()
} timeline: {
    NudgeEntry.placeholder
    NudgeEntry(date: Date(), counts: [.pushup: 25, .pullup: 8, .squat: 40], exercise: .pullup)
}

#Preview("Tri (medium)", as: .systemMedium) {
    NudgeTriWidget()
} timeline: {
    NudgeEntry.placeholder
}
