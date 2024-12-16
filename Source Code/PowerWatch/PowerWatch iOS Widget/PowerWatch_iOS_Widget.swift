//
//  PowerWatch_iOS_Widget.swift
//  PowerWatch iOS Widget
//
//  Created by Mark Howard on 26/03/2024.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate A Timeline Consisting Of 24 Entries An Hour Apart, Starting From The Current Date.
        let currentDate = Date()
        for hourOffset in 0 ..< 24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct PowerWatch_iOS_WidgetEntryView_Phone: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @State var batteryLevel = 100.0
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            ZStack {
                Rectangle()
                    .foregroundStyle(.accent)
                    .scaledToFill()
                VStack {
                    Label("iPhone", systemImage: "iphone")
                        .bold()
                        .foregroundStyle(.white)
                        .font(.title2)
                    Text("\(batteryLevel)%")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
        case .systemMedium:
            Text("N/A")
        case .systemLarge:
            Text("N/A")
        case .systemExtraLarge:
            Text("N/A")
        case .accessoryCorner:
            Text("N/A")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Gauge(value: batteryLevel, in: 0...100) {
                    Image(systemName: "iphone")
                } currentValueLabel: {
                    Text("\(batteryLevel)")
                }
                .gaugeStyle(.accessoryCircular)
            }
        case .accessoryRectangular:
            VStack {
                Label("iPhone", systemImage: "iphone")
                Text("\(batteryLevel)%")
            }
        case .accessoryInline:
            Label("iPhone - \(batteryLevel)%", systemImage: "iphone")
        @unknown default:
            Text("Unknown")
        }
    }
}

struct PowerWatch_iOS_WidgetEntryView_Watch: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @State var batteryLevel = 100.0
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            ZStack {
                Rectangle()
                    .foregroundStyle(.accent)
                    .scaledToFill()
                VStack {
                    Label("Watch", systemImage: "applewatch")
                        .bold()
                        .foregroundStyle(.white)
                        .font(.title2)
                    Text("\(batteryLevel)%")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
        case .systemMedium:
            Text("N/A")
        case .systemLarge:
            Text("N/A")
        case .systemExtraLarge:
            Text("N/A")
        case .accessoryCorner:
            Text("N/A")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Gauge(value: batteryLevel, in: 0...100) {
                    Image(systemName: "applewatch")
                } currentValueLabel: {
                    Text("\(batteryLevel)")
                }
                .gaugeStyle(.accessoryCircular)
            }
        case .accessoryRectangular:
            VStack {
                Label("Apple Watch", systemImage: "applewatch")
                Text("\(batteryLevel)%")
            }
        case .accessoryInline:
            Label("Watch - \(batteryLevel)%", systemImage: "applewatch")
        @unknown default:
            Text("Unknown")
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
        .description("Current Battery Level For iPhone.")
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
        .description("Current Battery Level For Apple Watch.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}
