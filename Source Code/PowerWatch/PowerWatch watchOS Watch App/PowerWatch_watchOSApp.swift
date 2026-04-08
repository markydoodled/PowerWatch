//
//  PowerWatch_watchOSApp.swift
//  PowerWatch watchOS Watch App
//
//  Created by Mark Howard on 04/08/2023.
//

import SwiftUI
import WatchConnectivity
import WatchKit
import WidgetKit

private let powerWatchWatchAppGroup = "group.com.MSJ.PowerWatch.shared"
private let watchWidgetKinds = [
    "PowerWatch_watchOS_Widget_Phone",
    "PowerWatch_watchOS_Widget_Watch"
]

private enum WatchBatteryStoreKey {
    static let phoneSnapshot = "phoneSnapshot"
    static let watchSnapshot = "watchSnapshot"
}

private enum WatchBatteryRequest: String {
    case phoneBatterySnapshot
    case watchBatterySnapshot
}

private enum WatchBatterySnapshotOrigin: String {
    case phone
    case watch
}

struct WatchBatterySnapshot: Codable, Equatable {
    let level: Double
    let state: Int
    let updatedAt: Date

    static let empty = WatchBatterySnapshot(level: 0, state: 0, updatedAt: .distantPast)
}

@main
struct PowerWatch_watchOS_Watch_AppApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}

final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published private(set) var phoneSnapshot: WatchBatterySnapshot = .empty
    @Published private(set) var watchSnapshot: WatchBatterySnapshot = .empty

    private let defaults = UserDefaults(suiteName: powerWatchWatchAppGroup) ?? .standard
    private var syncTimer: Timer?

    private override init() {
        super.init()
        loadPersistedSnapshots()
        configureSession()
        configureBatteryMonitoring()
        refreshLocalWatchBattery(sendUpdate: false)
    }

    deinit {
        syncTimer?.invalidate()
    }

    func refreshAll() {
        refreshLocalWatchBattery(sendUpdate: true)
        requestPhoneBatterySnapshot()
    }

    @MainActor
    func refreshForIntent() async -> (phone: WatchBatterySnapshot, watch: WatchBatterySnapshot) {
        refreshLocalWatchBattery(sendUpdate: true)
        let latestPhoneSnapshot = await requestPhoneBatterySnapshotForIntent() ?? phoneSnapshot
        return (latestPhoneSnapshot, watchSnapshot)
    }

    func requestPhoneBatterySnapshot() {
        guard WCSession.isSupported() else { return }
        let message = ["request": WatchBatteryRequest.phoneBatterySnapshot.rawValue]
        let session = WCSession.default

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(message)
        }
    }

    private func requestPhoneBatterySnapshotForIntent() async -> WatchBatterySnapshot? {
        guard WCSession.isSupported() else { return phoneSnapshot }
        let session = WCSession.default

        guard session.isReachable else {
            requestPhoneBatterySnapshot()
            return phoneSnapshot
        }

        return await withCheckedContinuation { continuation in
            var resumed = false
            let fallbackSnapshot = self.phoneSnapshot

            func finish(with snapshot: WatchBatterySnapshot?) {
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: snapshot)
            }

            session.sendMessage(["request": WatchBatteryRequest.phoneBatterySnapshot.rawValue], replyHandler: { [weak self] reply in
                let snapshot = self?.snapshot(from: reply, expectedOrigin: .phone)
                if let snapshot {
                    self?.apply(snapshot, origin: .phone)
                }
                finish(with: snapshot)
            }, errorHandler: { [weak self] _ in
                finish(with: self?.phoneSnapshot)
            })

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                finish(with: fallbackSnapshot)
            }
        }
    }

    private func configureSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func configureBatteryMonitoring() {
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        syncTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refreshLocalWatchBattery(sendUpdate: true)
        }
    }

    private func refreshLocalWatchBattery(sendUpdate: Bool) {
        let snapshot = WatchBatterySnapshot(
            level: normalizedBatteryLevel(Double(WKInterfaceDevice.current().batteryLevel)),
            state: WKInterfaceDevice.current().batteryState.rawValue,
            updatedAt: Date()
        )
        let previousSnapshot = watchSnapshot

        apply(snapshot, origin: .watch)

        if sendUpdate, snapshot != previousSnapshot {
            send(snapshot: snapshot, origin: .watch)
        }
    }

    private func send(snapshot: WatchBatterySnapshot, origin: WatchBatterySnapshotOrigin) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        let payload = payload(for: snapshot, origin: origin)

        if session.activationState != .activated {
            session.activate()
        }

        do {
            try session.updateApplicationContext(payload)
        } catch {
            session.transferUserInfo(payload)
        }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }

    private func payload(for snapshot: WatchBatterySnapshot, origin: WatchBatterySnapshotOrigin) -> [String: Any] {
        [
            "device": origin.rawValue,
            "level": snapshot.level,
            "state": snapshot.state,
            "updatedAt": snapshot.updatedAt.timeIntervalSince1970
        ]
    }

    private func handlePayload(_ payload: [String: Any]) {
        if let request = payload["request"] as? String,
           let batteryRequest = WatchBatteryRequest(rawValue: request) {
            handleRequest(batteryRequest)
            return
        }

        guard
            let originRawValue = payload["device"] as? String,
            let origin = WatchBatterySnapshotOrigin(rawValue: originRawValue),
            let snapshot = snapshot(from: payload, expectedOrigin: origin)
        else {
            return
        }

        apply(snapshot, origin: origin)
    }

    private func handleRequest(_ request: WatchBatteryRequest) {
        switch request {
        case .phoneBatterySnapshot:
            requestPhoneBatterySnapshot()
        case .watchBatterySnapshot:
            refreshLocalWatchBattery(sendUpdate: true)
        }
    }

    private func apply(_ snapshot: WatchBatterySnapshot, origin: WatchBatterySnapshotOrigin) {
        DispatchQueue.main.async {
            switch origin {
            case .phone:
                self.phoneSnapshot = snapshot
            case .watch:
                self.watchSnapshot = snapshot
            }

            self.persist(snapshot, origin: origin)
            self.reloadWidgets()
        }
    }

    private func snapshot(from payload: [String: Any], expectedOrigin: WatchBatterySnapshotOrigin) -> WatchBatterySnapshot? {
        guard
            let originRawValue = payload["device"] as? String,
            originRawValue == expectedOrigin.rawValue,
            let level = payload["level"] as? Double,
            let state = payload["state"] as? Int
        else {
            return nil
        }

        let timestamp = (payload["updatedAt"] as? TimeInterval) ?? Date().timeIntervalSince1970
        return WatchBatterySnapshot(
            level: normalizedBatteryLevel(level),
            state: state,
            updatedAt: Date(timeIntervalSince1970: timestamp)
        )
    }

    private func currentWatchPayload() -> [String: Any] {
        let snapshot = WatchBatterySnapshot(
            level: normalizedBatteryLevel(Double(WKInterfaceDevice.current().batteryLevel)),
            state: WKInterfaceDevice.current().batteryState.rawValue,
            updatedAt: Date()
        )
        return payload(for: snapshot, origin: .watch)
    }

    private func reloadWidgets() {
        for kind in watchWidgetKinds {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
    }

    private func persist(_ snapshot: WatchBatterySnapshot, origin: WatchBatterySnapshotOrigin) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(snapshot) else { return }

        switch origin {
        case .phone:
            defaults.set(data, forKey: WatchBatteryStoreKey.phoneSnapshot)
        case .watch:
            defaults.set(data, forKey: WatchBatteryStoreKey.watchSnapshot)
        }
    }

    private func loadPersistedSnapshots() {
        let decoder = JSONDecoder()

        if let phoneData = defaults.data(forKey: WatchBatteryStoreKey.phoneSnapshot),
           let snapshot = try? decoder.decode(WatchBatterySnapshot.self, from: phoneData) {
            phoneSnapshot = snapshot
        }

        if let watchData = defaults.data(forKey: WatchBatteryStoreKey.watchSnapshot),
           let snapshot = try? decoder.decode(WatchBatterySnapshot.self, from: watchData) {
            watchSnapshot = snapshot
        }
    }

    private func normalizedBatteryLevel(_ level: Double) -> Double {
        if level.isNaN || level.isInfinite || level < 0 {
            return 0
        }

        if level > 1 {
            return min(level / 100, 1)
        }

        return min(level, 1)
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        refreshLocalWatchBattery(sendUpdate: true)
        requestPhoneBatterySnapshot()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handlePayload(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handlePayload(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handlePayload(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let request = message["request"] as? String,
           let batteryRequest = WatchBatteryRequest(rawValue: request),
           batteryRequest == .watchBatterySnapshot {
            refreshLocalWatchBattery(sendUpdate: true)
            replyHandler(currentWatchPayload())
            return
        }

        handlePayload(message)
        replyHandler([:])
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            requestPhoneBatterySnapshot()
        }
    }
}
