//
//  SharedStore.swift
//  nudge
//
//  앱 ↔ 위젯 공용 데이터 저장소 (App Group UserDefaults 기반)
//
//  ⚠️ 이 파일은 NudgeWidget/SharedStore.swift 와 내용이 동일해야 합니다.
//     한 쪽 수정 시 다른 쪽도 반드시 같이 수정하세요.
//

import Foundation
import SwiftUI

// MARK: - Exercise

enum Exercise: String, CaseIterable, Codable, Identifiable {
    case pushup
    case pullup
    case squat

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pushup: return "푸시업"
        case .pullup: return "풀업"
        case .squat:  return "스쿼트"
        }
    }

    var symbolName: String {
        switch self {
        case .pushup: return "figure.strengthtraining.traditional"
        case .pullup: return "figure.pilates"
        case .squat:  return "figure.cross.training"
        }
    }

    var accentColor: Color {
        switch self {
        case .pushup: return Color(red: 0.18, green: 0.58, blue: 0.57) // teal
        case .pullup: return Color(red: 0.24, green: 0.50, blue: 0.70) // blue-teal
        case .squat:  return Color(red: 0.35, green: 0.60, blue: 0.45) // sage
        }
    }
}

// MARK: - SharedStore

/// 위젯 ↔ 앱이 공유하는 저장소.
/// Phase 1 에선 App Group UserDefaults 기반.
/// Phase 4(통계)에서 히스토리 필요해지면 SwiftData 또는 JSON 파일로 확장.
enum SharedStore {
    /// App Group identifier. nudge.entitlements / NudgeWidget.entitlements 와 일치.
    static let appGroupID = "group.site.salarykorea.nudge"

    private static let activeExerciseKey = "activeExercise"
    private static let countsKey = "dailyCounts"
    private static let lastModifiedKey = "lastModified"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: Active exercise

    static var activeExercise: Exercise {
        get {
            let raw = defaults.string(forKey: activeExerciseKey) ?? Exercise.pushup.rawValue
            return Exercise(rawValue: raw) ?? .pushup
        }
        set {
            defaults.set(newValue.rawValue, forKey: activeExerciseKey)
            touch()
        }
    }

    // MARK: Last modified (WatchConnectivity sync 용 last-writer-wins 타임스탬프)

    static var lastModified: TimeInterval {
        get { defaults.double(forKey: lastModifiedKey) }
        set { defaults.set(newValue, forKey: lastModifiedKey) }
    }

    /// 데이터 변경 시 호출. 현재 시각으로 타임스탬프 갱신.
    static func touch(_ date: Date = Date()) {
        lastModified = date.timeIntervalSince1970
    }

    // MARK: Daily counts
    // 저장 포맷: [ "2026-04-15": ["pushup": 10, "pullup": 3, "squat": 15] ]

    private static var allCounts: [String: [String: Int]] {
        get {
            guard let data = defaults.data(forKey: countsKey) else { return [:] }
            return (try? JSONDecoder().decode([String: [String: Int]].self, from: data)) ?? [:]
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: countsKey)
        }
    }

    /// "YYYY-MM-DD" 형식 키 (로컬 타임존 기준).
    static func dateKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    static func count(for exercise: Exercise, on date: Date = Date()) -> Int {
        let key = dateKey(for: date)
        return allCounts[key]?[exercise.rawValue] ?? 0
    }

    @discardableResult
    static func increment(_ exercise: Exercise, on date: Date = Date()) -> Int {
        var counts = allCounts
        let key = dateKey(for: date)
        var day = counts[key] ?? [:]
        let next = (day[exercise.rawValue] ?? 0) + 1
        day[exercise.rawValue] = next
        counts[key] = day
        allCounts = counts
        touch()
        return next
    }

    @discardableResult
    static func decrement(_ exercise: Exercise, on date: Date = Date()) -> Int {
        var counts = allCounts
        let key = dateKey(for: date)
        var day = counts[key] ?? [:]
        let next = max(0, (day[exercise.rawValue] ?? 0) - 1)
        day[exercise.rawValue] = next
        counts[key] = day
        allCounts = counts
        touch()
        return next
    }

    // MARK: Sync (WatchConnectivity payload 형태)

    /// WC 전송용 스냅샷. 전체 history 가 아니라 최근 60 일만 포함 (payload 크기 ↓).
    static func syncSnapshot(daysBack: Int = 60) -> [String: Any] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let cutoff = cal.date(byAdding: .day, value: -daysBack, to: today)
        var trimmed: [String: [String: Int]] = [:]
        for (k, v) in allCounts {
            if let cut = cutoff {
                let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .current
                if let d = f.date(from: k), d >= cut { trimmed[k] = v }
            } else {
                trimmed[k] = v
            }
        }
        return [
            "activeExercise": activeExercise.rawValue,
            "counts": trimmed,
            "lastModified": lastModified
        ]
    }

    /// WC 수신 시 병합. 원격 lastModified 가 로컬보다 최신이면 overwrite.
    /// `true` 반환 시 UI 갱신 필요.
    @discardableResult
    static func applyRemoteSnapshot(_ payload: [String: Any]) -> Bool {
        guard let remoteModified = payload["lastModified"] as? TimeInterval else { return false }
        // 같거나 과거면 무시
        guard remoteModified > lastModified else { return false }

        if let activeRaw = payload["activeExercise"] as? String,
           let ex = Exercise(rawValue: activeRaw) {
            defaults.set(ex.rawValue, forKey: activeExerciseKey)
        }
        if let remoteCounts = payload["counts"] as? [String: [String: Int]] {
            // 최근 60일 치만 덮어쓰고, 원격이 보내지 않은 오래된 기록은 보존
            var merged = allCounts
            for (k, v) in remoteCounts { merged[k] = v }
            allCounts = merged
        }
        lastModified = remoteModified
        return true
    }

    static func todayTotal() -> Int {
        let day = allCounts[dateKey()] ?? [:]
        return day.values.reduce(0, +)
    }

    // MARK: History (Phase 4 — stats)

    /// 날짜 하루의 운동별 카운트 dict 반환.
    static func counts(on date: Date) -> [Exercise: Int] {
        let day = allCounts[dateKey(for: date)] ?? [:]
        var out: [Exercise: Int] = [:]
        for ex in Exercise.allCases {
            out[ex] = day[ex.rawValue] ?? 0
        }
        return out
    }

    /// 최근 `days` 일 (오늘 포함, 오래된 → 최신 순) 배열.
    static func recentDays(_ days: Int) -> [(date: Date, counts: [Exercise: Int])] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).reversed().compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (d, counts(on: d))
        }
    }

    /// 전체 기록된 날짜 범위 (가장 오래된 날짜, 가장 최신 날짜). 기록 없으면 nil.
    static func recordedDateRange() -> (oldest: Date, newest: Date)? {
        let keys = allCounts.keys.sorted()
        guard let first = keys.first, let last = keys.last else { return nil }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .current
        guard let o = f.date(from: first), let n = f.date(from: last) else { return nil }
        return (o, n)
    }
}
