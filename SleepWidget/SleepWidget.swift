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
        VStack(alignment: .center, spacing: 0) {
            Text("入睡时间")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 10)

            Text(entry.date, style: .time)
                .font(.system(size: 38, weight: .medium))
                .foregroundColor(.white)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 10)

            Text("晚安打卡")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color.white, in: Capsule())
        }
        .widgetURL(URL(string: "sleeptime://checkin"))
    }
}

struct SleepWidget: Widget {
    let kind: String = "SleepWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                SleepWidgetEntryView(entry: entry)
                    .containerBackground(Color.black, for: .widget)
            } else {
                SleepWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.black)
            }
        }
        .configurationDisplayName("晚安打卡")
        .description("快速在桌面记录你的入睡时间。")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    SleepWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
