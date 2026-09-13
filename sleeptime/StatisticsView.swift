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
    case day = "天"
    case week = "周"
    case month = "月"
    case year = "年"
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
                    
                    Text("统计")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(ink)
                        .padding(.top, 10)
                    
                    // 自定义分段控制器
                    HStack(spacing: 0) {
                        let tabs = StatsTab.allCases
                        ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 15, weight: selectedTab == tab ? .bold : .medium))
                                    .foregroundColor(selectedTab == tab ? ink : Color(white: 0.55))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedTab == tab ? Color.white : Color.clear)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(Color(white: 0.92))
                    .clipShape(Capsule())
                    .padding(.top, 4)
                    
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
                    } else if selectedTab == .week {
                        // 周视图的头部：第几周 & 日期范围切换
                        HStack(alignment: .center) {
                            Text("week 35")
                                .font(.system(size: 34, weight: .bold)) // 移除圆体，加大字号
                                .foregroundColor(ink)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Button(action: {}) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ink.opacity(0.4))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .contentShape(Rectangle()) // 增加点击热区
                                }
                                
                                Text("8.26 - 9.01")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(ink.opacity(0.8))
                                    .padding(.horizontal, 4)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Button(action: {}) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ink.opacity(0.4))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .contentShape(Rectangle()) // 增加点击热区
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        // 统计卡片 (2x2 Grid)
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                // 早睡天数卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("早睡天数")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("4")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ink)
                                        Text("天")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(ink.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                
                                // 熬夜天数卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("熬夜天数")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("2")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ink)
                                        Text("天")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(ink.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            HStack(spacing: 12) {
                                // 最晚入睡时间卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("最晚入睡")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    Text("02:00")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(ink)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                
                                // 熬夜超出时长卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("超额熬夜")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("2.5")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ink)
                                        Text("小时")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(ink.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            
                            HStack(spacing: 12) {
                                // 平均入睡时间卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("平均入睡")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    Text("00:15")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(ink)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                
                                // 平均睡眠时长卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("平均时长")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("7.5")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ink)
                                        Text("小时")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(ink.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top, 16)
                        
                        WeekSleepTimelineView()
                            .padding(.top, 16)
                        
                        // 预留周视图的图表/列表内容
                        Spacer()
                    } else if selectedTab == .month {
                        // 月视图的头部：月份切换
                        HStack(alignment: .center) {
                            Text("8 月")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(ink)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Button(action: {}) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ink.opacity(0.4))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .contentShape(Rectangle())
                                }
                                
                                Button(action: {}) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ink.opacity(0.4))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        // 统计卡片 (2x2 Grid)
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                // 早睡天数卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("早睡天数")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("18")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ink)
                                        Text("天")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(ink.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                
                                // 熬夜天数卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("熬夜天数")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("12")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ink)
                                        Text("天")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(ink.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            
                            HStack(spacing: 12) {
                                // 最长连续早睡卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("最长连续早睡")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("5")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ink)
                                        Text("天")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(ink.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                
                                // 最长连续熬夜卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("最长连续熬夜")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("3")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ink)
                                        Text("天")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(ink.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            
                            HStack(spacing: 12) {
                                // 最晚入睡时间卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("最晚入睡")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    Text("02:30")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(ink)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                
                                // 熬夜超出时长卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("超额熬夜")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("14.5")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ink)
                                        Text("小时")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(ink.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                            
                            HStack(spacing: 12) {
                                // 平均入睡时间卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("平均入睡")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    Text("00:20")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(ink)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                                
                                // 平均睡眠时长卡片
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("平均时长")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ink.opacity(0.6))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("7.2")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(ink)
                                        Text("小时")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(ink.opacity(0.5))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top, 16)
                        
                        MonthSleepTrajectoryView()
                            .padding(.top, 32)
                            
                        ConsecutiveDistributionView()
                            .padding(.top, 40)
                        
                        Spacer()
                    } else if selectedTab == .year {
                        // 年视图的头部：年份切换
                        HStack(alignment: .center) {
                            Text("2026 年")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(ink)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Button(action: {}) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ink.opacity(0.4))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .contentShape(Rectangle())
                                }
                                
                                Button(action: {}) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ink.opacity(0.4))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .contentShape(Rectangle())
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        YearlyBedtimeRangeView()
                            .padding(.top, 24)
                        
                        Spacer()
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
            .background(pageBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
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

struct WeekTimelineData: Identifiable {
    let id = UUID()
    let weekday: String
    let bedtime: String
    let wakeTime: String
    let isLate: Bool
}

enum BedtimeCategory: Int, CaseIterable {
    case early = 4   // 早睡
    case regular = 3 // 常规
    case late = 2    // 偏晚
    case nightOwl = 1 // 夜猫
    case immortal = 0 // 修仙
    
    var title: String {
        switch self {
        case .early: return "早睡"
        case .regular: return "常规"
        case .late: return "偏晚"
        case .nightOwl: return "夜猫"
        case .immortal: return "修仙"
        }
    }
    
    var color: Color {
        switch self {
        case .early, .regular:
            // 健康作息 (Health/Good) - 同 DailySleepRow 中的正常绿色
            return Color(red: 0.2, green: 0.65, blue: 0.4)
        case .late, .nightOwl, .immortal:
            // 熬夜作息 (Late/Warning) - 同 DailySleepRow 中的熬夜红色
            return Color(red: 0.88, green: 0.32, blue: 0.22)
        }
    }
}

struct MonthSleepTrajectoryView: View {
    let days: [BedtimeCategory] = [
        .immortal, .nightOwl, .nightOwl, .late, .late,
        .late, .late, .late, .late, .nightOwl,
        .nightOwl, .regular, .regular, .regular, .late,
        .regular, .regular, .nightOwl, .regular, .regular,
        .regular, .early, .regular, .regular, .early,
        .regular, .early, .early, .early, .early
    ]
    
    private let ink = Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("月度入睡轨迹")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ink)
                Spacer()
            }
            .padding(.bottom, 24)
            
            // Chart Area
            GeometryReader { geo in
                let h = geo.size.height
                let stepY = h / 5 
                
                ZStack(alignment: .bottomLeading) {
                    // Grid and Labels
                    VStack(spacing: 0) {
                        ForEach((0..<5).reversed(), id: \.self) { i in
                            let cat = BedtimeCategory(rawValue: i)!
                            HStack(alignment: .center, spacing: 12) {
                                Text(cat.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(ink.opacity(0.8))
                                    .frame(width: 36, alignment: .trailing)
                                
                                // Dashed line
                                GeometryReader { lineGeo in
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: lineGeo.size.height / 2))
                                        path.addLine(to: CGPoint(x: lineGeo.size.width, y: lineGeo.size.height / 2))
                                    }
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .foregroundColor(Color(white: 0.85))
                                }
                            }
                            .frame(height: stepY)
                        }
                    }
                    
                    // Bars
                    HStack(spacing: 0) {
                        Spacer().frame(width: 48)
                        ForEach(Array(days.enumerated()), id: \.offset) { index, cat in
                            let barH = CGFloat(cat.rawValue + 1) * stepY
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(cat.color)
                                    .frame(height: barH - stepY / 2)
                            }
                        }
                    }
                }
            }
            .frame(height: 240)
            
            // X-Axis
            HStack(spacing: 0) {
                Spacer().frame(width: 48)
                GeometryReader { geo in
                    let w = geo.size.width
                    let dayWidth = w / CGFloat(days.count)
                    
                    let labels = [1, 5, 10, 15, 20, 25, 30]
                    ForEach(labels, id: \.self) { label in
                        Text("\(label)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ink)
                            .position(x: CGFloat(label - 1) * dayWidth + dayWidth / 2, y: geo.size.height / 2)
                    }
                }
                .frame(height: 24)
            }
            .padding(.top, 12)
        }
    }
}



struct ConsecutiveDistributionView: View {
    private let ink = Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
    private let earlyColor = Color(red: 0.2, green: 0.65, blue: 0.4)
    private let lateColor = Color(red: 0.88, green: 0.32, blue: 0.22)
    
    // Mock data matching the screenshot
    let data = [
        (3, 2), // 连续2天: 3段早睡，2段熬夜
        (2, 1), // 连续3天: 2段早睡，1段熬夜
        (1, 2)  // 连续4天+: 1段早睡，2段熬夜
    ]
    let labels = ["连续2天", "连续3天", "连续4天+"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .bottom) {
                Text("作息连续性分布")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ink)
                Spacer()
            }
            .padding(.bottom, 24)
            
            // Y-Axis label "段数"
            HStack {
                Text("段数")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ink.opacity(0.6))
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Chart Area
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let maxLevels = 3
                let stepY = h / CGFloat(maxLevels)
                
                ZStack(alignment: .bottomLeading) {
                    // Grid and Y-Axis numbers
                    VStack(spacing: 0) {
                        ForEach((0...maxLevels).reversed(), id: \.self) { i in
                            HStack(alignment: .center, spacing: 12) {
                                Text("\(i)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ink)
                                    .frame(width: 16, alignment: .leading)
                                
                                // Line (Solid for 0, Dashed for others)
                                GeometryReader { lineGeo in
                                    Path { path in
                                        path.move(to: CGPoint(x: 0, y: lineGeo.size.height / 2))
                                        path.addLine(to: CGPoint(x: lineGeo.size.width, y: lineGeo.size.height / 2))
                                    }
                                    .stroke(style: StrokeStyle(lineWidth: i == 0 ? 1 : 1, dash: i == 0 ? [] : [4, 4]))
                                    .foregroundColor(i == 0 ? Color(white: 0.8) : Color(white: 0.9))
                                }
                            }
                            .frame(height: i == 0 ? 0 : stepY, alignment: i == 0 ? .center : .top)
                        }
                    }
                    
                    // Bars
                    HStack(spacing: 0) {
                        Spacer().frame(width: 28)
                        let groupWidth = (w - 28) / CGFloat(data.count)
                        let boxSize: CGFloat = 28 // height of the stacked box
                        
                        ForEach(0..<data.count, id: \.self) { index in
                            let item = data[index]
                            
                            HStack(alignment: .bottom, spacing: 12) {
                                // Early stack
                                VStack(spacing: 4) {
                                    if item.0 > 0 {
                                        Text("\(item.0)段")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(earlyColor)
                                            .padding(.bottom, 2)
                                        ForEach(0..<item.0, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(earlyColor)
                                                .frame(width: boxSize, height: boxSize)
                                        }
                                    }
                                }
                                
                                // Late stack
                                VStack(spacing: 4) {
                                    if item.1 > 0 {
                                        Text("\(item.1)段")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(lateColor)
                                            .padding(.bottom, 2)
                                        ForEach(0..<item.1, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(lateColor)
                                                .frame(width: boxSize, height: boxSize)
                                        }
                                    }
                                }
                            }
                            .frame(width: groupWidth)
                        }
                    }
                }
            }
            .frame(height: 140)
            
            // X-Axis Labels
            HStack(spacing: 0) {
                Spacer().frame(width: 28)
                GeometryReader { geo in
                    let w = geo.size.width
                    let groupWidth = w / CGFloat(labels.count)
                    
                    ForEach(0..<labels.count, id: \.self) { index in
                        Text(labels[index])
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(ink.opacity(0.7))
                            .frame(width: groupWidth)
                            .position(x: CGFloat(index) * groupWidth + groupWidth / 2, y: geo.size.height / 2)
                    }
                }
                .frame(height: 30)
            }
            .padding(.top, 8)
            
            // Legend
            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(earlyColor)
                        .frame(width: 16, height: 16)
                    Text("早睡")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ink)
                }
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(lateColor)
                        .frame(width: 16, height: 16)
                    Text("熬夜")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ink)
                }
            }
            .padding(.top, 16)
        }
    }
}


struct YearlyBedtimeRangeView: View {
    private let ink = Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
    
    struct YearRangeData {
        let month: Int
        let earliestMins: CGFloat
        let latestMins: CGFloat
    }
    
    // Mock data: mins past 22:00. (e.g. 22:00=0, 04:00=360)
    // To handle before 22:00, we could use negative, but let's assume bedtime is >= 22:00
    let mockData: [YearRangeData] = [
        YearRangeData(month: 1, earliestMins: 30, latestMins: 150),  // 22:30 - 00:30
        YearRangeData(month: 2, earliestMins: 0, latestMins: 180),   // 22:00 - 01:00
        YearRangeData(month: 3, earliestMins: 60, latestMins: 120),  // 23:00 - 00:00
        YearRangeData(month: 4, earliestMins: -30, latestMins: 240), // 21:30 - 02:00 (Mapped to 22:00 if needed, but math handles it)
        YearRangeData(month: 5, earliestMins: 90, latestMins: 210),  // 23:30 - 01:30
        YearRangeData(month: 6, earliestMins: 120, latestMins: 270), // 00:00 - 02:30
        YearRangeData(month: 7, earliestMins: 180, latestMins: 360), // 01:00 - 04:00
        YearRangeData(month: 8, earliestMins: 30, latestMins: 150),  // 22:30 - 00:30
        YearRangeData(month: 9, earliestMins: 120, latestMins: 270), // 00:00 - 02:30
        YearRangeData(month: 10, earliestMins: 150, latestMins: 300),// 00:30 - 03:00
        YearRangeData(month: 11, earliestMins: 90, latestMins: 330), // 23:30 - 03:30
        YearRangeData(month: 12, earliestMins: 0, latestMins: 180)   // 22:00 - 01:00
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .bottom) {
                Text("年度入睡区间")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ink)
                Spacer()
            }
            .padding(.bottom, 24)
            
            // Chart Area
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                ZStack {
                    // Grid lines (22:00 to 04:00 = 360 mins)
                    let yLabels = ["04:00", "02:00", "00:00", "22:00"]
                    let yMins: [CGFloat] = [360, 240, 120, 0]
                    
                    ForEach(0..<yLabels.count, id: \.self) { i in
                        let yPos = h * (1 - yMins[i] / 360)
                        
                        HStack(alignment: .center, spacing: 12) {
                            Text(yLabels[i])
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(ink.opacity(0.4))
                                .frame(width: 36, alignment: .leading)
                            
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addLine(to: CGPoint(x: w - 48, y: 0))
                            }
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                            .foregroundColor(Color(white: 0.92))
                            .frame(height: 1)
                        }
                        .position(x: w / 2, y: yPos)
                    }
                    
                    // Dumbbell Bars (Thin line with dots)
                    let groupWidth = (w - 48) / 12.0
                    ForEach(0..<mockData.count, id: \.self) { i in
                        let data = mockData[i]
                        // Clamp values between 0 and 360 so they don't draw outside
                        let clampedLatest = min(max(data.latestMins, 0), 360)
                        let clampedEarliest = min(max(data.earliestMins, 0), 360)
                        
                        let topY = h * (1 - clampedLatest / 360)
                        let bottomY = h * (1 - clampedEarliest / 360)
                        let barHeight = bottomY - topY
                        
                        let xPos = 48 + CGFloat(i) * groupWidth + groupWidth / 2
                        
                        ZStack {
                            // Connecting Line
                            Rectangle()
                                .fill(ink.opacity(0.15))
                                .frame(width: 3, height: max(barHeight, 0))
                                .position(x: xPos, y: topY + barHeight / 2)
                            
                            // Top Dot (Latest)
                            Circle()
                                .fill(ink)
                                .frame(width: 8, height: 8)
                                .position(x: xPos, y: topY)
                            
                            // Bottom Dot (Earliest)
                            Circle()
                                .strokeBorder(ink, lineWidth: 2)
                                .background(Circle().fill(Color.white))
                                .frame(width: 8, height: 8)
                                .position(x: xPos, y: bottomY)
                        }
                    }
                }
            }
            .frame(height: 200)
            
            // X-Axis Labels
            HStack(spacing: 0) {
                Spacer().frame(width: 48)
                GeometryReader { geo in
                    let w = geo.size.width
                    let groupWidth = w / 12.0
                    
                    ForEach(1...12, id: \.self) { month in
                        Text("\(month)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ink.opacity(0.5))
                            .frame(width: groupWidth)
                            .position(x: CGFloat(month - 1) * groupWidth + groupWidth / 2, y: geo.size.height / 2)
                    }
                }
                .frame(height: 24)
            }
            .padding(.top, 12)
        }
    }
}

struct WeekSleepTimelineView: View {
    private let ink = Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
    private let barColor = Color(red: 160 / 255, green: 168 / 255, blue: 178 / 255)
    private let bedTickColor = Color(red: 40 / 255, green: 100 / 255, blue: 230 / 255) // Blue
    private let wakeTickColor = Color(red: 230 / 255, green: 60 / 255, blue: 40 / 255) // Red
    
    let targetBedtime = "23:30"
    let targetWake = "07:30"
    
    let mockData = [
        WeekTimelineData(weekday: "周一", bedtime: "23:15", wakeTime: "07:00", isLate: false),
        WeekTimelineData(weekday: "周二", bedtime: "00:15", wakeTime: "08:00", isLate: true),
        WeekTimelineData(weekday: "周三", bedtime: "22:30", wakeTime: "06:30", isLate: false),
        WeekTimelineData(weekday: "周四", bedtime: "23:00", wakeTime: "07:00", isLate: false),
        WeekTimelineData(weekday: "周五", bedtime: "02:00", wakeTime: "10:00", isLate: true),
        WeekTimelineData(weekday: "周六", bedtime: "01:30", wakeTime: "09:00", isLate: true),
        WeekTimelineData(weekday: "周日", bedtime: "23:45", wakeTime: "07:30", isLate: false)
    ]
    
    func fraction(for time: String) -> CGFloat {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        let hour = parts[0]
        let min = parts[1]
        var mappedHour = hour
        if hour >= 20 {
            mappedHour = hour - 20
        } else {
            mappedHour = hour + 4
        }
        let totalMinutes = CGFloat(mappedHour * 60 + min)
        return Swift.min(Swift.max(totalMinutes / 840.0, 0), 1.0)
    }
    
    var earliestBedtimeStr: String {
        mockData.min(by: { fraction(for: $0.bedtime) < fraction(for: $1.bedtime) })?.bedtime ?? "22:00"
    }
    
    var latestBedtimeStr: String {
        mockData.max(by: { fraction(for: $0.bedtime) < fraction(for: $1.bedtime) })?.bedtime ?? "02:00"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart Title
            HStack {
                Text("本周作息")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ink)
                Spacer()
            }
            .padding(.bottom, 12)
            // Goal Row
            HStack(alignment: .center, spacing: 0) {
                Text("目标")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ink.opacity(0.5))
                    .frame(width: 45, alignment: .leading)
                
                GeometryReader { geo in
                    let bedFrac = fraction(for: targetBedtime)
                    let wakeFrac = fraction(for: targetWake)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .foregroundColor(bedTickColor)
                            .font(.system(size: 10))
                        Text(targetBedtime)
                            .font(.system(size: 12))
                            .foregroundColor(ink.opacity(0.6))
                    }
                    .position(x: geo.size.width * bedFrac, y: geo.size.height / 2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(wakeTickColor)
                            .font(.system(size: 10))
                        Text(targetWake)
                            .font(.system(size: 12))
                            .foregroundColor(ink.opacity(0.6))
                    }
                    .position(x: geo.size.width * wakeFrac, y: geo.size.height / 2)
                }
                .frame(height: 20)
            }
            .padding(.bottom, 12)
            ZStack {
                // Vertical Dotted Lines
                HStack(spacing: 0) {
                    Spacer().frame(width: 45)
                    GeometryReader { geo in
                        // Target Bedtime Line
                        Path { path in
                            let x = geo.size.width * fraction(for: targetBedtime)
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundColor(bedTickColor.opacity(0.3))
                        
                        // Target Wake Line
                        Path { path in
                            let x = geo.size.width * fraction(for: targetWake)
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundColor(wakeTickColor.opacity(0.3))
                    }
                }
                
                // Data Rows
                VStack(spacing: 16) {
                    ForEach(mockData) { data in
                        HStack(alignment: .center, spacing: 0) {
                            Text(data.weekday)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(ink)
                                .frame(width: 45, alignment: .leading)
                            
                            GeometryReader { geo in
                                let midY = geo.size.height / 2
                                let w = geo.size.width
                                
                                // Horizontal Grid Line
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: midY))
                                    path.addLine(to: CGPoint(x: w, y: midY))
                                }
                                .stroke(Color(white: 0.9), lineWidth: 1)
                                
                                let bedFrac = fraction(for: data.bedtime)
                                let wakeFrac = fraction(for: data.wakeTime)
                                
                                let startX = w * bedFrac
                                let rawEndX = w * wakeFrac
                                let endX = rawEndX < startX ? w : rawEndX
                                let trackWidth = max(endX - startX, 4)
                                
                                // Sleep Track Bar
                                Rectangle()
                                    .fill(barColor)
                                    .frame(width: trackWidth, height: 4)
                                    .position(x: startX + trackWidth / 2, y: midY)
                                
                                // Bedtime Tick
                                Rectangle()
                                    .fill(bedTickColor)
                                    .frame(width: 2, height: 10)
                                    .position(x: startX, y: midY - 2)
                                
                                // Wake Time Tick
                                Rectangle()
                                    .fill(wakeTickColor)
                                    .frame(width: 2, height: 10)
                                    .position(x: endX, y: midY - 2)
                            }
                            .frame(height: 14)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.bottom, 8)
            
            // Bottom Axis
            HStack(alignment: .center, spacing: 0) {
                Spacer().frame(width: 45) // offset for weekday label
                GeometryReader { geo in
                    Text("20:00")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ink.opacity(0.4))
                        .position(x: 0, y: geo.size.height / 2)
                    
                    Text("00:00")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ink.opacity(0.4))
                        .position(x: geo.size.width * fraction(for: "00:00"), y: geo.size.height / 2)
                    
                    Text("10:00")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ink.opacity(0.4))
                        .position(x: geo.size.width, y: geo.size.height / 2)
                }
                .frame(height: 16)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    StatisticsView()
}
