//
//  ContentView.swift
//  sleeptime
//

import SwiftUI
import UIKit
import Combine

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @StateObject private var tabBarVisibility = SleepTabBarVisibility()

    var body: some View {
        TabView(selection: $selectedTab) {
            VStack {
                Image(systemName: "moon.stars.fill")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("首页")
                    .font(.title)
                    .padding()
            }
            .tabItem {
                Label("首页", systemImage: "moon.stars.fill")
            }
            .tag(AppTab.home)
            
            SleepProgressView()
            .tabItem {
                Label("计划", systemImage: "star.fill")
            }
            .tag(AppTab.plan)
            
            ProfileView()
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

private struct SleepDetailChromeModifier: ViewModifier {
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

private extension View {
    func sleepDetailChrome(_ tabBarVisibility: SleepTabBarVisibility) -> some View {
        modifier(SleepDetailChromeModifier(tabBarVisibility: tabBarVisibility))
    }
}

private enum AppTab: CaseIterable {
    case home
    case plan
    case profile

    var title: String {
        switch self {
        case .home:
            return "首页"
        case .plan:
            return "计划"
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

struct SleepProgressView: View {
    @State private var exportedPlan: ExportedPlanImage?

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // 标题区 (去掉返回箭头)
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("21天早睡计划")
                                .font(.system(size: 28, weight: .black))
                                .tracking(-0.5) // 字距微调，更紧凑
                                .foregroundColor(.primary)

                            WavyLine()
                                .stroke(Color(red: 0.2, green: 0.75, blue: 0.4), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                                .frame(width: 120, height: 7)
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

                // 入睡分布卡片 (图表样式)
                SleepDistributionCardView()

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
                        Text("21天早睡计划")
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

                SleepDistributionCardView()

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

struct AnnualGoalView: View {
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                BadgeProgressCard()
                    .padding(16)
            }
        }
        .navigationTitle("年度目标")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BadgeProgressCard: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text("勋章进度")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.primary)

                Spacer()

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("29")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.primary)
                    Text("/30")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            .padding(.bottom, 12)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                        .frame(height: 12)

                    Capsule()
                        .fill(Color(red: 0.2, green: 0.75, blue: 0.4))
                        .frame(width: geometry.size.width * (29.0 / 30.0), height: 12)

                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                        Circle()
                            .stroke(Color(red: 0.2, green: 0.75, blue: 0.4), lineWidth: 4)
                            .frame(width: 20, height: 20)
                    }
                    .position(x: geometry.size.width, y: 7.5)
                }
            }
            .frame(height: 24)

            GeometryReader { geometry in
                let stepWidth = geometry.size.width / 5
                ZStack {
                    Text("0").position(x: 0, y: 7)
                    Text("6").position(x: stepWidth, y: 7)
                    Text("12").position(x: stepWidth * 2, y: 7)
                    Text("18").position(x: stepWidth * 3, y: 7)
                    Text("24").position(x: stepWidth * 4, y: 7)
                    Text("30").position(x: stepWidth * 5, y: 7)
                }
                .font(.custom("AvenirNext-Medium", size: 12))
                .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .frame(height: 14)
            .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct ProfileView: View {
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility

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
                        emptyProfileNavigationRow(icon: "calendar", title: "日历", showDivider: true)

                        NavigationLink {
                            SleepTrackingDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "chart.xyaxis.line", title: "睡眠追踪", showDivider: true)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            EmptyProfileDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "moon.stars", title: "早睡计划", showDivider: true)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            AnnualGoalView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "target", title: "年度目标", showDivider: true)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SleepDistributionView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "chart.bar.fill", title: "入睡分布", showDivider: false)
                        }
                        .buttonStyle(.plain)
                    }

                    ProfileSection {
                        emptyProfileNavigationRow(icon: "tag", title: "标签管理", showDivider: true)
                        emptyProfileNavigationRow(icon: "icloud", title: "iCloud 备份", trailingText: "未备份", showDivider: false)
                    }

                    ProfileSection {
                        emptyProfileNavigationRow(icon: "bell", title: "通知", trailingText: "未开启", showDivider: true)
                        emptyProfileNavigationRow(icon: "square.grid.2x2", title: "小组件", showDivider: true)
                        emptyProfileNavigationRow(icon: "globe", title: "语言", trailingText: "简体中文", showDivider: true)
                        emptyProfileNavigationRow(icon: "circle.lefthalf.filled", title: "主题外观", trailingText: "浅色模式", showDivider: false)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
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
    @State private var editingGroup: SleepGoalGroup?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                SleepGoalCard(
                    title: "工作日",
                    selectedDays: workdayDays,
                    bedtime: minutesBinding(for: $workdayBedtime),
                    wakeTime: minutesBinding(for: $workdayWakeTime),
                    onSelectDays: { editingGroup = .workday }
                )

                SleepGoalCard(
                    title: "周末",
                    selectedDays: weekendDays,
                    bedtime: minutesBinding(for: $weekendBedtime),
                    wakeTime: minutesBinding(for: $weekendWakeTime),
                    onSelectDays: { editingGroup = .weekend }
                )

                SleepGoalDeviationSection(selection: $allowedDeviation)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("睡眠目标")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingGroup) { group in
            weekdaySheet(for: group)
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

private struct SleepGoalDeviationSection: View {
    @Binding var selection: Int

    private let options = [0, 5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)

            VStack(spacing: 0) {
                Button(action: onSelectDays) {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 30)

                        Text("星期")
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

private enum AppTheme {
    static let pageBackground = Color(red: 0.97, green: 0.97, blue: 0.98)
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
        ProfileRowView(icon: "moon.zzz", title: "睡眠目标", showDivider: false)
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

// MARK: - 单日打卡记录卡片

struct DayRecordCardView: View {
    var body: some View {
        VStack(spacing: 0) { // 取消全局间距，改用精准控制
            // 头部标题和操作按钮
            HStack {
                Text("第 1 天")
                    .font(.system(size: 17, weight: .bold)) // 字号微调
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 24)
            
            // 四个核心数据指标 (均匀分布)
            HStack {
                MetricColumn(value: "23:30", label: "入睡时间", dotColor: .blue)
                Spacer()
                MetricColumn(value: "07:15", label: "起床时间", dotColor: .purple)
                Spacer()
                MetricColumn(value: "良好", label: "状态", dotColor: .yellow)
                Spacer()
                MetricColumn(value: "看书", label: "11点行为", dotColor: .orange)
            }
            .padding(.bottom, 24)
            
            // 分割线与子标题
            HStack(spacing: 12) {
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor.separator).opacity(0.5))
                
                Text("行为列表")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .frame(height: 1)
                    .foregroundColor(Color(UIColor.separator).opacity(0.5))
            }
            .padding(.bottom, 20)
            
            // 底部列表项：一比一还原“食物列表”那样的结构
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("睡前冥想")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Text("15 分钟")
                        .font(.system(size: 13))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("已完成")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .padding(.horizontal, 16)
    }
}

// 独立的指标列组件，方便复用和对齐
struct MetricColumn: View {
    let value: String
    let label: String
    let dotColor: Color
    
    var body: some View {
        VStack(spacing: 6) { // 收紧上下间距
            Text(value)
                .font(.system(size: 20, weight: .semibold)) // 调整为半粗体，显得更干净
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 5, height: 5) // 极小号的纯色圆点
                
                Text(label)
                    .font(.system(size: 11, weight: .medium)) // 辅助文字做得非常小且淡
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
    }
}

// 用于绘制横向虚线的 Shape
struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// MARK: - 连续规律记录组件 (横向滚动卡片)

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
                Text("21天早睡计划")
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

// MARK: - 睡眠分布统计页面 (横向条形图)
struct SleepDistributionView: View {
    // 模拟数据：分别对应 提前, 早睡, 拖延, 熬夜, 通宵 的天数
    let distribution = [8, 3, 5, 2, 0]
    let maxCount = 8
    
    // 配置：标签, 颜色
    let categories = [
        ("提前", Color(red: 0.2, green: 0.8, blue: 0.6)), // 健康绿
        ("早睡", Color.primary), // 达成目标的黑色实心
        ("拖延", Color.orange), // 警告橙
        ("熬夜", Color(red: 0.98, green: 0.45, blue: 0.52)), // 严重粉红
        ("通宵", Color.purple) // 危险紫
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // 标题区
                VStack(alignment: .leading, spacing: 8) {
                    Text("你的入睡分布")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.primary)
                    
                    Text("最近 21 天的数据统计。好的坏的，都在这里。")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineSpacing(6)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // 横向条形图区
                VStack(spacing: 24) {
                    ForEach(0..<categories.count, id: \.self) { index in
                        let category = categories[index]
                        let count = distribution[index]
                        let widthPercent = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                        
                        HStack(spacing: 16) {
                            Text(category.0)
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.primary)
                                .frame(width: 44, alignment: .leading)
                            
                            // 进度条
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    // 背景槽 (极简风，浅灰色)
                                    Capsule()
                                        .fill(Color(UIColor.tertiaryLabel).opacity(0.15))
                                    
                                    // 实际数据条
                                    if count > 0 {
                                        Capsule()
                                            .fill(category.1)
                                            // 最小宽度限制，确保数值极小时也能显示一个圆角点
                                            .frame(width: max(geo.size.width * widthPercent, 16))
                                    }
                                }
                            }
                            .frame(height: 24)
                            
                            Text("\(count)天")
                                .font(.custom("AvenirNext-Bold", size: 18))
                                .foregroundColor(count > 0 ? .primary : Color(UIColor.tertiaryLabel))
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea())
        .navigationTitle("入睡分布")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 入睡分布卡片 (图表样式)
struct SleepDistributionCardView: View {
    // 模拟数据：最近 21 天的数据统计
    let distribution = [8, 3, 5, 2, 0]
    let maxCount = 8 // 用于计算进度条比例
    
    // 配置：标签, 时间区间, 颜色
    let categories = [
        ("提前", "23:00 前", Color(red: 0.2, green: 0.8, blue: 0.6)), // 健康绿
        ("早睡", "23:00-00:00", Color.primary), // 达成目标的黑色实心
        ("拖延", "00:00-01:00", Color.orange), // 警告橙
        ("熬夜", "01:00-02:00", Color(red: 0.98, green: 0.45, blue: 0.52)), // 严重粉红
        ("通宵", "02:00 后", Color.purple) // 危险紫
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("入睡分布")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            .padding(.horizontal, 16)
            
            // 连续进度条图表区 (包裹在白色卡片内部)
            VStack(spacing: 16) {
                ForEach(0..<categories.count, id: \.self) { index in
                    let category = categories[index]
                    let count = distribution[index]
                    let widthPercent = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                    
                    if count > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            // 文本行：左侧是 "标签 · 时间"，右侧是 "天数"
                            HStack(alignment: .bottom) {
                                HStack(spacing: 6) {
                                    Text(category.0)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text(category.1)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Text("\(count)天")
                                    .font(.custom("AvenirNext-DemiBold", size: 15))
                                    .foregroundColor(.primary)
                            }
                            
                            // 进度条行
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    // 背景槽 (浅灰色)
                                    Capsule()
                                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                                    
                                    // 实际数据条
                                    if count > 0 {
                                        Capsule()
                                            .fill(category.2)
                                            .frame(width: max(geo.size.width * widthPercent, 8))
                                    }
                                }
                            }
                            .frame(height: 8) // 图表更加纤细精致
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(UIColor.secondarySystemGroupedBackground)) // 白色卡片
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }
}
