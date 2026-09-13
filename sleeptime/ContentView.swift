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
                Label("统计", systemImage: "chart.bar.fill")
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
        .background(
            SleepTabBarVisibilityBridge(isHidden: tabBarVisibility.isHidden)
                .frame(width: 0, height: 0)
        )
        .onChange(of: selectedTab) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.8)
        }
    }
}

private struct SleepCheckInRecord: Codable, Identifiable {
    let id: UUID
    let sleepDate: Date
    let bedtimeMinutes: Int
    let wakeMinutes: Int
    let durationMinutes: Int
    let isEarlySleep: Bool
    let isDemo: Bool?
}

private struct SleepTrajectorySegment: Identifiable {
    let id = UUID()
    let isEarlySleep: Bool
    var dates: [Date]

    var title: String { isEarlySleep ? "连续早睡" : "连续熬夜" }
    var days: Int { dates.count }
}

private enum SleepCheckInStore {
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
    @State private var sleepStates: [Int: HomeSleepState] = [:]
    @State private var sleepOnsetRoute: SleepOnsetRoute?
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
            
            // 下方两个白色新卡片
            HStack(spacing: 8) {
                HomePastTodayCard()
                HomeYearProgressCard()
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 0)
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.homeBackground.ignoresSafeArea())
        .onAppear(perform: refreshSleepStates)
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
        decodedSleepOnsetEntries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
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
                    .foregroundStyle(Color.black.opacity(0.42))
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

private enum HomeSleepState: String, CaseIterable, Identifiable, Codable {
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
    @State private var habits: [BedtimeHabit] = [
        BedtimeHabit(name: "冥想", hasAlarm: true, alarmTime: Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date(), repeatDays: [0,1,2,3,4,5,6], checkInTime: nil)
    ]
    @State private var isShowingAddHabitSheet = false
    @AppStorage("shorterPlan.isActive") private var isShorterPlanActive = false
    @AppStorage("shorterPlan.durationDays") private var planDurationDays = 7
    @AppStorage("shorterPlan.maxLateStreak") private var maxLateStreak = 2
    @AppStorage("shorterPlan.currentMaxLateStreak") private var currentMaxLateStreak = 0
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility

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
                        Image(systemName: "medal.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(red: 0.95, green: 0.67, blue: 0.16))
                            .frame(width: 36, height: 36)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())

                        NavigationLink {
                            EarlySleepStreakDetailView()
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
                        LongestEarlySleepCard(
                            currentValue: derivedEarlySleepStreak,
                            targetValue: targetEarlySleepStreak
                        )
                    } else {
                        LatestBedtimeGoalCard(
                            bedtimeMinutes: latestBedtimeMinutes,
                            targetMinutes: targetSleepTimeMinutes
                        )

                        BedtimeStreakSummaryCard(earlyDays: 2, lateDays: 3)
                    }

                    if activePlanType == "streak" {
                        EmptyPlanFrameworkCard(segments: trajectorySegments)
                    }

                    PlanControlFlowCard()

                    TodayWorkCardView(
                        planDurationDays: planDurationDays,
                        maxLateStreak: maxLateStreak,
                        currentDay: currentDay,
                        planStartedAt: planStartedAt,
                        isShorterPlanActive: isShorterPlanActive
                    )

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

                    PlanHabitSection(habits: $habits, isShowingAddHabitSheet: $isShowingAddHabitSheet)

                    Button {
                        exportCurrentPlan()
                    } label: {
                        Label("导出图片", systemImage: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: AppTheme.planCardRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
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
            .sheet(isPresented: $isShowingAddHabitSheet) {
                AddHabitSheet(habits: $habits)
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
                meditationCheckInTime: meditationCheckInTime,
                habits: habits
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
    let habits: [BedtimeHabit]

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

            if activePlanType == "streak" {
                LongestEarlySleepCard(
                    currentValue: currentEarlySleepStreak,
                    targetValue: targetEarlySleepStreak
                )
            } else {
                LatestBedtimeGoalCard(
                    bedtimeMinutes: latestBedtimeMinutes,
                    targetMinutes: targetSleepTimeMinutes
                )

                BedtimeStreakSummaryCard(earlyDays: 2, lateDays: 3)
            }
            if activePlanType == "streak" {
                EmptyPlanFrameworkCard(segments: trajectorySegments)
            }

            PlanControlFlowCard()

            TodayWorkCardView(
                planDurationDays: planDurationDays,
                maxLateStreak: maxLateStreak,
                currentDay: currentDay,
                planStartedAt: planStartedAt,
                isShorterPlanActive: isShorterPlanActive
            )

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

            PlanHabitSection(
                habits: .constant(habits),
                isShowingAddHabitSheet: .constant(false),
                showsAddButton: false
            )
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
            HStack {
                Text("睡前习惯")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.black)

                Spacer()

                if showsAddButton {
                    Button(action: { isShowingAddHabitSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("添加睡前习惯")
                }
            }

            VStack(spacing: 16) {
                ForEach($habits) { $habit in
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

private struct EmptyPlanFrameworkCard: View {
    let segments: [SleepTrajectorySegment]

    private var isEmpty: Bool { segments.isEmpty }

    var body: some View {
        GeometryReader { proxy in
            let dividerX = proxy.size.width * 0.15

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)

                VStack(spacing: 2) {
                    ForEach(["作", "息", "轨", "迹"], id: \.self) { character in
                        Text(character)
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .foregroundStyle(Color.black)
                .position(x: dividerX / 2, y: proxy.size.height / 2)

                Group {
                    if isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("看见每段作息的变化")
                                .font(.system(size: 17, weight: .semibold))

                            Text("完成睡眠记录后，早睡与熬夜将会分段呈现，让作息变化清晰可见")
                                .font(.system(size: 16, weight: .regular))
                                .lineSpacing(6)
                                .multilineTextAlignment(.leading)
                        }
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    } else {
                        HStack(spacing: 5) {
                            ForEach(segments) { segment in
                                trackingMetric(
                                    title: segment.title,
                                    value: segment.days,
                                    dateRange: dateRange(for: segment.dates)
                                )
                            }
                        }
                        .padding(8)
                        .padding(.horizontal, 8)
                    }
                }
                .frame(width: proxy.size.width - dividerX, height: proxy.size.height)
                .position(
                    x: dividerX + (proxy.size.width - dividerX) / 2,
                    y: proxy.size.height / 2
                )

                Path { path in
                    path.move(to: CGPoint(x: dividerX, y: 10))
                    path.addLine(to: CGPoint(x: dividerX, y: proxy.size.height - 10))
                }
                .stroke(
                    Color.black.opacity(0.14),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 6])
                )

                VStack {
                    Circle()
                        .fill(AppTheme.homeBackground)
                        .frame(width: 14, height: 14)
                        .offset(y: -7)

                    Spacer()

                    Circle()
                        .fill(AppTheme.homeBackground)
                        .frame(width: 14, height: 14)
                        .offset(y: 7)
                }
                .position(x: dividerX, y: proxy.size.height / 2)
            }
        }
        .frame(height: 124)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            isEmpty
                ? "作息轨迹，完成睡眠记录后，早睡与熬夜将会分段呈现，让作息变化清晰可见"
                : "作息轨迹，" + segments.map { "\($0.title)\($0.days)天" }.joined(separator: "，")
        )
    }

    private func dateRange(for dates: [Date]) -> String {
        guard let first = dates.first, let last = dates.last else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M.d"
        let firstText = formatter.string(from: first)
        let lastText = formatter.string(from: last)
        return Calendar.current.isDate(first, inSameDayAs: last) ? firstText : "\(firstText)–\(lastText)"
    }

    private func trackingMetric(title: String, value: Int, dateRange: String) -> some View {
        VStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.black)
                .tracking(0)
                .lineLimit(1)
                .frame(height: 20)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("\(value)天")
                .font(.system(size: 24, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color.black)
                .frame(height: 32)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(dateRange)
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color.black.opacity(0.56))
                .lineLimit(1)
                .frame(height: 18)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PlanControlFlowCard: View {
    private let accentColor = Color(red: 0.18, green: 0.48, blue: 0.36)

    var body: some View {
        HStack(spacing: 0) {
            flowText("熬夜魔", weight: .semibold, color: .black)
            Spacer(minLength: 7)
            arrow
            Spacer(minLength: 7)
            flowText("选择早睡", weight: .medium, color: .black)
            Spacer(minLength: 7)
            arrow
            Spacer(minLength: 7)
            flowText("增强掌控力", weight: .medium, color: .black)
            Spacer(minLength: 7)
            arrow
            Spacer(minLength: 7)
            flowText("早睡喵", weight: .semibold, color: accentColor)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(
            Color.white,
            in: RoundedRectangle(cornerRadius: AppTheme.planCardRadius, style: .continuous)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("熬夜魔，选择早睡，增强掌控力，成为早睡喵")
    }

    private func flowText(_ text: String, weight: Font.Weight, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: weight))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.9)
    }

    private var arrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.28))
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
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("最晚入睡时间")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.black)

                    Text(timeText(prototypeBedtimeMinutes))
                        .font(.system(size: 38, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Color.black)
                }

                Spacer()

                Text("目标最晚 \(timeText(targetMinutes))")
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.black.opacity(0.52))
                    .padding(.top, 2)
            }

            VStack(spacing: 8) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Color(red: 0.96, green: 0.71, blue: 0.0)

                        Color(red: 0.65, green: 0.44, blue: 1.0)
                            .frame(width: max(proxy.size.width * actualProgress, 0))

                        HStack {
                            Text(timeText(20 * 60))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Spacer()
                            Text(timeText(targetMinutes))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                        .padding(.horizontal, 14)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(height: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: AppTheme.planCardRadius, style: .continuous))
    }

    private var prototypeBedtimeMinutes: Int {
        bedtimeMinutes ?? 23 * 60
    }

    private var normalizedTargetMinutes: Int {
        targetMinutes <= 20 * 60 ? targetMinutes + 24 * 60 : targetMinutes
    }

    private var normalizedBedtimeMinutes: Int {
        prototypeBedtimeMinutes < 20 * 60 ? prototypeBedtimeMinutes + 24 * 60 : prototypeBedtimeMinutes
    }

    private var actualProgress: CGFloat {
        let total = max(normalizedTargetMinutes - 20 * 60, 1)
        let elapsed = normalizedBedtimeMinutes - 20 * 60
        return min(max(CGFloat(elapsed) / CGFloat(total), 0), 1)
    }

    private func timelineLabel(_ text: String, alignment: Alignment, emphasized: Bool) -> some View {
        Text(text)
            .font(.system(size: 12, weight: emphasized ? .semibold : .medium))
            .monospacedDigit()
            .foregroundStyle(emphasized ? Color.black : Color.black.opacity(0.46))
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    private func timeText(_ minutes: Int) -> String {
        String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60)
    }
}

private struct BedtimeStreakSummaryCard: View {
    let earlyDays: Int
    let lateDays: Int

    var body: some View {
        HStack(spacing: 12) {
            metric(title: "最长连续早睡", value: earlyDays)
            metric(title: "最长连续熬夜", value: lateDays)
        }
    }

    private func metric(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.62))

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text("\(value)")
                    .font(.system(size: 28, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.black)
                Text("天")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.48))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 17)
        .frame(minHeight: 92)
        .background(
            Color.white,
            in: RoundedRectangle(cornerRadius: AppTheme.planCardRadius, style: .continuous)
        )
    }
}

private struct EarlySleepStreakDetailView: View {
    private let recentDays = ["一", "二", "三", "四", "五", "六", "日"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Text("🔥")
                        .font(.system(size: 58))

                    Text("0")
                        .font(.system(size: 52, weight: .bold, design: .rounded))

                    Text("当前连续早睡天数")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)

                HStack(spacing: 12) {
                    streakMetric(title: "历史最长", value: "0 天")
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

struct TodayWorkCardView: View {
    @State private var isShowingControlInfo = false
    @State private var isShowingFactors = false
    @State private var selectedFactors: Set<String> = []

    let planDurationDays: Int
    let maxLateStreak: Int
    let currentDay: Int
    let planStartedAt: Double
    let isShorterPlanActive: Bool

    let textDark = Color.black.opacity(0.88)
    let textGrey = Color.black.opacity(0.48)
    let cardBg = Color.white

    let trackBg = Color.black.opacity(0.12)
    let trackFill = Color.black.opacity(0.82)

    let btnAttackBg = Color.black.opacity(0.88)
    let btnReviewBg = Color.black.opacity(0.08)

    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 2) {
                Text("早睡掌控力")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(textDark)

                Button {
                    isShowingControlInfo = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("了解掌控力")

                Spacer()

                Text("Lv.1")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(textDark)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("早睡掌控力 Lv.1")
            }

            HStack(spacing: 7) {
                ForEach(0..<7, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(index < 1 ? trackFill : trackBg.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .overlay {
                            if index < 1 {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(dateDayNumber(for: index))")
                                    .font(.system(size: 13, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(textGrey)
                            }
                        }
                }
            }

            HStack(alignment: .center, spacing: 20) {
                VStack(spacing: 8) {
                    Image("stay_up_late_demon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)

                    Text("熬夜魔")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(textDark)
                }
                .frame(width: 96)

                VStack(spacing: 12) {
                    NavigationLink {
                        BedtimeDecisionView()
                            .sleepDetailChrome(tabBarVisibility)
                    } label: {
                        Text("熬夜值不值")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(btnAttackBg)
                            .clipShape(Capsule())
                    }

                    if selectedFactors.isEmpty {
                        Button(action: { isShowingFactors = true }) {
                            Text("记录熬夜原因")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textDark)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(btnReviewBg)
                                .clipShape(Capsule())
                        }
                    } else {
                        HStack(spacing: 8) {
                            let tagsToShow = Array(selectedFactors.prefix(2))
                            
                            ForEach(tagsToShow, id: \.self) { factor in
                                Button(action: { isShowingFactors = true }) {
                                    Text(factor)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(textDark)
                                        .padding(.horizontal, 16)
                                        .frame(height: 44)
                                        .background(btnReviewBg)
                                        .cornerRadius(12)
                                }
                            }
                            
                            if selectedFactors.count < 2 {
                                Button(action: { isShowingFactors = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(textDark)
                                        .frame(width: 44, height: 44)
                                        .background(btnReviewBg)
                                        .cornerRadius(12)
                                }
                            }
                            
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(20)
        .background(cardBg, in: RoundedRectangle(cornerRadius: AppTheme.planCardRadius, style: .continuous))
        .alert("什么是早睡掌控力？", isPresented: $isShowingControlInfo) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("当你想熬夜时，主动结束一次熬夜倾向或打断连续熬夜，就会获得1次掌控力。")
        }
        .sheet(isPresented: $isShowingFactors) {
            SleepFactorsSheetView(selectedItems: $selectedFactors)
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func dateDayNumber(for index: Int) -> Int {
        let startDate = planStartedAt > 0 ? Date(timeIntervalSince1970: planStartedAt) : Date()
        let date = Calendar.current.date(byAdding: .day, value: index, to: startDate) ?? startDate
        return Calendar.current.component(.day, from: date)
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



struct ProfileView: View {
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    @AppStorage("appLock.isEnabled") private var isAppLockEnabled = false
    let onPlanStarted: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    NavigationLink {
                        SleepGoalDetailView()
                            .sleepDetailChrome(tabBarVisibility)
                    } label: {
                        ProfileSummaryView()
                    }
                    .buttonStyle(.plain)

                    ProfileSection {
                        NavigationLink {
                            EarlySleepPlanDetailView(onPlanStarted: onPlanStarted)
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "moon.stars", title: "早睡计划", showDivider: true)
                        }
                        .buttonStyle(.plain)

                        emptyProfileNavigationRow(icon: "alarm", title: "闹钟提醒", trailingText: "未开启", showDivider: true)
                        NavigationLink {
                            WidgetGalleryDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "square.grid.2x2", title: "小组件", showDivider: true)
                        }
                        .buttonStyle(.plain)
                        NavigationLink {
                            AppLockDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(
                                icon: "lock",
                                title: "应用锁",
                                trailingText: isAppLockEnabled ? "已开启" : "未开启",
                                showDivider: true
                            )
                        }
                        .buttonStyle(.plain)
                        NavigationLink {
                            CelebrityRoutineListView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "person.crop.circle", title: "名人作息", showDivider: false)
                        }
                        .buttonStyle(.plain)
                    }

                    ProfileSection {
                        NavigationLink {
                            EmotionDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "book.pages", title: "睡眠札记", showDivider: true)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            CalendarDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "calendar", title: "年度日历", showDivider: true)
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            BodyAndSleepDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "heart.text.square", title: "身体与睡眠", showDivider: false)
                        }
                        .buttonStyle(.plain)
                    }



                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsManagementView()
                            .sleepDetailChrome(tabBarVisibility)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func emptyProfileNavigationRow(
        icon: String,
        title: String,
        trailingText: String? = nil,
        showDivider: Bool
    ) -> some View {
        NavigationLink {
            EmptyProfileDetailView()
                .sleepDetailChrome(tabBarVisibility)
        } label: {
            ProfileRowView(icon: icon, title: title, trailingText: trailingText, showDivider: showDivider)
        }
        .buttonStyle(.plain)
    }
}

private struct SleepGoalDetailView: View {
    @AppStorage("sleepGoal.workdaySelection") private var workdaySelection = "2,3,4,5,6"
    @AppStorage("sleepGoal.weekendSelection") private var weekendSelection = "1,7"
    @AppStorage("sleepGoal.workdayBedtime") private var workdayBedtime = 23 * 60
    @AppStorage("sleepGoal.workdayWakeTime") private var workdayWakeTime = 7 * 60
    @AppStorage("sleepGoal.weekendBedtime") private var weekendBedtime = 23 * 60
    @AppStorage("sleepGoal.weekendWakeTime") private var weekendWakeTime = 7 * 60
    @AppStorage("sleepGoal.allowedDeviation") private var allowedDeviation = 0
    @AppStorage("sleepSettings.intervals") private var encodedIntervals = ""
    @State private var editingGroup: SleepGoalGroup?
    @State private var isEditingIntervals = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                SleepGoalDeviationSection(selection: $allowedDeviation)

                SleepGoalCard(
                    title: "工作日",
                    icon: "briefcase.fill",
                    iconColor: Color(red: 0.20, green: 0.47, blue: 0.95),
                    selectedDays: workdayDays,
                    bedtime: minutesBinding(for: $workdayBedtime),
                    wakeTime: minutesBinding(for: $workdayWakeTime),
                    onSelectDays: { editingGroup = .workday }
                )

                SleepGoalCard(
                    title: "周末",
                    icon: "sparkles",
                    iconColor: Color(red: 0.18, green: 0.68, blue: 0.45),
                    selectedDays: weekendDays,
                    bedtime: minutesBinding(for: $weekendBedtime),
                    wakeTime: minutesBinding(for: $weekendWakeTime),
                    onSelectDays: { editingGroup = .weekend }
                )

                SleepIntervalSection(
                    intervals: sleepIntervals,
                    onEdit: { isEditingIntervals = true }
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("睡眠设置")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingGroup) { group in
            weekdaySheet(for: group)
        }
        .sheet(isPresented: $isEditingIntervals) {
            SleepIntervalEditorSheet(intervals: sleepIntervals) { intervals in
                guard let data = try? JSONEncoder().encode(intervals),
                      let value = String(data: data, encoding: .utf8) else { return }
                encodedIntervals = value
            }
        }
    }

    @ViewBuilder
    private func weekdaySheet(for group: SleepGoalGroup) -> some View {
        if group == .workday {
            SleepGoalWeekdaySheet(
                title: "工作日",
                selectedDays: workdayDays,
                onToggleDay: toggleWorkday
            )
        } else {
            SleepGoalWeekdaySheet(
                title: "周末",
                selectedDays: weekendDays,
                onToggleDay: toggleWeekend
            )
        }
    }

    private var workdayDays: Set<Int> {
        decodedDays(workdaySelection)
    }

    private var weekendDays: Set<Int> {
        decodedDays(weekendSelection)
    }

    private var sleepIntervals: [SleepInterval] {
        guard let data = encodedIntervals.data(using: .utf8),
              let intervals = try? JSONDecoder().decode([SleepInterval].self, from: data),
              intervals.count == 5 else {
            return SleepInterval.defaults
        }
        return intervals
    }

    private func toggleWorkday(_ day: Int) {
        var workdays = workdayDays
        var weekends = weekendDays
        if workdays.contains(day) {
            workdays.remove(day)
        } else {
            workdays.insert(day)
            weekends.remove(day)
        }
        workdaySelection = encodedDays(workdays)
        weekendSelection = encodedDays(weekends)
    }

    private func toggleWeekend(_ day: Int) {
        var workdays = workdayDays
        var weekends = weekendDays
        if weekends.contains(day) {
            weekends.remove(day)
        } else {
            weekends.insert(day)
            workdays.remove(day)
        }
        workdaySelection = encodedDays(workdays)
        weekendSelection = encodedDays(weekends)
    }

    private func decodedDays(_ value: String) -> Set<Int> {
        Set(value.split(separator: ",").compactMap { Int($0) })
    }

    private func encodedDays(_ days: Set<Int>) -> String {
        days.sorted().map(String.init).joined(separator: ",")
    }

    private func minutesBinding(for storage: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                let minutes = storage.wrappedValue
                return Calendar.current.date(
                    bySettingHour: minutes / 60,
                    minute: minutes % 60,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                storage.wrappedValue = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }
}

private struct SleepInterval: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var startMinutes: Int
    var endMinutes: Int

    static let defaults = [
        SleepInterval(name: "早睡", startMinutes: 20 * 60, endMinutes: 22 * 60),
        SleepInterval(name: "按时", startMinutes: 22 * 60, endMinutes: 23 * 60 + 30),
        SleepInterval(name: "晚睡", startMinutes: 23 * 60 + 30, endMinutes: 30),
        SleepInterval(name: "熬夜", startMinutes: 30, endMinutes: 2 * 60),
        SleepInterval(name: "修仙", startMinutes: 2 * 60, endMinutes: 6 * 60)
    ]
}

private struct SleepIntervalSection: View {
    let intervals: [SleepInterval]
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onEdit) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("睡眠时段")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)

                        Text("用于统计睡眠分布和看见作息规律")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.leading, 16)

            ForEach(Array(intervals.enumerated()), id: \.element.id) { index, interval in
                HStack(spacing: 12) {
                    Text(interval.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    Text("\(timeText(interval.startMinutes))–\(timeText(interval.endMinutes))")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .frame(height: 54)
                .padding(.horizontal, 16)

                if index < intervals.count - 1 {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func timeText(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

private struct SleepIntervalEditorSheet: View {
    let onSave: ([SleepInterval]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var intervals: [SleepInterval]

    init(intervals: [SleepInterval], onSave: @escaping ([SleepInterval]) -> Void) {
        self.onSave = onSave
        _intervals = State(initialValue: intervals)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach($intervals) { $interval in
                        SleepIntervalEditCard(interval: $interval)
                    }
                }
                .padding(18)
                .padding(.bottom, 24)
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("修改睡眠区间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(intervals)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var canSave: Bool {
        intervals.allSatisfy {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            $0.startMinutes != $0.endMinutes
        } && !hasOverlappingIntervals
    }

    private var hasOverlappingIntervals: Bool {
        let ranges = intervals.map(splitRanges)
        for firstIndex in intervals.indices {
            for secondIndex in intervals.indices where secondIndex > firstIndex {
                if ranges[firstIndex].contains(where: { first in
                    ranges[secondIndex].contains(where: { second in
                        first.lowerBound < second.upperBound && second.lowerBound < first.upperBound
                    })
                }) {
                    return true
                }
            }
        }
        return false
    }

    private func splitRanges(_ interval: SleepInterval) -> [Range<Int>] {
        if interval.endMinutes > interval.startMinutes {
            return [interval.startMinutes..<interval.endMinutes]
        }
        return [interval.startMinutes..<1440, 0..<interval.endMinutes]
    }
}

private struct SleepIntervalEditCard: View {
    @Binding var interval: SleepInterval

    var body: some View {
        HStack(spacing: 8) {
            TextField("区间名称", text: $interval.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 60, alignment: .leading)
            
            Spacer(minLength: 0)
            
            DatePicker("", selection: dateBinding($interval.startMinutes), displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: "zh_CN"))
            
            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
                
            DatePicker("", selection: dateBinding($interval.endMinutes), displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: "zh_CN"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func dateBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: minutes.wrappedValue / 60,
                    minute: minutes.wrappedValue % 60,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                minutes.wrappedValue = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }
}

private struct SleepGoalDeviationSection: View {
    @Binding var selection: Int

    private let options = [0, 5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 14) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color(red: 0.48, green: 0.40, blue: 0.76))
                    .frame(width: 30)

                Text("允许偏差")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Menu {
                    ForEach(options, id: \.self) { minutes in
                        Button {
                            selection = minutes
                        } label: {
                            if selection == minutes {
                                Label("\(minutes) 分钟", systemImage: "checkmark")
                            } else {
                                Text("\(minutes) 分钟")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("\(selection) 分钟")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            .frame(height: 58)
            .padding(.horizontal, 18)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text("系统将结合睡眠目标与允许偏差，判断睡眠记录是否属于晚睡或早起。")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
    }
}

private enum SleepGoalGroup: String, Identifiable {
    case workday
    case weekend

    var id: String { rawValue }
}

private struct SleepGoalCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let selectedDays: Set<Int>
    @Binding var bedtime: Date
    @Binding var wakeTime: Date
    let onSelectDays: () -> Void

    private let days = [
        (id: 2, title: "一"),
        (id: 3, title: "二"),
        (id: 4, title: "三"),
        (id: 5, title: "四"),
        (id: 6, title: "五"),
        (id: 7, title: "六"),
        (id: 1, title: "日")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                Button(action: onSelectDays) {
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(iconColor)
                            .frame(width: 30)

                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)

                        Spacer(minLength: 8)

                        Text(selectedDaysText)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                SleepGoalTimeRow(
                    icon: "moon.fill",
                    iconColor: Color(red: 0.20, green: 0.47, blue: 0.95),
                    title: "目标就寝时间",
                    selection: $bedtime
                )

                SleepGoalTimeRow(
                    icon: "sun.horizon.fill",
                    iconColor: Color(red: 0.96, green: 0.58, blue: 0.18),
                    title: "目标起床时间",
                    selection: $wakeTime
                )

            }
            .padding(.horizontal, 16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var selectedDaysText: String {
        let selected = days.filter { selectedDays.contains($0.id) }
        if selected.map(\.id) == [2, 3, 4, 5, 6] { return "周一至周五" }
        if selected.map(\.id) == [7, 1] { return "周六、周日" }
        if selected.isEmpty { return "未选择日期" }
        return selected.map { "周\($0.title)" }.joined(separator: " ")
    }
}

private struct SleepGoalWeekdaySheet: View {
    let title: String
    let selectedDays: Set<Int>
    let onToggleDay: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    private let days = [
        (id: 2, title: "周一"),
        (id: 3, title: "周二"),
        (id: 4, title: "周三"),
        (id: 5, title: "周四"),
        (id: 6, title: "周五"),
        (id: 7, title: "周六"),
        (id: 1, title: "周日")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    Button {
                        onToggleDay(day.id)
                    } label: {
                        HStack {
                            Text(day.title)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedDays.contains(day.id) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .frame(height: 54)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < days.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 20)
            .background(Color.white)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

private struct SleepGoalTimeRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var selection: Date

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 30)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 8)

            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .tint(AppTheme.accent)
        }
        .frame(height: 58)
    }
}

private struct EmptyProfileDetailView: View {
    var body: some View {
        AppTheme.pageBackground
            .ignoresSafeArea()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AppLockDetailView: View {
    @AppStorage("appLock.isEnabled") private var isEnabled = false
    @State private var authenticationState: AuthenticationState = .requesting

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 34)

            Image(systemName: isEnabled ? "lock.fill" : "lock.open")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(isEnabled ? Color.white : Color.primary)
                .frame(width: 72, height: 72)
                .background(
                    isEnabled ? Color.primary : Color.white,
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )

            Text(isEnabled ? "应用锁已开启" : "使用生物识别保护应用")
                .font(.system(size: 21, weight: .semibold))
                .padding(.top, 20)

            Text(statusText)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 8)

            if authenticationState == .failed || authenticationState == .unavailable {
                Button("重新验证") {
                    authenticate()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(height: 42)
                .padding(.horizontal, 28)
                .background(Color.primary, in: Capsule())
                .padding(.top, 24)
            }

            Spacer()

            if isEnabled {
                Button("关闭应用锁") {
                    isEnabled = false
                    authenticationState = .idle
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.red)
                .padding(.bottom, 28)
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("应用锁")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !isEnabled else {
                authenticationState = .authenticated
                return
            }
            authenticate()
        }
    }

    private var statusText: String {
        switch authenticationState {
        case .requesting:
            return "正在请求 Face ID 或 Touch ID 验证"
        case .authenticated:
            return "再次打开应用时，将通过 Face ID 或 Touch ID 验证身份"
        case .failed:
            return "验证未完成，应用锁尚未开启"
        case .unavailable:
            return "当前设备无法使用 Face ID 或 Touch ID"
        case .idle:
            return "开启后，再次打开应用需要验证身份"
        }
    }

    private func authenticate() {
        authenticationState = .requesting
        let context = LAContext()
        context.localizedCancelTitle = "取消"
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authenticationState = .unavailable
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "验证身份以开启应用锁"
        ) { success, _ in
            DispatchQueue.main.async {
                isEnabled = success
                authenticationState = success ? .authenticated : .failed
            }
        }
    }

    private enum AuthenticationState {
        case idle
        case requesting
        case authenticated
        case failed
        case unavailable
    }
}

private struct WidgetGalleryDetailView: View {
    @AppStorage("widget.sleepCheckIn.completed") private var isSleepCheckedIn = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let progress = WidgetTimeProgress(date: context.date)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Label("小尺寸", systemImage: "square")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(.primary)

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                        WidgetProgressCard(
                            title: progress.dateTitle,
                            percentage: progress.dayPercentage,
                            remainingText: progress.remainingHoursText,
                            columns: 6,
                            rows: 4,
                            progress: progress.dayProgress
                        )

                        WidgetProgressCard(
                            title: progress.timeTitle,
                            percentage: progress.minutePercentage,
                            remainingText: progress.remainingMinutesText,
                            columns: 10,
                            rows: 6,
                            progress: progress.minuteProgress
                        )

                        SleepCheckInWidgetCard(
                            date: context.date,
                            isCheckedIn: $isSleepCheckedIn
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("小组件")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SleepCheckInWidgetCard: View {
    let date: Date
    @Binding var isCheckedIn: Bool

    var body: some View {
        WidgetSquareCard {
            VStack(alignment: .center, spacing: 0) {
                Text("入睡时间")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 10)

                Text(timeText)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 10)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCheckedIn.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
                } label: {
                    Text(isCheckedIn ? "已打卡" : "晚安打卡")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isCheckedIn ? Color.secondary : Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            isCheckedIn ? Color(uiColor: .systemGray5) : Color.primary,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var timeText: String {
        let calendar = Calendar.current
        return String(
            format: "%02d:%02d",
            calendar.component(.hour, from: date),
            calendar.component(.minute, from: date)
        )
    }
}

private struct WidgetProgressCard: View {
    let title: String
    let percentage: Int
    let remainingText: String
    let columns: Int
    let rows: Int
    let progress: Double

    var body: some View {
        WidgetSquareCard {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                    Spacer()
                    Text("\(percentage)%")
                }
                .font(.system(size: 16, weight: .semibold))

                Spacer(minLength: 16)

                WidgetDotGrid(columns: columns, rows: rows, progress: progress)

                Spacer(minLength: 16)

                Text(remainingText)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct WidgetSquareCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                content
                    .padding(18)
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct WidgetDotGrid: View {
    let columns: Int
    let rows: Int
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            let horizontalSpacing = columns > 1 ? (geometry.size.width - CGFloat(columns * 7)) / CGFloat(columns - 1) : 0
            let verticalSpacing = rows > 1 ? (geometry.size.height - CGFloat(rows * 7)) / CGFloat(rows - 1) : 0
            let total = columns * rows
            let filled = progress * Double(total)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(7), spacing: horizontalSpacing), count: columns),
                spacing: verticalSpacing
            ) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(dotColor(at: index, filled: filled))
                        .frame(width: 7, height: 7)
                }
            }
        }
        .frame(height: rows == 4 ? 54 : 66)
    }

    private func dotColor(at index: Int, filled: Double) -> Color {
        if Double(index + 1) <= filled {
            return .primary
        }
        if Double(index) < filled {
            return Color(uiColor: .systemGray2)
        }
        return Color(uiColor: .systemGray5)
    }
}

private struct WidgetTimeProgress {
    let date: Date
    private let calendar = Calendar.current

    private var minutesElapsed: Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    var dayProgress: Double { Double(minutesElapsed) / 1_440 }
    var minuteProgress: Double { Double(calendar.component(.second, from: date)) / 60 }
    var dayPercentage: Int { Int(dayProgress * 100) }
    var minutePercentage: Int { Int(minuteProgress * 100) }
    var remainingHoursText: String { "还剩 \((1_440 - minutesElapsed + 59) / 60) 小时" }
    var remainingMinutesText: String { "还剩 \(60 - calendar.component(.second, from: date)) 分钟" }

    var dateTitle: String {
        "\(calendar.component(.month, from: date))月\(calendar.component(.day, from: date))日"
    }

    var timeTitle: String {
        String(format: "%02d:%02d", calendar.component(.hour, from: date), calendar.component(.minute, from: date))
    }
}

private struct EarlySleepPlanDetailView: View {
    @AppStorage("shorterPlan.isActive") private var isActive = false
    @AppStorage("shorterPlan.durationDays") private var durationDays = 7
    @AppStorage("shorterPlan.maxLateStreak") private var maxLateStreak = 2
    @AppStorage("shorterPlan.targetSleepTimeMinutes") private var targetSleepTimeMinutes = 23 * 60 + 30
    @AppStorage("shorterPlan.startedAt") private var startedAt = 0.0
    @AppStorage("earlySleepPlan.history") private var historyData = "[]"
    @AppStorage("earlySleepPlan.activeType") private var activePlanType = "shorter"
    @AppStorage("earlySleepPlan.activeName") private var activePlanName = "连续熬夜越来越短"
    @AppStorage("earlySleepPlan.targetStreak") private var targetEarlySleepStreak = 5
    @AppStorage("sleepGoal.workdaySelection") private var workdaySelection = "2,3,4,5,6"
    @AppStorage("sleepGoal.workdayBedtime") private var workdayBedtime = 23 * 60
    @AppStorage("sleepGoal.weekendBedtime") private var weekendBedtime = 23 * 60
    @AppStorage("sleepGoal.allowedDeviation") private var allowedDeviation = 0

    @State private var isShowingPlanPicker = false
    @State private var isShowingShorterSetup = false
    @State private var isShowingStreakSetup = false

    let onPlanStarted: () -> Void

    private var currentPlanHasEnded: Bool {
        guard isActive, startedAt > 0 else { return false }
        let endDate = Calendar.current.date(
            byAdding: .day,
            value: durationDays,
            to: Date(timeIntervalSince1970: startedAt)
        ) ?? .distantFuture
        return Date() >= endDate
    }

    private var history: [EarlySleepPlanRecord] {
        guard let data = historyData.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([EarlySleepPlanRecord].self, from: data)) ?? []
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 14) {
                Button {
                    isShowingPlanPicker = true
                } label: {
                    Label("创建早睡计划", systemImage: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                        .padding(.horizontal, 20)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                if isActive && !currentPlanHasEnded {
                    planSectionTitle("进行中")
                    EarlySleepPlanRecordCard(
                        record: currentRecord,
                        status: "进行中",
                        currentDay: currentPlanDay,
                        title: activePlanName,
                        objective: currentObjective
                    )
                }

                let endedPlans = displayedHistory
                if !endedPlans.isEmpty {
                    planSectionTitle("历史计划")
                    ForEach(endedPlans) { record in
                        EarlySleepPlanRecordCard(record: record, status: "已结束", currentDay: nil)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("早睡计划")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $isShowingShorterSetup) {
            ShorterLateNightPlanSetupView(onPlanStarted: onPlanStarted)
        }
        .navigationDestination(isPresented: $isShowingStreakSetup) {
            EarlySleepStreakPlanSetupView(onPlanStarted: onPlanStarted)
        }
        .sheet(isPresented: $isShowingPlanPicker) {
            EarlySleepPlanPicker { plan in
                isShowingPlanPicker = false
                DispatchQueue.main.async {
                    if plan.title == "最长连续早睡" {
                        isShowingStreakSetup = true
                    } else if plan.title == "最晚入睡时间" {
                        isShowingShorterSetup = true
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var currentRecord: EarlySleepPlanRecord {
        EarlySleepPlanRecord(
            id: "current-\(startedAt)",
            durationDays: durationDays,
            maxLateStreak: maxLateStreak,
            startedAt: startedAt,
            targetSleepTimeMinutes: targetSleepTimeMinutes
        )
    }

    private var currentObjective: String {
        if activePlanType == "streak" {
            return "在 \(durationDays) 天内，最长连续早睡达到 \(targetEarlySleepStreak) 天 · \(bedtimeText) 前入睡"
        }
        return "目标最晚入睡时间 \(String(format: "%02d:%02d", targetSleepTimeMinutes / 60, targetSleepTimeMinutes % 60))"
    }

    private var bedtimeText: String {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let workdays = Set(workdaySelection.split(separator: ",").compactMap { Int($0) })
        let target = workdays.contains(weekday) ? workdayBedtime : weekendBedtime
        let boundary = (target + allowedDeviation) % (24 * 60)
        return String(format: "%02d:%02d", boundary / 60, boundary % 60)
    }

    private var currentPlanDay: Int {
        let elapsed = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date(timeIntervalSince1970: startedAt)),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0
        return min(max(elapsed + 1, 1), durationDays)
    }

    private var displayedHistory: [EarlySleepPlanRecord] {
        var records = history
        if isActive && currentPlanHasEnded {
            records.insert(currentRecord, at: 0)
        }
        return records
    }

    private func planSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 8)
            .padding(.horizontal, 2)
    }
}

private struct EarlySleepPlanPicker: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (EarlySleepPlan) -> Void

    private let plans = EarlySleepPlan.availablePlans

    var body: some View {
        NavigationStack {
            List(plans) { plan in
                Button {
                    onSelect(plan)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(plan.color)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        if !plan.isAvailable {
                            Text("稍后开放")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!plan.isAvailable)
            }
            .listStyle(.plain)
            .navigationTitle("选择数据指标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

private struct EarlySleepStreakPlanSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("shorterPlan.isActive") private var isActive = false
    @AppStorage("shorterPlan.durationDays") private var savedDurationDays = 14
    @AppStorage("shorterPlan.startedAt") private var startedAt = 0.0
    @AppStorage("earlySleepPlan.activeType") private var activePlanType = "shorter"
    @AppStorage("earlySleepPlan.activeName") private var activePlanName = "连续熬夜越来越短"
    @AppStorage("earlySleepPlan.targetStreak") private var savedTargetStreak = 5
    @AppStorage("earlySleepPlan.currentStreak") private var currentStreak = 0
    @AppStorage("sleepGoal.workdaySelection") private var workdaySelection = "2,3,4,5,6"
    @AppStorage("sleepGoal.workdayBedtime") private var workdayBedtime = 23 * 60
    @AppStorage("sleepGoal.weekendBedtime") private var weekendBedtime = 23 * 60
    @AppStorage("sleepGoal.allowedDeviation") private var allowedDeviation = 0

    @State private var durationDays = 14
    @State private var targetStreak = 5

    let onPlanStarted: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最长连续早睡")
                        .font(.system(size: 30, weight: .bold))

                }
                .padding(.horizontal, 2)
                .padding(.bottom, 6)

                planSettingCard(
                    title: "计划天数",
                    value: durationDays,
                    range: 3...30
                ) { newValue in
                    durationDays = newValue
                    targetStreak = min(targetStreak, newValue)
                }

                numberSettingCard(
                    title: "目标连续最长早睡天数",
                    value: targetStreak,
                    range: 2...max(durationDays, 2)
                ) { targetStreak = $0 }

            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("创建计划")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: startPlan) {
                Text("开始计划")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(red: 0.65, green: 0.32, blue: 0.32), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 110)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            durationDays = savedDurationDays
            targetStreak = min(max(savedTargetStreak, 2), savedDurationDays)
        }
    }

    private func planSettingCard(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)

            HStack(spacing: 0) {
                let options = [7, 14, 21, 30]
                ForEach(options.indices, id: \.self) { index in
                    let option = options[index]
                    let isSelected = value == option
                    
                    Button {
                        onChange(option)
                    } label: {
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(option)")
                                .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                            Text("天")
                                .font(.system(size: 12, weight: .regular))
                        }
                        .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isSelected ? Color(red: 0.65, green: 0.32, blue: 0.32) : Color.clear)
                    }
                    .buttonStyle(.plain)
                    
                    if index < options.count - 1 {
                        Divider()
                            .background(Color.gray.opacity(0.2))
                    }
                }
            }
            .background(Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func numberSettingCard(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 20, weight: .bold))
                    .monospacedDigit()
                Text("天")
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.trailing, 12)

            HStack(spacing: 0) {
                Button {
                    if value > range.lowerBound { onChange(value - 1) }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 36, height: 32)
                        .contentShape(Rectangle())
                }
                .disabled(value <= range.lowerBound)

                Divider()
                    .frame(height: 16)
                    .background(Color.black.opacity(0.2))

                Button {
                    if value < range.upperBound { onChange(value + 1) }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 36, height: 32)
                        .contentShape(Rectangle())
                }
                .disabled(value >= range.upperBound)
            }
            .background(Color(white: 0.85))
            .clipShape(Capsule())
            .foregroundColor(.black)
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var targetBedtimeMinutes: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let workdays = Set(workdaySelection.split(separator: ",").compactMap { Int($0) })
        return workdays.contains(weekday) ? workdayBedtime : weekendBedtime
    }

    private var targetBedtimeText: String {
        String(format: "%02d:%02d", targetBedtimeMinutes / 60, targetBedtimeMinutes % 60)
    }

    private var bedtimeText: String {
        let boundary = (targetBedtimeMinutes + allowedDeviation) % (24 * 60)
        return String(format: "%02d:%02d", boundary / 60, boundary % 60)
    }

    private func startPlan() {
        savedDurationDays = durationDays
        savedTargetStreak = targetStreak
        currentStreak = 0
        activePlanType = "streak"
        activePlanName = "最长连续早睡"
        startedAt = Date().timeIntervalSince1970
        isActive = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
        dismiss()
        DispatchQueue.main.async {
            onPlanStarted()
        }
    }
}

private struct ShorterLateNightPlanSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("shorterPlan.isActive") private var isActive = false
    @AppStorage("shorterPlan.durationDays") private var savedDurationDays = 7
    @AppStorage("shorterPlan.maxLateStreak") private var savedMaxLateStreak = 2
    @AppStorage("shorterPlan.targetSleepTimeMinutes") private var savedTargetSleepTimeMinutes = 23 * 60 + 30
    @AppStorage("shorterPlan.currentMaxLateStreak") private var currentMaxLateStreak = 0
    @AppStorage("shorterPlan.startedAt") private var startedAt = 0.0
    @AppStorage("earlySleepPlan.history") private var historyData = "[]"
    @AppStorage("earlySleepPlan.activeType") private var activePlanType = "shorter"
    @AppStorage("earlySleepPlan.activeName") private var activePlanName = "连续熬夜越来越短"

    @State private var durationDays = 7
    @State private var maxLateStreak = 2
    @State private var targetSleepTimeMinutes = 23 * 60 + 30

    let onPlanStarted: () -> Void

    private var targetSleepTimeDate: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = targetSleepTimeMinutes / 60
                components.minute = targetSleepTimeMinutes % 60
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                targetSleepTimeMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            }
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最晚入睡时间")
                        .font(.system(size: 30, weight: .bold))

                }
                .padding(.horizontal, 2)
                .padding(.bottom, 6)

                planSettingCard(
                    title: "计划天数",
                    value: durationDays,
                    range: 3...30,
                    onChange: { newValue in
                        durationDays = newValue
                        maxLateStreak = min(maxLateStreak, newValue - 1)
                    }
                )

                timeSettingCard(
                    title: "目标最晚入睡时间",
                    dateBinding: targetSleepTimeDate
                )

            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("创建计划")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: startPlan) {
                Text("开始计划")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(red: 0.65, green: 0.32, blue: 0.32), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 110)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            durationDays = savedDurationDays
            maxLateStreak = min(savedMaxLateStreak, savedDurationDays - 1)
            targetSleepTimeMinutes = savedTargetSleepTimeMinutes
        }
    }

    private func timeSettingCard(
        title: String,
        dateBinding: Binding<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("入睡时间")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)

            HStack(alignment: .center) {
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.primary)

                Spacer()

                DatePicker("", selection: dateBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func planSettingCard(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)

            HStack(spacing: 0) {
                let options = [7, 14, 21, 30]
                ForEach(options.indices, id: \.self) { index in
                    let option = options[index]
                    let isSelected = value == option
                    
                    Button {
                        onChange(option)
                    } label: {
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(option)")
                                .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                            Text("天")
                                .font(.system(size: 12, weight: .regular))
                        }
                        .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isSelected ? Color(red: 0.65, green: 0.32, blue: 0.32) : Color.clear)
                    }
                    .buttonStyle(.plain)
                    
                    if index < options.count - 1 {
                        Divider()
                            .background(Color.gray.opacity(0.2))
                    }
                }
            }
            .background(Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func startPlan() {
        archiveCurrentPlanIfNeeded()
        savedDurationDays = durationDays
        savedMaxLateStreak = maxLateStreak
        savedTargetSleepTimeMinutes = targetSleepTimeMinutes
        currentMaxLateStreak = 0
        activePlanType = "shorter"
        activePlanName = "最晚入睡时间"
        startedAt = Date().timeIntervalSince1970
        isActive = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
        dismiss()
        DispatchQueue.main.async {
            onPlanStarted()
        }
    }

    private func archiveCurrentPlanIfNeeded() {
        guard isActive, startedAt > 0 else { return }
        var history: [EarlySleepPlanRecord] = []
        if let data = historyData.data(using: .utf8) {
            history = (try? JSONDecoder().decode([EarlySleepPlanRecord].self, from: data)) ?? []
        }

        let record = EarlySleepPlanRecord(
            id: "archived-\(startedAt)",
            durationDays: savedDurationDays,
            maxLateStreak: savedMaxLateStreak,
            startedAt: startedAt,
            targetSleepTimeMinutes: savedTargetSleepTimeMinutes
        )
        history.removeAll { $0.startedAt == startedAt }
        history.insert(record, at: 0)

        if let encoded = try? JSONEncoder().encode(history),
           let value = String(data: encoded, encoding: .utf8) {
            historyData = value
        }
    }
}

private struct EarlySleepPlanRecord: Identifiable, Codable {
    let id: String
    let durationDays: Int
    let maxLateStreak: Int
    let startedAt: Double
    var targetSleepTimeMinutes: Int?

    var startDate: Date { Date(timeIntervalSince1970: startedAt) }

    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: durationDays - 1, to: startDate) ?? startDate
    }
}

private struct EarlySleepPlanRecordCard: View {
    let record: EarlySleepPlanRecord
    let status: String
    let currentDay: Int?
    var title = "连续熬夜越来越短"
    var objective: String? = nil

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return "\(formatter.string(from: record.startDate)) - \(formatter.string(from: record.endDate))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Text(status)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(status == "进行中" ? Color.orange : Color.secondary)
            }

            Text(objective ?? (record.targetSleepTimeMinutes != nil ? "目标最晚入睡时间 \(String(format: "%02d:%02d", record.targetSleepTimeMinutes! / 60, record.targetSleepTimeMinutes! % 60))" : "连续熬夜不超过 \(record.maxLateStreak) 天"))
                .font(.system(size: 15))
                .foregroundStyle(.primary)

            HStack {
                if let currentDay {
                    Text("Day \(currentDay) / \(record.durationDays)")
                } else {
                    Text("共 \(record.durationDays) 天")
                }

                Spacer()
                Text(dateText)
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct EarlySleepPlan: Identifiable {
    let title: String
    let subtitle: String
    let color: Color
    var isAvailable = false

    var id: String { title }

    static let availablePlans = [
        EarlySleepPlan(
            title: "最长连续早睡",
            subtitle: "",
            color: Color(red: 0.18, green: 0.48, blue: 0.36),
            isAvailable: true
        ),
        EarlySleepPlan(
            title: "最晚入睡时间",
            subtitle: "",
            color: Color(red: 0.23, green: 0.48, blue: 0.95),
            isAvailable: true
        )
    ]
}

private enum AppTheme {
    static let planCardRadius: CGFloat = 10
    static let homeBackground = Color(
        red: 243.0 / 255.0,
        green: 244.0 / 255.0,
        blue: 246.0 / 255.0
    )
    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let accent = Color(red: 0.16, green: 0.16, blue: 0.18)
}

private struct ProfileCardSurface: ViewModifier {
    private let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

    func body(content: Content) -> some View {
        content
            .background(Color.white, in: shape)
    }
}

private struct ProfileSummaryView: View {
    var body: some View {
        ProfileRowView(icon: "moon.zzz", title: "睡眠设置", showDivider: false)
            .modifier(ProfileCardSurface())
    }
}

private struct ProfileSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .modifier(ProfileCardSurface())
    }
}

struct ProfileRowView: View {
    let icon: String
    let title: String
    var trailingText: String? = nil
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 34, height: 34)

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                if let trailingText = trailingText {
                    Text(trailingText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
            .frame(minHeight: 58)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())

            if showDivider {
                Divider()
                    .padding(.leading, 63)
            }
        }
    }
}

// 专门为标题绘制的波浪线形状
struct WavyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2

        // 既然波浪线只覆盖前 5 个字，波浪周期也相应减少，保持舒缓感
        let cycles: CGFloat = 2.8
        let wavelength = width / cycles

        path.move(to: CGPoint(x: 0, y: midHeight))

        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / wavelength
            // 在 iOS 坐标系中，y 往下是正的。sin() 从 0 开始增加，会向下弯曲，正好契合截图的起始下划轨迹
            let sine = sin(relativeX * .pi * 2)
            let y = midHeight + sine * (height / 2)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

// 计划目标卡片组件
struct TargetCardView: View {
    let title: String
    let value: String
    let unit: String
    let themeColor: Color
    let rotationAngle: Double
    let titleFontSize: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: titleFontSize, weight: .bold))
                .foregroundColor(.primary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.custom("AvenirNext-CondensedBold", size: 36))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(themeColor, lineWidth: 3)
        )
        .rotationEffect(.degrees(rotationAngle))
    }
}

// MARK: - 连续规律记录组件 (横向滚动卡片)
struct HabitStreakView: View {
    let renderForExport: Bool

    init(renderForExport: Bool = false) {
        self.renderForExport = renderForExport
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("连续趋势")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            .padding(.horizontal, 16)

            if renderForExport {
                trendCards(cardWidth: 140)
                    .padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    trendCards(cardWidth: 140)
                    }
                    .padding(.horizontal, 16)
            }
        }
    }

    private func trendCards(cardWidth: CGFloat) -> some View {
        HStack(spacing: 12) {
            HabitCard(
                title: "连续早睡",
                count: "3天",
                dateRange: "8.29 - 8.31",
                isActive: true,
                themeColor: Color(red: 0.95, green: 0.77, blue: 0.2),
                width: cardWidth
            )

            HabitCard(
                title: "连续熬夜",
                count: "2天",
                dateRange: "8.25 - 8.26",
                isActive: false,
                themeColor: Color(red: 0.82, green: 0.95, blue: 0.84),
                width: cardWidth
            )

            if !renderForExport {
                HabitCard(
                    title: "早睡",
                    count: "1天",
                    dateRange: "8.24",
                    isActive: false,
                    themeColor: Color(red: 0.95, green: 0.77, blue: 0.2),
                    width: cardWidth
                )
            }
        }
    }
}

struct HabitCard: View {
    let title: String
    let count: String
    let dateRange: String
    let isActive: Bool
    let themeColor: Color
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 左上角徽章 (全员继承第一张卡片的黑色粗边框+主题色底)
            Text(title)
                .font(.system(size: 15, weight: .heavy))
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 3)
            )

            Spacer()

            // 中间大字：天数
            Text(count)
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(.primary)
                .padding(.bottom, 2)

            // 底部小字：日期段
            Text(dateRange)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(width: width, height: 150, alignment: .topLeading)
        .background(Color.white) // 统一采用干净的纯白底色
        .cornerRadius(24)
    }
}

struct EarlySleepDayGridView: View {
    private let completedDays = 6
    private let totalDays = 21
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let completedColor = Color(red: 0.48, green: 0.68, blue: 0.54)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Day 1")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer(minLength: 8)

                Text("8月26日 - 9月15日")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...totalDays, id: \.self) { day in
                    Group {
                        if day <= completedDays {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .black))
                        } else {
                            Text("\(day)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                    }
                        .foregroundColor(foregroundColor(for: day))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(background(for: day))
                        .overlay {
                            if day == completedDays + 1 {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(completedColor, lineWidth: 1.5)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private func background(for day: Int) -> Color {
        if day <= completedDays {
            return completedColor
        }
        if day == completedDays + 1 {
            return Color(.systemBackground)
        }
        return Color(.secondarySystemBackground)
    }

    private func foregroundColor(for day: Int) -> Color {
        day <= completedDays ? .white : .primary
    }
}

struct DayTimelineCardView: View {
    @State private var selectedDay = 1
    @State private var completedItems: Set<Int> = []

    private let schedule = [
        ("11:00", "刷牙"),
        ("11:15", "放下手机"),
        ("11:30", "上床准备入睡")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Day \(selectedDay)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    ForEach(1...7, id: \.self) { day in
                        Button {
                            selectedDay = day
                        } label: {
                            Text("\(day)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(day == selectedDay ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .background(
                                    day == selectedDay
                                        ? Color(red: 0.48, green: 0.68, blue: 0.54)
                                        : Color(UIColor.secondarySystemBackground)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 20) {
                Text("入睡准备")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(schedule.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                Button {
                                    if completedItems.contains(index) {
                                        completedItems.remove(index)
                                    } else {
                                        completedItems.insert(index)
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(completedItems.contains(index) ? Color(red: 0.48, green: 0.68, blue: 0.54) : Color.clear)
                                        Circle()
                                            .stroke(Color(red: 0.48, green: 0.68, blue: 0.54), lineWidth: 1.5)
                                        if completedItems.contains(index) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .black))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(width: 22, height: 22)
                                }
                                .buttonStyle(.plain)

                                if index < schedule.count - 1 {
                                    Rectangle()
                                        .fill(Color(red: 0.48, green: 0.68, blue: 0.54).opacity(0.28))
                                        .frame(width: 1, height: 32)
                                }
                            }

                            HStack(alignment: .firstTextBaseline, spacing: 14) {
                                Text(item.0)
                                    .font(.system(size: 17, weight: .semibold, design: .default))
                                    .monospacedDigit()
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .frame(width: 56, alignment: .leading)
                                Text(item.1)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Spacer(minLength: 0)
                        }
                        .frame(height: index < schedule.count - 1 ? 54 : 22, alignment: .top)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct SettingsManagementView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProfileSection {
                    NavigationLink {
                        EarlySleepPlan1DetailView()
                    } label: {
                        ProfileRowView(icon: "star", title: "早睡方案1", showDivider: true)
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        EmptyProfileDetailView()
                    } label: {
                        ProfileRowView(icon: "tag", title: "标签管理", showDivider: true)
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        EmptyProfileDetailView()
                    } label: {
                        ProfileRowView(icon: "icloud", title: "iCloud 备份", trailingText: "未备份", showDivider: false)
                    }
                    .buttonStyle(.plain)
                }
                
                ProfileSection {
                    NavigationLink {
                        SleepTrackingDetailView()
                    } label: {
                        ProfileRowView(icon: "chart.xyaxis.line", title: "睡眠追踪", showDivider: false)
                    }
                    .buttonStyle(.plain)
                }
                
                ProfileSection {
                    NavigationLink {
                        EmptyProfileDetailView()
                    } label: {
                        ProfileRowView(icon: "globe", title: "语言", trailingText: "简体中文", showDivider: true)
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        EmptyProfileDetailView()
                    } label: {
                        ProfileRowView(icon: "circle.lefthalf.filled", title: "主题外观", trailingText: "浅色模式", showDivider: false)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}


private struct SleepOnsetRoute: Identifiable, Hashable {
    let date: Date
    var id: Date { date }
}

private struct SleepOnsetEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    var state: HomeSleepState
    var bedtime: String
    var note: String
}

private struct SleepOnsetRecordView: View {
    private enum EditStage {
        case type
        case note
    }

    let date: Date
    let entry: SleepOnsetEntry?
    let onSave: (SleepOnsetEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    @State private var selectedState: HomeSleepState?
    @State private var note = ""
    @State private var isEditing: Bool
    @State private var editStage: EditStage
    @FocusState private var noteIsFocused: Bool

    init(date: Date, entry: SleepOnsetEntry?, onSave: @escaping (SleepOnsetEntry) -> Void) {
        self.date = date
        self.entry = entry
        self.onSave = onSave
        _selectedState = State(initialValue: entry?.state)
        _note = State(initialValue: entry?.note ?? "")
        _isEditing = State(initialValue: entry == nil)
        _editStage = State(initialValue: .type)
    }

    var body: some View {
        Group {
            if isEditing {
                editor
            } else if let entry {
                detail(entry)
            }
        }
        .background(AppTheme.homeBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("编辑") {
                        editStage = .type
                        isEditing = true
                    }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black)
                }
            }
        }
        .sleepDetailChrome(tabBarVisibility)
    }

    private var editor: some View {
        Group {
            switch editStage {
            case .type:
                typePicker
            case .note:
                noteEditor
            }
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("昨晚的入睡情况怎么样？")
                .font(.system(size: 31, weight: .bold))
                .foregroundStyle(Color.black)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(HomeSleepState.allCases) { state in
                    Button {
                        selectedState = state
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            editStage = .note
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            noteIsFocused = true
                        }
                    } label: {
                        Text(state.title)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.78))
                            .frame(width: 126, height: 126)
                            .background(state.selectionColor)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
                                    .padding(5)
                            }
                            .shadow(color: state.color.opacity(0.12), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 30)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 20)
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(notePrompt)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.72))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 30)

            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("开始记录...")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.32))
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $note)
                    .font(.system(size: 20, weight: .regular))
                    .lineSpacing(6)
                    .scrollContentBackground(.hidden)
                    .focused($noteIsFocused)
                    .padding(.horizontal, -5)
                    .background(Color.clear)
            }
            .padding(.top, 18)

            Button(action: save) {
                Text("保存")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(selectedState == nil ? Color.black.opacity(0.22) : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selectedState == nil)
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 20)
    }

    private func detail(_ entry: SleepOnsetEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.state.title)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.black)

                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(dateTitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.black)

                        Text("入睡时间")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.48))

                        Spacer()

                        Text(entry.bedtime)
                            .font(.system(size: 20, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color.black)
                    }
                    .padding(.top, 20)

                    if !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Divider()
                            .padding(.vertical, 24)

                        Text(entry.note)
                            .font(.system(size: 19, weight: .regular))
                            .foregroundStyle(Color.black.opacity(0.84))
                            .lineSpacing(7)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(22)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 18)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    private var recordHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(dateTitle)
                .font(.system(size: 18, weight: .semibold))
            Text("昨晚")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.48))
            Spacer()
            Text("入睡情况")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(Color.black)
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private var notePrompt: String {
        guard let selectedState else {
            return "记录下昨晚入睡时的想法和感受。"
        }
        switch selectedState {
        case .insomnia:
            return "记录下昨晚让你失眠的事情，以及当时的想法和感受。"
        case .allNight:
            return "记录下昨晚通宵时在做什么，以及为什么没有停下来休息。"
        case .midnightWake:
            return "记录下昨晚醒来的时间和身体感受，以及后来有没有再次入睡。"
        case .difficulty:
            return "记录下昨晚睡前的情绪、环境，或者让你迟迟没有睡着的事情。"
        case .poorSleep:
            return "记录下昨晚睡眠中的感受，以及醒来后身体和精神的状态。"
        case .dream:
            return "记录下昨晚梦里的人、事情和情绪，以及醒来后的感受。"
        }
    }

    private func save() {
        guard let selectedState else { return }
        let savedEntry = SleepOnsetEntry(
            id: entry?.id ?? UUID(),
            date: date,
            state: selectedState,
            bedtime: entry?.bedtime ?? "23:30",
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(savedEntry)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}


private struct BedtimeDecisionView: View {
    private enum Step: Int, CaseIterable {
        case activity
        case habit
        case duration
        case control
        case tomorrow
        case choice
        case result
    }

    private enum Choice {
        case sleepNow
        case limitedContinue
        case continueTonight
    }

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .activity
    @State private var activity = ""
    @State private var activityDraft = ""
    @State private var habit = ""
    @State private var duration = ""
    @State private var control = ""
    @State private var tomorrow = ""
    @State private var finalChoice: Choice?
    @FocusState private var activityIsFocused: Bool

    private let background = AppTheme.homeBackground
    private let foreground = Color.black
    private let accent = Color(red: 0.72, green: 0.30, blue: 0.29)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Group {
                    if step == .result {
                        resultView
                    } else {
                        questionView
                    }
                }
                .id(step)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                activityIsFocused = true
            }
        }
    }

    private var topBar: some View {
        HStack {
            if step.rawValue > Step.activity.rawValue && step != .result {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(foreground)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            if step != .result {
                Text("\(step.rawValue + 1) / 6")
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(foreground.opacity(0.42))
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(foreground)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var questionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(question)
                .font(.system(size: 31, weight: .bold))
                .foregroundStyle(foreground)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 72)

            if let supportingText {
                Text(supportingText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(foreground.opacity(0.55))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
            }

            Spacer(minLength: 36)

            optionLayout
                .padding(.bottom, 44)
        }
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var optionLayout: some View {
        let options = currentOptions
        if step == .activity {
            VStack(spacing: 18) {
                TextField("比如刷手机、追剧，或者处理工作", text: $activityDraft, axis: .vertical)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.black)
                    .lineLimit(2...4)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 17)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .focused($activityIsFocused)
                    .submitLabel(.done)
                    .onSubmit(saveActivity)

                Button(action: saveActivity) {
                    Text("继续想一想")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(activityDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.black.opacity(0.16) : accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(activityDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } else if step == .duration {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 18
            ) {
                ForEach(options, id: \.self) { option in
                    circularOption(option)
                }
            }
            .frame(maxWidth: .infinity)
        } else if options.count == 2 {
            HStack(spacing: 26) {
                ForEach(options, id: \.self) { option in
                    circularOption(option)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button {
                        choose(option)
                    } label: {
                        Text(option)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.84))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .frame(minHeight: 58)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func circularOption(_ title: String) -> some View {
        Button {
            choose(title)
        } label: {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(foreground)
                .multilineTextAlignment(.center)
                .frame(width: 136, height: 136)
                .background(accent)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var question: String {
        switch step {
        case .activity: return "今晚熬夜想做什么？"
        case .habit: return "睡前想做的小习惯，今天完成了吗？"
        case .duration: return "\(activity)，你还想继续多久？"
        case .control: return "到了刚才选的时间，你觉得自己能停下来吗？"
        case .tomorrow: return "如果今晚睡晚一点，你觉得明天会怎么样？"
        case .choice: return "想过这些以后，今晚准备怎么安排？"
        case .result: return ""
        }
    }

    private var supportingText: String? {
        switch step {
        case .habit:
            return "先看看今晚想照顾好的事情，有没有已经完成。"
        case .duration:
            return "选一个差不多的时间，给今晚留个容易做到的小约定。"
        case .control:
            return activity.contains("手机")
                ? "想想平时刷手机的情况，按自己的真实感受来选。"
                : "回想一下以前做这件事时，通常能不能按时结束。"
        case .tomorrow:
            return "不用想得太严重，只要回想一下平时睡晚后的状态。"
        case .choice:
            return summary
        default:
            return nil
        }
    }

    private var currentOptions: [String] {
        switch step {
        case .activity: return []
        case .habit: return ["已经完成", "还没有", "今晚没有安排"]
        case .duration: return ["10 分钟", "20 分钟", "30 分钟", "还没想好"]
        case .control: return ["能停下来", "可能停不下来", "通常停不下来"]
        case .tomorrow: return ["早上不太想起床", "白天可能有点困", "注意力不太集中", "应该没太大影响"]
        case .choice: return ["现在去睡", "再待一小会儿", "今晚想继续"]
        case .result: return []
        }
    }

    private var summary: String {
        var parts: [String] = []
        if habit == "还没有" { parts.append("睡前的小习惯还没完成") }
        if control != "能停下来" { parts.append("到时间后可能还想继续") }
        if tomorrow != "应该没太大影响", !tomorrow.isEmpty { parts.append("明天\(tomorrow)") }
        return parts.isEmpty ? "现在已经想得更清楚了，选一个让自己舒服的安排。" : parts.joined(separator: "，") + "。再看看今晚怎么安排更合适。"
    }

    private var resultView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text(resultTitle)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(foreground)
                .lineSpacing(7)

            Text(resultMessage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(foreground.opacity(0.68))
                .lineSpacing(7)
                .padding(.top, 18)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("好的")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(foreground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 44)
        }
        .padding(.horizontal, 30)
    }

    private var resultTitle: String {
        switch finalChoice {
        case .sleepNow: return "那就安心结束今天吧。"
        case .limitedContinue: return "再待一小会儿，也记得回来休息。"
        case .continueTonight: return "今晚想多留一会儿，也照顾好自己。"
        case nil: return "选择已经记下。"
        }
    }

    private var resultMessage: String {
        switch finalChoice {
        case .sleepNow:
            return habit == "还没有"
                ? "先做一个最简单的版本，不必追求完整，然后安心结束今天。"
                : "放下正在做的事，简单洗漱、关灯，让今天停在这里。"
        case .limitedContinue:
            let limit = duration == "还没想好" ? "10 分钟" : duration
            return "可以设置一个 \(limit) 的计时器。响起以后，就给今天一个温柔的结束。"
        case .continueTonight:
            return "给自己留一个最晚休息时间。想停的时候就停，不需要把今晚安排得太满。"
        case nil:
            return ""
        }
    }

    private func choose(_ answer: String) {
        switch step {
        case .activity: activity = answer
        case .habit: habit = answer
        case .duration: duration = answer
        case .control: control = answer
        case .tomorrow: tomorrow = answer
        case .choice:
            switch answer {
            case "现在去睡": finalChoice = .sleepNow
            case "再待一小会儿": finalChoice = .limitedContinue
            default: finalChoice = .continueTonight
            }
        case .result: break
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        advance()
    }

    private func saveActivity() {
        let value = activityDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        activity = value
        activityIsFocused = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        advance()
    }

    private func advance() {
        let next = Step(rawValue: step.rawValue + 1)
        guard let next else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            step = next
        }
    }

    private func goBack() {
        let previous = Step(rawValue: step.rawValue - 1)
        guard let previous else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            step = previous
        }
    }
}

struct StayUpLateReasonView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    
    // Step 1 Multi-selection
    @State private var selectedTags: Set<String> = []
    let tags = [
        "📺 剧太上头了",
        "🎮 连败不甘心/连胜停不下来",
        "📱 漫无目的刷短视频",
        "💻 报复性工作/学习",
        "🤯 心事重重睡不着",
        "🍻 聚会/应酬/夜生活"
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar with Close Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Content Area
                VStack(spacing: 40) {
                    if step == 0 {
                        Text("昨晚是怎么被“熬夜魔”绊住的？")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        // Tag Grid
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                            ForEach(tags, id: \.self) { tag in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    }
                                } label: {
                                    Text(tag)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedTags.contains(tag) ? .white : .black)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedTags.contains(tag) ? Color.black : Color.clear)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedTags.contains(tag) ? Color.clear : Color.black.opacity(0.8), lineWidth: 1.5)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .transition(.opacity)
                        
                    } else if step == 1 {
                        Text("剖析一下，当时最真实的心理状态是什么？")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        VStack(spacing: 16) {
                            stepButton(title: "白天太忙，想找回一点属于自己的时间") { advanceStep() }
                            stepButton(title: "当时完全沉浸进去了，没意识到时间流逝") { advanceStep() }
                            stepButton(title: "情绪不太好，就是不想结束这一天") { advanceStep() }
                            stepButton(title: "客观原因，硬着头皮也得熬") { advanceStep() }
                        }
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                        
                    } else if step == 2 {
                        Text("发现原因就是最大的进步！今晚如果它再来，我们怎么反击？")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .lineSpacing(6)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        VStack(spacing: 16) {
                            stepButton(title: "提前定个“断电”闹钟，响了绝不碰手机") { advanceStep() }
                            stepButton(title: "睡前把最大的诱惑源（手机/平板）放远点") { advanceStep() }
                            stepButton(title: "换个放松方式，今晚睡前改听播客/白噪音") { advanceStep() }
                        }
                        .padding(.horizontal, 30)
                        .transition(.opacity)
                        
                    } else if step == 3 {
                        VStack(spacing: 24) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.black)
                                .transition(.scale.combined(with: .opacity))
                            
                            Text("很好！\n熬夜魔的弱点已记录在案。")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        .padding(.horizontal, 30)
                    }
                }
                
                Spacer()
                
                // Bottom Button Action
                if step == 0 {
                    Button {
                        if !selectedTags.isEmpty {
                            advanceStep()
                        }
                    } label: {
                        Text("下一步")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(selectedTags.isEmpty ? Color.gray : Color.black)
                            .cornerRadius(28)
                            .padding(.horizontal, 30)
                    }
                    .disabled(selectedTags.isEmpty)
                    .padding(.bottom, 40)
                    .transition(.opacity)
                } else if step == 3 {
                    Button {
                        dismiss()
                    } label: {
                        Text("收起档案，今天好好过")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(28)
                            .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 40)
                    .transition(.opacity)
                } else {
                    // Empty space filler to keep the layout consistent for step 1 & 2
                    Color.clear.frame(height: 96)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func stepButton(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.8), lineWidth: 1.5)
                )
        }
    }
    
    private func advanceStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            step += 1
        }
    }
}

struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var habits: [BedtimeHabit]
    
    @State private var name: String = ""
    @State private var hasAlarm: Bool = true
    @State private var alarmTime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
    @State private var repeatDays: Set<Int> = [0, 1, 2, 3, 4, 5, 6] // Default all
    
    let daysOfWeek = ["日", "一", "二", "三", "四", "五", "六"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button("取消") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("新建睡前习惯")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button("保存") {
                            let newHabit = BedtimeHabit(
                                name: name.isEmpty ? "新习惯" : name,
                                hasAlarm: hasAlarm,
                                alarmTime: alarmTime,
                                repeatDays: repeatDays,
                                checkInTime: nil
                            )
                            withAnimation {
                                habits.append(newHabit)
                            }
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            
                            // Name Input
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("习惯名称，如：冥想、拉伸、看书...", text: $name)
                                    .font(.system(size: 20, weight: .medium))
                                    .padding(.vertical, 8)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)
                            
                            // Alarm Section
                            VStack(alignment: .leading, spacing: 16) {
                                Toggle(isOn: $hasAlarm) {
                                    Text("开启提醒")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                .tint(.black)
                                
                                if hasAlarm {
                                    HStack {
                                        Text("时间")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        DatePicker("", selection: $alarmTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Repeat Days Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("重复日期")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                
                                HStack {
                                    ForEach(0..<7, id: \.self) { index in
                                        Button {
                                            if repeatDays.contains(index) {
                                                if repeatDays.count > 1 { // Prevent unselecting all
                                                    repeatDays.remove(index)
                                                }
                                            } else {
                                                repeatDays.insert(index)
                                            }
                                        } label: {
                                            Text(daysOfWeek[index])
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(repeatDays.contains(index) ? .white : .black)
                                                .frame(width: 36, height: 36)
                                                .background(repeatDays.contains(index) ? Color.black : Color.white)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(repeatDays.contains(index) ? Color.clear : Color.black.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct BlankDetailView: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color.black.opacity(0.3))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
