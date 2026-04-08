//
//  AppIntents.swift
//  PowerWatch watchOS Watch App
//
//  Created by Mark Howard on 27/03/2024.
//

import AppIntents
import WatchKit

private struct WatchIntentBatterySnapshot: Decodable {
    let level: Double
    let state: Int
    let updatedAt: Date

    var percentage: Int {
        Int((max(0, min(level, 1)) * 100).rounded())
    }
}

private enum WatchIntentBatterySnapshotStore {
    static let appGroup = "group.com.MSJ.PowerWatch.shared"
    static let phoneSnapshotKey = "phoneSnapshot"

    static func currentWatchSnapshot() -> WatchIntentBatterySnapshot {
        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        return WatchIntentBatterySnapshot(
            level: max(0, Double(WKInterfaceDevice.current().batteryLevel)),
            state: WKInterfaceDevice.current().batteryState.rawValue,
            updatedAt: Date()
        )
    }

    static func storedPhoneSnapshot() -> WatchIntentBatterySnapshot? {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let data = defaults.data(forKey: phoneSnapshotKey)
        else {
            return nil
        }

        return try? JSONDecoder().decode(WatchIntentBatterySnapshot.self, from: data)
    }

    static func stateDescription(for state: Int) -> String {
        switch state {
        case WKInterfaceDeviceBatteryState.unplugged.rawValue:
            return "unplugged"
        case WKInterfaceDeviceBatteryState.charging.rawValue:
            return "charging"
        case WKInterfaceDeviceBatteryState.full.rawValue:
            return "full"
        default:
            return "unknown"
        }
    }
}

struct GetPhoneBattery: AppIntent {
    static var title: LocalizedStringResource = "Get iPhone Battery Status"
    static var description = IntentDescription("Get the latest synced battery level and charging state of your iPhone.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshots = await WatchSessionManager.shared.refreshForIntent()
        let snapshot = WatchIntentBatterySnapshot(
            level: snapshots.phone.level,
            state: snapshots.phone.state,
            updatedAt: snapshots.phone.updatedAt
        )

        guard snapshot.updatedAt != .distantPast else {
            return .result(dialog: "The iPhone battery is unavailable until your watch syncs with the phone.")
        }

        let dialog = IntentDialog("Your iPhone battery is \(snapshot.percentage) percent and \(WatchIntentBatterySnapshotStore.stateDescription(for: snapshot.state)).")
        return .result(dialog: dialog)
    }
}

struct GetWatchBattery: AppIntent {
    static var title: LocalizedStringResource = "Get Apple Watch Battery Status"
    static var description = IntentDescription("Get the current battery level and charging state of your Apple Watch.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshots = await WatchSessionManager.shared.refreshForIntent()
        let snapshot = WatchIntentBatterySnapshot(
            level: snapshots.watch.level,
            state: snapshots.watch.state,
            updatedAt: snapshots.watch.updatedAt
        )
        let dialog = IntentDialog("Your Apple Watch battery is \(snapshot.percentage) percent and \(WatchIntentBatterySnapshotStore.stateDescription(for: snapshot.state)).")
        return .result(dialog: dialog)
    }
}

struct PowerWatchShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetPhoneBattery(),
            phrases: [
                "What's the iPhone battery in \(.applicationName)",
                "Get iPhone battery from \(.applicationName)"
            ],
            shortTitle: "iPhone Battery",
            systemImageName: "iphone"
        )
        AppShortcut(
            intent: GetWatchBattery(),
            phrases: [
                "What's the Apple Watch battery in \(.applicationName)",
                "Get Apple Watch battery from \(.applicationName)"
            ],
            shortTitle: "Watch Battery",
            systemImageName: "applewatch"
        )
    }
}
