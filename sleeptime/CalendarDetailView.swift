// CalendarDetailView.swift
import SwiftUI

// MARK: - Hex color helper (file-private)
private extension Color {
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

// MARK: - Month metadata
private struct MonthInfo: Identifiable {
    var id: Int { index }
    let index: Int
    let fullName: String
}

private let kAllMonths: [MonthInfo] = [
    .init(index:  0, fullName: "一月"),
    .init(index:  1, fullName: "二月"),
    .init(index:  2, fullName: "三月"),
    .init(index:  3, fullName: "四月"),
    .init(index:  4, fullName: "五月"),
    .init(index:  5, fullName: "六月"),
    .init(index:  6, fullName: "七月"),
    .init(index:  7, fullName: "八月"),
    .init(index:  8, fullName: "九月"),
    .init(index:  9, fullName: "十月"),
    .init(index: 10, fullName: "十一月"),
    .init(index: 11, fullName: "十二月"),
]

private let kWeekdayLabels = ["一", "二", "三", "四", "五", "六", "日"]

// MARK: - Main View
struct CalendarDetailView: View {

    @State private var viewMode: CalendarViewMode = .year
    @State private var isYearVisualizationStyle: Bool = false
    private let displayYear: Int = 2026 // Currently hardcoded for the annual view
    private let initialMonth: Int = Calendar.current.component(.month, from: Date()) - 1

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch viewMode {
                case .year:
                    if isYearVisualizationStyle {
                        YearVisualizationView(year: displayYear)
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 0) {
                                    ForEach(kAllMonths) { month in
                                        monthSection(month)
                                            .id(month.index)
                                    }
                                    Color.clear.frame(height: 100) // Padding for bottom picker
                                }
                            }
                            .onAppear {
                                proxy.scrollTo(initialMonth, anchor: .top)
                            }
                        }
                    }
                case .month:
                    MonthGridDetailView(year: displayYear, monthIndex: initialMonth)
                case .total:
                    TotalSummaryArchiveView(year: displayYear)
                case .day:
                    Color.clear // 空白占位
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            ViewModePicker(selectedMode: $viewMode)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if viewMode == .year {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isYearVisualizationStyle.toggle()
                            }
                        } label: {
                            Image(systemName: "circle.grid.2x2")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isYearVisualizationStyle ? .accentColor : .primary)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                    }
                    
                    Button {
                        // 分享逻辑
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                }
            }
        }
    }

    // MARK: - [3] Month Section
    @ViewBuilder
    private func monthSection(_ month: MonthInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Month header
            HStack {
                Text(month.fullName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)

            // 7-column day grid
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: gridColumns, spacing: 0) {
                // Weekday header row
                ForEach(kWeekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .frame(height: 22)
                }
                // Leading empty cells (Monday-based offset)
                let offset = weekdayOffset(year: displayYear, monthIndex: month.index)
                ForEach(0 ..< offset, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }
                // Day cells
                let total = daysInMonth(year: displayYear, monthIndex: month.index)
                ForEach(1 ... max(1, total), id: \.self) { day in
                    if day <= total {
                        dayCell(day: day, monthIndex: month.index)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            Divider()
        }
    }

    // MARK: - Day Cell
    @ViewBuilder
    private func dayCell(day: Int, monthIndex: Int) -> some View {
        let isToday: Bool = {
            var c = DateComponents()
            c.year  = displayYear
            c.month = monthIndex + 1
            c.day   = day
            guard let d = Calendar.current.date(from: c) else { return false }
            return Calendar.current.isDateInToday(d)
        }()

        ZStack {
            if isToday {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 32, height: 32)
            }
            Text("\(day)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? Color(UIColor.systemBackground) : .primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
    }

    // MARK: - Calendar Helpers
    private func daysInMonth(year: Int, monthIndex: Int) -> Int {
        var c = DateComponents()
        c.year  = year
        c.month = monthIndex + 1
        guard let date  = Calendar.current.date(from: c),
              let range = Calendar.current.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }

    /// Empty leading cells so day 1 lands on the correct column (Monday = 0, Sunday = 6).
    private func weekdayOffset(year: Int, monthIndex: Int) -> Int {
        var c = DateComponents()
        c.year  = year
        c.month = monthIndex + 1
        c.day   = 1
        guard let date = Calendar.current.date(from: c) else { return 0 }
        let weekday = Calendar.current.component(.weekday, from: date) // 1 = Sunday
        return (weekday + 5) % 7
    }
}

enum CalendarViewMode: String, CaseIterable {
    case day = "日"
    case month = "月"
    case year = "年"
    case total = "总"
}

struct ViewModePicker: View {
    @Binding var selectedMode: CalendarViewMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue)
                    .font(.system(size: 15, weight: selectedMode == mode ? .medium : .regular))
                    .foregroundColor(selectedMode == mode ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedMode == mode ? Color(.systemBackground) : Color.clear)
                            .shadow(color: Color.black.opacity(selectedMode == mode ? 0.05 : 0), radius: 2, x: 0, y: 1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMode = mode
                        }
                    }
            }
        }
        .padding(4)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal, 40)
        .padding(.bottom, 24)
    }
}

// MARK: - Detailed Month View
// MARK: - Detailed Month View
struct MonthGridDetailView: View {
    let year: Int
    let monthIndex: Int
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                
                // 星期表头
                let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
                LazyVGrid(columns: gridColumns, spacing: 0) {
                    ForEach(kWeekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                            .frame(height: 30)
                    }
                }
                .padding(.horizontal, 16)
                
                // 日历主体：去边框，加高留白
                LazyVGrid(columns: gridColumns, spacing: 0) {
                    let offset = weekdayOffset(year: year, monthIndex: monthIndex)
                    let total = daysInMonth(year: year, monthIndex: monthIndex)
                    
                    // 补充上个月的空白
                    ForEach(0 ..< offset, id: \.self) { _ in
                        Color.clear.frame(height: 110)
                    }
                    
                    // 当月日期
                    ForEach(1 ... total, id: \.self) { day in
                        detailedDayCell(day: day)
                    }
                }
                .padding(.horizontal, 16)
                
                Color.clear.frame(height: 120) // 给底部悬浮按钮留出空间
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
    
    @ViewBuilder
    private func detailedDayCell(day: Int) -> some View {
        let isToday: Bool = {
            var c = DateComponents()
            c.year  = year
            c.month = monthIndex + 1
            c.day   = day
            guard let d = Calendar.current.date(from: c) else { return false }
            return Calendar.current.isDateInToday(d)
        }()
        
        let tags = mockTags(for: day)

        VStack(spacing: 8) {
            // 日期数字
            let weekday = (weekdayOffset(year: year, monthIndex: monthIndex) + day - 1) % 7
            let isWeekend = weekday == 5 || weekday == 6
            
            Text("\(day)")
                .font(.system(size: 15, weight: isToday ? .bold : .medium))
                .foregroundColor(
                    isToday ? .primary : (isWeekend ? Color.red.opacity(0.8) : .primary)
                )
                .padding(.top, 12)
            
            // 标签列表
            VStack(spacing: 4) {
                ForEach(tags, id: \.text) { tag in
                    Text(tag.text)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 16)
                        .background(tag.bgColor)
                        .cornerRadius(3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, 4)
            
            Spacer(minLength: 0)
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        // 只有顶部有极细的分割线，像原生极简日历一样
        .overlay(
            VStack {
                Rectangle().fill(Color(UIColor.separator).opacity(0.2)).frame(height: 0.5)
                Spacer()
            }
        )
    }
    
    // 伪造标签数据
    private struct MockTag {
        let text: String
        let bgColor: Color
    }
    
    private func mockTags(for day: Int) -> [MockTag] {
        var tags: [MockTag] = []
        
        // 用极简的纯色块+白字，像截图里的 "Veterans" 或 "Halloween"
        let isEarly = day % 3 != 0 && day != 5 && day != 12
        let isLate = !isEarly
        let playedPhone = day % 4 == 0
        
        if isEarly {
            // 少量偶尔出现的奖励标记，比如某几天特别棒
            if day % 7 == 0 {
                tags.append(MockTag(text: "极佳", bgColor: Color(red: 0.2, green: 0.7, blue: 0.4)))
            }
        } else if isLate {
            tags.append(MockTag(text: "熬夜", bgColor: Color(red: 0.85, green: 0.3, blue: 0.3)))
        }
        
        if playedPhone && tags.count < 1 {
            tags.append(MockTag(text: "玩手机", bgColor: Color.gray.opacity(0.7)))
        }
        
        return tags
    }
    
    private func daysInMonth(year: Int, monthIndex: Int) -> Int {
        var c = DateComponents()
        c.year  = year
        c.month = monthIndex + 1
        guard let date  = Calendar.current.date(from: c),
              let range = Calendar.current.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }

    private func weekdayOffset(year: Int, monthIndex: Int) -> Int {
        var c = DateComponents()
        c.year  = year
        c.month = monthIndex + 1
        c.day   = 1
        guard let date = Calendar.current.date(from: c) else { return 0 }
        let weekday = Calendar.current.component(.weekday, from: date)
        return (weekday + 5) % 7
    }
}

// MARK: - Total Summary Archive View
struct TotalSummaryArchiveView: View {
    let year: Int
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                Spacer().frame(height: 32)
                
                VStack(spacing: 0) {
                    // Top header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(year)")
                                .font(.custom("AvenirNext-Regular", size: 36))
                                .foregroundColor(Color.primary.opacity(0.85))
                            Text("ANNUAL ARCHIVE · 睡眠年卷")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.primary.opacity(0.5))
                                .tracking(1.5)
                        }
                        
                        Spacer()
                        
                        Text("安 睡")
                            .font(.system(size: 18, weight: .light))
                            .tracking(3)
                            .foregroundColor(Color.primary.opacity(0.85))
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 28)
                    
                    Divider()
                        .padding(.vertical, 28)
                        .padding(.horizontal, 28)
                        .opacity(0.6)
                    
                    // Poem / Quote
                    VStack(spacing: 16) {
                        Text("日出而作，日入而息。")
                        Text("给时间以时间，")
                        Text("给睡眠以安宁。")
                    }
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Color.primary.opacity(0.7))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    
                    Text("—— 时隙 / 留白")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(Color.primary.opacity(0.4))
                        .padding(.top, 24)
                    
                    Divider()
                        .padding(.vertical, 28)
                        .padding(.horizontal, 28)
                        .opacity(0.6)
                    
                    // Stats
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("YEARLY TOTAL")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.primary.opacity(0.5))
                                .tracking(1)
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("238")
                                    .font(.custom("AvenirNext-Regular", size: 34))
                                    .foregroundColor(Color.primary.opacity(0.85))
                                Text("天早睡")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(Color.primary.opacity(0.6))
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("AVG DURATION")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.primary.opacity(0.5))
                                .tracking(1)
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("7.4")
                                    .font(.custom("AvenirNext-Regular", size: 34))
                                    .foregroundColor(Color.primary.opacity(0.85))
                                Text("小时")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(Color.primary.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
                }
                .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                .cornerRadius(24)
                .padding(.horizontal, 24)
                
                Color.clear.frame(height: 120) // bottom padding
            }
        }
    }
}

// MARK: - Year Visualization View
struct YearVisualizationView: View {
    let year: Int
    
    // 极简色彩配置：拒绝花里胡哨，使用莫兰迪高级灰调
    private let colorEarly = Color(red: 0.45, green: 0.55, blue: 0.50) // 沉稳灰绿 (早睡)
    private let colorLate = Color(red: 0.75, green: 0.55, blue: 0.50)  // 柔和陶土色 (熬夜)
    private let colorEmpty = Color(UIColor.quaternarySystemFill)       // 极淡灰色 (空白)
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                // 顶部标题
                HStack {
                    Text("\(year)")
                        .font(.custom("AvenirNext-Bold", size: 40))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // 纵向瀑布流网格 (1列日期 + 12列月份 + 1列右侧平衡占位)
                // 缩减间距，让方格更紧凑密集，提升可视化的高级“颗粒感”
                let gridColumns = [GridItem(.fixed(20), spacing: 10)] + Array(repeating: GridItem(.flexible(), spacing: 3), count: 12) + [GridItem(.fixed(20), spacing: 0)]
                
                LazyVGrid(columns: gridColumns, spacing: 3) {
                    // 表头：月份 1~12
                    Text("") // 左上角占位
                    ForEach(1...12, id: \.self) { m in
                        Text("\(m)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.primary) // 更大更清晰的纯黑
                    }
                    Text("") // 右侧平衡占位
                    
                    // 主体：31天的数据
                    ForEach(1...31, id: \.self) { day in
                        // 第一列：纵轴的日期刻度
                        Text("\(day)")
                            .font(.custom("AvenirNext-Bold", size: 12))
                            .foregroundColor(Color.primary.opacity(0.75)) // 放大并加深颜色，保证清晰
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        // 后12列：每个月的方块
                        ForEach(0..<12, id: \.self) { monthIndex in
                            let totalDays = daysInMonth(year: year, monthIndex: monthIndex)
                            if day <= totalDays {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(mockColor(for: day, month: monthIndex))
                                    .aspectRatio(1, contentMode: .fit)
                            } else {
                                // 处理月份不足31天的情况，留出完美的空白占位
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                        
                        // 最后一列：右侧平衡占位
                        Text("")
                        
                        // 每 7 天插入一个空行，拉开空间感（周期的视觉节奏）
                        if day % 7 == 0 && day != 31 {
                            ForEach(0..<14, id: \.self) { _ in
                                Color.clear.frame(height: 6) // 控制空行的高度
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Color.clear.frame(height: 120) // 底部留白
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }
    
    // 生成伪造颜色，避免花里胡哨，只有绿、红、灰
    private func mockColor(for day: Int, month: Int) -> Color {
        // 让数据看起来有一些随机连贯性
        let seed = day * 13 + month * 7
        let randomVal = seed % 10
        
        if randomVal < 5 {
            return colorEarly // 50% 早睡
        } else if randomVal < 7 {
            return colorLate // 20% 熬夜
        } else {
            return colorEmpty // 30% 空缺
        }
    }
    
    private func daysInMonth(year: Int, monthIndex: Int) -> Int {
        var c = DateComponents()
        c.year  = year
        c.month = monthIndex + 1
        guard let date  = Calendar.current.date(from: c),
              let range = Calendar.current.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }
}

// MARK: - Preview
struct CalendarDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CalendarDetailView()
        }
        .preferredColorScheme(.light)
        NavigationStack {
            CalendarDetailView()
        }
        .preferredColorScheme(.dark)
    }
}
