//
//  NudgeWatchComplicationBundle.swift
//  NudgeWatchComplication
//
//  @main 진입점. 여러 개의 Widget 을 하나의 extension 에 담을 수 있음.
//

import WidgetKit
import SwiftUI

@main
struct NudgeWatchComplicationBundle: WidgetBundle {
    var body: some Widget {
        NudgeWatchComplication()
    }
}
