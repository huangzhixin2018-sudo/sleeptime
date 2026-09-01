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
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // 数据总结卡片
                        VStack(alignment: .leading, spacing: 16) {
                            DataRow(label: "quiet hours:", value: "23:30 - 07:30")
                            DataRow(label: "day limit:", value: "8 h")
                            DataRow(label: "current streak:", value: "3 days")
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(24)
                        
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

struct DataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
            
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
            
            Spacer()
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
