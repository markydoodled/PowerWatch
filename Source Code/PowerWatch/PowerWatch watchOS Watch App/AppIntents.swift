//
//  AppIntents.swift
//  PowerWatch watchOS Watch App
//
//  Created by Mark Howard on 27/03/2024.
//

import AppIntents

struct GetPhoneBattery: AppIntent {
    static var title: LocalizedStringResource = "Get iPhone Battery Level"
    static var description = IntentDescription("Get The Current Battery Level Of Your iPhone.")

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        return .result(dialog: "The Current Battery Level Of Your iPhone Is .")
    }
}

struct GetWatchBattery: AppIntent {
    static var title: LocalizedStringResource = "Get Apple Watch Battery Level"
    static var description = IntentDescription("Get The Current Battery Level Of Your Apple Watch.")

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        return .result(dialog: "The Current Battery Level Of Your Apple Watch Is .")
    }
}

struct TimerIntentProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [AppShortcut(
                intent: GetPhoneBattery(),
                phrases: ["Get \(.applicationName) iPhone Battery Level"],
                shortTitle: "Get iPhone Battery",
                systemImageName: "iphone"
            ),
            AppShortcut(
                    intent: GetWatchBattery(),
                    phrases: ["Get \(.applicationName) Apple Watch Battery Level"],
                    shortTitle: "Get Apple Watch Battery",
                    systemImageName: "applewatch"
                )
        ]
    }
}
