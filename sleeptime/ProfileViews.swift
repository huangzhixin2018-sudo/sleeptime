import SwiftUI
import UIKit
import LocalAuthentication

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

                        NavigationLink {
                            AlarmDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "alarm", title: "闹钟与事件", trailingText: "2", showDivider: true)
                        }
                        .buttonStyle(.plain)
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
                            CalendarDetailView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "calendar", title: "年度日历", showDivider: true)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            HolidayListView()
                                .sleepDetailChrome(tabBarVisibility)
                        } label: {
                            ProfileRowView(icon: "suitcase", title: "法定节假日", showDivider: true)
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

struct EmptyProfileDetailView: View {
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
    @AppStorage("earlySleepPlan.activeType") private var activePlanType = "fish"
    @AppStorage("earlySleepPlan.activeName") private var activePlanName = "养鱼计划"
    @AppStorage("earlySleepPlan.targetStreak") private var targetEarlySleepStreak = 5
    @AppStorage("earlySleepPlan.metricType") private var metricType = PlanMetric.earlySleepDays.rawValue
    @AppStorage("earlySleepPlan.metricTargetDays") private var metricTargetDays = 3
    @AppStorage("sleepGoal.workdaySelection") private var workdaySelection = "2,3,4,5,6"
    @AppStorage("sleepGoal.workdayBedtime") private var workdayBedtime = 23 * 60
    @AppStorage("sleepGoal.weekendBedtime") private var weekendBedtime = 23 * 60
    @AppStorage("sleepGoal.allowedDeviation") private var allowedDeviation = 0

    @State private var isShowingFishSetup = false

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
                    isShowingFishSetup = true
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
        .fullScreenCover(isPresented: $isShowingFishSetup) {
            EarlySleepFishPlanSetupView(onPlanStarted: onPlanStarted)
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
        "共 5 项计划目标"
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
                    Text("不养鱼计划")
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
        activePlanName = "不养鱼计划"
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
            title: "不养鱼计划",
            subtitle: "",
            color: Color(red: 0.18, green: 0.48, blue: 0.36),
            isAvailable: true
        ),
        EarlySleepPlan(
            title: "养鱼计划",
            subtitle: "",
            color: Color(red: 0.2, green: 0.6, blue: 0.6),
            isAvailable: true
        )
    ]
}

enum AppTheme {
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

struct ProfileSection<Content: View>: View {
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
