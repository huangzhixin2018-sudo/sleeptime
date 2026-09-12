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
    @State private var isMonthVisualizationStyle: Bool = false
    @State private var isDayVisualizationStyle: Bool = false
    @State private var isTotalVisualizationStyle: Bool = false
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
                    if isMonthVisualizationStyle {
                        MonthHangingVisualizationView(year: displayYear, monthIndex: initialMonth)
                    } else {
                        MonthGridDetailView(year: displayYear, monthIndex: initialMonth)
                    }
                case .total:
                    if isTotalVisualizationStyle {
                        ConvergenceShiftView(year: displayYear)
                    } else {
                        TotalSummaryArchiveView(year: displayYear)
                    }
                case .day:
                    if isDayVisualizationStyle {
                        DayTearOffCalendarView()
                    } else {
                        DayReceiptView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            ViewModePicker(selectedMode: $viewMode)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("年度日历")
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
                    } else if viewMode == .month {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isMonthVisualizationStyle.toggle()
                            }
                        } label: {
                            Image(systemName: isMonthVisualizationStyle ? "square.grid.2x2" : "waveform.path")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isMonthVisualizationStyle ? .accentColor : .primary)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                    } else if viewMode == .day {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isDayVisualizationStyle.toggle()
                            }
                        } label: {
                            Image(systemName: isDayVisualizationStyle ? "doc.plaintext" : "bookmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isDayVisualizationStyle ? .accentColor : .primary)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                    } else if viewMode == .total {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isTotalVisualizationStyle.toggle()
                            }
                        } label: {
                            Image(systemName: isTotalVisualizationStyle ? "chart.xyaxis.line" : "chart.bar")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isTotalVisualizationStyle ? .accentColor : .primary)
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

// MARK: - Day Receipt View (睡眠日签)
struct DayReceiptView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                Spacer().frame(height: 24)
                
                // The Receipt Card
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("睡眠日签")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.primary)
                        Text("编号：20260906-001")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(Color.primary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    Divider().padding(.vertical, 20).padding(.horizontal, 24)
                    
                    // Date & Day
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("日期")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.primary.opacity(0.4))
                            Text("2026.09.06")
                                .font(.custom("AvenirNext-Bold", size: 24))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("星期")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.primary.opacity(0.4))
                            Text("星期日")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Divider().padding(.vertical, 20).padding(.horizontal, 24)
                    
                    // Core Data (Bedtime & Wake Up)
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("入睡时间")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.primary.opacity(0.4))
                            Text("23:15")
                                .font(.custom("AvenirNext-Regular", size: 36))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider().frame(height: 50)
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("起床时间")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.primary.opacity(0.4))
                            Text("06:45")
                                .font(.custom("AvenirNext-Regular", size: 36))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 24)
                    
                    Divider().padding(.vertical, 20).padding(.horizontal, 24)
                    
                    // Duration
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("睡眠总时长")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.primary.opacity(0.4))
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("7")
                                    .font(.custom("AvenirNext-Bold", size: 52))
                                    .foregroundColor(.primary)
                                Text("小时")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.primary.opacity(0.6))
                                Text("30")
                                    .font(.custom("AvenirNext-Bold", size: 52))
                                    .foregroundColor(.primary)
                                Text("分钟")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.primary.opacity(0.6))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .background(Color(red: 0.96, green: 0.95, blue: 0.93)) // 经典票据/微黄纸张颜色
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 8)
                .padding(.horizontal, 24)
                
                Color.clear.frame(height: 120)
            }
        }
    }
}

// MARK: - Month Hanging Visualization View (入睡时辰风铃日历)
struct MonthHangingVisualizationView: View {
    let year: Int
    let monthIndex: Int
    
    // 5个入睡时辰标记：22点(10)、23点(11)、0点(12)、1点(1)、2点(2)
    private let hourLabels = ["10", "11", "12", "1", "2"]
    
    // 将当月 31 天按照入睡时辰分组到 5 个挂钩列
    private var columnsData: [[Int]] {
        let totalDays = daysInMonth(year: year, monthIndex: monthIndex)
        var col10: [Int] = []
        var col11: [Int] = []
        var col12: [Int] = []
        var col1: [Int]  = []
        var col2: [Int]  = []
        
        for d in 1...totalDays {
            if d <= 3 {
                col10.append(d)
            } else if d <= 10 {
                col11.append(d)
            } else if d <= 17 {
                col12.append(d)
            } else if d <= 24 {
                col1.append(d)
            } else {
                col2.append(d)
            }
        }
        return [col10, col11, col12, col1, col2]
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Title
                VStack(spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BEDTIME MOBILE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.primary.opacity(0.4))
                                .tracking(2)
                            Text("入睡时辰风铃 · \(kAllMonths[monthIndex].fullName)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    Divider().padding(.horizontal, 24).opacity(0.4)
                }
                .padding(.top, 16)
                
                // Hanging Mobile Graphic Container
                GeometryReader { geo in
                    let w = geo.size.width
                    let archHeight: CGFloat = 46 // 微小调大拱形高度，让弧度更明显优雅
                    let startY: CGFloat = 72
                    
                    ZStack(alignment: .top) {
                        // 1. 粗黑色拱梁 (Arch Beam - 稍大一些微弧度)
                        ArchBeamShape()
                            .stroke(Color.primary, lineWidth: 6)
                            .frame(width: w - 48, height: archHeight)
                            .padding(.horizontal, 24)
                            .offset(y: startY)
                        
                        // 2. 拱梁上方居中的月份标识 (如 1月 与向下箭头)
                        VStack(spacing: 2) {
                            Text(kAllMonths[monthIndex].fullName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            Image(systemName: "arrow.down")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.primary)
                        }
                        .offset(y: startY - 38)
                        
                        // 3. 5 个入睡时辰挂钩与悬挂日期列 (10, 11, 12, 1, 2)
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(0..<5, id: \.self) { colIdx in
                                let days = columnsData[colIdx]
                                let hourText = hourLabels[colIdx]
                                let colRatio = CGFloat(colIdx) / 4.0
                                // 抛物线弧度偏移 y = 4 * H * x * (1 - x)
                                let curveOffsetY = 4 * archHeight * colRatio * (1.0 - colRatio)
                                
                                VStack(spacing: 0) {
                                    // 1. 从黑色拱梁向下延伸的挂线
                                    Rectangle()
                                        .fill(Color.primary)
                                        .frame(width: 1.5, height: 18)
                                    
                                    // 2. 加粗黑色时辰数字 (10, 11, 12, 1, 2)
                                    Text(hourText)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(.vertical, 2)
                                    
                                    // 3. 连接到下方日期的细吊线
                                    Rectangle()
                                        .fill(Color.primary.opacity(0.3))
                                        .frame(width: 1, height: 10)
                                    
                                    // 4. 垂直自然交错悬挂日期
                                    VStack(spacing: 6) {
                                        ForEach(days, id: \.self) { day in
                                            hangingDayNode(day: day)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .offset(y: startY + archHeight - curveOffsetY)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .frame(height: 570)
                
                DialScaleView()
                    .padding(.top, 20)
                
                Color.clear.frame(height: 120)
            }
        }
    }
    
    // Day Node Component (具有自然 S 型微波浪交错与倾斜度的艺术字)
    @ViewBuilder
    private func hangingDayNode(day: Int) -> some View {
        let tilt = Double(((day * 13) % 17) - 8) // -8° ~ +8° 自然手写倾角
        let waveOffsetX = CGFloat(sin(Double(day) * 0.85) * 5.0) // ±5pt 的自然左右微调波浪感
        
        Text("\(day)")
            .font(.system(size: 22, weight: .light, design: .rounded))
            .foregroundColor(Color.primary.opacity(0.85))
            .rotationEffect(.degrees(tilt))
            .offset(x: waveOffsetX)
            .frame(height: 30)
    }
    
    private func daysInMonth(year: Int, monthIndex: Int) -> Int {
        var c = DateComponents()
        c.year = year
        c.month = monthIndex + 1
        guard let date = Calendar.current.date(from: c),
              let range = Calendar.current.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }
}

// MARK: - Curved Arch Beam Shape
struct ArchBeamShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startPoint = CGPoint(x: 0, y: rect.height)
        let controlPoint = CGPoint(x: rect.width / 2, y: -rect.height * 0.65)
        let endPoint = CGPoint(x: rect.width, y: rect.height)
        
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, control: controlPoint)
        return path
    }
}

// MARK: - Day Art Lockscreen View (日度锁屏极简历 + 节日适配)
struct DayTearOffCalendarView: View {
    @State private var selectedFestival: DemoFestival = .qingming
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Spacer().frame(height: 8)
                
                // 节日演示切换器 (轻触即可预览 清明节 / 情人节 / 春节 / 中秋节)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DemoFestival.allCases, id: \.self) { festival in
                            Text(festival.rawValue)
                                .font(.system(size: 12, weight: selectedFestival == festival ? .bold : .regular))
                                .foregroundColor(selectedFestival == festival ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(selectedFestival == festival ? festival.accentColor : Color.primary.opacity(0.06))
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        selectedFestival = festival
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Card Container
                VStack(spacing: 20) {
                    // 1. 顶部日期与农历胶囊条 (参照 iOS 锁屏顶部小字条 + 节日名称)
                    HStack {
                        Text(selectedFestival.dateString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedFestival.accentColor)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(selectedFestival.accentColor.opacity(0.3), lineWidth: 1)
                            .background(Capsule().fill(selectedFestival.accentColor.opacity(0.06)))
                    )
                    .padding(.top, 24)
                    
                    // 2. 主视觉锁屏风格大字框 (参照 iOS 锁屏巨幅时间/入睡时间)
                    VStack(spacing: 8) {
                        Text("23:15")
                            .font(.system(size: 76, weight: .thin, design: .rounded))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                        
                        HStack(spacing: 12) {
                            Label("06:45 起床", systemImage: "sun.max.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.primary.opacity(0.6))
                            
                            Text("·")
                                .foregroundColor(Color.primary.opacity(0.3))
                            
                            Label("睡眠 7h 30m", systemImage: "clock.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.primary.opacity(0.6))
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 24).fill(Color.primary.opacity(0.03)))
                    )
                    .padding(.horizontal, 20)
                    
                    // 3. 状态与节日主题标签条 (Pill Badges)
                    HStack(spacing: 8) {
                        // 节日专有主题 Pill
                        Text(selectedFestival.festivalTag)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(selectedFestival.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedFestival.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                        
                        Text("熬夜: 刷短视频")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.primary.opacity(0.75))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Capsule())
                        
                        Text("深睡充沛")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.25, green: 0.6, blue: 0.4))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.25, green: 0.6, blue: 0.4).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    
                    // 4. 睡不着的几句话 (节日专属夜深随笔 - 无标题，极简纯文本)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedFestival.quoteText)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.primary.opacity(0.85))
                            .lineSpacing(5)
                        
                        HStack {
                            Spacer()
                            Text("—— 01:25 记于枕边")
                                .font(.system(size: 11, weight: .light))
                                .foregroundColor(Color.primary.opacity(0.5))
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primary.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .background(Color(red: 0.96, green: 0.95, blue: 0.93))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 24)
                
                Color.clear.frame(height: 120)
            }
        }
    }
}

// MARK: - 节日数据枚举 (清明节、情人节、春节、中秋节等)
private enum DemoFestival: String, CaseIterable {
    case qingming = "清明节"
    case valentines = "情人节"
    case springFestival = "春节"
    case midAutumn = "中秋节"
    case regular = "常规日"
    
    var dateString: String {
        switch self {
        case .qingming: return "4月4日 · 周六 · 丙午年二月十七 · 清明节"
        case .valentines: return "2月14日 · 周六 · 丙午年十二月廿七 · 情人节"
        case .springFestival: return "1月29日 · 周四 · 丙午年正月初一 · 春节"
        case .midAutumn: return "9月25日 · 周五 · 丙午年八月十五 · 中秋节"
        case .regular: return "9月6日 · 周日 · 丙午年七月廿五 · 白露"
        }
    }
    
    var festivalTag: String {
        switch self {
        case .qingming: return "清明折柳"
        case .valentines: return "情人节浪漫"
        case .springFestival: return "新春大吉"
        case .midAutumn: return "月圆中秋"
        case .regular: return "常规日"
        }
    }
    
    var quoteText: String {
        switch self {
        case .qingming: return "「清明时节雨纷纷，听雨入梦。给远方的人送去深深思念，今夜愿你安睡。」"
        case .valentines: return "「爱意在静谧的夜里悄然生长。关掉台灯，晚安，心上人。」"
        case .springFestival: return "「除夕今宵尽，新岁春风来。告别旧岁的疲惫，今晚睡个无比踏实的好觉。」"
        case .midAutumn: return "「但愿人长久，千里共婵娟。今夜月光皎洁如水，梦也香甜。」"
        case .regular: return "「手机切静音的那刻，夜空才真正收回了它的宁静。今晚月光很轻，适合在梦里重逢。」"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .qingming: return Color(red: 0.3, green: 0.55, blue: 0.4) // 鼠尾草绿
        case .valentines: return Color(red: 0.85, green: 0.4, blue: 0.5) // 玫瑰木粉
        case .springFestival: return Color(red: 0.85, green: 0.3, blue: 0.25) // 朱红
        case .midAutumn: return Color(red: 0.85, green: 0.6, blue: 0.25) // 暖月黄
        case .regular: return Color.primary.opacity(0.85)
        }
    }
}





struct CelebrityCard: Identifiable {
    let id = UUID()
    let name: String
    let tag: String
}

struct CelebrityRoutineView: View {
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    
    let cards: [CelebrityCard] = [
        CelebrityCard(name: "村上春树", tag: "极致自律的马拉松小说家"),
        CelebrityCard(name: "科比·布莱恩特", tag: "凌晨四点的洛杉矶"),
        CelebrityCard(name: "列奥纳多·达·芬奇", tag: "多相睡眠法先驱")
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(cards) { card in
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(card.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(card.tag)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        Toggle("", isOn: .constant(card.name == "村上春树"))
                            .labelsHidden()
                            .tint(Color.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .frame(minHeight: 110)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding(20)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97).ignoresSafeArea())
        .navigationTitle("名人库")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Celebrity Routine View (名人时相 · 村上春树作息)
struct CelebrityRoutineLegacyView: View {
    @State private var isSynced: Bool = false
    @State private var currentTimeString: String = ""
    
    // 24小时时间段数据 (村上春树)
    fileprivate struct RoutineBlock: Identifiable {
        let id = UUID()
        let start: Double // 0-24
        let end: Double
        let type: BlockType
        let title: String
        let desc: String
        
        enum BlockType {
            case sleep, focus, routine
        }
    }
    
    private let blocks: [RoutineBlock] = [
        .init(start: 21, end: 24, type: .sleep, title: "深度睡眠", desc: "养精蓄锐，准备清晨爆发"),
        .init(start: 0, end: 4, type: .sleep, title: "深度睡眠", desc: "维持高质量深睡周期"),
        .init(start: 4, end: 9, type: .focus, title: "黄金写作", desc: "绝对专注，绝不让外界讯息侵入"),
        .init(start: 9, end: 12, type: .routine, title: "十公里跑步", desc: "体能锚定，重构肌肉与耐力"),
        .init(start: 12, end: 14, type: .routine, title: "午餐与阅读", desc: "黑胶唱片与书籍养分输入"),
        .init(start: 14, end: 20, type: .routine, title: "生活杂务", desc: "完全不从事繁重文字工作"),
        .init(start: 20, end: 21, type: .routine, title: "晚间静息", desc: "调暗光线，准备就寝")
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // headerView
                Divider().padding(.horizontal, 24).opacity(0.4)
                
                personaHeaderCard
                
                clockDialSection
                
                quoteSection
                
                timelineSection
                
                syncActionCard
                
                Color.clear.frame(height: 120)
            }
        }
        .onAppear {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            currentTimeString = formatter.string(from: Date())
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("名人库") {
                    CelebrityRoutineView()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 1. 顶部标题栏
    @ViewBuilder
    private var headerView: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("昼夜节律图鉴 · 名人作息")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primary.opacity(0.4))
                    .tracking(1.5)
                
                Text("名人时相")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(currentTimeString)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primary.opacity(0.5))
                Text("节律实时映射中")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.primary.opacity(0.4))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // 2. 人物卡片头部
    @ViewBuilder
    private var personaHeaderCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("01")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 1.0, green: 0.9, blue: 0.0))
                        .cornerRadius(4)
                    
                    Text("村上春树")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Text("作家 · 机械式清晨创作者")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.primary.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("每日睡眠总长")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primary.opacity(0.4))
                Text("7.0小时")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // 3. 24小时环形作息表盘
    @ViewBuilder
    private var clockDialSection: some View {
        VStack(spacing: 16) {
            ZStack {
                CircadianClockCanvas(blocks: blocks)
                    .frame(width: 240, height: 240)
                
                VStack(spacing: 2) {
                    Text("黄金深度专注")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.primary.opacity(0.4))
                    
                    Text("5.0小时")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text("04:00 起床")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.primary.opacity(0.6))
                }
            }
            
            // 图例标识 (纯中文)
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "18181B")).frame(width: 8, height: 8)
                    Text("睡眠")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.primary.opacity(0.6))
                }
                
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "FFE500")).frame(width: 8, height: 8)
                    Text("专注写作")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.primary.opacity(0.6))
                }
                
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "E4E4E7")).frame(width: 8, height: 8)
                    Text("日常生活")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.primary.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.primary.opacity(0.02)))
        )
        .padding(.horizontal, 24)
    }
    
    // 4. 作息箴言引用
    @ViewBuilder
    private var quoteSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.primary)
                .frame(width: 3)
            
            Text("“写长篇小说就像进行体力劳动。早晨四点起床，伏案写上四五个小时，跑上十公里，然后早早沉睡。”")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.primary.opacity(0.8))
                .lineSpacing(5)
        }
        .padding(.horizontal, 24)
    }
    
    // 5. 24小时时间骨骼列表
    @ViewBuilder
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("24小时时间骨骼")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primary.opacity(0.4))
                    .tracking(1.5)
                Spacer()
                Text("全天节律轨迹")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.primary.opacity(0.4))
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 8) {
                ForEach(blocks.filter { $0.type != .sleep }) { b in
                    HStack(spacing: 12) {
                        Text(formatTimeRange(start: b.start, end: b.end))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(b.type == .focus ? .black : Color.primary.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(b.type == .focus ? Color(hex: "FFE500") : Color.primary.opacity(0.06))
                            .cornerRadius(6)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(b.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                            Text(b.desc)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color.primary.opacity(0.55))
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.02)))
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // 6. 底部作息目标卡 (一键同步)
    @ViewBuilder
    private var syncActionCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("同频目标")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primary.opacity(0.4))
                Text("将此作息设为我的今日目标")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    isSynced.toggle()
                }
            } label: {
                Text(isSynced ? "已同步 ✓" : "一键同步")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSynced ? .white : Color(UIColor.systemBackground))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isSynced ? Color.green : Color.primary)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4]))
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.primary.opacity(0.02)))
        )
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    private func formatTimeRange(start: Double, end: Double) -> String {
        let sh = Int(start) % 24
        let sm = Int((start - Double(sh)) * 60)
        let eh = Int(end) % 24
        let em = Int((end - Double(eh)) * 60)
        return String(format: "%02d:%02d - %02d:%02d", sh, sm, eh, em)
    }
}

// MARK: - 24小时环形时钟 Shape/Canvas 绘制
fileprivate struct CircadianClockCanvas: View {
    let blocks: [CelebrityRoutineLegacyView.RoutineBlock]
    
    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius: CGFloat = 92
            let lineWidth: CGFloat = 20
            
            drawTicks(ctx: ctx, center: center, radius: radius, lineWidth: lineWidth)
            drawArcs(ctx: ctx, center: center, radius: radius, lineWidth: lineWidth)
            drawPointer(ctx: ctx, center: center, radius: radius, lineWidth: lineWidth)
        }
    }
    
    private func drawTicks(ctx: GraphicsContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        for i in 0..<24 {
            let frac: Double = Double(i) / 24.0
            let angle: Double = frac * 2.0 * .pi - (.pi / 2.0)
            let innerR: CGFloat = radius - lineWidth / 2.0 - 10.0
            let outerR: CGFloat = radius - lineWidth / 2.0 - 4.0
            
            let x1: CGFloat = center.x + CGFloat(cos(angle)) * innerR
            let y1: CGFloat = center.y + CGFloat(sin(angle)) * innerR
            let x2: CGFloat = center.x + CGFloat(cos(angle)) * outerR
            let y2: CGFloat = center.y + CGFloat(sin(angle)) * outerR
            
            var path = Path()
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x2, y: y2))
            
            let isMajor = (i % 6 == 0)
            let color = isMajor ? Color.primary.opacity(0.8) : Color.primary.opacity(0.2)
            ctx.stroke(path, with: .color(color), lineWidth: isMajor ? 2.0 : 1.0)
        }
    }
    
    private func drawArcs(ctx: GraphicsContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        for b in blocks {
            let startRad: Double = (b.start / 24.0) * 2.0 * .pi - (.pi / 2.0)
            let endRad: Double = (b.end / 24.0) * 2.0 * .pi - (.pi / 2.0)
            
            var path = Path()
            path.addArc(center: center, radius: radius, startAngle: Angle(radians: startRad), endAngle: Angle(radians: endRad), clockwise: false)
            
            let arcColor: Color
            switch b.type {
            case .sleep:
                arcColor = Color(hex: "18181B")
            case .focus:
                arcColor = Color(hex: "FFE500")
            case .routine:
                arcColor = Color(hex: "E4E4E7")
            }
            
            ctx.stroke(path, with: .color(arcColor), lineWidth: lineWidth)
        }
    }
    
    private func drawPointer(ctx: GraphicsContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        let now = Date()
        let cal = Calendar.current
        let hour = Double(cal.component(.hour, from: now)) + Double(cal.component(.minute, from: now)) / 60.0
        let curAngle: Double = (hour / 24.0) * 2.0 * .pi - (.pi / 2.0)
        
        let pointerR: CGFloat = radius + lineWidth / 2.0 + 4.0
        let px: CGFloat = center.x + CGFloat(cos(curAngle)) * pointerR
        let py: CGFloat = center.y + CGFloat(sin(curAngle)) * pointerR
        
        var dotPath = Path()
        dotPath.addEllipse(in: CGRect(x: px - 3.5, y: py - 3.5, width: 7.0, height: 7.0))
        ctx.fill(dotPath, with: .color(Color.red))
    }
}

// MARK: - Convergence Shift View
struct ConvergenceShiftView: View {
    let year: Int
    
    private let c_gold = Color(hex: "E6A100")
    private let c_green = Color(hex: "34C759")
    private let c_blue = Color(hex: "007AFF")
    private let c_orange = Color(hex: "FF9500")
    private let c_red = Color(hex: "FF3B30")
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 3) {
                    Text("Convergence Shift")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "8E8E93"))
                        .tracking(1.2)
                        .textCase(.uppercase)
                    Text("历年入睡区间收敛演变")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 44)
                
                // Timeline stream
                VStack(spacing: 36) {
                    yearGroup(year: 2026, dotColor: Color(hex: "34C759"), months: mock2026())
                    yearGroup(year: 2025, dotColor: Color(hex: "007AFF"), months: mock2025())
                    yearGroup(year: 2024, dotColor: Color(hex: "FF3B30"), months: mock2024(), isLast: true)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
        }
        .background(Color(hex: "FFFFFF").ignoresSafeArea())
    }
    
    private func yearGroup(year: Int, dotColor: Color, months: [(String, [Color?])], isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Axis
            VStack(spacing: 0) {
                Circle()
                    .stroke(dotColor, lineWidth: 2)
                    .background(Circle().fill(Color.white))
                    .frame(width: 9, height: 9)
                    .padding(.top, 12)
                    .zIndex(2)
                
                if !isLast {
                    Rectangle()
                        .fill(Color(hex: "E5E5EA"))
                        .frame(width: 1)
                        .padding(.bottom, -36)
                        .zIndex(1)
                } else {
                    Spacer()
                }
            }
            .frame(width: 18)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Year placed above 12
                Text(String(year))
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                if year == 2026 {
                    scaleHeaderView
                        .padding(.top, 4)
                }
                
                // Months
                VStack(spacing: 8) {
                    ForEach(months.indices, id: \.self) { idx in
                        let monthData = months[idx]
                        HStack(spacing: 8) {
                            Text(monthData.0)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "8E8E93"))
                                .frame(width: 24, alignment: .leading)
                            
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { cellIdx in
                                    RoundedRectangle(cornerRadius: 2.5)
                                        .fill(monthData.1[cellIdx] ?? Color(hex: "F2F2F7"))
                                        .frame(height: 7)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .frame(height: 16)
                    }
                }
            }
            .padding(.leading, 8)
        }
    }
    
    private var scaleHeaderView: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 32)
            HStack(spacing: 4) {
                let times = ["22:30", "23:00", "00:00", "01:00", "02:00+"]
                let colors: [Color] = [c_gold, c_green, c_blue, c_orange, c_red]
                ForEach(0..<times.count, id: \.self) { idx in
                    VStack(spacing: 6) {
                        Text(times[idx])
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.primary)
                        
                        ZStack(alignment: .bottom) {
                            Rectangle().fill(colors[idx]).frame(width: 2.5, height: 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if idx == times.count - 1 {
                                Rectangle().fill(colors[idx]).frame(width: 2.5, height: 8)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .overlay(
                Rectangle().frame(height: 1).foregroundColor(Color.primary.opacity(0.3)),
                alignment: .bottom
            )
        }
        .padding(.bottom, 10)
    }
    
    private func mock2026() -> [(String, [Color?])] {
        return [
            ("12", [nil, c_green, nil, nil, nil]),
            ("11", [nil, c_green, nil, nil, nil]),
            ("10", [c_gold, nil, nil, nil, nil]),
            ("09", [nil, c_green, nil, nil, nil]),
            ("08", [nil, c_green, nil, nil, nil]),
            ("07", [nil, c_green, nil, nil, nil]),
            ("06", [c_gold, nil, nil, nil, nil]),
            ("05", [nil, c_green, nil, nil, nil]),
            ("04", [nil, c_green, nil, nil, nil]),
            ("03", [nil, c_green, nil, nil, nil]),
            ("02", [nil, c_green, nil, nil, nil]),
            ("01", [c_gold, nil, nil, nil, nil])
        ]
    }
    
    private func mock2025() -> [(String, [Color?])] {
        return [
            ("12", [nil, c_green, nil, nil, nil]),
            ("11", [nil, c_green, c_blue, nil, nil]),
            ("10", [nil, c_green, c_blue, nil, nil]),
            ("09", [nil, c_green, c_blue, nil, nil]),
            ("08", [nil, nil, c_blue, c_orange, nil]),
            ("07", [nil, nil, c_blue, c_orange, nil]),
            ("06", [nil, nil, c_blue, c_orange, nil]),
            ("05", [nil, c_green, c_blue, nil, nil]),
            ("04", [nil, c_green, c_blue, nil, nil]),
            ("03", [nil, nil, c_blue, c_orange, nil]),
            ("02", [nil, nil, c_blue, c_orange, nil]),
            ("01", [nil, nil, c_blue, c_orange, nil])
        ]
    }
    
    private func mock2024() -> [(String, [Color?])] {
        return [
            ("12", [nil, nil, c_blue, c_orange, nil]),
            ("11", [nil, nil, c_blue, c_orange, nil]),
            ("10", [nil, nil, c_blue, c_orange, c_red]),
            ("09", [nil, nil, nil, c_orange, c_red]),
            ("08", [nil, nil, c_blue, c_orange, c_red]),
            ("07", [nil, nil, nil, c_orange, c_red]),
            ("06", [nil, nil, c_blue, c_orange, c_red]),
            ("05", [nil, nil, c_blue, c_orange, nil]),
            ("04", [nil, nil, c_blue, c_orange, nil]),
            ("03", [nil, nil, c_blue, c_orange, c_red]),
            ("02", [nil, nil, nil, c_orange, c_red]),
            ("01", [nil, nil, c_blue, c_orange, nil])
        ]
    }
}

// MARK: - Dial Scale View (刻度风铃盘)
struct DialScaleView: View {
    var body: some View {
        VStack {
            // Ticks Arc only
            ZStack(alignment: .top) {
                Color.clear.frame(height: 80)
                ZStack {
                    ForEach(0..<41, id: \.self) { i in
                        let isMajor = i % 5 == 0
                        let isBright = i == 5 // 模拟发光刻度
                        
                        let tickColor: Color = isBright ? .primary : (isMajor ? Color.primary.opacity(0.6) : Color.primary.opacity(0.3))
                        
                        Rectangle()
                            .fill(tickColor)
                            .frame(width: isBright ? 3 : 2, height: isMajor ? 16 : 10)
                            .shadow(color: isBright ? Color.primary.opacity(0.9) : .clear, radius: 4, x: 0, y: 0)
                            .offset(y: -220)
                            .rotationEffect(.degrees(Double(i - 20) * 1.5))
                    }
                }
                .offset(y: 220)
            }
            .frame(height: 80)
            .clipped()
        }
        .padding(.vertical, 20)
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
