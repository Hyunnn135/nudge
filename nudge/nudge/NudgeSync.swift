//
//  NudgeSync.swift
//  nudge (+ NudgeWatch Watch App — 같은 내용으로 복제)
//
//  WatchConnectivity 기반 iPhone ↔ Watch 데이터 동기화.
//  전략: last-writer-wins (SharedStore.lastModified 타임스탬프 비교)
//  전송 방식: updateApplicationContext (최신 값만 배달, 용량 4KB 이내)
//
//  ⚠️ 이 파일은 iOS 타겟(nudge/)과 watchOS 타겟(NudgeWatch Watch App/)에 동일 내용으로 존재합니다.
//     한쪽 수정 시 반드시 다른 쪽도 같이 수정하세요.
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
        guard let session, session.activationState == .activated else { return }
        let snapshot = SharedStore.syncSnapshot()
        do {
            try session.updateApplicationContext(snapshot)
        } catch {
            #if DEBUG
            print("NudgeSync updateApplicationContext error: \(error)")
            #endif
        }
        #endif
    }
}

#if canImport(WatchConnectivity)
extension NudgeSync: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if DEBUG
        print("NudgeSync activation: \(activationState.rawValue), err=\(String(describing: error))")
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
        handleRemote(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleRemote(message)
    }

    private func handleRemote(_ payload: [String: Any]) {
        let changed = SharedStore.applyRemoteSnapshot(payload)
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
