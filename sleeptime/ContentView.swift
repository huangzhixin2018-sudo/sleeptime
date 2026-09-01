//
//  ContentView.swift
//  sleeptime
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
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
            
            SleepProgressView()
            .tabItem {
                Label("计划", systemImage: "star.fill")
            }
            
            ProfileView()
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
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
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // 标题区 (去掉返回箭头)
                    VStack(alignment: .leading, spacing: 8) {
                    Text("夜猫子改造营")
                        .font(.system(size: 28, weight: .black))
                        .tracking(-0.5) // 字距微调，更紧凑
                        .foregroundColor(.primary)
                        .overlay(
                            WavyLine()
                                .stroke(Color(red: 0.2, green: 0.75, blue: 0.4), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                                .frame(height: 7)
                                .padding(.leading, 2)
                                .padding(.trailing, 32) // 右侧留出大约一个字的宽度，避开“营”字
                                .offset(y: 16)
                            , alignment: .bottom
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // 计划目标卡片
                HStack(spacing: 16) {
                    TargetCardView(
                        title: "最晚入睡时间",
                        value: "2:00",
                        unit: "",
                        themeColor: Color(red: 0.82, green: 0.89, blue: 0.96), // 极低饱和度的婴儿蓝
                        rotationAngle: -2
                    )
                    
                    TargetCardView(
                        title: "最长连续熬夜",
                        value: "5",
                        unit: "天",
                        themeColor: Color(red: 0.82, green: 0.95, blue: 0.84), // 极低饱和度的薄荷绿
                        rotationAngle: 2
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16) // 距离上方卡片的间距
                
                // 单日记录卡片
                DayRecordCardView()
                    .padding(.top, 16)
                
                // 作息漂移刻度尺
                SleepTrendView()
                    .padding(.top, 24)
                
                Divider()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    
                // 入睡轨迹分布
                SleepDistributionView()
                    .padding(.top, 24)

                // 承诺追踪卡片 (说到做到 vs 破戒)
                HabitStreakView()
                    .padding(.top, 16)
                
                Spacer()
            }
            .padding(.bottom, 40) // 底部留白，防止滚动到底部时贴边
            }
        }
    }
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
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色：保持我们的燕麦白
                Color(red: 0.98, green: 0.97, blue: 0.95).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 独立卡片：睡眠追踪
                        NavigationLink(destination: SleepTrackingDetailView()) {
                            ProfileRowView(icon: "chart.xyaxis.line", title: "睡眠追踪", showDivider: false)
                        }
                        .buttonStyle(.plain)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        
                        // 分组卡片：设置组
                        VStack(spacing: 0) {
                            NavigationLink(destination: AnnualGoalView()) {
                                ProfileRowView(icon: "gearshape", title: "年度目标", showDivider: false)
                            }
                            .buttonStyle(.plain)
                            ProfileRowView(icon: "calendar", title: "日期设置", showDivider: false)
                            ProfileRowView(icon: "tag", title: "标签管理", showDivider: false)
                            ProfileRowView(icon: "icloud", title: "iCloud 备份", trailingText: "未备份", showDivider: false)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        
                        // 分组卡片：偏好组
                        VStack(spacing: 0) {
                            ProfileRowView(icon: "bell", title: "通知", trailingText: "未开启", showDivider: false)
                            ProfileRowView(icon: "globe", title: "语言", trailingText: "简体中文", showDivider: false)
                            ProfileRowView(icon: "paintbrush", title: "主题外观", trailingText: "浅色模式", showDivider: false)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 设置动作
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct ProfileRowView: View {
    let icon: String
    let title: String
    var trailingText: String? = nil
    let showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.primary)
                    .frame(width: 24) // 统一图标宽度以便文字对齐
                
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let trailingText = trailingText {
                    Text(trailingText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .contentShape(Rectangle()) // 保证整行可点击
            
            if showDivider {
                Divider()
                    .padding(.leading, 60) // 分割线与文字左对齐
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
            
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
        // 保留微微的倾斜，打破死板
        .rotationEffect(.degrees(rotationAngle))
        // 稍微加一点阴影增加层次感
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
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

struct HabitStreakView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题区
            VStack(alignment: .leading, spacing: 6) {
                Text("规律记录")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            
            // 横向滑动的卡片列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 高亮激活的卡片 (对应截图左侧白色卡片)
                    HabitCard(
                        title: "早睡",
                        icon: "moon.stars.fill",
                        count: "3天",
                        dateRange: "8.29 - 8.31",
                        isActive: true,
                        themeColor: Color(red: 0.95, green: 0.77, blue: 0.2) // 明黄色
                    )
                    
                    // 黑色未激活卡片 (对应截图右侧黑色卡片)
                    HabitCard(
                        title: "熬夜",
                        icon: "flame.fill",
                        count: "2天",
                        dateRange: "8.25 - 8.26",
                        isActive: false,
                        themeColor: Color(red: 0.95, green: 0.4, blue: 0.2) // 橘红色
                    )
                    
                    HabitCard(
                        title: "起床",
                        icon: "alarm.fill",
                        count: "2天",
                        dateRange: "8.22 - 8.23",
                        isActive: false,
                        themeColor: Color(red: 0.2, green: 0.8, blue: 0.5) // 翠绿色
                    )
                    
                    HabitCard(
                        title: "午休",
                        icon: "zzz",
                        count: "1天",
                        dateRange: "8.21",
                        isActive: false,
                        themeColor: Color(red: 0.3, green: 0.6, blue: 0.9) // 亮蓝色
                    )
                }
                .padding(.horizontal, 16)
                // 左右边缘留白
            }
        }
    }
}

struct HabitCard: View {
    let title: String
    let icon: String
    let count: String
    let dateRange: String
    let isActive: Bool
    let themeColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 左上角徽章 (全员继承第一张卡片的黑色粗边框+主题色底)
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                Text(title)
                    .font(.system(size: 15, weight: .heavy))
            }
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
        }
        .padding(16)
        .frame(width: 140, height: 150, alignment: .topLeading)
        .background(Color.white) // 统一采用干净的纯白底色
        .cornerRadius(24)
        // 统一加上淡淡的阴影，从燕麦色背景中浮现出来
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - 作息漂移趋势 (刻度尺)

struct SleepTrendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // 刻度尺区域 (带时间的高级刻度)
            GeometryReader { geo in
                let tickCount = 11 // 缩减为 11 根线：每小时只分两格（整点和半点），避免太密
                let totalIntervals = tickCount - 1
                let itemWidth: CGFloat = 20 // 加宽一点
                let stepWidth = (geo.size.width - itemWidth) / CGFloat(totalIntervals)
                
                VStack(spacing: 8) {
                    // 上半部：刻度线和彩色横轴 (底部对齐)
                    ZStack(alignment: .bottomLeading) {
                        // 1. 绘制一条贯穿的彩色横轴
                        HStack(spacing: 0) {
                            // 共 5 个小时区间 (21-22, 22-23, 23-00, 00-01, 01-02)
                            ForEach(0..<5, id: \.self) { i in
                                let hour = (21 + i) % 24
                                Rectangle()
                                    .fill(getZoneColor(for: hour))
                                    .frame(height: 3) // 横轴粗细
                            }
                        }
                        .clipShape(Capsule()) // 两端圆角
                        .padding(.horizontal, itemWidth / 2) // 横轴从第一个刻度中心连到最后一个刻度中心
                        
                        // 2. 竖向刻度线 (长在横轴上方)
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(0..<tickCount, id: \.self) { i in
                                let isMajor = (i % 2 == 0)
                                
                                Rectangle()
                                    .fill(isMajor ? Color(UIColor.secondaryLabel) : Color(UIColor.tertiaryLabel))
                                    .frame(width: isMajor ? 2 : 1.5,
                                           height: isMajor ? 12 : 6)
                                    .frame(width: itemWidth, alignment: .bottom) // 占位保证间距
                                
                                if i < tickCount - 1 {
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        
                        // 3. 悬浮指示点与垂直对齐线
                        let actualPosition: CGFloat = 6.66 // 实际时间 (例如 00:20)
                        
                        let actualX = (itemWidth / 2) + (stepWidth * actualPosition)
                        let axisY: CGFloat = 10.5 // 底轴中心 (ZStack高度12，底轴高度3)
                        let suspendedY: CGFloat = axisY - 36 // 悬浮在轴线上方 36 个 point
                        
                        // 垂直向下对应的虚线
                        Path { path in
                            path.move(to: CGPoint(x: actualX, y: suspendedY + 7)) // 从圆点底部开始
                            path.addLine(to: CGPoint(x: actualX, y: axisY)) // 连到底轴
                        }
                        .stroke(Color(UIColor.tertiaryLabel), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        
                        // 悬浮在空中的指示圆点
                        Circle()
                            .fill(Color(red: 0.98, green: 0.45, blue: 0.52)) // 标志性高亮粉色
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle().stroke(Color(red: 0.98, green: 0.97, blue: 0.95), lineWidth: 3)
                            )
                            .position(x: actualX, y: suspendedY)
                    }
                    // 为了不让悬浮点被切掉，给 ZStack 增加顶部内边距
                    .padding(.top, 40)
                    
                    // 下半部：时间文字
                    HStack(spacing: 0) {
                        ForEach(0..<tickCount, id: \.self) { i in
                            let isMajor = (i % 2 == 0)
                            let hour = (21 + i / 2) % 24
                            let zoneColor = getZoneColor(for: hour)
                            
                            Group {
                                if isMajor {
                                    Text(String(format: "%02d", hour))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(zoneColor)
                                } else {
                                    Text("00").font(.system(size: 12)).hidden()
                                }
                            }
                            .frame(width: itemWidth)
                            
                            if i < tickCount - 1 {
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }
            .frame(height: 70) // 增加整体高度，给超高的抛物线留足天空
            
            // 底部说明文案
            Text("最近两周的有效睡眠记录都不足 4 晚。记录满 4 晚后，会告诉你作息在往哪个方向走。")
                .font(.system(size: 14))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .lineSpacing(6)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
    }
    
    // 区间颜色映射逻辑
    private func getZoneColor(for hour: Int) -> Color {
        switch hour {
        case 21, 22:
            // 11点前：健康睡眠区间 (薄荷绿/青色)
            return Color(red: 0.2, green: 0.8, blue: 0.6)
        case 23:
            // 11点-12点：临界警告区间 (亮橙色/黄色)
            return Color.orange
        case 0:
            // 12点-1点：严重熬夜区间 (粉红色)
            return Color(red: 0.98, green: 0.45, blue: 0.52)
        default:
            // 1点以后：修仙危险区间 (深紫色/黑色)
            return Color.purple
        }
    }
}

// MARK: - 承诺追踪组件 (说到做到 vs 破戒)

struct PromiseTrackingView: View {
    let promise: String
    let successRate: Double // 0.0 to 1.0
    
    var body: some View {
        VStack(spacing: 12) {
            // 顶部聊天气泡
            HStack {
                Spacer()
                
                Text(promise)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .cornerRadius(20)
                    .overlay(
                        // 气泡右下角的小尾巴
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            // 稍微调整一下尾巴的位置，让它看起来更自然地连接
                            .offset(x: -24, y: 10)
                        , alignment: .bottomTrailing
                    )
            }
            .padding(.bottom, 12) // 气泡和下方内容的间距
            
            // 进度条文字标签
            HStack {
                Text("说到做到")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Text("又破戒了")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // 拼接进度条
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: geo.size.width * successRate)
                    
                    Rectangle()
                        .fill(Color(red: 0.98, green: 0.45, blue: 0.52)) // 截图中的浅粉红色
                        .frame(width: geo.size.width * (1.0 - successRate))
                }
                .clipShape(Capsule()) // 整体裁切成胶囊体
            }
            .frame(height: 12)
            
            // 底部百分比大字
            HStack {
                Text("\(Int(successRate * 100))%")
                    .font(.custom("AvenirNext-CondensedBold", size: 28))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int((1.0 - successRate) * 100))%")
                    .font(.custom("AvenirNext-CondensedBold", size: 28))
                    .foregroundColor(Color(red: 0.98, green: 0.45, blue: 0.52))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        // 完全去除白底、圆角和阴影，让它直接浮在燕麦色主背景上
    }
}

// MARK: - 睡眠分布轨迹组件 (积木图)
struct SleepDistributionView: View {
    // 模拟数据：分别对应 提前, 守信, 拖延, 熬夜, 通宵 的天数
    let distribution = [1, 4, 3, 2, 0]
    let maxBlocks = 6
    
    // 配置：标签, 时间段, 积木颜色
    let categories = [
        ("提前", "22-23", Color(red: 0.2, green: 0.8, blue: 0.6)), // 健康绿
        ("守信", "23-00", Color.primary), // 达成目标的黑色实心
        ("拖延", "00-01", Color.orange), // 警告橙
        ("熬夜", "01-02", Color(red: 0.98, green: 0.45, blue: 0.52)), // 严重粉红
        ("通宵", "02后", Color.purple) // 危险紫
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) { // 调整整体纵向间距以匹配其他卡片
            // 标题区
            VStack(alignment: .leading, spacing: 6) {
                Text("入睡轨迹") // 恢复统一命名
                    .font(.system(size: 18, weight: .bold)) // 与规律记录完全一致
                    .foregroundColor(.primary)
                
                Text("习惯是一块块拼出来的。今晚的积木，你想落在哪个区？")
                    .font(.system(size: 14)) // 字号微调，避免抢戏
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineSpacing(4)
            }
            .padding(.horizontal, 16) // 与规律记录的标题左边距一致
            
            // 柱状图区
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<categories.count, id: \.self) { index in
                    let category = categories[index]
                    let count = distribution[index]
                    
                    VStack(spacing: 20) {
                        // 积木块
                        VStack(spacing: 8) {
                            ForEach((0..<maxBlocks).reversed(), id: \.self) { blockIndex in
                                if blockIndex < count {
                                    // 实体块
                                    Capsule()
                                        .fill(category.2)
                                        .frame(width: 44, height: 22)
                                } else {
                                    // 虚线空心块
                                    Capsule()
                                        .stroke(Color(UIColor.tertiaryLabel).opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                        .frame(width: 44, height: 22)
                                }
                            }
                        }
                        
                        // 底部标签
                        VStack(spacing: 6) {
                            Text(category.0)
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.primary)
                            Text(category.1)
                                .font(.custom("AvenirNext-DemiBold", size: 12))
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16) // 与规律记录卡片的左边距一致
        }
        .padding(.vertical, 24)
        // 移除了这里的外层 .padding(.horizontal, 24)，改为内部独立控制 16
    }
}
