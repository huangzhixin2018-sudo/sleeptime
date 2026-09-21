import SwiftUI
import UIKit

struct EarlySleepFishPlanSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("shorterPlan.isActive") private var isActive = false
    @AppStorage("shorterPlan.startedAt") private var startedAt = 0.0
    @AppStorage("shorterPlan.durationDays") private var savedDurationDays = 14
    @AppStorage("shorterPlan.targetSleepTimeMinutes") private var savedTargetSleepTimeMinutes = 26 * 60
    @AppStorage("shorterPlan.maxLateStreak") private var savedMaxLateStreak = 3
    @AppStorage("earlySleepPlan.activeType") private var activePlanType = "fish"
    @AppStorage("earlySleepPlan.activeName") private var activePlanName = "养鱼计划"
    @AppStorage("earlySleepPlan.metricType") private var savedMetricType = PlanMetric.earlySleepDays.rawValue
    @AppStorage("earlySleepPlan.metricTargetDays") private var savedMetricTargetDays = 3
    @AppStorage("earlySleepPlan.earlySleepTargetDays") private var savedEarlySleepTargetDays = 2
    @AppStorage("earlySleepPlan.bedtimeTargetDays") private var savedBedtimeTargetDays = 1
    @AppStorage("earlySleepPlan.longestEarlySleepTargetDays") private var savedLongestEarlySleepTargetDays = 5
    @AppStorage("earlySleepPlan.currentStreak") private var currentEarlySleepStreak = 0
    @AppStorage("shorterPlan.currentMaxLateStreak") private var currentMaxLateStreak = 0

    @State private var durationDays = 14
    @State private var earlySleepTargetDays = 2
    @State private var bedtimeTargetDays = 1
    @State private var maxLateTargetDays = 3
    @State private var latestBedtimeMinutes = 26 * 60
    @State private var longestEarlySleepTargetDays = 5

    let onPlanStarted: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    durationSection
                    metricSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("创建早睡计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
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
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .onAppear(perform: loadSavedValues)
        }
    }

    private var durationSection: some View {
        settingSection(title: "计划周期") {
            HStack(spacing: 0) {
                ForEach([7, 14, 21, 30], id: \.self) { days in
                    Button {
                        durationDays = days
                        earlySleepTargetDays = min(earlySleepTargetDays, days)
                        bedtimeTargetDays = min(bedtimeTargetDays, days)
                        maxLateTargetDays = min(maxLateTargetDays, days)
                        longestEarlySleepTargetDays = min(longestEarlySleepTargetDays, days)
                    } label: {
                        Text("\(days) 天")
                            .font(.system(size: 15, weight: durationDays == days ? .semibold : .regular))
                            .foregroundStyle(durationDays == days ? .white : .primary)
                            .frame(maxWidth: .infinity).frame(height: 42)
                            .background(durationDays == days ? Color(red: 0.65, green: 0.32, blue: 0.32) : .clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
    }

    private var metricSection: some View {
        settingSection(title: "计划目标") {
            VStack(spacing: 0) {
                ForEach(PlanMetric.allCases) { item in
                    VStack(spacing: 0) {
                        HStack {
                            Text(item.title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(metricValueText(for: item))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .frame(height: 48)

                        metricControl(for: item)
                            .padding(.bottom, 18)
                    }
                    if item != PlanMetric.allCases.last { Divider() }
                }
            }
        }
    }

    @ViewBuilder
    private func metricControl(for item: PlanMetric) -> some View {
        switch item {
        case .earlySleepDays:
            daySlider(value: $earlySleepTargetDays)
        case .bedtimeDays:
            daySlider(value: $bedtimeTargetDays)
        case .maxLateStreak:
            daySlider(value: $maxLateTargetDays)
        case .latestBedtime:
            Slider(
                value: Binding(
                    get: { Double(latestBedtimeMinutes) },
                    set: { latestBedtimeMinutes = Int($0) }
                ),
                in: Double(20 * 60)...Double(27 * 60),
                step: 15
            )
            .tint(Color(red: 0.65, green: 0.32, blue: 0.32))
        case .longestEarlySleepStreak:
            daySlider(value: $longestEarlySleepTargetDays)
        }
    }

    private func daySlider(value: Binding<Int>) -> some View {
        Slider(
            value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0.rounded()) }
            ),
            in: 1...Double(durationDays),
            step: 1
        )
        .tint(Color(red: 0.65, green: 0.32, blue: 0.32))
    }

    private func metricValueText(for item: PlanMetric) -> String {
        switch item {
        case .earlySleepDays:
            return "\(earlySleepTargetDays) 天"
        case .bedtimeDays:
            return "\(bedtimeTargetDays) 天"
        case .maxLateStreak:
            return "\(maxLateTargetDays) 天"
        case .latestBedtime:
            return displayTimeText
        case .longestEarlySleepStreak:
            return "\(longestEarlySleepTargetDays) 天"
        }
    }

    private func settingSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.system(size: 16, weight: .bold))
            content()
        }
    }

    private var displayTimeText: String {
        let normalizedMinutes = latestBedtimeMinutes % (24 * 60)
        return String(format: "%02d:%02d", normalizedMinutes / 60, normalizedMinutes % 60)
    }

    private func loadSavedValues() {
        durationDays = savedDurationDays
        earlySleepTargetDays = min(2, durationDays)
        bedtimeTargetDays = 1
        maxLateTargetDays = min(3, durationDays)
        latestBedtimeMinutes = 26 * 60
        longestEarlySleepTargetDays = min(5, durationDays)
    }

    private func startPlan() {
        savedDurationDays = durationDays
        savedMetricType = PlanMetric.earlySleepDays.rawValue
        savedMetricTargetDays = earlySleepTargetDays
        savedEarlySleepTargetDays = earlySleepTargetDays
        savedBedtimeTargetDays = bedtimeTargetDays
        savedMaxLateStreak = maxLateTargetDays
        savedTargetSleepTimeMinutes = latestBedtimeMinutes % (24 * 60)
        savedLongestEarlySleepTargetDays = longestEarlySleepTargetDays
        currentEarlySleepStreak = 0
        currentMaxLateStreak = 0
        activePlanType = "fish"
        activePlanName = "养鱼计划"
        startedAt = Date().timeIntervalSince1970
        isActive = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
        dismiss()
        DispatchQueue.main.async { onPlanStarted() }
    }
}

enum PlanMetric: String, CaseIterable, Identifiable {
    case earlySleepDays, bedtimeDays, maxLateStreak, latestBedtime, longestEarlySleepStreak
    var id: String { rawValue }
    var title: String {
        switch self {
        case .earlySleepDays: return "早睡天数"
        case .bedtimeDays: return "11点入睡"
        case .maxLateStreak: return "最长连续熬夜不超过"
        case .latestBedtime: return "最晚入睡时间不超过"
        case .longestEarlySleepStreak: return "最长连续早睡天数"
        }
    }
}
