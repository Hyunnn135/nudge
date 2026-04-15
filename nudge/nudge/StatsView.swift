//
//  StatsView.swift
//  nudge
//
//  Phase 4 — 통계 화면
//  일간(7일) / 주간(4주) / 월간(12개월) 스택 바 차트 + 최근 12주 히트맵.
//

import SwiftUI
import Charts

// MARK: - Range

enum StatsRange: String, CaseIterable, Identifiable {
    case week   // 최근 7일
    case month  // 최근 4주 (주 단위 집계)
    case year   // 최근 12개월 (월 단위 집계)

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week:  return "주간"
        case .month: return "월간"
        case .year:  return "연간"
        }
    }
}

// MARK: - Bucket

/// 차트에 그릴 단일 x축 항목 (하루 / 한 주 / 한 달).
struct StatsBucket: Identifiable {
    let id: String
    let label: String          // x축 표시용 짧은 라벨
    let fullLabel: String      // 접근성/툴팁
    let counts: [Exercise: Int]

    var total: Int { counts.values.reduce(0, +) }
}

// MARK: - ViewModel helpers

enum StatsAggregator {
    static func buckets(for range: StatsRange) -> [StatsBucket] {
        switch range {
        case .week:  return weekBuckets()
        case .month: return monthBuckets()
        case .year:  return yearBuckets()
        }
    }

    // 최근 7일 (하루 1버킷)
    private static func weekBuckets() -> [StatsBucket] {
        let days = SharedStore.recentDays(7)
        let f = DateFormatter(); f.dateFormat = "E"; f.locale = Locale(identifier: "ko_KR")
        let ff = DateFormatter(); ff.dateFormat = "M/d (E)"; ff.locale = Locale(identifier: "ko_KR")
        return days.map { d in
            StatsBucket(
                id: ISO8601DateFormatter().string(from: d.date),
                label: f.string(from: d.date),
                fullLabel: ff.string(from: d.date),
                counts: d.counts
            )
        }
    }

    // 최근 4주 (주 단위 합산, 월요일 시작)
    private static func monthBuckets() -> [StatsBucket] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // 월요일

        let days = SharedStore.recentDays(28)
        // 월요일 시작 ISO-week 로 그룹화
        let groups = Dictionary(grouping: days) { entry -> Date in
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)
            return cal.date(from: comps) ?? entry.date
        }
        let sortedKeys = groups.keys.sorted()
        let f = DateFormatter(); f.dateFormat = "M/d"; f.locale = Locale(identifier: "ko_KR")

        return sortedKeys.map { weekStart in
            let items = groups[weekStart] ?? []
            var merged: [Exercise: Int] = [:]
            for ex in Exercise.allCases { merged[ex] = 0 }
            for item in items {
                for ex in Exercise.allCases {
                    merged[ex, default: 0] += (item.counts[ex] ?? 0)
                }
            }
            return StatsBucket(
                id: ISO8601DateFormatter().string(from: weekStart),
                label: f.string(from: weekStart),
                fullLabel: "\(f.string(from: weekStart)) 주",
                counts: merged
            )
        }
    }

    // 최근 12개월 (월 단위 합산)
    private static func yearBuckets() -> [StatsBucket] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // 12개월 전체 일수
        let dayCount: Int = {
            if let start = cal.date(byAdding: .month, value: -11, to: today) {
                return (cal.dateComponents([.day], from: start, to: today).day ?? 0) + 1
            }
            return 365
        }()
        let days = SharedStore.recentDays(dayCount)

        let groups = Dictionary(grouping: days) { entry -> Date in
            let comps = cal.dateComponents([.year, .month], from: entry.date)
            return cal.date(from: comps) ?? entry.date
        }
        let sortedKeys = groups.keys.sorted()
        let f = DateFormatter(); f.dateFormat = "M월"; f.locale = Locale(identifier: "ko_KR")
        let ff = DateFormatter(); ff.dateFormat = "yyyy년 M월"; ff.locale = Locale(identifier: "ko_KR")

        return sortedKeys.map { monthStart in
            let items = groups[monthStart] ?? []
            var merged: [Exercise: Int] = [:]
            for ex in Exercise.allCases { merged[ex] = 0 }
            for item in items {
                for ex in Exercise.allCases {
                    merged[ex, default: 0] += (item.counts[ex] ?? 0)
                }
            }
            return StatsBucket(
                id: ISO8601DateFormatter().string(from: monthStart),
                label: f.string(from: monthStart),
                fullLabel: ff.string(from: monthStart),
                counts: merged
            )
        }
    }
}

// MARK: - StatsView

struct StatsView: View {
    @State private var range: StatsRange = .week
    @State private var tick: Int = 0  // refresh trigger

    private var buckets: [StatsBucket] {
        _ = tick  // force recompute
        return StatsAggregator.buckets(for: range)
    }

    private var total: Int {
        buckets.reduce(0) { $0 + $1.total }
    }

    private var perExerciseTotal: [Exercise: Int] {
        var out: [Exercise: Int] = [:]
        for ex in Exercise.allCases { out[ex] = 0 }
        for b in buckets {
            for ex in Exercise.allCases {
                out[ex, default: 0] += (b.counts[ex] ?? 0)
            }
        }
        return out
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Picker("기간", selection: $range) {
                    ForEach(StatsRange.allCases) { r in
                        Text(r.title).tag(r)
                    }
                }
                .pickerStyle(.segmented)

                summaryCard

                chartCard

                if range == .week {
                    heatmapCard
                }

                breakdownCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("통계")
        .navigationBarTitleDisplayMode(.large)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            tick &+= 1
        }
    }

    // MARK: Cards

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(range.title + " 합계")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("\(total)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(total)))
                .animation(.snappy, value: total)
            Text("회")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("기간별 합계")
                .font(.headline)

            if buckets.isEmpty || total == 0 {
                emptyState(message: "아직 기록이 없어요. +1 버튼을 눌러 시작해보세요.")
            } else {
                Chart {
                    ForEach(buckets) { bucket in
                        ForEach(Exercise.allCases) { ex in
                            BarMark(
                                x: .value("기간", bucket.label),
                                y: .value("횟수", bucket.counts[ex] ?? 0)
                            )
                            .foregroundStyle(by: .value("운동", ex.displayName))
                        }
                    }
                }
                .chartForegroundStyleScale([
                    Exercise.pushup.displayName: Exercise.pushup.accentColor,
                    Exercise.pullup.displayName: Exercise.pullup.accentColor,
                    Exercise.squat.displayName:  Exercise.squat.accentColor
                ])
                .chartLegend(position: .bottom, spacing: 8)
                .frame(height: 220)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("일일 활동 히트맵")
                    .font(.headline)
                Spacer()
                Text(heatmapDateRangeLabel)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text("왼쪽→오른쪽 = 과거→오늘 · 진할수록 많이 운동한 날 · 셀을 탭하면 상세")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            Heatmap()
                .padding(.top, 4)

            HStack(spacing: 6) {
                Text("적음").font(.caption2).foregroundStyle(.secondary)
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Heatmap.colorForLevel(i))
                        .frame(width: 12, height: 12)
                }
                Text("많음").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.primary, lineWidth: 1.5)
                    .frame(width: 12, height: 12)
                Text("오늘").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.top, 6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    /// "1/27 ~ 4/15" 형식 날짜 범위 (최근 12주 전 월요일 ~ 오늘)
    private var heatmapDateRangeLabel: String {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        guard let thisMonday = cal.date(byAdding: .day, value: -daysSinceMonday, to: today),
              let startMonday = cal.date(byAdding: .day, value: -7 * 11, to: thisMonday)
        else { return "" }
        let f = DateFormatter()
        f.dateFormat = "M/d"
        f.locale = Locale(identifier: "ko_KR")
        return "\(f.string(from: startMonday)) ~ \(f.string(from: today))"
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("운동별 합계")
                .font(.headline)
            ForEach(Exercise.allCases) { ex in
                HStack(spacing: 12) {
                    Circle()
                        .fill(ex.accentColor)
                        .frame(width: 10, height: 10)
                    Text(ex.displayName)
                        .font(.body)
                    Spacer()
                    Text("\(perExerciseTotal[ex] ?? 0)회")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: Empty state

    private func emptyState(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
}

// MARK: - Heatmap (12 weeks × 7 days, GitHub-style)

struct Heatmap: View {
    private let weeks = 12
    private let spacing: CGFloat = 4
    private let yLabelWidth: CGFloat = 18

    struct Cell: Identifiable {
        let id: String
        let date: Date
        let total: Int
        let counts: [Exercise: Int]
        let isFuture: Bool
        let isToday: Bool
    }

    @State private var selectedCell: Cell?

    private var cells: [[Cell]] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // 월요일
        let today = cal.startOfDay(for: Date())

        // 오늘이 속한 주의 월요일
        let weekday = cal.component(.weekday, from: today)
        // weekday: 일=1, 월=2 ... 일요일 기준. firstWeekday=2 이면 월요일 오프셋 = (weekday + 5) % 7
        let daysSinceMonday = (weekday + 5) % 7
        guard let thisMonday = cal.date(byAdding: .day, value: -daysSinceMonday, to: today) else { return [] }
        guard let startMonday = cal.date(byAdding: .day, value: -7 * (weeks - 1), to: thisMonday) else { return [] }

        let iso = ISO8601DateFormatter()
        var columns: [[Cell]] = []
        for w in 0..<weeks {
            var col: [Cell] = []
            for d in 0..<7 {
                guard let date = cal.date(byAdding: .day, value: w * 7 + d, to: startMonday) else { continue }
                let isFuture = date > today
                let isToday = cal.isDate(date, inSameDayAs: today)
                let counts: [Exercise: Int] = isFuture ? [:] : SharedStore.counts(on: date)
                let sum = counts.values.reduce(0, +)
                col.append(Cell(
                    id: iso.string(from: date),
                    date: date,
                    total: sum,
                    counts: counts,
                    isFuture: isFuture,
                    isToday: isToday
                ))
            }
            columns.append(col)
        }
        return columns
    }

    static func colorForLevel(_ level: Int) -> Color {
        // level 0~4
        switch level {
        case 0: return Color(uiColor: .tertiarySystemFill)
        case 1: return Color(red: 0.78, green: 0.92, blue: 0.90)
        case 2: return Color(red: 0.47, green: 0.80, blue: 0.77)
        case 3: return Color(red: 0.18, green: 0.58, blue: 0.57)
        default: return Color(red: 0.09, green: 0.42, blue: 0.42)
        }
    }

    private func level(for total: Int) -> Int {
        switch total {
        case ..<1:   return 0
        case 1..<10: return 1
        case 10..<25: return 2
        case 25..<50: return 3
        default: return 4
        }
    }

    /// 월/수/금/일 행에만 라벨 (0=월, 2=수, 4=금, 6=일).
    private func yLabel(for row: Int) -> String {
        switch row {
        case 0: return "월"
        case 2: return "수"
        case 4: return "금"
        case 6: return "일"
        default: return ""
        }
    }

    var body: some View {
        // 고정 셀 크기 — 가로폭 계산(282pt)이 iPhone SE 카드 내부(≈295pt)에도 들어감.
        // GeometryReader 제거: 자체 사이즈 계산이 예측 가능해 범례와 겹치지 않음.
        let cols = cells
        let cellSize: CGFloat = 18

        HStack(alignment: .top, spacing: spacing) {
            // Y축 요일 라벨 (월/수/금/일)
            VStack(spacing: spacing) {
                ForEach(0..<7, id: \.self) { r in
                    Text(yLabel(for: r))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(width: yLabelWidth, height: cellSize, alignment: .trailing)
                }
            }

            // 히트맵 셀 12열 × 7행
            ForEach(Array(cols.enumerated()), id: \.offset) { _, col in
                VStack(spacing: spacing) {
                    ForEach(col) { cell in
                        cellView(cell, size: cellSize)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .popover(item: $selectedCell) { cell in
            popoverContent(for: cell)
        }
    }

    @ViewBuilder
    private func cellView(_ cell: Cell, size: CGFloat) -> some View {
        ZStack {
            if cell.isFuture {
                Color.clear
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Heatmap.colorForLevel(level(for: cell.total)))
            }
            if cell.isToday {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.primary, lineWidth: 1.5)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !cell.isFuture else { return }
            selectedCell = cell
        }
    }

    @ViewBuilder
    private func popoverContent(for cell: Cell) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formatDate(cell.date))
                .font(.subheadline.weight(.semibold))
            Divider()
            ForEach(Exercise.allCases) { ex in
                HStack(spacing: 8) {
                    Circle()
                        .fill(ex.accentColor)
                        .frame(width: 8, height: 8)
                    Text(ex.displayName)
                        .font(.caption)
                    Spacer()
                    Text("\(cell.counts[ex] ?? 0)회")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            HStack {
                Text("합계").font(.caption.weight(.semibold))
                Spacer()
                Text("\(cell.total)회")
                    .font(.caption.monospacedDigit().weight(.semibold))
            }
        }
        .padding(14)
        .frame(minWidth: 180)
        .presentationCompactAdaptation(.popover)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M월 d일 (E)"
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: date)
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
}
