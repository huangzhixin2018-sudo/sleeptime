import SwiftUI

struct PlanDualStatsCard: View {
    @AppStorage("earlySleepPlan.activeType") private var activePlanType = "streak"
    @AppStorage("earlySleepPlan.metricType") private var metricType = PlanMetric.earlySleepDays.rawValue
    @AppStorage("earlySleepPlan.metricTargetDays") private var targetDays = 3
    @AppStorage("shorterPlan.targetSleepTimeMinutes") private var targetSleepTimeMinutes = 23 * 60
    @AppStorage("shorterPlan.startedAt") private var startedAt = 0.0
    @AppStorage("sleepCheckIn.records") private var encodedSleepCheckIns = "[]"

    private var metric: PlanMetric { PlanMetric(rawValue: metricType) ?? .earlySleepDays }

    private var planRecords: [SleepCheckInRecord] {
        let calendar = Calendar.current
        let start = startedAt > 0 ? calendar.startOfDay(for: Date(timeIntervalSince1970: startedAt)) : .distantPast
        return SleepCheckInStore.decode(encodedSleepCheckIns)
            .filter { calendar.startOfDay(for: $0.sleepDate) >= start }
            .sorted { $0.sleepDate < $1.sleepDate }
    }

    private var currentEarlyStreak: Int {
        SleepCheckInStore.segments(from: planRecords, startedAt: startedAt).last.map { $0.isEarlySleep ? $0.days : 0 } ?? 0
    }
    private var earlySleepDays: Int { planRecords.filter(\.isEarlySleep).count }
    private var onTimeDays: Int {
        let target = nightAdjusted(targetSleepTimeMinutes)
        return planRecords.filter { nightAdjusted($0.bedtimeMinutes) <= target }.count
    }
    private var longestLateStreak: Int {
        SleepCheckInStore.segments(from: planRecords, startedAt: startedAt)
            .filter { !$0.isEarlySleep }.map(\.days).max() ?? 0
    }
    private var longestEarlySleepStreak: Int {
        SleepCheckInStore.segments(from: planRecords, startedAt: startedAt)
            .filter(\.isEarlySleep).map(\.days).max() ?? 0
    }
    private var latestBedtimeMinutes: Int? { planRecords.last?.bedtimeMinutes }
    private var taskValue: Int {
        switch metric {
        case .earlySleepDays: return earlySleepDays
        case .bedtimeDays: return onTimeDays
        case .maxLateStreak: return longestLateStreak
        case .latestBedtime: return 0
        case .longestEarlySleepStreak: return longestEarlySleepStreak
        }
    }
    private var taskProgress: Double {
        if metric == .latestBedtime {
            guard let latestBedtimeMinutes else { return 0 }
            return nightAdjusted(latestBedtimeMinutes) <= nightAdjusted(targetSleepTimeMinutes) ? 1 : 0
        }
        return min(Double(taskValue) / Double(max(targetDays, 1)), 1)
    }
    private var taskValueText: String {
        guard metric == .latestBedtime else { return "\(taskValue)" }
        guard let latestBedtimeMinutes else { return "--:--" }
        return timeText(latestBedtimeMinutes)
    }
    private var taskDetail: String {
        metric == .latestBedtime ? "目标 \(timeText(targetSleepTimeMinutes))" : "\(taskValue)/\(targetDays)天"
    }
    private var taskTitle: String {
        switch metric {
        case .earlySleepDays: return "早睡天数"
        case .bedtimeDays: return "11点入睡"
        case .maxLateStreak: return "最长连续熬夜"
        case .latestBedtime: return "最晚入睡时间"
        case .longestEarlySleepStreak: return "最长连续早睡"
        }
    }
    private var isOceanTheme: Bool { activePlanType == "fish" }
    private var accent: Color { isOceanTheme ? .blue : Color(red: 0.45, green: 0.35, blue: 0.75) }

    var body: some View {
        HStack(spacing: 0) {
            statColumn(value: "\(currentEarlyStreak)", title: "连续早睡", detail: "当前连胜", progress: min(Double(currentEarlyStreak) / 3.0, 1))
            Divider().frame(height: 120).background(Color.gray.opacity(0.1))
            statColumn(value: taskValueText, title: taskTitle, detail: taskDetail, progress: taskProgress)
        }
        .padding(.vertical, 24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
    }

    private func statColumn(value: String, title: String, detail: String, progress: Double) -> some View {
        VStack(spacing: 10) {
            Text(value)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(isOceanTheme ? Color.blue : Color(red: 0.1, green: 0.1, blue: 0.15))
                .monospacedDigit().frame(height: 54)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isOceanTheme ? Color.blue : .primary)
                .lineLimit(1).minimumScaleFactor(0.75)
            VStack(spacing: 7) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(accent.opacity(0.12))
                        Capsule().fill(accent).frame(width: proxy.size.width * max(0, min(progress, 1)))
                    }
                }
                .frame(width: 82, height: 8)
                Text(detail).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }

    private func nightAdjusted(_ minutes: Int) -> Int {
        minutes < 12 * 60 ? minutes + 24 * 60 : minutes
    }

    private func timeText(_ minutes: Int) -> String {
        let normalized = minutes % (24 * 60)
        return String(format: "%02d:%02d", normalized / 60, normalized % 60)
    }
}

#Preview {
    PlanDualStatsCard().padding().background(Color(uiColor: .systemGroupedBackground))
}
