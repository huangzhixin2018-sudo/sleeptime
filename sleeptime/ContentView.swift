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
                
                // 核心进度卡片
                VStack(spacing: 0) {
                    // 头部文字 (1:1 像素级复刻截图)
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
                    .padding(.bottom, 12) // 头部与进度条间距收紧
                    
                    // 自定义分段进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 进度条底色
                            Capsule()
                                .fill(Color(UIColor.tertiarySystemGroupedBackground))
                                .frame(height: 12) // 恢复原来的粗度
                            
                            // 进度条激活色 (原生态绿色)
                            Capsule()
                                .fill(Color(red: 0.2, green: 0.75, blue: 0.4))
                                .frame(width: geometry.size.width * (29.0 / 30.0), height: 12) // 恢复原来的粗度
                            
                            // 当前终点：绿边大空心圆
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 20, height: 20) // 恢复大号圆环
                                Circle()
                                    .stroke(Color(red: 0.2, green: 0.75, blue: 0.4), lineWidth: 4)
                                    .frame(width: 20, height: 20)
                            }
                            .position(x: geometry.size.width, y: 7.5) // 恢复微下调的位置
                        }
                    }
                    .frame(height: 24)
                    
                    // 底部刻度
                    GeometryReader { geometry in
                        let stepWidth = geometry.size.width / 5
                        ZStack {
                            Text("0").position(x: 0, y: 7)
                            Text("6").position(x: stepWidth * 1, y: 7)
                            Text("12").position(x: stepWidth * 2, y: 7)
                            Text("18").position(x: stepWidth * 3, y: 7)
                            Text("24").position(x: stepWidth * 4, y: 7)
                            Text("30").position(x: stepWidth * 5, y: 7)
                        }
                        .font(.custom("AvenirNext-Medium", size: 12)) // 刻度数字缩小到辅助级别
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                    .frame(height: 14)
                    .padding(.top, 4) // 与进度条紧密贴合
                }
                .padding(.vertical, 16) // 上下内边距极限压缩
                .padding(.horizontal, 16) // 左右内边距压缩
                .background(Color(.systemBackground))
                .cornerRadius(16) // 圆角稍微缩小，匹配更扁的卡片
                .padding(.horizontal, 16)
                
                Spacer()
            }
        }
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
                            ProfileRowView(icon: "gearshape", title: "高级设置", showDivider: false)
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
