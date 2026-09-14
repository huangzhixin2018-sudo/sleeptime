import ActivityKit
import WidgetKit
import SwiftUI

struct SleepWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepWidgetAttributes.self) { context in
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)

                    Text("距入睡还有")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text(timerInterval: context.attributes.startTime...context.attributes.targetBedtime, countsDown: true)
                        .font(.title2.monospacedDigit().bold())
                        .foregroundColor(.cyan)
                }

                ProgressView(
                    timerInterval: context.attributes.startTime...context.attributes.targetBedtime,
                    countsDown: true
                )
                .tint(.cyan)

                Text(context.state.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(.yellow)
                        Text("目标:")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.targetBedtime, style: .time)
                        .font(.headline)
                        .foregroundColor(.cyan)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading) {
                        Text(context.state.message)
                            .font(.subheadline)

                        ProgressView(
                            timerInterval: context.attributes.startTime...context.attributes.targetBedtime,
                            countsDown: true
                        )
                        .tint(.cyan)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "moon.zzz.fill")
                    .foregroundColor(.yellow)
            } compactTrailing: {
                Text(timerInterval: context.attributes.startTime...context.attributes.targetBedtime, countsDown: true)
                    .monospacedDigit()
                    .foregroundColor(.cyan)
            } minimal: {
                Image(systemName: "moon.zzz.fill")
                    .foregroundColor(.yellow)
            }
            .widgetURL(URL(string: "sleeptime://home"))
            .keylineTint(Color.cyan)
        }
    }
}
