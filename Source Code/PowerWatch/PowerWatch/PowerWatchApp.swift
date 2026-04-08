//
//  PowerWatchApp.swift
//  PowerWatch
//
//  Created by Mark Howard on 02/08/2023.
//

import SwiftUI
import WatchConnectivity
import WidgetKit

private let powerWatchAppGroup = "group.com.MSJ.PowerWatch.shared"
private let iOSWidgetKinds = [
    "PowerWatch_iOS_Widget_Phone",
    "PowerWatch_iOS_Widget_Watch"
]

private enum BatteryStoreKey {
    static let phoneSnapshot = "phoneSnapshot"
    static let watchSnapshot = "watchSnapshot"
}

private enum BatteryRequest: String {
    case phoneBatterySnapshot
    case watchBatterySnapshot
}

private enum BatterySnapshotOrigin: String {
    case phone
    case watch
}

struct BatterySnapshot: Codable, Equatable {
    let level: Double
    let state: Int
    let updatedAt: Date

    static let empty = BatterySnapshot(level: 0, state: 0, updatedAt: .distantPast)

    var percentage: Double {
        max(0, min(level, 1)) * 100
    }
}

@main
struct PowerWatchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    override init() {
        super.init()
        _ = PhoneBatterySyncController.shared
    }
}

final class PhoneBatterySyncController: NSObject, ObservableObject {
    static let shared = PhoneBatterySyncController()

    @Published private(set) var phoneSnapshot: BatterySnapshot = .empty
    @Published private(set) var watchSnapshot: BatterySnapshot = .empty

    private let defaults = UserDefaults(suiteName: powerWatchAppGroup) ?? .standard
    private var batteryObservers: [NSObjectProtocol] = []

    private override init() {
        super.init()
        loadPersistedSnapshots()
        configureSession()
        configureBatteryMonitoring()
        refreshLocalBattery(sendUpdate: false)
    }

    deinit {
        for observer in batteryObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func refreshAll() {
        refreshLocalBattery(sendUpdate: true)
        requestWatchBatterySnapshot()
    }

    @MainActor
    func refreshForIntent() async -> (phone: BatterySnapshot, watch: BatterySnapshot) {
        refreshLocalBattery(sendUpdate: true)
        let latestWatchSnapshot = await requestWatchBatterySnapshotForIntent() ?? watchSnapshot
        return (phoneSnapshot, latestWatchSnapshot)
    }

    private func configureSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func configureBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        let center = NotificationCenter.default
        batteryObservers.append(
            center.addObserver(
                forName: UIDevice.batteryLevelDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.refreshLocalBattery(sendUpdate: true)
            }
        )
        batteryObservers.append(
            center.addObserver(
                forName: UIDevice.batteryStateDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.refreshLocalBattery(sendUpdate: true)
            }
        )
    }

    private func refreshLocalBattery(sendUpdate: Bool) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let snapshot = BatterySnapshot(
            level: normalizedBatteryLevel(UIDevice.current.batteryLevel),
            state: UIDevice.current.batteryState.rawValue,
            updatedAt: Date()
        )
        let previousSnapshot = phoneSnapshot

        apply(snapshot, origin: .phone)

        if sendUpdate, snapshot != previousSnapshot {
            send(snapshot: snapshot, origin: .phone)
        }
    }

    private func requestWatchBatterySnapshot() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        let message = ["request": BatteryRequest.watchBatterySnapshot.rawValue]

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(message)
        }
    }

    private func requestWatchBatterySnapshotForIntent() async -> BatterySnapshot? {
        guard WCSession.isSupported() else { return watchSnapshot }
        let session = WCSession.default

        guard session.isReachable else {
            requestWatchBatterySnapshot()
            return watchSnapshot
        }

        return await withCheckedContinuation { continuation in
            var resumed = false
            let fallbackSnapshot = self.watchSnapshot

            func finish(with snapshot: BatterySnapshot?) {
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: snapshot)
            }

            session.sendMessage(["request": BatteryRequest.watchBatterySnapshot.rawValue], replyHandler: { [weak self] reply in
                let snapshot = self?.snapshot(from: reply, expectedOrigin: .watch)
                if let snapshot {
                    self?.apply(snapshot, origin: .watch)
                }
                finish(with: snapshot)
            }, errorHandler: { [weak self] _ in
                finish(with: self?.watchSnapshot)
            })

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                finish(with: fallbackSnapshot)
            }
        }
    }

    private func send(snapshot: BatterySnapshot, origin: BatterySnapshotOrigin) {
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

    private func payload(for snapshot: BatterySnapshot, origin: BatterySnapshotOrigin) -> [String: Any] {
        [
            "device": origin.rawValue,
            "level": snapshot.level,
            "state": snapshot.state,
            "updatedAt": snapshot.updatedAt.timeIntervalSince1970
        ]
    }

    private func handlePayload(_ payload: [String: Any]) {
        if let request = payload["request"] as? String,
           let batteryRequest = BatteryRequest(rawValue: request) {
            handleRequest(batteryRequest)
            return
        }

        guard
            let originRawValue = payload["device"] as? String,
            let origin = BatterySnapshotOrigin(rawValue: originRawValue),
            let snapshot = snapshot(from: payload, expectedOrigin: origin)
        else {
            return
        }

        apply(snapshot, origin: origin)
    }

    private func handleRequest(_ request: BatteryRequest) {
        switch request {
        case .phoneBatterySnapshot:
            refreshLocalBattery(sendUpdate: true)
        case .watchBatterySnapshot:
            requestWatchBatterySnapshot()
        }
    }

    private func apply(_ snapshot: BatterySnapshot, origin: BatterySnapshotOrigin) {
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

    private func snapshot(from payload: [String: Any], expectedOrigin: BatterySnapshotOrigin) -> BatterySnapshot? {
        guard
            let originRawValue = payload["device"] as? String,
            originRawValue == expectedOrigin.rawValue,
            let level = payload["level"] as? Double,
            let state = payload["state"] as? Int
        else {
            return nil
        }

        let timestamp = (payload["updatedAt"] as? TimeInterval) ?? Date().timeIntervalSince1970
        return BatterySnapshot(
            level: normalizedBatteryLevel(level),
            state: state,
            updatedAt: Date(timeIntervalSince1970: timestamp)
        )
    }

    private func currentPhonePayload() -> [String: Any] {
        let snapshot = BatterySnapshot(
            level: normalizedBatteryLevel(UIDevice.current.batteryLevel),
            state: UIDevice.current.batteryState.rawValue,
            updatedAt: Date()
        )
        return payload(for: snapshot, origin: .phone)
    }

    private func reloadWidgets() {
        for kind in iOSWidgetKinds {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
    }

    private func persist(_ snapshot: BatterySnapshot, origin: BatterySnapshotOrigin) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(snapshot) else { return }

        switch origin {
        case .phone:
            defaults.set(data, forKey: BatteryStoreKey.phoneSnapshot)
        case .watch:
            defaults.set(data, forKey: BatteryStoreKey.watchSnapshot)
        }
    }

    private func loadPersistedSnapshots() {
        let decoder = JSONDecoder()

        if let phoneData = defaults.data(forKey: BatteryStoreKey.phoneSnapshot),
           let snapshot = try? decoder.decode(BatterySnapshot.self, from: phoneData) {
            phoneSnapshot = snapshot
        }

        if let watchData = defaults.data(forKey: BatteryStoreKey.watchSnapshot),
           let snapshot = try? decoder.decode(BatterySnapshot.self, from: watchData) {
            watchSnapshot = snapshot
        }
    }

    private func normalizedBatteryLevel(_ level: Float) -> Double {
        normalizedBatteryLevel(Double(level))
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

extension PhoneBatterySyncController: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        refreshLocalBattery(sendUpdate: true)
        requestWatchBatterySnapshot()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handlePayload(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handlePayload(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handlePayload(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if let request = message["request"] as? String,
           let batteryRequest = BatteryRequest(rawValue: request),
           batteryRequest == .phoneBatterySnapshot {
            refreshLocalBattery(sendUpdate: true)
            replyHandler(currentPhonePayload())
            return
        }

        handlePayload(message)
        replyHandler([:])
    }
}
