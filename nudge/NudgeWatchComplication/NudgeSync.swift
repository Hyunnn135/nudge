//
//  NudgeSync.swift
//  NudgeWatchComplication (+ nudge, NudgeWatch Watch App — 동일 내용 3곳 복제)
//
//  WatchConnectivity 기반 iPhone ↔ Watch 데이터 동기화.
//  전략: last-writer-wins (SharedStore.lastModified 타임스탬프 비교)
//  전송 방식: updateApplicationContext (최신 값만 배달, 용량 4KB 이내)
//
//  ⚠️ 이 파일은 3개 타겟에 동일 내용으로 존재합니다. 한쪽 수정 시 반드시 다른 쪽도 같이 수정하세요:
//     - nudge/NudgeSync.swift (iOS 앱)
//     - NudgeWatch Watch App/NudgeSync.swift (watchOS 앱)
//     - NudgeWatchComplication/NudgeSync.swift (watchOS 컴플리케이션 — 위젯 탭 push 용)
//

import Foundation
import Combine  // ObservableObject 프로토콜

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
    /// 세션이 이미 활성화된 상태여야 함. (in-process 사용)
    func pushLocalChange() {
        #if canImport(WatchConnectivity)
        guard let session else {
            #if DEBUG
            print("[NudgeSync] push skipped: WCSession unsupported")
            #endif
            return
        }
        guard session.activationState == .activated else {
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
        #if DEBUG
        print("[NudgeSync] push → reachable=\(session.isReachable), companionInstalled=\(session.isCompanionAppInstalled)")
        #endif
        #endif
        let snapshot = SharedStore.syncSnapshot()
        do {
            try session.updateApplicationContext(snapshot)
            #if DEBUG
            let counts = (snapshot["counts"] as? [String: [String: Int]])?.count ?? 0
            let mod = snapshot["lastModified"] as? TimeInterval ?? 0
            print("[NudgeSync] push OK: days=\(counts), lastModified=\(mod)")
            #endif
        } catch {
            #if DEBUG
            print("[NudgeSync] push FAILED: \(error)")
            #endif
        }
        #endif
    }

    /// 위젯/컴플리케이션 등 **짧은 수명 프로세스**에서 사용.
    /// 세션 활성화를 최대 5초 대기한 뒤 `transferUserInfo` 로 push.
    /// `updateApplicationContext` 와 달리 queue 기반이라 위젯 프로세스가 종료돼도
    /// 시스템이 배송 책임을 짐 → 짧은 수명 프로세스에 적합.
    func pushAwaitingActivation() async {
        SharedStore.appendDebugLog("pushAwait:entry")
        #if canImport(WatchConnectivity)
        guard let session else {
            SharedStore.appendDebugLog("pushAwait:FAIL session nil (WCSession unsupported)")
            return
        }
        SharedStore.appendDebugLog("pushAwait:state=\(session.activationState.rawValue) reachable=\(session.isReachable) companionInstalled=\(session.isCompanionAppInstalled)")
        // 활성화 대기 (최대 5초, 100ms 간격 체크)
        if session.activationState != .activated {
            for i in 0..<50 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if session.activationState == .activated {
                    SharedStore.appendDebugLog("pushAwait:activated after \(i*100)ms")
                    break
                }
            }
        }
        guard session.activationState == .activated else {
            SharedStore.appendDebugLog("pushAwait:TIMEOUT state=\(session.activationState.rawValue)")
            return
        }
        let snapshot = SharedStore.syncSnapshot()
        let mod = snapshot["lastModified"] as? TimeInterval ?? 0
        // 이중 전송: applicationContext (latest state) + transferUserInfo (persistent queue)
        do {
            try session.updateApplicationContext(snapshot)
            SharedStore.appendDebugLog("pushAwait:updateApplicationContext OK mod=\(Int(mod))")
        } catch {
            SharedStore.appendDebugLog("pushAwait:updateApplicationContext FAIL \(error.localizedDescription)")
        }
        session.transferUserInfo(snapshot)
        SharedStore.appendDebugLog("pushAwait:transferUserInfo queued mod=\(Int(mod))")
        #else
        SharedStore.appendDebugLog("pushAwait:FAIL !canImport(WatchConnectivity)")
        #endif
    }
}

#if canImport(WatchConnectivity)
extension NudgeSync: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        SharedStore.appendDebugLog("delegate:activation state=\(activationState.rawValue) err=\(error?.localizedDescription ?? "nil")")
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
        session.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        #if DEBUG
        print("[NudgeSync] recv applicationContext")
        #endif
        handleRemote(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        #if DEBUG
        print("[NudgeSync] recv message")
        #endif
        handleRemote(message)
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
