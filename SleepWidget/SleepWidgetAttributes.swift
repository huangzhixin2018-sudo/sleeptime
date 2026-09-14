import ActivityKit
import Foundation

struct SleepWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: String
        var message: String
    }

    var startTime: Date
    var targetBedtime: Date
}
