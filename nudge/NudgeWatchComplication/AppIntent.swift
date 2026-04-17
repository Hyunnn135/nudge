//
//  AppIntent.swift
//  NudgeWatchComplication
//
//  두 개의 AppIntent:
//  - NudgeComplicationConfigIntent : 컴플리케이션 "운동 선택" 구성
//  - IncrementExerciseIntent       : 컴플리케이션 탭 = 해당 운동 +1 (앱 안 열림)
//

import AppIntents
import WidgetKit

// MARK: - Configuration Intent

/// 컴플리케이션 구성 UI에 표시될 열거형.
enum ExerciseChoice: String, AppEnum {
    case pushup
    case pullup
    case squat

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "운동"
    static var caseDisplayRepresentations: [ExerciseChoice: DisplayRepresentation] = [
        .pushup: DisplayRepresentation(title: "푸시업"),
        .pullup: DisplayRepresentation(title: "풀업"),
        .squat:  DisplayRepresentation(title: "스쿼트")
    ]

    var exercise: Exercise {
        Exercise(rawValue: rawValue) ?? .pushup
    }
}

/// Nudge 컴플리케이션 구성 Intent — "운동" 선택 Picker 로 표시.
struct NudgeComplicationConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Nudge 컴플리케이션"
    static var description = IntentDescription("이 컴플리케이션이 보여줄 운동을 선택하세요.")

    @Parameter(title: "운동", default: .pushup)
    var exercise: ExerciseChoice

    init() {}

    init(exercise: ExerciseChoice) {
        self.exercise = exercise
    }
}

// MARK: - Increment Intent (tap = +1)

/// 컴플리케이션 탭 → 해당 운동 +1. 앱은 열리지 않음.
/// Nudge 핵심 철학: "한 번의 탭 = 한 번의 기록".
struct IncrementExerciseIntent: AppIntent {
    static var title: LocalizedStringResource = "운동 +1"
    static var description = IntentDescription("선택한 운동 횟수를 1 증가시킵니다.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Exercise")
    var exerciseRaw: String

    init() {}

    init(exercise: Exercise) {
        self.exerciseRaw = exercise.rawValue
    }

    func perform() async throws -> some IntentResult {
        SharedStore.appendDebugLog("intent:perform start raw=\(exerciseRaw)")
        let exercise = Exercise(rawValue: exerciseRaw) ?? .pushup
        let newCount = SharedStore.increment(exercise)
        SharedStore.appendDebugLog("intent:incremented \(exercise.rawValue)=\(newCount)")
        // 타임라인 즉시 새로고침 → 탭 직후 숫자 갱신.
        WidgetCenter.shared.reloadAllTimelines()
        // 위젯 프로세스에서 iPhone 으로 WC push (세션 활성화까지 최대 5초 대기).
        await NudgeSync.shared.pushAwaitingActivation()
        SharedStore.appendDebugLog("intent:perform end")
        return .result()
    }
}
