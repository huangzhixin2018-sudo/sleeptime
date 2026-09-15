//
//  ContentView.swift
//  sleeptime
//

import SwiftUI
import UIKit
import Combine
import LocalAuthentication

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @StateObject private var tabBarVisibility = SleepTabBarVisibility()
    @StateObject private var fishTankVM = FishTankViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeWeekView()
            .tabItem {
                Label("首页", systemImage: "moon.stars.fill")
            }
            .tag(AppTab.home)

            BlankPlanView()
            .tabItem {
                Label("计划", systemImage: "star.fill")
            }
            .tag(AppTab.plan)

            StatisticsView()
            .tabItem {
                Label("统计", systemImage: "square.3.stack.3d")
            }
            .tag(AppTab.statistics)

            SoundView()
            .tabItem {
                Label("声音", systemImage: "speaker.wave.2.fill")
            }
            .tag(AppTab.sound)

            ProfileView {
                selectedTab = .plan
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(AppTab.profile)
        }
        .environmentObject(tabBarVisibility)
        .environmentObject(fishTankVM)
        .background(
            SleepTabBarVisibilityBridge(isHidden: tabBarVisibility.isHidden)
                .frame(width: 0, height: 0)
        )
        .onChange(of: selectedTab) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
        }
        .onOpenURL { url in
            if url.scheme == "sleeptime" {
                selectedTab = .home
            }
        }
    }
}

struct SleepCheckInRecord: Codable, Identifiable {
    let id: UUID
    let sleepDate: Date
    let bedtimeMinutes: Int
    let wakeMinutes: Int
    let durationMinutes: Int
    let isEarlySleep: Bool
    let isDemo: Bool?
}

struct SleepTrajectorySegment: Identifiable {
    let id = UUID()
    let isEarlySleep: Bool
    var dates: [Date]

    var title: String { isEarlySleep ? "连续早睡" : "连续熬夜" }
    var days: Int { dates.count }
}

enum SleepCheckInStore {
    static func decode(_ encoded: String) -> [SleepCheckInRecord] {
        guard let data = encoded.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([SleepCheckInRecord].self, from: data)) ?? []
    }

    static func encode(_ records: [SleepCheckInRecord]) -> String? {
        guard let data = try? JSONEncoder().encode(records) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func segments(from records: [SleepCheckInRecord], startedAt: Double) -> [SleepTrajectorySegment] {
        let calendar = Calendar.current
        let planStart = startedAt > 0 ? calendar.startOfDay(for: Date(timeIntervalSince1970: startedAt)) : .distantPast
        let sortedRecords = records
            .filter { $0.isDemo == true || calendar.startOfDay(for: $0.sleepDate) >= planStart }
            .sorted { $0.sleepDate < $1.sleepDate }

        return sortedRecords.reduce(into: []) { segments, record in
            if let lastIndex = segments.indices.last,
               segments[lastIndex].isEarlySleep == record.isEarlySleep {
                segments[lastIndex].dates.append(record.sleepDate)
            } else {
                segments.append(SleepTrajectorySegment(isEarlySleep: record.isEarlySleep, dates: [record.sleepDate]))
            }
        }
    }
}

private struct HomeWeekView: View {
    @ObservedObject private var liveActivityManager = LiveActivityManager.shared

    @EnvironmentObject var fishTankVM: FishTankViewModel

    @State private var sleepStates: [Int: HomeSleepState] = [:]
    @State private var sleepOnsetRoute: SleepOnsetRoute?
    @State private var habits: [BedtimeHabit] = [
        BedtimeHabit(name: "冥想", hasAlarm: true, alarmTime: Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date(), repeatDays: [0,1,2,3,4,5,6], checkInTime: nil)
    ]
    @State private var isShowingAddHabitSheet = false
    @AppStorage("home.sleepOnsetEntries") private var storedSleepOnsetEntries = "[]"
    @AppStorage("sleepCheckIn.records") private var encodedSleepCheckIns = "[]"
    @AppStorage("sleepGoal.workdaySelection") private var workdaySelection = "2,3,4,5,6"
    @AppStorage("sleepGoal.workdayBedtime") private var workdayBedtime = 23 * 60
    @AppStorage("sleepGoal.workdayWakeTime") private var workdayWakeTime = 7 * 60
    @AppStorage("sleepGoal.weekendBedtime") private var weekendBedtime = 23 * 60
    @AppStorage("sleepGoal.weekendWakeTime") private var weekendWakeTime = 7 * 60
    @AppStorage("sleepGoal.allowedDeviation") private var allowedDeviation = 0

    private let weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    HStack {
                Text("工作日")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.black)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "gift")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.78))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("礼物")

                Button(action: { isShowingAddHabitSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.78))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("添加习惯")
            }
                .padding(.horizontal, 18)
                .padding(.top, 10)

            HStack(spacing: 6) {
                ForEach(weekdays.indices, id: \.self) { index in
                    VStack(spacing: 8) {
                        Text(weekdays[index])
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.68))
                            .lineLimit(1)

                        Circle()
                            .fill(sleepStates[index]?.color ?? Color.black.opacity(0.08))
                            .frame(width: 30, height: 30)
                            .overlay {
                                Image(systemName: sleepStates[index]?.icon ?? "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(sleepStates[index] == nil ? Color.black.opacity(0.38) : Color.white)
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 2)

            HomeQuoteView()
                .padding(.horizontal, 18)
                .padding(.top, 18)

            VStack(alignment: .leading, spacing: 0) {
                Image("sleeping_cat")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 296)
                    .padding(.leading, 10)
                    .padding(.bottom, -1)

                SleepOverviewCard(
                    bedtimeMinutes: currentCheckIn?.bedtimeMinutes ?? targetBedtimeMinutes,
                    durationMinutes: currentCheckIn?.durationMinutes ?? plannedDurationMinutes,
                    wakeMinutes: currentCheckIn?.wakeMinutes ?? fixedWakeMinutes,
                    isCheckedIn: currentCheckIn != nil,
                    onCheckIn: saveSleepCheckIn
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)

            HStack(spacing: 8) {
                // 1. 睡眠状态 (结合清晨与入睡)
                Button {
                    sleepOnsetRoute = SleepOnsetRoute(date: lastNightDate)
                } label: {
                    HomeSleepInsightCard(
                        title: "睡眠状态",
                        value: sleepOnsetEntry(for: lastNightDate)?.state.title ?? "未记录",
                        icon: "moon.stars"
                    )
                }
                .buttonStyle(.plain)

                // 2. 午间小憩
                Button {
                    // 预留午休点击事件
                } label: {
                    HomeSleepInsightCard(
                        title: "午间小憩",
                        value: "35分钟",
                        icon: "sun.max"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)

            // 3. 新增：时刻记录卡片
            HStack(spacing: 8) {
                NavigationLink(destination: FactorsDetailView()) {
                    HomeSleepInsightCard(
                        title: "影响因素",
                        value: "去记录",
                        icon: "sun.and.horizon.fill",
                        iconColor: .orange
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: MorningFeelingDetailView()) {
                    HomeSleepInsightCard(
                        title: "清晨的感觉",
                        value: "去记录",
                        icon: "sun.haze.fill",
                        iconColor: .orange
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)

            // 下方两个白色新卡片
            HStack(spacing: 8) {
                HomePastTodayCard()
                HomeYearProgressCard()
            }
            .padding(.horizontal, 18)

            // 睡眠流程控制按钮
            if liveActivityManager.isSleepFlowActive {
                Button(action: {
                    liveActivityManager.stopSleepFlow()
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("结束睡眠流程")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            } else {
                Button(action: {
                    let now = Date()
                    let calendar = Calendar.current
                    var components = calendar.dateComponents([.year, .month, .day], from: now)
                    // 使用当天的23:30作为示例目标时间
                    components.hour = 23
                    components.minute = 30
                    var target = calendar.date(from: components) ?? now.addingTimeInterval(3600)
                    if target <= now {
                        target = calendar.date(byAdding: .day, value: 1, to: target) ?? now.addingTimeInterval(3600)
                    }

                    liveActivityManager.startSleepFlow(targetBedtime: target)
                }) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                        Text("开启睡眠流程")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                

            }
            
            PlanHabitSection(habits: $habits, isShowingAddHabitSheet: $isShowingAddHabitSheet)
                .padding(.horizontal, 18)
                .padding(.top, 16)

            Spacer(minLength: 0)
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.homeBackground.ignoresSafeArea())
        .onAppear(perform: refreshSleepStates)
        .sheet(isPresented: $isShowingAddHabitSheet) {
            AddHabitSheet(habits: $habits)
        }
        .navigationDestination(item: $sleepOnsetRoute) { route in
            SleepOnsetRecordView(
                date: route.date,
                entry: sleepOnsetEntry(for: route.date),
                onSave: saveSleepOnsetEntry
            )
        }
        }
    }

    private var lastNightDate: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }

    private var sleepCheckIns: [SleepCheckInRecord] {
        SleepCheckInStore.decode(encodedSleepCheckIns)
    }

    private var currentCheckIn: SleepCheckInRecord? {
        sleepCheckIns.first { Calendar.current.isDate($0.sleepDate, inSameDayAs: Date()) }
    }

    private var usesWorkdaySchedule: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let workdays = Set(workdaySelection.split(separator: ",").compactMap { Int($0) })
        return workdays.contains(weekday)
    }

    private var targetBedtimeMinutes: Int {
        usesWorkdaySchedule ? workdayBedtime : weekendBedtime
    }

    private var fixedWakeMinutes: Int {
        usesWorkdaySchedule ? workdayWakeTime : weekendWakeTime
    }

    private var plannedDurationMinutes: Int {
        minutesUntilWake(from: targetBedtimeMinutes, wake: fixedWakeMinutes)
    }

    private func minutesUntilWake(from bedtime: Int, wake: Int) -> Int {
        let difference = wake - bedtime
        return difference > 0 ? difference : difference + 24 * 60
    }

    private func saveSleepCheckIn() {
        guard currentCheckIn == nil else { return }
        let now = Date()
        let calendar = Calendar.current
        let bedtime = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let boundary = targetBedtimeMinutes + allowedDeviation
        let normalizedBedtime = bedtime < 12 * 60 ? bedtime + 24 * 60 : bedtime
        let normalizedBoundary = boundary < 12 * 60 ? boundary + 24 * 60 : boundary
        let record = SleepCheckInRecord(
            id: UUID(),
            sleepDate: now,
            bedtimeMinutes: bedtime,
            wakeMinutes: fixedWakeMinutes,
            durationMinutes: minutesUntilWake(from: bedtime, wake: fixedWakeMinutes),
            isEarlySleep: normalizedBedtime <= normalizedBoundary,
            isDemo: false
        )
        var records = sleepCheckIns
        let demoStart = calendar.date(byAdding: .day, value: -5, to: calendar.startOfDay(for: now)) ?? now
        records.removeAll {
            $0.isDemo == true || calendar.startOfDay(for: $0.sleepDate) >= demoStart
        }
        records.append(contentsOf: demoTrajectoryRecords(endingWith: record))
        if let encoded = SleepCheckInStore.encode(records) {
            encodedSleepCheckIns = encoded
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
    }

    private func demoTrajectoryRecords(endingWith current: SleepCheckInRecord) -> [SleepCheckInRecord] {
        let calendar = Calendar.current
        let pattern = [true, true, false, false, false, true]
        return pattern.enumerated().map { index, isEarlySleep in
            let dayOffset = index - (pattern.count - 1)
            let date = calendar.date(byAdding: .day, value: dayOffset, to: current.sleepDate) ?? current.sleepDate
            return SleepCheckInRecord(
                id: index == pattern.count - 1 ? current.id : UUID(),
                sleepDate: date,
                bedtimeMinutes: index == pattern.count - 1 ? current.bedtimeMinutes : (isEarlySleep ? 22 * 60 + 50 : 24 * 60 + 20) % (24 * 60),
                wakeMinutes: current.wakeMinutes,
                durationMinutes: index == pattern.count - 1 ? current.durationMinutes : (isEarlySleep ? 8 * 60 + 10 : 6 * 60 + 40),
                isEarlySleep: isEarlySleep,
                isDemo: true
            )
        }
    }

    private func weekdayIndex(for date: Date) -> Int {
        let systemWeekday = Calendar.current.component(.weekday, from: date)
        return (systemWeekday + 5) % 7
    }

    private func sleepOnsetEntry(for date: Date) -> SleepOnsetEntry? {
        decodedSleepOnsetEntries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
    }

    private var decodedSleepOnsetEntries: [SleepOnsetEntry] {
        guard let data = storedSleepOnsetEntries.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([SleepOnsetEntry].self, from: data)) ?? []
    }

    private func saveSleepOnsetEntry(_ entry: SleepOnsetEntry) {
        var entries = decodedSleepOnsetEntries
        entries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }
        entries.append(entry)
        guard let data = try? JSONEncoder().encode(entries),
              let encoded = String(data: data, encoding: .utf8) else { return }
        storedSleepOnsetEntries = encoded
        refreshSleepStates()
    }

    private func refreshSleepStates() {
        sleepStates = decodedSleepOnsetEntries.reduce(into: [:]) { result, entry in
            result[weekdayIndex(for: entry.date)] = entry.state
        }
    }
}

private struct HomeSleepInsightCard: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.48))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor ?? Color.black.opacity(0.42))
            }

            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.black)
                .monospacedDigit()
                .padding(.top, 9)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .frame(height: 78, alignment: .topLeading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - 新增白底卡片
private struct HomePastTodayCard: View {
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("往年今日")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            Text("01:57")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.black)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            Text("9月13日")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct HomeYearProgressCard: View {
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("今年 2026")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            // 进度可视化 (简易模拟轨道)
            ZStack {
                Ellipse()
                    .stroke(Color.black.opacity(0.1), lineWidth: 4)
                    .frame(width: 100, height: 40)
                    .rotationEffect(.degrees(-15))

                Ellipse()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.blue.opacity(0.6), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 100, height: 40)
                    .rotationEffect(.degrees(-15))

                // 模拟星球/发光点
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .shadow(color: .blue.opacity(0.8), radius: 4)
                    .offset(x: 35, y: 15) // 大致定位在轨道上

                // 百分比放中间
                Text("70%")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            Text("还剩 109 天")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
private struct SleepOverviewCard: View {
    let bedtimeMinutes: Int
    let durationMinutes: Int
    let wakeMinutes: Int
    let isCheckedIn: Bool
    let onCheckIn: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            SleepDurationDisplay(
                bedtimeMinutes: bedtimeMinutes,
                durationMinutes: durationMinutes,
                wakeMinutes: wakeMinutes
            )

            Button(action: onCheckIn) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14, weight: .semibold))

                    Text(isCheckedIn ? "今晚已打卡" : "晚安打卡")
                        .font(.system(size: 16, weight: .semibold))
                }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.black.opacity(0.9), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isCheckedIn)
        }
        .padding(.horizontal, 26)
        .padding(.top, 18)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, minHeight: 302, alignment: .top)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct SleepDurationDisplay: View {
    let bedtimeMinutes: Int
    let durationMinutes: Int
    let wakeMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(currentDateTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.black)

                Text("熬夜喵")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.black)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.72))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("分享睡眠记录")
            }

            Text(timeText(bedtimeMinutes))
                .font(.system(size: 50, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color(red: 0.72, green: 0.29, blue: 0.30))
                .padding(.top, 12)

            Text("入睡时间")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.42))
                .padding(.top, 2)

            HStack(alignment: .top, spacing: 30) {
                durationMetric
                wakeMetric
            }
            .padding(.top, 16)

        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(timeText(bedtimeMinutes))入睡，睡眠时长\(durationMinutes / 60)小时\(durationMinutes % 60)分钟，\(timeText(wakeMinutes))起床")
    }

    private var currentDateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: Date())
    }

    private var durationMetric: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(durationMinutes / 60)")
                    .font(.system(size: 27, weight: .semibold))
                Text("时")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(durationMinutes % 60)")
                    .font(.system(size: 27, weight: .semibold))
                Text("分")
                    .font(.system(size: 13, weight: .semibold))
            }
            .monospacedDigit()

            Text("时长")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.42))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var wakeMetric: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(timeText(wakeMinutes))
                .font(.system(size: 27, weight: .semibold))
                .monospacedDigit()

            Text("起床")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.42))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeText(_ minutes: Int) -> String {
        String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60)
    }
}

private struct HomeQuoteView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("觉醒的人只有一项义务，找到自我，固守自我，沿着自己的路向前走，不管它通向哪里。")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.black)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Text("——赫尔曼·黑塞")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.52))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum HomeSleepState: String, CaseIterable, Identifiable, Codable {
    case insomnia
    case allNight
    case midnightWake
    case difficulty
    case poorSleep
    case dream

    var id: String { rawValue }

    var title: String {
        switch self {
        case .insomnia: return "失眠"
        case .allNight: return "通宵"
        case .midnightWake: return "半夜醒"
        case .difficulty: return "入睡困难"
        case .poorSleep: return "睡不好"
        case .dream: return "梦境"
        }
    }

    var icon: String {
        switch self {
        case .insomnia: return "moon.zzz"
        case .allNight: return "sunrise.fill"
        case .midnightWake: return "clock"
        case .difficulty: return "ellipsis"
        case .poorSleep: return "cloud"
        case .dream: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .insomnia: return Color(red: 0.68, green: 0.43, blue: 0.42)
        case .allNight: return Color(red: 0.36, green: 0.38, blue: 0.43)
        case .midnightWake: return Color(red: 0.48, green: 0.53, blue: 0.64)
        case .difficulty: return Color(red: 0.72, green: 0.56, blue: 0.38)
        case .poorSleep: return Color(red: 0.48, green: 0.57, blue: 0.48)
        case .dream: return Color(red: 0.56, green: 0.47, blue: 0.62)
        }
    }

    var selectionColor: Color {
        switch self {
        case .insomnia: return Color(red: 0.91, green: 0.72, blue: 0.69)
        case .allNight: return Color(red: 0.75, green: 0.77, blue: 0.82)
        case .midnightWake: return Color(red: 0.73, green: 0.80, blue: 0.88)
        case .difficulty: return Color(red: 0.92, green: 0.82, blue: 0.65)
        case .poorSleep: return Color(red: 0.75, green: 0.84, blue: 0.75)
        case .dream: return Color(red: 0.83, green: 0.76, blue: 0.87)
        }
    }
}

final class SleepTabBarVisibility: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    var isHidden = false {
        willSet { objectWillChange.send() }
    }
}

private struct SleepTabBarVisibilityBridge: UIViewControllerRepresentable {
    let isHidden: Bool

    func makeUIViewController(context: Context) -> Controller {
        let controller = Controller()
        controller.setTabBarHidden(isHidden)
        return controller
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.setTabBarHidden(isHidden)
    }

    final class Controller: UIViewController {
        private var shouldHideTabBar = false
        private weak var legacyAdjustedViewController: UIViewController?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            updateTabBarVisibility()
        }

        func setTabBarHidden(_ isHidden: Bool) {
            shouldHideTabBar = isHidden
            updateTabBarVisibility()
        }

        private func updateTabBarVisibility() {
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      let tabBarController = findTabBarController(from: view.window?.rootViewController) else {
                    return
                }

                if #available(iOS 18.0, *) {
                    guard tabBarController.isTabBarHidden != shouldHideTabBar else { return }
                    tabBarController.setTabBarHidden(shouldHideTabBar, animated: false)
                } else {
                    updateLegacyTabBarVisibility(in: tabBarController)
                }

                tabBarController.view.setNeedsLayout()
                tabBarController.view.layoutIfNeeded()
            }
        }

        private func updateLegacyTabBarVisibility(in tabBarController: UITabBarController) {
            let selectedViewController = tabBarController.selectedViewController
            let tabBarHeight = tabBarController.tabBar.frame.height

            if legacyAdjustedViewController !== selectedViewController {
                legacyAdjustedViewController?.additionalSafeAreaInsets.bottom = 0
                legacyAdjustedViewController = selectedViewController
            }

            tabBarController.tabBar.isHidden = shouldHideTabBar
            selectedViewController?.additionalSafeAreaInsets.bottom = shouldHideTabBar ? -tabBarHeight : 0

            if !shouldHideTabBar {
                legacyAdjustedViewController = nil
            }
        }

        private func findTabBarController(from controller: UIViewController?) -> UITabBarController? {
            guard let controller else { return nil }
            if let tabBarController = controller as? UITabBarController {
                return tabBarController
            }

            for child in controller.children {
                if let tabBarController = findTabBarController(from: child) {
                    return tabBarController
                }
            }

            return findTabBarController(from: controller.presentedViewController)
        }
    }
}

struct SleepDetailChromeModifier: ViewModifier {
    @ObservedObject var tabBarVisibility: SleepTabBarVisibility

    func body(content: Content) -> some View {
        content
            .ignoresSafeArea(.container, edges: .bottom)
            .modifier(SleepBottomScrollEdgeEffectModifier())
            .toolbar(.hidden, for: .tabBar)
            .toolbarBackground(.hidden, for: .tabBar)
            .onAppear { tabBarVisibility.isHidden = true }
            .onDisappear { tabBarVisibility.isHidden = false }
    }
}

private struct SleepBottomScrollEdgeEffectModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectHidden(true, for: .bottom)
        } else {
            content
        }
    }
}

extension View {
    func sleepDetailChrome(_ tabBarVisibility: SleepTabBarVisibility) -> some View {
        modifier(SleepDetailChromeModifier(tabBarVisibility: tabBarVisibility))
    }
}

private enum AppTab: CaseIterable {
    case home
    case plan
    case statistics
    case sound
    case profile

    var title: String {
        switch self {
        case .home:
            return "首页"
        case .plan:
            return "计划"
        case .statistics:
            return "统计"
        case .sound:
            return "声音"
        case .profile:
            return "我的"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "moon.stars.fill"
        case .plan:
            return "star.fill"
        case .statistics:
            return "chart.bar.fill"
        case .sound:
            return "speaker.wave.2.fill"
        case .profile:
            return "person.fill"
        }
    }
}

struct SleepTrackingDetailView: View {
    let daysList = ["2", "3", "4", "5", "6", "7", "8+"]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(daysList, id: \.self) { days in
                    // 早睡卡片：统一使用蓝色
                    SleepTrackingCardView(
                        title: "连续早睡",
                        days: days,
                        count: Int.random(in: 1...10),
                        highlightColor: .blue
                    )

                    // 熬夜卡片：使用紫色（代表夜晚/熬夜），透明底色会非常干净通透
                    SleepTrackingCardView(
                        title: "连续熬夜",
                        days: days,
                        count: Int.random(in: 1...10),
                        highlightColor: .purple
                    )
                }
            }
            .padding()
        }
        .background(Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea())
        .navigationTitle("睡眠追踪")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SleepTrackingCardView: View {
    let title: String
    let days: String
    let count: Int
    let highlightColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.system(size: 19, weight: .bold)) // 标题加粗，压住阵脚
                    .foregroundColor(.primary)

                Spacer()

                // 顶部右侧留白，让标题更加独立
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text(days.replacingOccurrences(of: "+", with: ""))
                        .font(.custom("AvenirNext-CondensedBold", size: 48))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    if days.contains("+") {
                        Text("+")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }

                Text("天")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                // 把彩色胶囊移回右下角，并放大增强可读性
                Text("× \(count)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(highlightColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(highlightColor.opacity(0.15))
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private enum PlanTypography {
    static let pageTitle = Font.system(size: 32, weight: .bold)
    static let pageSubtitle = Font.system(size: 17, weight: .regular)
    static let cardTitle = Font.system(size: 16, weight: .semibold)
    static let cardSubtitle = Font.system(size: 13, weight: .regular)
    static let metricValue = Font.system(size: 26, weight: .semibold)
    static let supportingValue = Font.system(size: 20, weight: .semibold)
}


struct BedtimeHabit: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var hasAlarm: Bool
    var alarmTime: Date
    var repeatDays: Set<Int>
    var checkInTime: String?

    var isCompleted: Bool {
        checkInTime != nil
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: alarmTime)
    }
}

struct BlankPlanView: View {
    @State private var exportedPlan: ExportedPlanImage?
    @State private var meditationCheckInTime: String?
    @AppStorage("shorterPlan.isActive") private var isShorterPlanActive = false
    @AppStorage("shorterPlan.durationDays") private var planDurationDays = 7
    @AppStorage("shorterPlan.maxLateStreak") private var maxLateStreak = 2
    @AppStorage("shorterPlan.currentMaxLateStreak") private var currentMaxLateStreak = 0
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    @EnvironmentObject var fishTankVM: FishTankViewModel

    @AppStorage("shorterPlan.startedAt") private var planStartedAt = 0.0
    @AppStorage("earlySleepPlan.activeType") private var activePlanType = "shorter"
    @AppStorage("earlySleepPlan.targetStreak") private var targetEarlySleepStreak = 5
    @AppStorage("earlySleepPlan.currentStreak") private var currentEarlySleepStreak = 0
    @AppStorage("sleepCheckIn.records") private var encodedSleepCheckIns = "[]"
    @AppStorage("shorterPlan.targetSleepTimeMinutes") private var targetSleepTimeMinutes = 23 * 60 + 30

    private var trajectorySegments: [SleepTrajectorySegment] {
        Array(SleepCheckInStore.segments(
            from: SleepCheckInStore.decode(encodedSleepCheckIns),
            startedAt: planStartedAt
        ).suffix(3))
    }

    private var derivedEarlySleepStreak: Int {
        guard let last = trajectorySegments.last, last.isEarlySleep else { return 0 }
        return last.days
    }

    private var latestBedtimeMinutes: Int? {
        SleepCheckInStore.decode(encodedSleepCheckIns)
            .filter { planStartedAt <= 0 || $0.sleepDate >= Date(timeIntervalSince1970: planStartedAt) }
            .max { $0.sleepDate < $1.sleepDate }?
            .bedtimeMinutes
    }

    private var currentDay: Int {
        guard isShorterPlanActive, planStartedAt > 0 else { return 1 }
        let startDate = Date(timeIntervalSince1970: planStartedAt)
        let elapsedDays = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: startDate),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0
        return min(max(elapsedDays + 1, 1), planDurationDays)
    }

    private var hasPlanEnded: Bool {
        guard isShorterPlanActive, planStartedAt > 0 else { return false }
        let endDate = Calendar.current.date(
            byAdding: .day,
            value: planDurationDays,
            to: Date(timeIntervalSince1970: planStartedAt)
        ) ?? .distantFuture
        return Date() >= endDate
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
            // 自定义顶部：大标题与管理图标在同一高度
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 7) {
                            Text("Day \(currentDay)")
                                .font(PlanTypography.pageTitle)
                                .foregroundColor(.primary)

                            Text("of \(planDurationDays)")
                                .font(PlanTypography.pageTitle)
                                .foregroundStyle(Color.black.opacity(0.34))
                        }
                        .monospacedDigit()
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("计划第 \(currentDay) 天，共 \(planDurationDays) 天")
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        NavigationLink {
                            MedalDetailView()
                        } label: {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color(red: 0.95, green: 0.67, blue: 0.16))
                                .frame(width: 36, height: 36)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            EarlySleepStreakDetailView(
                                currentValue: derivedEarlySleepStreak,
                                targetValue: targetEarlySleepStreak
                            )
                        } label: {
                            HStack(spacing: 4) {
                                Text("🔥")
                                Text("0")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(Color(.systemBackground))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if activePlanType == "streak" {
                        PlanTimelineCarouselView(
                            totalDays: planDurationDays,
                            currentDay: currentDay
                        )
                    } else {
                        // 计划页面的动态阶段指示器
                        PlanStageCarouselView(
                            totalDays: planDurationDays,
                            currentDay: currentDay
                        )
                    }
                    
                    // 日间连胜与任务进度卡片（第二张卡片）
                    PlanDualStatsCard()
                    
                    if activePlanType != "fish" {
                    
                    if activePlanType != "streak" {
                        LatestBedtimeGoalCard(
                            bedtimeMinutes: latestBedtimeMinutes,
                            targetMinutes: targetSleepTimeMinutes
                        )
                    }



                    } // End of activePlanType != "fish"
                    
                    if activePlanType == "streak" {
                        LongestEarlySleepCard(
                            currentValue: currentEarlySleepStreak,
                            targetValue: targetEarlySleepStreak
                        )
                    }

                    HStack(spacing: 8) {
                        NavigationLink {
                            TimeTravelDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            PlanPatternCard(
                                title: "原则",
                                subtitle: nil,
                                icon: "checkmark.shield.fill",
                                tint: Color(red: 0.42, green: 0.56, blue: 0.16),
                                shapeStyle: .left
                            )
                        }
                        .frame(width: 100)
                        .buttonStyle(.plain)

                        NavigationLink {
                            EarlySleepMethodsView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            PlanPatternCard(
                                title: "早睡方法",
                                subtitle: nil,
                                icon: "lightbulb.fill",
                                tint: Color(red: 0.30, green: 0.52, blue: 0.78),
                                shapeStyle: .plain
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.plain)

                        NavigationLink {
                            ProgressDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            PlanPatternCard(
                                title: "进步",
                                subtitle: nil,
                                icon: "moon.fill",
                                tint: Color(red: 0.95, green: 0.40, blue: 0.38),
                                usesFlowerIcon: true,
                                shapeStyle: .right
                            )
                        }
                        .frame(width: 100)
                        .buttonStyle(.plain)
                    }



                    if activePlanType != "fish" {
                        let planName: String = {
                            switch activePlanType {
                            case "fish": return "养鱼计划"
                            case "streak": return "不养鱼计划"
                            default: return "渐进早睡计划"
                            }
                        }()
                        
                        EmptyPlanFrameworkCard(
                            segments: trajectorySegments,
                            planName: planName
                        )
                        .padding(.top, 8)
                        
                        // 页面底部的装饰性小鱼
                        SimpleFishView()
                            .frame(width: 44, height: 26)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                    } else {
                        FishTankView(vm: fishTankVM)
                        
                        EmptyPlanFrameworkCard(
                            segments: trajectorySegments,
                            planName: "养鱼计划"
                        )
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                    }

                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.homeBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $exportedPlan) { plan in
                ActivityShareSheet(items: [plan.image])
            }
            .onAppear(perform: synchronizePlanStreaks)
            .onChange(of: encodedSleepCheckIns) {
                synchronizePlanStreaks()
            }
        }
    }

    private func synchronizePlanStreaks() {
        currentEarlySleepStreak = derivedEarlySleepStreak
        currentMaxLateStreak = trajectorySegments
            .filter { !$0.isEarlySleep }
            .map(\.days)
            .max() ?? 0
    }

    @MainActor
    private func exportCurrentPlan() {
        let renderer = ImageRenderer(
            content: CurrentPlanExportView(
                currentDay: currentDay,
                planDurationDays: planDurationDays,
                maxLateStreak: maxLateStreak,
                planStartedAt: planStartedAt,
                isShorterPlanActive: isShorterPlanActive,
                activePlanType: activePlanType,
                targetEarlySleepStreak: targetEarlySleepStreak,
                currentEarlySleepStreak: currentEarlySleepStreak,
                targetSleepTimeMinutes: targetSleepTimeMinutes,
                latestBedtimeMinutes: latestBedtimeMinutes,
                trajectorySegments: trajectorySegments,
                meditationCheckInTime: meditationCheckInTime
            )
                .frame(width: 390)
                .fixedSize(horizontal: false, vertical: true)
        )
        renderer.scale = 3

        if let image = renderer.uiImage {
            exportedPlan = ExportedPlanImage(image: image)
        }
    }
}

private struct CurrentPlanExportView: View {
    let currentDay: Int
    let planDurationDays: Int
    let maxLateStreak: Int
    let planStartedAt: Double
    let isShorterPlanActive: Bool
    let activePlanType: String
    let targetEarlySleepStreak: Int
    let currentEarlySleepStreak: Int
    let targetSleepTimeMinutes: Int
    let latestBedtimeMinutes: Int?
    let trajectorySegments: [SleepTrajectorySegment]
    let meditationCheckInTime: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("Day \(currentDay)")
                    .font(.system(size: 30, weight: .bold))

                Text("of \(planDurationDays)")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.34))
            }
                .monospacedDigit()

            if activePlanType != "streak" {
                LatestBedtimeGoalCard(
                    bedtimeMinutes: latestBedtimeMinutes,
                    targetMinutes: targetSleepTimeMinutes
                )
            }
            if activePlanType == "streak" {
                let planName: String = {
                    switch activePlanType {
                    case "fish": return "养鱼计划"
                    case "streak": return "不养鱼计划"
                    default: return "渐进早睡计划"
                    }
                }()
                EmptyPlanFrameworkCard(
                    segments: trajectorySegments,
                    planName: planName
                )
            }


            HStack(spacing: 8) {
                PlanPatternCard(
                    title: "原则",
                    subtitle: nil,
                    icon: "checkmark.shield.fill",
                    tint: Color(red: 0.42, green: 0.56, blue: 0.16),
                    shapeStyle: .left
                )
                .frame(width: 100)

                PlanPatternCard(
                    title: "早睡方法",
                    subtitle: nil,
                    icon: "lightbulb.fill",
                    tint: Color(red: 0.30, green: 0.52, blue: 0.78),
                    shapeStyle: .plain
                )
                .frame(maxWidth: .infinity)

                PlanPatternCard(
                    title: "进步",
                    subtitle: nil,
                    icon: "moon.fill",
                    tint: Color(red: 0.95, green: 0.40, blue: 0.38),
                    usesFlowerIcon: true,
                    shapeStyle: .right
                )
                .frame(width: 100)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 18)
        .background(AppTheme.homeBackground)
    }
}

private struct PlanHabitSection: View {
    @Binding var habits: [BedtimeHabit]
    @Binding var isShowingAddHabitSheet: Bool
    var showsAddButton = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 16) {
                ForEach($habits) { $habit in
                    NavigationLink {
                        HabitDetailView(habit: $habit) {
                            if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                                withAnimation {
                                    _ = habits.remove(at: index)
                                }
                            }
                        }
                    } label: {
                        VStack(spacing: 12) {
                            HStack(alignment: .lastTextBaseline, spacing: 8) {
                                Text(habit.name)
                                    .font(.system(size: 23, weight: .bold))
                                    .foregroundStyle(Color.black)

                            if habit.hasAlarm {
                                Text("（\(habit.timeString) 提醒）")
                                    .font(.system(size: 15, weight: .regular))
                                    .monospacedDigit()
                                    .foregroundStyle(Color.black.opacity(0.62))
                            }

                            Spacer()

                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    let currentTime = {
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "HH:mm"
                                        return formatter.string(from: Date())
                                    }()
                                    habit.checkInTime = habit.isCompleted ? nil : currentTime
                                }
                            } label: {
                                Circle()
                                    .fill(habit.isCompleted ? AppTheme.accent : Color.clear)
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        Circle()
                                            .stroke(
                                                habit.isCompleted ? Color.clear : Color.black.opacity(0.18),
                                                lineWidth: 1.5
                                            )
                                    }
                                    .overlay {
                                        if habit.isCompleted {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(habit.isCompleted ? "取消\(habit.name)打卡" : "完成\(habit.name)打卡")
                        }

                        // Track week history for THIS habit
                        HStack(spacing: 6) {
                            ForEach(1...7, id: \.self) { day in
                                Group {
                                    if day == 1 && habit.isCompleted {
                                        Text(habit.checkInTime ?? "")
                                            .font(.system(size: 13, weight: .semibold))
                                            .monospacedDigit()
                                            .foregroundStyle(Color.black.opacity(0.72))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                    } else {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(Color.black.opacity(0.06))
                                            .overlay {
                                                Text(day == 1 ? "--:--" : "\(day)")
                                                    .font(.system(size: day == 1 ? 10 : 12, weight: .semibold))
                                                    .monospacedDigit()
                                                    .foregroundStyle(Color.black.opacity(0.52))
                                            }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 30)
                            }
                        }

                        HStack(spacing: 6) {
                            ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { weekday in
                                Text(weekday)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.black.opacity(0.52))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 18)
                    .frame(maxWidth: .infinity)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: AppTheme.planCardRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct PlanPatternCard: View {
    let title: String
    let subtitle: String?
    let icon: String
    let tint: Color
    var usesFlowerIcon = false
    let shapeStyle: PlanPatternCardShapeStyle

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                if usesFlowerIcon {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 25, weight: .regular))
                        .foregroundStyle(tint)
                        .overlay {
                            Image(systemName: "seal.fill")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Color.black.opacity(0.84))
                        }
                        .overlay {
                            Circle()
                                .fill(tint)
                                .frame(width: 6, height: 6)
                        }
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                }
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.42))
                }
            }

        }
        .padding(.horizontal, 9)
        .padding(.top, 15)
        .padding(.bottom, 7)
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 66, alignment: .leading)
        .background {
            if shapeStyle == .plain {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .padding(.top, 14)
            } else {
                PatternFolderShape(mirrored: shapeStyle == .right)
                    .fill(Color.white)
            }
        }
    }
}

private enum PlanPatternCardShapeStyle {
    case left
    case plain
    case right
}

private struct PatternFolderShape: Shape {
    let mirrored: Bool

    func path(in rect: CGRect) -> Path {
        let corner: CGFloat = 18
        let shoulderX = rect.width * 0.43
        let shoulderY: CGFloat = 14
        var path = Path()

        path.move(to: CGPoint(x: corner, y: 0))
        path.addLine(to: CGPoint(x: shoulderX - 18, y: 0))
        path.addCurve(
            to: CGPoint(x: shoulderX + 16, y: shoulderY),
            control1: CGPoint(x: shoulderX - 3, y: 0),
            control2: CGPoint(x: shoulderX, y: shoulderY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - corner, y: shoulderY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: shoulderY + corner),
            control: CGPoint(x: rect.maxX, y: shoulderY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - corner))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - corner, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: corner, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - corner),
            control: CGPoint(x: 0, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: 0, y: corner))
        path.addQuadCurve(
            to: CGPoint(x: corner, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        path.closeSubpath()
        if mirrored {
            return path.applying(
                CGAffineTransform(
                    a: -1,
                    b: 0,
                    c: 0,
                    d: 1,
                    tx: rect.width,
                    ty: 0
                )
            )
        }
        return path
    }
}

private struct LongestEarlySleepCard: View {
    let currentValue: Int
    let targetValue: Int

    private let accentColor = Color(red: 0.18, green: 0.48, blue: 0.36)

    private var milestones: [Int] {
        let target = max(targetValue, 1)
        if target <= 7 {
            return Array(1...target)
        }

        return Array(Set([1, target / 4, target / 2, target * 3 / 4, target]))
            .filter { $0 > 0 }
            .sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("最长连续早睡")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(accentColor)

                    Spacer(minLength: 8)

                    Text("目标 \(targetValue)天")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 8)
                        .frame(height: 30)
                        .background(
                            accentColor.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                        )
                }

                HStack(alignment: .lastTextBaseline, spacing: 5) {
                        Text("\(currentValue)")
                            .font(.system(size: 40, weight: .medium))
                            .monospacedDigit()
                            .foregroundStyle(accentColor)

                    Text("天")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.62))
                }
            }

            VStack(spacing: 0) {
                ZStack {
                    Capsule()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 32)

                    HStack {
                        ForEach(milestones, id: \.self) { day in
                            Circle()
                                .fill(day <= currentValue ? accentColor : Color.white)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    if day == milestones.last {
                                        Image(systemName: "flag.fill")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(accentColor)
                                    } else if day <= currentValue {
                                        Image(systemName: "moon.fill")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(.white)
                                    } else {
                                        Text("\(day)")
                                            .font(.system(size: 11, weight: .semibold))
                                            .monospacedDigit()
                                            .foregroundStyle(Color.black.opacity(0.38))
                                    }
                                }

                            if day != milestones.last {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: AppTheme.planCardRadius, style: .continuous))
    }
}


private struct LatestBedtimeGoalCard: View {
    let bedtimeMinutes: Int?
    let targetMinutes: Int

    var body: some View {
        HStack {
            Text("熬夜超时")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black)
            
            Spacer()
            
            Text(timeText(prototypeBedtimeMinutes))
                .font(.system(size: 18, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color.black)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(Color.white, in: RoundedRectangle(cornerRadius: AppTheme.planCardRadius, style: .continuous))
    }

    private var prototypeBedtimeMinutes: Int {
        bedtimeMinutes ?? 23 * 60
    }


    private func timeText(_ minutes: Int) -> String {
        String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60)
    }
}



private struct MedalDetailView: View {
    @EnvironmentObject var fishTankVM: FishTankViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack {
                    Image("stay_up_late_demon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.top, 40)
                    
                    Text("熬夜掌控力与勋章")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    Text("勋章系统即将上线...")
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                
                FishTankControlCard(vm: fishTankVM)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("勋章")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EarlySleepStreakDetailView: View {
    var currentValue: Int
    var targetValue: Int
    private let recentDays = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Text("🔥")
                        .font(.system(size: 58))

                    Text("0")
                        .font(.system(size: 52, weight: .bold, design: .rounded))

                    Text("连续早睡天数")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)

                HStack(spacing: 12) {
                    streakMetric(title: "历史最长", value: "\(currentValue) 天")
                    streakMetric(title: "本月早睡", value: "0 天")
                }

                VStack(alignment: .leading, spacing: 18) {
                    Text("最近 7 天")
                        .font(.system(size: 17, weight: .semibold))

                    HStack(spacing: 8) {
                        ForEach(recentDays, id: \.self) { day in
                            VStack(spacing: 9) {
                                Circle()
                                    .fill(Color(uiColor: .tertiarySystemFill))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Image(systemName: "minus")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.tertiary)
                                    }

                                Text(day)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    Text("完成一次早睡后，连续记录会从这里开始累积。")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("连续早睡")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func streakMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 25, weight: .bold, design: .rounded))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}



struct EarlySleepPlan1DetailView: View {
    @State private var exportedPlan: ExportedPlanImage?

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // 标题区 (去掉返回箭头)
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Day 1")
                                .font(.system(size: 28, weight: .black))
                                .tracking(-0.5) // 字距微调，更紧凑
                                .foregroundColor(.primary)

                            WavyLine()
                                .stroke(Color(red: 0.2, green: 0.75, blue: 0.4), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                                .frame(width: 70, height: 7)
                                .padding(.leading, 2)
                        }

                        Text("最晚 02:00 入睡 · 连续熬夜不超过 5 天")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.88)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                HStack(spacing: 16) {
                    TargetCardView(
                        title: "超时熬夜时长",
                        value: "2",
                        unit: "小时",
                        themeColor: Color(red: 0.82, green: 0.89, blue: 0.96),
                        rotationAngle: -1.4
                    )

                    TargetCardView(
                        title: "早睡天数",
                        value: "6",
                        unit: "天",
                        themeColor: Color(red: 0.82, green: 0.95, blue: 0.84),
                        rotationAngle: 1.6
                    )
                }
                .padding(.horizontal, 16)

                HStack(spacing: 16) {
                    TargetCardView(
                        title: "实际最晚入睡",
                        value: "23:45",
                        unit: "",
                        themeColor: Color(red: 0.82, green: 0.89, blue: 0.96),
                        rotationAngle: 1.1
                    )

                    TargetCardView(
                        title: "最长连续熬夜",
                        value: "5",
                        unit: "天",
                        themeColor: Color(red: 0.82, green: 0.95, blue: 0.84),
                        rotationAngle: -1.8
                    )
                }
                .padding(.horizontal, 16)

                DayTimelineCardView()
                    .padding(.horizontal, 16)


                // 承诺追踪卡片 (说到做到 vs 破戒)
                HabitStreakView()

                VStack(spacing: 12) {
                    EarlySleepDayGridView()
                        .padding(.horizontal, 16)
                }

                Button {
                    exportPlanImage()
                } label: {
                    Label("分享计划", systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(UIColor.separator).opacity(0.7), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.bottom, 40) // 底部留白，防止滚动到底部时贴边
            }
        }
        .navigationTitle("早睡方案1")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportedPlan) { plan in
            ActivityShareSheet(items: [plan.image])
        }
    }

    @MainActor
    private func exportPlanImage() {
        let renderer = ImageRenderer(
            content: PlanShareImageView()
                .frame(width: 390)
        )
        renderer.scale = 3

        if let image = renderer.uiImage {
            exportedPlan = ExportedPlanImage(image: image)
        }
    }
}

struct ExportedPlanImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct PlanShareImageView: View {
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95)

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Day 1")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.primary)

                        WavyLine()
                            .stroke(Color(red: 0.2, green: 0.75, blue: 0.4), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .frame(width: 120, height: 7)
                            .padding(.leading, 2)
                    }

                    Text("最晚 02:00 入睡 · 连续熬夜不超过 5 天")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 24)

                HStack(spacing: 16) {
                    TargetCardView(
                        title: "超时熬夜时长",
                        value: "2",
                        unit: "小时",
                        themeColor: Color(red: 0.82, green: 0.89, blue: 0.96),
                        rotationAngle: -1.4
                    )

                    TargetCardView(
                        title: "早睡天数",
                        value: "6",
                        unit: "天",
                        themeColor: Color(red: 0.82, green: 0.95, blue: 0.84),
                        rotationAngle: 1.6
                    )
                }
                .padding(.horizontal, 16)

                HStack(spacing: 16) {
                    TargetCardView(
                        title: "实际最晚入睡",
                        value: "23:45",
                        unit: "",
                        themeColor: Color(red: 0.82, green: 0.89, blue: 0.96),
                        rotationAngle: 1.1
                    )

                    TargetCardView(
                        title: "最长连续熬夜",
                        value: "5",
                        unit: "天",
                        themeColor: Color(red: 0.82, green: 0.95, blue: 0.84),
                        rotationAngle: -1.8
                    )
                }
                .padding(.horizontal, 16)

                DayTimelineCardView()
                    .padding(.horizontal, 16)


                HabitStreakView(renderForExport: true)

                EarlySleepDayGridView()
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 24)
        }
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
