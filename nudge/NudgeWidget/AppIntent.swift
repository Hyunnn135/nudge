//
//  AppIntent.swift
//  NudgeWidget
//
//  위젯 탭으로 운동 카운트 +1 실행하는 App Intent.
//

import AppIntents
import WidgetKit

/// 위젯 버튼 탭 → 해당 운동 +1.
struct IncrementExerciseIntent: AppIntent {
    static var title: LocalizedStringResource = "운동 +1"
    static var description = IntentDescription("선택한 운동 횟수를 1 증가시킵니다.")

    /// 실행 즉시 돌려주고 앱을 열지 않음 (홈 화면 / 잠금 화면 위젯에서 그대로 실행).
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
        // 위젯 갱신은 SharedStore 값 읽어서 다음 timeline 에 반영.
        return .result()
    }
}

/// 위젯에서 활성 운동(메인으로 보여질 운동)을 바꾸는 Intent — 사용자가 위젯을 꾹 눌러 편집 시.
struct SetActiveExerciseIntent: AppIntent {
    static var title: LocalizedStringResource = "활성 운동 변경"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Exercise")
    var exerciseRaw: String

    init() {}

    init(exercise: Exercise) {
        self.exerciseRaw = exercise.rawValue
    }

    func perform() async throws -> some IntentResult {
        let exercise = Exercise(rawValue: exerciseRaw) ?? .pushup
        SharedStore.activeExercise = exercise
        return .result()
    }
}
