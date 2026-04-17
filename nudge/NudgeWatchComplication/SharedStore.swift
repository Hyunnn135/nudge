//
//  SharedStore.swift
//  NudgeWatchComplication
//
//  ⚠️ 이 파일은 아래 4곳에 동일 내용으로 존재합니다. 한 쪽 수정 시 전부 동기화하세요:
//     - nudge/SharedStore.swift (iOS 앱)
//     - NudgeWidget/SharedStore.swift (iOS 위젯)
//     - NudgeWatch Watch App/SharedStore.swift (watchOS 앱)
//     - NudgeWatchComplication/SharedStore.swift (watchOS 컴플리케이션)
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
enum SharedStore {
    static let appGroupID = "group.site.salarykorea.nudge"

    private static let activeExerciseKey = "activeExercise"
    private static let countsKey = "dailyCounts"
    private static let lastModifiedKey = "lastModified"
    private static let debugLogKey = "syncDebugLog"

    // MARK: Debug log (App Group 공유 — 위젯 프로세스 trace 확인용)

    static func appendDebugLog(_ message: String) {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        let ts = f.string(from: Date())
        let entry = "[\(ts)] \(message)"
        var log = defaults.stringArray(forKey: debugLogKey) ?? []
        log.append(entry)
        if log.count > 100 { log = Array(log.suffix(100)) }
        defaults.set(log, forKey: debugLogKey)
    }

    static var debugLog: [String] {
        defaults.stringArray(forKey: debugLogKey) ?? []
    }

    static func clearDebugLog() {
        defaults.removeObject(forKey: debugLogKey)
    }

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

    // MARK: Last modified

    static var lastModified: TimeInterval {
        get { defaults.double(forKey: lastModifiedKey) }
        set { defaults.set(newValue, forKey: lastModifiedKey) }
    }

    static func touch(_ date: Date = Date()) {
        lastModified = date.timeIntervalSince1970
    }

    // MARK: Daily counts

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

    // MARK: Sync

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

    @discardableResult
    static func applyRemoteSnapshot(_ payload: [String: Any]) -> Bool {
        guard let remoteModified = payload["lastModified"] as? TimeInterval else { return false }
        guard remoteModified > lastModified else { return false }

        if let activeRaw = payload["activeExercise"] as? String,
           let ex = Exercise(rawValue: activeRaw) {
            defaults.set(ex.rawValue, forKey: activeExerciseKey)
        }
        if let remoteCounts = payload["counts"] as? [String: [String: Int]] {
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

    // MARK: History

    static func counts(on date: Date) -> [Exercise: Int] {
        let day = allCounts[dateKey(for: date)] ?? [:]
        var out: [Exercise: Int] = [:]
        for ex in Exercise.allCases {
            out[ex] = day[ex.rawValue] ?? 0
        }
        return out
    }

    static func recentDays(_ days: Int) -> [(date: Date, counts: [Exercise: Int])] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).reversed().compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (d, counts(on: d))
        }
    }

    static func recordedDateRange() -> (oldest: Date, newest: Date)? {
        let keys = allCounts.keys.sorted()
        guard let first = keys.first, let last = keys.last else { return nil }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .current
        guard let o = f.date(from: first), let n = f.date(from: last) else { return nil }
        return (o, n)
    }
}
