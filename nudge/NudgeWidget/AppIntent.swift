//
//  AppIntent.swift
//  NudgeWidget
//
//  위젯 관련 AppIntent들:
//  - IncrementExerciseIntent : 위젯 탭 → 해당 운동 +1
//  - NudgeSingleConfigIntent : 소형 위젯의 "운동 선택" 구성 (꾹 눌러 Edit Widget)
//

import AppIntents
import WidgetKit

// MARK: - Increment (tap to +1)

/// 위젯 버튼 탭 → 해당 운동 +1. 앱을 열지 않음.
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
        let exercise = Exercise(rawValue: exerciseRaw) ?? .pushup
        SharedStore.increment(exercise)
        return .result()
    }
}

// MARK: - Widget configuration

/// 위젯 "운동 선택" Edit Widget UI 에 표시될 열거형.
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

/// Nudge 소형 위젯 구성 Intent — 꾹 눌러 Edit Widget 시 "운동" 선택 Picker 로 나타남.
struct NudgeSingleConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Nudge 위젯 설정"
    static var description = IntentDescription("이 위젯이 보여줄 운동을 선택하세요.")

    @Parameter(title: "운동", default: .pushup)
    var exercise: ExerciseChoice

    init() {}

    init(exercise: ExerciseChoice) {
        self.exercise = exercise
    }
}
