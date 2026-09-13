import SwiftUI

struct MockSleepData: Identifiable {
    let id = UUID()
    let day: String
    let weekday: String
    let bedtime: String
    let sleepStatus: String
    let isLate: Bool
    let wakeTime: String
    let duration: String
    let feeling: String
    let reason: String
    let note: String?
}

enum StatsTab: String, CaseIterable {
    case day = "日"
    case week = "周"
    case month = "月"
    case year = "年"
    case total = "总"
}

struct StatisticsView: View {
    private let pageBackground = Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    private let ink = Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
    
    @State private var selectedTab: StatsTab = .day
    
    let mockData = [
        MockSleepData(day: "09日", weekday: "星期三", bedtime: "23:15", sleepStatus: "早睡", isLate: false, wakeTime: "07:00", duration: "7h45m", feeling: "精神很好", reason: "看书", note: nil),
        MockSleepData(day: "08日", weekday: "星期二", bedtime: "01:30", sleepStatus: "熬夜", isLate: true, wakeTime: "09:00", duration: "7h30m", feeling: "有点困", reason: "玩游戏", note: "昨晚一直失眠没睡好，脑子里全在想白天的工作。"),
        MockSleepData(day: "07日", weekday: "星期一", bedtime: "00:15", sleepStatus: "熬夜", isLate: true, wakeTime: "08:00", duration: "7h45m", feeling: "一般", reason: "加班", note: nil),
        MockSleepData(day: "06日", weekday: "星期日", bedtime: "22:30", sleepStatus: "早睡", isLate: false, wakeTime: "06:30", duration: "8h00m", feeling: "元气满满", reason: "无", note: "睡得特别香，没做梦。"),
        MockSleepData(day: "05日", weekday: "星期六", bedtime: "02:00", sleepStatus: "熬夜", isLate: true, wakeTime: "10:30", duration: "8h30m", feeling: "睡不醒", reason: "聚会", note: nil),
        MockSleepData(day: "04日", weekday: "星期五", bedtime: "23:45", sleepStatus: "早睡", isLate: false, wakeTime: "07:30", duration: "7h45m", feeling: "精神很好", reason: "无", note: nil),
        MockSleepData(day: "03日", weekday: "星期四", bedtime: "00:45", sleepStatus: "熬夜", isLate: true, wakeTime: "08:15", duration: "7h30m", feeling: "有点困", reason: "刷视频", note: "不小心刷短视频停不下来，以后要把手机放远点。"),
        MockSleepData(day: "02日", weekday: "星期三", bedtime: "23:00", sleepStatus: "早睡", isLate: false, wakeTime: "07:00", duration: "8h00m", feeling: "很棒", reason: "无", note: nil),
        MockSleepData(day: "01日", weekday: "星期二", bedtime: "23:30", sleepStatus: "早睡", isLate: false, wakeTime: "07:15", duration: "7h45m", feeling: "不错", reason: "看电影", note: nil)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 自定义分段控制器
                    HStack(spacing: 0) {
                        ForEach(StatsTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? ink : ink.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selectedTab == tab ? Color.white : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(4)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.top, 16)
                    
                    // 数据列表内容
                    if selectedTab == .day {
                        ForEach(Array(mockData.enumerated()), id: \.element.id) { index, data in
                            DailySleepRow(
                                dayMonth: data.day,
                                weekday: data.weekday,
                                bedtime: data.bedtime,
                                sleepStatus: data.sleepStatus,
                                isLate: data.isLate,
                                wakeTime: data.wakeTime,
                                duration: data.duration,
                                feeling: data.feeling,
                                reason: data.reason,
                                note: data.note
                            )
                        }
                    } else {
                        // 其他选项卡留白
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
            .background(pageBackground.ignoresSafeArea())
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DailySleepRow: View {
    let dayMonth: String
    let weekday: String
    let bedtime: String
    let sleepStatus: String
    let isLate: Bool
    let wakeTime: String
    let duration: String
    let feeling: String
    let reason: String
    let note: String?
    
    private let ink = Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 第一排：日期栏 与 入睡时间（卡片外，作为区域标题）
            HStack(alignment: .firstTextBaseline) {
                // 左侧：日期
                HStack(spacing: 6) {
                    Text(dayMonth)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isLate ? Color(red: 0.88, green: 0.32, blue: 0.22) : ink.opacity(0.92))
                    
                    Text("·")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(isLate ? Color(red: 0.88, green: 0.32, blue: 0.22) : ink.opacity(0.5))
                    
                    Text(weekday)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(isLate ? Color(red: 0.88, green: 0.32, blue: 0.22) : ink.opacity(0.5))
                }
                
                Spacer()
                
                // 右侧：入睡时间与状态
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(bedtime)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ink.opacity(0.92))
                        .monospacedDigit()
                    
                    Text(sleepStatus)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isLate ? Color(red: 0.88, green: 0.32, blue: 0.22) : Color(red: 0.2, green: 0.65, blue: 0.4))
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
            
            // 下方：白色卡片内部信息
            VStack(alignment: .leading, spacing: 16) {
                
                // 起床与时长（回归正常大小）
                HStack(spacing: 32) {
                    // 起床时间
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(wakeTime > "08:30" ? "晚起" : "早起")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ink.opacity(0.5))
                        Text(wakeTime)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ink.opacity(0.92))
                            .monospacedDigit()
                    }
                    
                    // 睡眠时长
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("时长")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ink.opacity(0.5))
                        Text(duration)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(ink.opacity(0.92))
                            .monospacedDigit()
                    }
                }
                
                // 备注（如果有）
                if let note = note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(ink.opacity(0.6))
                        .lineSpacing(4)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    StatisticsView()
}
