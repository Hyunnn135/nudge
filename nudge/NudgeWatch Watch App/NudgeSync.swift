//
//  NudgeSync.swift
//  NudgeWatch Watch App (+ nudge, NudgeWatchComplication — 동일 내용 3곳 복제)
//
//  WatchConnectivity 기반 iPhone ↔ Watch 데이터 동기화.
//  전략: last-writer-wins (SharedStore.lastModified 타임스탬프 비교)
//  전송 방식: updateApplicationContext (최신 값만 배달, 용량 4KB 이내)
//
//  ⚠️ 이 파일은 3개 타겟에 동일 내용으로 존재합니다. 한쪽 수정 시 반드시 다른 쪽도 같이 수정하세요:
//     - nudge/NudgeSync.swift (iOS 앱)
//     - NudgeWatch Watch App/NudgeSync.swift (watchOS 앱) ← 이 파일
//     - NudgeWatchComplication/NudgeSync.swift (watchOS 컴플리케이션 — pushAwaitingActivation 추가본)
//

import Foundation
import Combine  // ObservableObject 프로토콜 (SwiftUI/Combine 양쪽에서 노출)

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

#if os(iOS)
import UIKit
import WidgetKit
#endif

final class NudgeSync: NSObject, ObservableObject {

    static let shared = NudgeSync()

    @Published private(set) var lastSyncAt: Date?

    #if canImport(WatchConnectivity)
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    #endif

    private override init() {
        super.init()
        activate()
    }

    func activate() {
        #if canImport(WatchConnectivity)
        guard let session else { return }
        session.delegate = self
        session.activate()
        #endif
    }

    /// 로컬에서 변경이 일어난 뒤 호출. 상대 기기에 최신 스냅샷 전송.
    func pushLocalChange() {
        #if canImport(WatchConnectivity)
        guard let session else {
            SharedStore.appendDebugLog("Watch:push skipped (WCSession unsupported)")
            #if DEBUG
            print("[NudgeSync] push skipped: WCSession unsupported")
            #endif
            return
        }
        guard session.activationState == .activated else {
            SharedStore.appendDebugLog("Watch:push skipped state=\(session.activationState.rawValue)")
            #if DEBUG
            print("[NudgeSync] push skipped: session not activated (state=\(session.activationState.rawValue))")
            #endif
            return
        }
        #if os(iOS)
        let reachable = session.isReachable
        let installed = session.isWatchAppInstalled
        let paired = session.isPaired
        #if DEBUG
        print("[NudgeSync] push → paired=\(paired), installed=\(installed), reachable=\(reachable)")
        #endif
        #else
        SharedStore.appendDebugLog("Watch:push start reachable=\(session.isReachable) companionInstalled=\(session.isCompanionAppInstalled)")
        #if DEBUG
        print("[NudgeSync] push → reachable=\(session.isReachable), companionInstalled=\(session.isCompanionAppInstalled)")
        #endif
        #endif
        let snapshot = SharedStore.syncSnapshot()
        let mod = snapshot["lastModified"] as? TimeInterval ?? 0
        do {
            try session.updateApplicationContext(snapshot)
            SharedStore.appendDebugLog("Watch:push OK updateApplicationContext mod=\(Int(mod))")
            #if DEBUG
            let counts = (snapshot["counts"] as? [String: [String: Int]])?.count ?? 0
            print("[NudgeSync] push OK: days=\(counts), lastModified=\(mod)")
            #endif
        } catch {
            SharedStore.appendDebugLog("Watch:push FAIL updateApplicationContext \(error.localizedDescription)")
            #if DEBUG
            print("[NudgeSync] push FAILED: \(error)")
            #endif
        }
        #endif
    }
}

#if canImport(WatchConnectivity)
extension NudgeSync: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if DEBUG
        let stateName: String
        switch activationState {
        case .notActivated: stateName = "notActivated"
        case .inactive: stateName = "inactive"
        case .activated: stateName = "activated"
        @unknown default: stateName = "unknown(\(activationState.rawValue))"
        }
        print("[NudgeSync] activation: \(stateName)\(error.map { " err=\($0)" } ?? "")")
        #if os(iOS)
        print("[NudgeSync] iOS session → paired=\(session.isPaired), watchAppInstalled=\(session.isWatchAppInstalled), reachable=\(session.isReachable)")
        #else
        print("[NudgeSync] Watch session → companionInstalled=\(session.isCompanionAppInstalled), reachable=\(session.isReachable)")
        #endif
        #endif
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        // iPhone 이 여러 watch 페어링 전환 시 호출. 새로 활성화.
        session.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        SharedStore.appendDebugLog("Watch:recv applicationContext")
        #if DEBUG
        print("[NudgeSync] recv applicationContext")
        #endif
        handleRemote(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        SharedStore.appendDebugLog("Watch:recv message")
        #if DEBUG
        print("[NudgeSync] recv message")
        #endif
        handleRemote(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        SharedStore.appendDebugLog("Watch:recv userInfo")
        #if DEBUG
        print("[NudgeSync] recv userInfo")
        #endif
        handleRemote(userInfo)
    }

    private func handleRemote(_ payload: [String: Any]) {
        let changed = SharedStore.applyRemoteSnapshot(payload)
        #if DEBUG
        let mod = payload["lastModified"] as? TimeInterval ?? 0
        let days = (payload["counts"] as? [String: [String: Int]])?.count ?? 0
        print("[NudgeSync] applyRemote → changed=\(changed), days=\(days), remoteLastModified=\(mod)")
        #endif
        DispatchQueue.main.async {
            self.lastSyncAt = Date()
            if changed {
                NotificationCenter.default.post(name: .nudgeDataChangedRemote, object: nil)
                #if os(iOS)
                WidgetCenter.shared.reloadAllTimelines()
                #endif
            }
        }
    }
}
#endif

extension Notification.Name {
    /// 원격 동기화로 로컬 데이터가 변경됐을 때 브로드캐스트.
    static let nudgeDataChangedRemote = Notification.Name("NudgeDataChangedRemote")
}
