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
            
            BlankPlanView()
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

struct BlankPlanView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("敬请期待")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 预留管理入口
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
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
    @AppStorage("appLock.isEnabled") private var isAppLockEnabled = false

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
                            EarlySleepPlanDetailView()
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
                            CelebrityRoutineView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "person.crop.circle", title: "名人作息", showDivider: true)
                        }
                        .buttonStyle(.plain)
                        NavigationLink {
                            EarlySleepPlan1DetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "star", title: "早睡方案1", showDivider: false)
                        }
                        .buttonStyle(.plain)
                    }

                    ProfileSection {
                        NavigationLink {
                            TimeTravelDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "clock.arrow.circlepath", title: "时间穿梭", showDivider: true)
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            EmotionDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "face.smiling", title: "情绪", showDivider: true)
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
                            SleepTrackingDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "chart.xyaxis.line", title: "睡眠追踪", showDivider: true)
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
                            ProfileRowView(icon: "chart.bar.fill", title: "入睡分布", showDivider: true)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ClockDistributionView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "clock.badge.checkmark", title: "时钟分布", showDivider: false)
                        }
                        .buttonStyle(.plain)
                    }

                    ProfileSection {
                        emptyProfileNavigationRow(icon: "tag", title: "标签管理", showDivider: true)
                        emptyProfileNavigationRow(icon: "icloud", title: "iCloud 备份", trailingText: "未备份", showDivider: false)
                    }

                    ProfileSection {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 预留管理页面入口
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
        SleepInterval(name: "正常入睡", startMinutes: 22 * 60, endMinutes: 23 * 60 + 30),
        SleepInterval(name: "轻度晚睡", startMinutes: 23 * 60 + 30, endMinutes: 30),
        SleepInterval(name: "晚睡", startMinutes: 30, endMinutes: 2 * 60),
        SleepInterval(name: "深夜入睡", startMinutes: 2 * 60, endMinutes: 6 * 60)
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
        VStack(spacing: 12) {
            TextField("区间名称", text: $interval.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                intervalTimeField(title: "开始", minutes: $interval.startMinutes)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                intervalTimeField(title: "结束", minutes: $interval.endMinutes)
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func intervalTimeField(title: String, minutes: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            DatePicker("", selection: dateBinding(minutes), displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: "zh_CN"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    private let plans = [
        EarlySleepPlan(
            title: "循序早睡",
            subtitle: "慢慢提前入睡时间，让身体自然适应新节奏",
            icon: "clock.arrow.circlepath",
            color: Color(red: 0.23, green: 0.48, blue: 0.95)
        ),
        EarlySleepPlan(
            title: "固定作息",
            subtitle: "稳定每天的入睡时间，建立更规律的睡眠习惯",
            icon: "moon.stars.fill",
            color: Color(red: 0.43, green: 0.35, blue: 0.88)
        ),
        EarlySleepPlan(
            title: "睡前放松",
            subtitle: "留出安静的睡前时间，帮助身心平稳入睡",
            icon: "wind",
            color: Color(red: 0.13, green: 0.66, blue: 0.55)
        ),
        EarlySleepPlan(
            title: "连续达成",
            subtitle: "连续达到设定目标，帮助身体逐步适应新的作息",
            icon: "iphone.slash",
            color: Color(red: 0.95, green: 0.48, blue: 0.22)
        )
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(plans) { plan in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
                    } label: {
                        EarlySleepPlanCard(plan: plan)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("早睡计划")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct EarlySleepPlan: Identifiable {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var id: String { title }
}

private struct EarlySleepPlanCard: View {
    let plan: EarlySleepPlan

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: plan.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(plan.color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(plan.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(plan.subtitle)
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
        .padding(.vertical, 17)
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private enum AppTheme {
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

// MARK: - 时钟分布 (Clock Distribution View)
struct ClockDistributionView: View {
    @State private var selectedSector: Int = 0 // 0: 核心高频段 (23:00-00:30), 1: 预备次要段 (22:00-23:00)
    
    private let habits = [
        ("刷牙洗漱", "21次", Color(red: 0.1, green: 0.65, blue: 0.45)),
        ("放下手机", "18次", Color(red: 0.95, green: 0.6, blue: 0.2)),
        ("睡前冥想", "15次", Color(red: 0.4, green: 0.45, blue: 0.9))
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 1. 日期阶段头部
                dateRangeHeader
                
                // 2. 12时辰入睡表盘 (支持点击色块)
                VStack(spacing: 12) {
                    ClockDialCanvas(selectedSector: selectedSector) { tappedSector in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedSector = tappedSector
                        }
                    }
                    .frame(width: 340, height: 340)
                    .padding(.vertical, 4)
                    
                    // 可点击的扇形色块选择按钮图例
                    sectorSelectorButtons
                }
                
                // 3. 最早 / 最晚 入睡时间卡片
                extremeTimesRow
                
                // 4. 睡前准备色块与习惯次数
                preSleepHabitsCard
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea())
        .navigationTitle("时钟分布")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 1. 日期阶段头部
    @ViewBuilder
    private var dateRangeHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("日期阶段")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                Text("8月26日 - 9月15日")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("近 21 天")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.05, green: 0.65, blue: 0.38))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(red: 0.9, green: 0.96, blue: 0.92))
                .cornerRadius(8)
        }
    }
    
    // 2. 可点击扇形色块图例按钮
    @ViewBuilder
    private var sectorSelectorButtons: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedSector = 0
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "10B981"))
                        .frame(width: 10, height: 10)
                    Text("高频核心段 (23:00 - 00:30)")
                        .font(.system(size: 12, weight: selectedSector == 0 ? .bold : .medium))
                        .foregroundColor(selectedSector == 0 ? .primary : Color(uiColor: .secondaryLabel))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedSector == 0 ? Color.white : Color.clear)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(selectedSector == 0 ? 0.04 : 0), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedSector == 0 ? Color(hex: "10B981") : Color.clear, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedSector = 1
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "A7F3D0"))
                        .frame(width: 10, height: 10)
                    Text("预备入睡段 (22:00 - 23:00)")
                        .font(.system(size: 12, weight: selectedSector == 1 ? .bold : .medium))
                        .foregroundColor(selectedSector == 1 ? .primary : Color(uiColor: .secondaryLabel))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedSector == 1 ? Color.white : Color.clear)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(selectedSector == 1 ? 0.04 : 0), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedSector == 1 ? Color(hex: "10B981") : Color.clear, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // 3. 最早 / 最晚 入睡时间区间
    @ViewBuilder
    private var extremeTimesRow: some View {
        HStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最早入睡")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    Text("22:15")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.05, green: 0.65, blue: 0.38))
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最晚入睡")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                    Text("01:20")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.85, green: 0.3, blue: 0.3))
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
    }
    
    // 4. 睡前准备色块与习惯次数
    @ViewBuilder
    private var preSleepHabitsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("睡前准备")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.05, green: 0.65, blue: 0.38))
                    .cornerRadius(8)
                
                Spacer()
                
                Text("习惯完成率")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            
            VStack(spacing: 10) {
                ForEach(habits, id: \.0) { habit in
                    HStack {
                        Circle()
                            .fill(habit.2)
                            .frame(width: 8, height: 8)
                        
                        Text(habit.0)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(habit.1)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

// MARK: - 时钟表盘 Canvas 绘制组件 (支持扇形点击交互)
fileprivate struct ClockDialCanvas: View {
    let selectedSector: Int
    let onTapSector: (Int) -> Void
    
    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let center = CGPoint(x: cx, y: cy)
            
            // 扩大后的表盘整体半径
            let sectorRadius: CGFloat = 135
            
            // 0. 绘制表盘底图背景边框圆圈
            var dialBgPath = Path()
            dialBgPath.addEllipse(in: CGRect(x: cx - sectorRadius, y: cy - sectorRadius, width: sectorRadius * 2, height: sectorRadius * 2))
            ctx.fill(dialBgPath, with: .color(Color(hex: "F3F4F6").opacity(0.6)))
            ctx.stroke(dialBgPath, with: .color(Color(hex: "E5E7EB")), style: StrokeStyle(lineWidth: 1.5))
            
            // 1. 绘制作息时段扇形区域
            drawSectors(ctx: ctx, center: center, radius: sectorRadius)
            
            // 2. 绘制 12 点/时辰刻度线 (刻度线朝向表盘内侧)
            drawTicks(ctx: ctx, center: center, radius: sectorRadius)
            
            // 3. 绘制 12点, 3点, 6点, 9点 内部文字 (完全位于时钟表盘内部)
            drawLabels(ctx: ctx, center: center)
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            let cx: CGFloat = 170
            let cy: CGFloat = 170
            let dx = location.x - cx
            let dy = location.y - cy
            let dist = sqrt(dx*dx + dy*dy)
            
            if dist <= 140 {
                // 计算从12点方向顺时针的角度(0..12h)
                var angle = atan2(dy, dx) + .pi / 2.0
                if angle < 0 { angle += 2.0 * .pi }
                let hour = (angle / (2.0 * .pi)) * 12.0
                
                // 预备段 22:00 - 23:00 (10.0 - 11.0 hour)
                if hour >= 10.0 && hour < 11.0 {
                    onTapSector(1)
                } else if hour >= 11.0 || hour <= 0.5 {
                    // 核心段 23:00 - 00:30 (11.0 - 12.5 hour)
                    onTapSector(0)
                } else {
                    onTapSector(selectedSector == 0 ? 1 : 0)
                }
            } else {
                onTapSector(selectedSector == 0 ? 1 : 0)
            }
        }
    }
    
    private func drawSectors(ctx: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // 次要段 (22:00-23:00, 10点到11点)
        let backStartHour: Double = 10.0
        let backEndHour: Double = 11.0
        // 核心段 (23:00-00:30, 11点到12.5点)
        let frontStartHour: Double = 11.0
        let frontEndHour: Double = 12.5
        
        // 绘制 back sector (#A7F3D0 淡柔绿)
        var backPath = Path()
        backPath.move(to: center)
        let a1 = Angle(radians: (backStartHour / 12.0) * 2.0 * .pi - (.pi / 2.0))
        let a2 = Angle(radians: (backEndHour / 12.0) * 2.0 * .pi - (.pi / 2.0))
        backPath.addArc(center: center, radius: radius, startAngle: a1, endAngle: a2, clockwise: false)
        backPath.closeSubpath()
        ctx.fill(backPath, with: .color(Color(hex: "A7F3D0")))
        
        // 绘制 front sector (#10B981 鲜明翡翠绿)
        var frontPath = Path()
        frontPath.move(to: center)
        let a3 = Angle(radians: (frontStartHour / 12.0) * 2.0 * .pi - (.pi / 2.0))
        let a4 = Angle(radians: (frontEndHour / 12.0) * 2.0 * .pi - (.pi / 2.0))
        frontPath.addArc(center: center, radius: radius, startAngle: a3, endAngle: a4, clockwise: false)
        frontPath.closeSubpath()
        ctx.fill(frontPath, with: .color(Color(hex: "10B981")))
    }
    
    private func drawTicks(ctx: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // 12大刻度 (整点), 48小刻度 (每15分钟)
        for i in 0..<60 {
            let frac = Double(i) / 60.0
            let angle = frac * 2.0 * .pi - (.pi / 2.0)
            let isMajor = (i % 5 == 0) // 整点
            
            let r1: CGFloat = isMajor ? radius - 14 : radius - 8
            let r2: CGFloat = radius
            
            let x1 = center.x + CGFloat(cos(angle)) * r1
            let y1 = center.y + CGFloat(sin(angle)) * r1
            let x2 = center.x + CGFloat(cos(angle)) * r2
            let y2 = center.y + CGFloat(sin(angle)) * r2
            
            var linePath = Path()
            linePath.move(to: CGPoint(x: x1, y: y1))
            linePath.addLine(to: CGPoint(x: x2, y: y2))
            
            let color = isMajor ? Color(hex: "1F1F24") : Color(hex: "A0A0A5")
            let lineWidth: CGFloat = isMajor ? 2.5 : 1.5
            ctx.stroke(linePath, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
    
    private func drawLabels(ctx: GraphicsContext, center: CGPoint) {
        let darkColor = Color(hex: "374151")
        let font = Font.system(size: 14, weight: .bold)
        
        // 放置在时钟表盘内侧 (距离中心 92pt)
        let distance: CGFloat = 92
        
        // 12点 (位于顶侧绿块内，使用白色高亮)
        ctx.draw(Text("12点").font(font).foregroundColor(.white), at: CGPoint(x: center.x, y: center.y - distance), anchor: .center)
        // 3点 (右侧)
        ctx.draw(Text("3点").font(font).foregroundColor(darkColor), at: CGPoint(x: center.x + distance, y: center.y), anchor: .center)
        // 6点 (底侧)
        ctx.draw(Text("6点").font(font).foregroundColor(darkColor), at: CGPoint(x: center.x, y: center.y + distance), anchor: .center)
        // 9点 (左侧)
        ctx.draw(Text("9点").font(font).foregroundColor(darkColor), at: CGPoint(x: center.x - distance, y: center.y), anchor: .center)
    }
}

fileprivate extension Color {
    init(hex string: String) {
        let hex = string.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >>  8) & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}
