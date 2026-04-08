//
//  PowerWatch_watchOS_Widget.swift
//  PowerWatch watchOS Widget
//
//  Created by Mark Howard on 26/03/2024.
//

import WidgetKit
import SwiftUI

private let complicationAppGroup = "group.com.MSJ.PowerWatch.shared"

struct ComplicationBatterySnapshot: Decodable {
    let level: Double
    let state: Int
    let updatedAt: Date

    static let empty = ComplicationBatterySnapshot(level: 0, state: 0, updatedAt: .distantPast)

    var percentage: Double {
        max(0, min(level, 1)) * 100
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let phoneSnapshot: ComplicationBatterySnapshot
    let watchSnapshot: ComplicationBatterySnapshot
}

private enum ComplicationSnapshotStore {
    static func loadSnapshot(for key: String) -> ComplicationBatterySnapshot {
        guard
            let defaults = UserDefaults(suiteName: complicationAppGroup),
            let data = defaults.data(forKey: key),
            let snapshot = try? JSONDecoder().decode(ComplicationBatterySnapshot.self, from: data)
        else {
            return .empty
        }

        return snapshot
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), phoneSnapshot: .empty, watchSnapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentEntry = entry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [currentEntry], policy: .after(nextRefresh)))
    }

    private func entry() -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            phoneSnapshot: ComplicationSnapshotStore.loadSnapshot(for: "phoneSnapshot"),
            watchSnapshot: ComplicationSnapshotStore.loadSnapshot(for: "watchSnapshot")
        )
    }
}

private struct CircularBatteryView: View {
    let systemImage: String
    let percentage: Double
    let gradient = Gradient(colors: [.red, .orange, .yellow, .green])

    var body: some View {
        Gauge(value: percentage, in: 0...100) {
            Image(systemName: systemImage)
        } currentValueLabel: {
            Text("\(Int(percentage.rounded()))")
        }
        .gaugeStyle(.circular)
    }
}

private struct CornerBatteryView: View {
    let systemImage: String
    let percentage: Double
    let gradient = Gradient(colors: [.red, .orange, .yellow, .green])

    var body: some View {
        Gauge(value: percentage, in: 0...100) {
            Image(systemName: systemImage)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

struct PowerWatch_watchOS_WidgetEntryView_Phone: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        complicationView(title: "iPhone", systemImage: "iphone", snapshot: entry.phoneSnapshot)
    }

    @ViewBuilder
    private func complicationView(title: String, systemImage: String, snapshot: ComplicationBatterySnapshot) -> some View {
        switch widgetFamily {
        case .accessoryCorner:
            CornerBatteryView(systemImage: systemImage, percentage: snapshot.percentage)
        case .accessoryCircular:
            CircularBatteryView(systemImage: systemImage, percentage: snapshot.percentage)
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Label(title, systemImage: systemImage)
                Text("\(snapshot.percentage, specifier: "%.0f")%")
            }
        case .accessoryInline:
            Label("iPhone \(snapshot.percentage, specifier: "%.0f")%", systemImage: systemImage)
        default:
            Text("N/A")
        }
    }
}

struct PowerWatch_watchOS_WidgetEntryView_Watch: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        complicationView(title: "Watch", systemImage: "applewatch", snapshot: entry.watchSnapshot)
    }

    @ViewBuilder
    private func complicationView(title: String, systemImage: String, snapshot: ComplicationBatterySnapshot) -> some View {
        switch widgetFamily {
        case .accessoryCorner:
            CornerBatteryView(systemImage: systemImage, percentage: snapshot.percentage)
        case .accessoryCircular:
            CircularBatteryView(systemImage: systemImage, percentage: snapshot.percentage)
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Label(title, systemImage: systemImage)
                Text("\(snapshot.percentage, specifier: "%.0f")%")
            }
        case .accessoryInline:
            Label("Watch \(snapshot.percentage, specifier: "%.0f")%", systemImage: systemImage)
        default:
            Text("N/A")
        }
    }
}

struct PowerWatch_watchOS_Widget_Phone: Widget {
    let kind: String = "PowerWatch_watchOS_Widget_Phone"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PowerWatch_watchOS_WidgetEntryView_Phone(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("iPhone Battery Level")
        .description("Latest synced battery level for iPhone.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}

struct PowerWatch_watchOS_Widget_Watch: Widget {
    let kind: String = "PowerWatch_watchOS_Widget_Watch"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PowerWatch_watchOS_WidgetEntryView_Watch(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Apple Watch Battery Level")
        .description("Current battery level for Apple Watch.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}
