//
//  AppIntents.swift
//  PowerWatch
//
//  Created by Mark Howard on 27/03/2024.
//

import AppIntents
import UIKit

private struct IntentBatterySnapshot: Decodable {
    let level: Double
    let state: Int
    let updatedAt: Date

    var percentage: Int {
        Int((max(0, min(level, 1)) * 100).rounded())
    }
}

private enum IntentBatterySnapshotStore {
    static let appGroup = "group.com.MSJ.PowerWatch.shared"
    static let watchSnapshotKey = "watchSnapshot"

    static func currentPhoneSnapshot() -> IntentBatterySnapshot {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return IntentBatterySnapshot(
            level: max(0, Double(UIDevice.current.batteryLevel)),
            state: UIDevice.current.batteryState.rawValue,
            updatedAt: Date()
        )
    }

    static func storedWatchSnapshot() -> IntentBatterySnapshot? {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let data = defaults.data(forKey: watchSnapshotKey)
        else {
            return nil
        }

        return try? JSONDecoder().decode(IntentBatterySnapshot.self, from: data)
    }

    static func stateDescription(for state: Int) -> String {
        switch state {
        case UIDevice.BatteryState.unplugged.rawValue:
            return "unplugged"
        case UIDevice.BatteryState.charging.rawValue:
            return "charging"
        case UIDevice.BatteryState.full.rawValue:
            return "full"
        default:
            return "unknown"
        }
    }
}

struct GetPhoneBattery: AppIntent {
    static var title: LocalizedStringResource = "Get iPhone Battery Status"
    static var description = IntentDescription("Get the current battery level and charging state of your iPhone.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshots = await PhoneBatterySyncController.shared.refreshForIntent()
        let snapshot = IntentBatterySnapshot(
            level: snapshots.phone.level,
            state: snapshots.phone.state,
            updatedAt: snapshots.phone.updatedAt
        )
        let dialog = IntentDialog("Your iPhone battery is \(snapshot.percentage) percent and \(IntentBatterySnapshotStore.stateDescription(for: snapshot.state)).")
        return .result(dialog: dialog)
    }
}

struct GetWatchBattery: AppIntent {
    static var title: LocalizedStringResource = "Get Apple Watch Battery Status"
    static var description = IntentDescription("Get the latest synced battery level and charging state of your Apple Watch.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshots = await PhoneBatterySyncController.shared.refreshForIntent()
        let snapshot = IntentBatterySnapshot(
            level: snapshots.watch.level,
            state: snapshots.watch.state,
            updatedAt: snapshots.watch.updatedAt
        )

        guard snapshot.updatedAt != .distantPast else {
            return .result(dialog: "The Apple Watch battery is unavailable until the watch syncs with your iPhone.")
        }

        let dialog = IntentDialog("Your Apple Watch battery is \(snapshot.percentage) percent and \(IntentBatterySnapshotStore.stateDescription(for: snapshot.state)).")
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
