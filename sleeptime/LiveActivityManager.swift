import Foundation
import ActivityKit
import Combine

@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published private(set) var isSleepFlowActive: Bool

    private var currentActivity: Activity<SleepWidgetAttributes>?

    private init() {
        currentActivity = Activity<SleepWidgetAttributes>.activities.first
        isSleepFlowActive = currentActivity != nil
    }

    func startSleepFlow(targetBedtime: Date) {
        if #available(iOS 16.2, *) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                print("Live Activities are not enabled.")
                return
            }

            let attributes = SleepWidgetAttributes(
                startTime: Date(),
                targetBedtime: targetBedtime
            )

            let contentState = SleepWidgetAttributes.ContentState(
                status: "countdown",
                message: "准备入睡"
            )

            let content = ActivityContent(state: contentState, staleDate: nil)

            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
                currentActivity = activity
                isSleepFlowActive = true
                print("Started Live Activity: \(activity.id)")
            } catch {
                print("Failed to start Live Activity: \(error.localizedDescription)")
            }
        }
    }

    func stopSleepFlow() {
        if #available(iOS 16.2, *) {
            guard let activity = currentActivity else { return }

            let finalState = SleepWidgetAttributes.ContentState(
                status: "done",
                message: "已结束"
            )

            let finalContent = ActivityContent(state: finalState, staleDate: nil)

            Task {
                await activity.end(finalContent, dismissalPolicy: .immediate)
                isSleepFlowActive = false
                currentActivity = nil
                print("Ended Live Activity.")
            }
        }
    }
}
