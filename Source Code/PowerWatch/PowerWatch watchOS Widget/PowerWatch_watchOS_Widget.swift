//
//  PowerWatch_watchOS_Widget.swift
//  PowerWatch watchOS Widget
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

struct PowerWatch_watchOS_WidgetEntryView_Phone: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @State var batteryLevel = 100.0
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            Text("N/A")
        case .systemMedium:
            Text("N/A")
        case .systemLarge:
            Text("N/A")
        case .systemExtraLarge:
            Text("N/A")
        case .accessoryCorner:
            VStack {
                
            }
        case .accessoryCircular:
            ZStack {
                
            }
        case .accessoryRectangular:
            VStack {
                
            }
        case .accessoryInline:
            Label("iPhone - ", systemImage: "iphone")
        @unknown default:
            Text("Unknown")
        }
    }
}

struct PowerWatch_watchOS_WidgetEntryView_Watch: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @State var batteryLevel = 100.0
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            Text("N/A")
        case .systemMedium:
            Text("N/A")
        case .systemLarge:
            Text("N/A")
        case .systemExtraLarge:
            Text("N/A")
        case .accessoryCorner:
            VStack {
                
            }
        case .accessoryCircular:
            ZStack {
                
            }
        case .accessoryRectangular:
            VStack {
                
            }
        case .accessoryInline:
            Label("Apple Watch", systemImage: "applewatch")
        @unknown default:
            Text("Unknown")
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
        .description("Current Battery Level For iPhone.")
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
        .description("Current Battery Level For Apple Watch.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}
