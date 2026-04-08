//
//  PowerWatch_iOS_Widget.swift
//  PowerWatch iOS Widget
//
//  Created by Mark Howard on 26/03/2024.
//

import WidgetKit
import SwiftUI

private let widgetAppGroup = "group.com.MSJ.PowerWatch.shared"

struct WidgetBatterySnapshot: Decodable {
    let level: Double
    let state: Int
    let updatedAt: Date

    static let empty = WidgetBatterySnapshot(level: 0, state: 0, updatedAt: .distantPast)

    var percentage: Double {
        max(0, min(level, 1)) * 100
    }

    var stateText: String {
        switch state {
        case 1:
            return "Unplugged"
        case 2:
            return "Charging"
        case 3:
            return "Full"
        default:
            return "Unknown"
        }
    }
}

struct BatteryWidgetEntry: TimelineEntry {
    let date: Date
    let phoneSnapshot: WidgetBatterySnapshot
    let watchSnapshot: WidgetBatterySnapshot
}

private enum WidgetSnapshotStore {
    static func loadSnapshot(for key: String) -> WidgetBatterySnapshot {
        guard
            let defaults = UserDefaults(suiteName: widgetAppGroup),
            let data = defaults.data(forKey: key),
            let snapshot = try? JSONDecoder().decode(WidgetBatterySnapshot.self, from: data)
        else {
            return .empty
        }

        return snapshot
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BatteryWidgetEntry {
        BatteryWidgetEntry(date: Date(), phoneSnapshot: .empty, watchSnapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (BatteryWidgetEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BatteryWidgetEntry>) -> Void) {
        let currentEntry = entry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [currentEntry], policy: .after(nextRefresh)))
    }

    private func entry() -> BatteryWidgetEntry {
        BatteryWidgetEntry(
            date: Date(),
            phoneSnapshot: WidgetSnapshotStore.loadSnapshot(for: "phoneSnapshot"),
            watchSnapshot: WidgetSnapshotStore.loadSnapshot(for: "watchSnapshot")
        )
    }
}

private struct BatteryGaugeView: View {
    let systemImage: String
    let value: Double

    var body: some View {
        Gauge(value: value, in: 0...100) {
            Image(systemName: systemImage)
        } currentValueLabel: {
            Text("\(Int(value.rounded()))")
        }
        .gaugeStyle(.accessoryCircular)
    }
}

private struct SmallBatteryWidgetView: View {
    let title: String
    let systemImage: String
    let snapshot: WidgetBatterySnapshot

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.clear)
                .scaledToFill()
            VStack(spacing: 6) {
                Label(title, systemImage: systemImage)
                    .bold()
                    .foregroundStyle(.white)
                    .font(.title2)
                Text("\(snapshot.percentage, specifier: "%.0f")%")
                    .font(.title3)
                    .foregroundStyle(.white)
                Text(snapshot.stateText)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(8)
        }
    }
}

struct PowerWatch_iOS_WidgetEntryView_Phone: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        batteryView(title: "iPhone", systemImage: "iphone", snapshot: entry.phoneSnapshot)
    }

    @ViewBuilder
    private func batteryView(title: String, systemImage: String, snapshot: WidgetBatterySnapshot) -> some View {
        switch widgetFamily {
        case .systemSmall:
            SmallBatteryWidgetView(title: title, systemImage: systemImage, snapshot: snapshot)
        case .accessoryCircular:
            BatteryGaugeView(systemImage: systemImage, value: snapshot.percentage)
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Label(title, systemImage: systemImage)
                Text("\(snapshot.percentage, specifier: "%.0f")%")
                Text(snapshot.stateText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .accessoryInline:
            Label("\(title) \(snapshot.percentage, specifier: "%.0f")%", systemImage: systemImage)
        default:
            Text("N/A")
        }
    }
}

struct PowerWatch_iOS_WidgetEntryView_Watch: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        batteryView(title: "Watch", systemImage: "applewatch", snapshot: entry.watchSnapshot)
    }

    @ViewBuilder
    private func batteryView(title: String, systemImage: String, snapshot: WidgetBatterySnapshot) -> some View {
        switch widgetFamily {
        case .systemSmall:
            SmallBatteryWidgetView(title: title, systemImage: systemImage, snapshot: snapshot)
        case .accessoryCircular:
            BatteryGaugeView(systemImage: systemImage, value: snapshot.percentage)
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Label("Apple Watch", systemImage: systemImage)
                Text("\(snapshot.percentage, specifier: "%.0f")%")
                Text(snapshot.stateText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .accessoryInline:
            Label("Watch \(snapshot.percentage, specifier: "%.0f")%", systemImage: systemImage)
        default:
            Text("N/A")
        }
    }
}

struct PowerWatch_iOS_Widget_Phone: Widget {
    let kind: String = "PowerWatch_iOS_Widget_Phone"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PowerWatch_iOS_WidgetEntryView_Phone(entry: entry)
                .containerBackground(.accent, for: .widget)
        }
        .configurationDisplayName("iPhone Battery Level")
        .description("Current battery level for iPhone.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

struct PowerWatch_iOS_Widget_Watch: Widget {
    let kind: String = "PowerWatch_iOS_Widget_Watch"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PowerWatch_iOS_WidgetEntryView_Watch(entry: entry)
                .containerBackground(.accent, for: .widget)
        }
        .configurationDisplayName("Apple Watch Battery Level")
        .description("Latest synced battery level for Apple Watch.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}
