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
        }
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
        return next
    }

    static func todayTotal() -> Int {
        let day = allCounts[dateKey()] ?? [:]
        return day.values.reduce(0, +)
    }
}
