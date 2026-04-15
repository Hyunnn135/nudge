//
//  NudgeWidget.swift
//  NudgeWidget
//
//  Nudge 위젯 — 3개 운동(푸시업/풀업/스쿼트) 버튼 탭으로 +1.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline

struct NudgeEntry: TimelineEntry {
    let date: Date
    let counts: [Exercise: Int]
    let activeExercise: Exercise

    static let placeholder = NudgeEntry(
        date: Date(),
        counts: [.pushup: 12, .pullup: 4, .squat: 20],
        activeExercise: .pushup
    )
}

struct NudgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> NudgeEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (NudgeEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NudgeEntry>) -> Void) {
        // 현재 값 기반 엔트리 + 자정 리셋을 위해 다음 자정에 리프레시 예약.
        let now = Date()
        let entry = currentEntry(at: now)

        let calendar = Calendar.current
        let nextMidnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(60 * 60)

        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func currentEntry(at date: Date = Date()) -> NudgeEntry {
        let counts: [Exercise: Int] = Exercise.allCases.reduce(into: [:]) { acc, ex in
            acc[ex] = SharedStore.count(for: ex, on: date)
        }
        return NudgeEntry(
            date: date,
            counts: counts,
            activeExercise: SharedStore.activeExercise
        )
    }
}

// MARK: - Views

/// 소형 위젯 — 활성 운동 1개만 크게 보여주고 탭 영역 전체가 +1.
struct NudgeSmallView: View {
    let entry: NudgeEntry

    private var activeCount: Int { entry.counts[entry.activeExercise] ?? 0 }

    var body: some View {
        Button(intent: IncrementExerciseIntent(exercise: entry.activeExercise)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: entry.activeExercise.symbolName)
                        .font(.title3)
                        .foregroundStyle(entry.activeExercise.accentColor)
                    Spacer()
                    Text("+1")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(entry.activeExercise.accentColor.opacity(0.15))
                        .foregroundStyle(entry.activeExercise.accentColor)
                        .clipShape(Capsule())
                }

                Spacer()

                Text("\(activeCount)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(entry.activeExercise.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .buttonStyle(.plain)
    }
}

/// 중형 위젯 — 3개 운동 모두 표시. 각 카드 탭 = 해당 운동 +1.
struct NudgeMediumView: View {
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

struct NudgeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: NudgeEntry

    var body: some View {
        switch family {
        case .systemSmall:
            NudgeSmallView(entry: entry)
        default:
            NudgeMediumView(entry: entry)
        }
    }
}

// MARK: - Widget

struct NudgeWidget: Widget {
    let kind: String = "NudgeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NudgeProvider()) { entry in
            NudgeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Nudge")
        .description("탭 한 번으로 오늘의 운동 1회 기록.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    NudgeWidget()
} timeline: {
    NudgeEntry.placeholder
}

#Preview(as: .systemMedium) {
    NudgeWidget()
} timeline: {
    NudgeEntry.placeholder
}
