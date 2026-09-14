//
//  SleepWidget.swift
//  SleepWidget
//
//  Created by zhixin on 2026/9/14.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "😀")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "😀")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct SleepWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            Text("入睡时间")
                .font(.headline)
                .foregroundColor(Color.white)

            Text(entry.date, style: .time)
                .font(.title)
                .bold()
                .foregroundColor(Color.white)

            Text("晚安打卡")
                .font(.caption)
                .bold()
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.white)
                .foregroundColor(Color.black)
                .clipShape(Capsule())
        }
        .widgetURL(URL(string: "sleeptime://checkin"))
    }
}

struct SleepWidget: Widget {
    let kind: String = "SleepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SleepWidgetEntryView(entry: entry)
                .containerBackground(Color(white: 0.1), for: .widget)
        }
        .configurationDisplayName("晚安打卡")
        .description("快速在桌面记录你的入睡时间。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    SleepWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
