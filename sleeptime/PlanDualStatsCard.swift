import SwiftUI

struct PlanDualStatsCard: View {
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    @AppStorage("earlySleepPlan.earlySleepTargetDays") private var earlySleepTargetDays = 2
    @AppStorage("earlySleepPlan.bedtimeTargetDays") private var bedtimeTargetDays = 1
    @AppStorage("shorterPlan.maxLateStreak") private var maxLateStreak = 3
    @AppStorage("shorterPlan.targetSleepTimeMinutes") private var latestBedtimeTargetMinutes = 2 * 60
    @AppStorage("earlySleepPlan.longestEarlySleepTargetDays") private var longestEarlySleepTargetDays = 5
    @AppStorage("shorterPlan.startedAt") private var startedAt = 0.0
    @AppStorage("sleepCheckIn.records") private var encodedSleepCheckIns = "[]"

    private var progress: PlanGoalProgress {
        PlanGoalProgress(
            records: SleepCheckInStore.decode(encodedSleepCheckIns),
            startedAt: startedAt,
            earlySleepTargetDays: earlySleepTargetDays,
            bedtimeTargetDays: bedtimeTargetDays,
            maxLateStreak: maxLateStreak,
            latestBedtimeTargetMinutes: latestBedtimeTargetMinutes,
            longestEarlySleepTargetDays: longestEarlySleepTargetDays
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            statColumn(
                value: "\(progress.currentEarlySleepStreak)",
                title: "连续早睡",
                detail: "当前连胜",
                progress: min(Double(progress.currentEarlySleepStreak) / Double(max(longestEarlySleepTargetDays, 1)), 1)
            )

            Divider().frame(height: 120)

            NavigationLink {
                PlanActionProgressDetailView()
                    .sleepDetailChrome(tabBarVisibility)
            } label: {
                statColumn(
                    value: "\(progress.completedGoalCount)",
                    title: "行动进度",
                    detail: "\(progress.completedGoalCount)/5任务",
                    progress: Double(progress.completedGoalCount) / 5.0
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 4)
    }

    private func statColumn(value: String, title: String, detail: String, progress: Double) -> some View {
        VStack(spacing: 10) {
            Text(value)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Color(red: 0.12, green: 0.34, blue: 0.45))
                .monospacedDigit()
                .frame(height: 54)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            VStack(spacing: 7) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.blue.opacity(0.12))
                        Capsule().fill(Color.blue)
                            .frame(width: proxy.size.width * max(0, min(progress, 1)))
                    }
                }
                .frame(width: 82, height: 8)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }
}

struct PlanActionProgressDetailView: View {
    @AppStorage("earlySleepPlan.earlySleepTargetDays") private var earlySleepTargetDays = 2
    @AppStorage("earlySleepPlan.bedtimeTargetDays") private var bedtimeTargetDays = 1
    @AppStorage("shorterPlan.maxLateStreak") private var maxLateStreak = 3
    @AppStorage("shorterPlan.targetSleepTimeMinutes") private var latestBedtimeTargetMinutes = 2 * 60
    @AppStorage("earlySleepPlan.longestEarlySleepTargetDays") private var longestEarlySleepTargetDays = 5
    @AppStorage("shorterPlan.startedAt") private var startedAt = 0.0
    @AppStorage("sleepCheckIn.records") private var encodedSleepCheckIns = "[]"

    private var progress: PlanGoalProgress {
        PlanGoalProgress(
            records: SleepCheckInStore.decode(encodedSleepCheckIns),
            startedAt: startedAt,
            earlySleepTargetDays: earlySleepTargetDays,
            bedtimeTargetDays: bedtimeTargetDays,
            maxLateStreak: maxLateStreak,
            latestBedtimeTargetMinutes: latestBedtimeTargetMinutes,
            longestEarlySleepTargetDays: longestEarlySleepTargetDays
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                progressSummary

                goalCard(
                    title: "早睡天数",
                    current: "\(progress.earlySleepDays)",
                    unit: "天",
                    target: "\(earlySleepTargetDays) 天",
                    status: progress.earlySleepDays >= earlySleepTargetDays ? "已完成" : "进行中",
                    tint: Color(red: 0.25, green: 0.48, blue: 0.78)
                )
                goalCard(
                    title: "11点入睡",
                    current: "\(progress.bedtimeDays)",
                    unit: "天",
                    target: "\(bedtimeTargetDays) 天",
                    status: progress.bedtimeDays >= bedtimeTargetDays ? "已完成" : "进行中",
                    tint: Color(red: 0.18, green: 0.58, blue: 0.47)
                )
                goalCard(
                    title: "最长连续熬夜不超过",
                    current: "\(progress.longestLateStreak)",
                    unit: "天",
                    target: "\(maxLateStreak) 天",
                    status: limitStatus(progress.longestLateStreak, maxLateStreak),
                    tint: Color(red: 0.76, green: 0.38, blue: 0.30)
                )
                goalCard(
                    title: "最晚入睡时间不超过",
                    current: progress.latestBedtimeText,
                    unit: "",
                    target: timeText(latestBedtimeTargetMinutes),
                    status: timeLimitStatus,
                    tint: Color(red: 0.48, green: 0.38, blue: 0.72)
                )
                goalCard(
                    title: "最长连续早睡天数",
                    current: "\(progress.longestEarlySleepStreak)",
                    unit: "天",
                    target: "\(longestEarlySleepTargetDays) 天",
                    status: progress.longestEarlySleepStreak >= longestEarlySleepTargetDays ? "已完成" : "进行中",
                    tint: Color(red: 0.36, green: 0.55, blue: 0.20)
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("行动进度")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("已完成")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(progress.completedGoalCount) / 5")
                    .font(.system(size: 24, weight: .bold))
                    .monospacedDigit()
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule().fill(Color(red: 0.18, green: 0.55, blue: 0.47))
                        .frame(width: proxy.size.width * Double(progress.completedGoalCount) / 5.0)
                }
            }
            .frame(height: 10)
        }
        .padding(.bottom, 6)
    }

    private func goalCard(title: String, current: String, unit: String, target: String, status: String, tint: Color) -> some View {
        let currentText = unit.isEmpty ? current : "\(current)\(unit)"
        let targetText = target.replacingOccurrences(of: " ", with: "")

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(status)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(tint)
            }

            HStack(alignment: .lastTextBaseline) {
                Text(currentText)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                Spacer()
                Text("目标\(targetText)")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(18)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func limitStatus(_ value: Int, _ target: Int) -> String {
        guard progress.hasRecords else { return "未开始" }
        return value <= target ? "保持中" : "已超出"
    }

    private var timeLimitStatus: String {
        guard progress.hasRecords else { return "未开始" }
        return progress.latestBedtimePassed ? "保持中" : "已超出"
    }

    private func timeText(_ minutes: Int) -> String {
        let normalized = minutes % (24 * 60)
        return String(format: "%02d:%02d", normalized / 60, normalized % 60)
    }
}

private struct PlanGoalProgress {
    let records: [SleepCheckInRecord]
    let startedAt: Double
    let earlySleepTargetDays: Int
    let bedtimeTargetDays: Int
    let maxLateStreak: Int
    let latestBedtimeTargetMinutes: Int
    let longestEarlySleepTargetDays: Int

    private var planRecords: [SleepCheckInRecord] {
        let calendar = Calendar.current
        let start = startedAt > 0 ? calendar.startOfDay(for: Date(timeIntervalSince1970: startedAt)) : .distantPast
        return records
            .filter { calendar.startOfDay(for: $0.sleepDate) >= start }
            .sorted { $0.sleepDate < $1.sleepDate }
    }

    private var segments: [SleepTrajectorySegment] {
        SleepCheckInStore.segments(from: planRecords, startedAt: startedAt)
    }

    var earlySleepDays: Int { planRecords.filter(\.isEarlySleep).count }
    var hasRecords: Bool { !planRecords.isEmpty }
    var bedtimeDays: Int { planRecords.filter { nightAdjusted($0.bedtimeMinutes) <= 23 * 60 }.count }
    var longestLateStreak: Int { segments.filter { !$0.isEarlySleep }.map(\.days).max() ?? 0 }
    var longestEarlySleepStreak: Int { segments.filter(\.isEarlySleep).map(\.days).max() ?? 0 }
    var currentEarlySleepStreak: Int { segments.last.map { $0.isEarlySleep ? $0.days : 0 } ?? 0 }
    var latestBedtimeMinutes: Int? { planRecords.map(\.bedtimeMinutes).max(by: { nightAdjusted($0) < nightAdjusted($1) }) }
    var latestBedtimePassed: Bool {
        guard let latestBedtimeMinutes else { return false }
        return nightAdjusted(latestBedtimeMinutes) <= nightAdjusted(latestBedtimeTargetMinutes)
    }
    var latestBedtimeText: String {
        guard let latestBedtimeMinutes else { return "--:--" }
        let normalized = latestBedtimeMinutes % (24 * 60)
        return String(format: "%02d:%02d", normalized / 60, normalized % 60)
    }
    var completedGoalCount: Int {
        var count = 0
        if earlySleepDays >= earlySleepTargetDays { count += 1 }
        if bedtimeDays >= bedtimeTargetDays { count += 1 }
        if !planRecords.isEmpty && longestLateStreak <= maxLateStreak { count += 1 }
        if latestBedtimePassed { count += 1 }
        if longestEarlySleepStreak >= longestEarlySleepTargetDays { count += 1 }
        return count
    }

    private func nightAdjusted(_ minutes: Int) -> Int {
        minutes < 12 * 60 ? minutes + 24 * 60 : minutes
    }
}

#Preview {
    NavigationStack {
        PlanDualStatsCard().padding().background(Color(uiColor: .systemGroupedBackground))
    }
}
