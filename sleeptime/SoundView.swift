import SwiftUI

private struct SoundTrack: Identifiable {
    var id: String { trackNumber + title }
    let trackNumber: String
    let title: String
    let color: Color
}

private struct MoodCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SoundView: View {
    private let bgColor = Color(red: 0.07, green: 0.13, blue: 0.20) // Midnight Dark Blue

    // 主题切换状态
    @AppStorage("selectedSoundThemeIndex") private var selectedThemeIndex = 0
    @State private var showingThemeSelection = false

    // 分类模块
    private let categories = ["睡眠", "声音", "冥想", "心境"]
    @State private var selectedCategory = "睡眠"

    private let sleepTracks = [
        SoundTrack(trackNumber: "01", title: "窗外淅沥", color: Color(red: 0.15, green: 0.20, blue: 0.30)), // 幽暗的雨夜蓝
        SoundTrack(trackNumber: "02", title: "晚班列车", color: Color(red: 0.22, green: 0.22, blue: 0.25)), // 铁轨的深灰色
        SoundTrack(trackNumber: "03", title: "炉火噼啪", color: Color(red: 0.45, green: 0.20, blue: 0.10)), // 温暖的暗橙/棕色
        SoundTrack(trackNumber: "04", title: "盛夏旧风扇", color: Color(red: 0.18, green: 0.28, blue: 0.25)) // 复古的暗青色
    ]

    private let soundTracks = [
        SoundTrack(trackNumber: "01", title: "夏日蝉鸣", color: Color(red: 0.25, green: 0.35, blue: 0.20)), // 森林绿
        SoundTrack(trackNumber: "02", title: "海浪拍岸", color: Color(red: 0.10, green: 0.30, blue: 0.45)), // 深海蓝
        SoundTrack(trackNumber: "03", title: "山涧清泉", color: Color(red: 0.20, green: 0.40, blue: 0.35)), // 溪流青
        SoundTrack(trackNumber: "04", title: "老式电视", color: Color(red: 0.30, green: 0.30, blue: 0.35))  // 噪点灰
    ]

    private let meditationTracks = [
        SoundTrack(trackNumber: "01", title: "清晨正念", color: Color(red: 0.40, green: 0.30, blue: 0.45)), // 晨曦紫
        SoundTrack(trackNumber: "02", title: "深度放松", color: Color(red: 0.20, green: 0.25, blue: 0.35)), // 宁静蓝
        SoundTrack(trackNumber: "03", title: "呼吸法", color: Color(red: 0.35, green: 0.45, blue: 0.40)),   // 柔和绿
        SoundTrack(trackNumber: "04", title: "入眠引导", color: Color(red: 0.15, green: 0.15, blue: 0.25))   // 暗夜紫
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                let currentTheme = soundThemes[selectedThemeIndex < soundThemes.count ? selectedThemeIndex : 0]
                
                // 顶部：文案与右侧声音库图标的组合
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        // 将标题作为主题切换入口
                        Button(action: {
                            showingThemeSelection = true
                        }) {
                            HStack(spacing: 8) {
                                Text(currentTheme.title)
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText())
                                    .animation(.easeInOut, value: selectedThemeIndex)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.top, 2)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .sheet(isPresented: $showingThemeSelection) {
                            SoundThemeSelectionView(selectedThemeIndex: $selectedThemeIndex)
                        }

                        Spacer()

                        // 右侧声音库图标
                        NavigationLink(destination: SoundLibraryDetailView()) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    
                    Text(currentTheme.content)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(10)
                        .multilineTextAlignment(.leading)
                        .animation(.easeInOut, value: selectedThemeIndex)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
                
                // 动态分类切换 (胶囊样式横向滚动)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if selectedCategory == category {
                                        Image(systemName: "circle.circle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    Text(category)
                                        .font(.system(size: 14, weight: selectedCategory == category ? .bold : .medium))
                                }
                                .foregroundColor(selectedCategory == category ? .black : .white.opacity(0.9))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == category ? Color.white : Color.clear)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory == category ? Color.clear : Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
                
                // 专属音频列表
                if !currentTracks.isEmpty {
                    VStack(spacing: 24) {
                        ForEach(currentTracks) { track in
                            HStack(spacing: 16) {
                                // Mock Album Art
                                Rectangle()
                                    .fill(track.color)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text(track.title.prefix(1))
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white.opacity(0.5))
                                    )
                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                
                                Text(track.trackNumber)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 28, alignment: .leading)
                                
                                Text(track.title)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                } else if selectedCategory == "心境" {
                    // 心境专有卡片列表
                    VStack(spacing: 20) {
                        // 系统推荐的名言
                        MoodCard(
                            title: "每日箴言",
                            subtitle: "采撷触动灵魂的文字",
                            destination: QuoteOfTheDayView()
                        )

                        // 自己收集的名言
                        MoodCard(
                            title: "心语珍藏",
                            subtitle: "记录你的每一次感悟",
                            destination: MyQuotesView()
                        )
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 60)
            } // end VStack
        } // end ScrollView
        .background(bgColor.ignoresSafeArea())
        .navigationBarHidden(true)
        } // end NavigationStack
        // 使底部 TabBar 适配暗黑模式，并融为一体
        .toolbarBackground(bgColor, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }

    private var currentTracks: [SoundTrack] {
        switch selectedCategory {
        case "睡眠": sleepTracks
        case "声音": soundTracks
        case "冥想": meditationTracks
        default: []
        }
    }
}

struct QuoteOfTheDayView: View {
    @Environment(\.dismiss) private var dismiss
    private let bgColor = Color(red: 0.07, green: 0.13, blue: 0.20)
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                }
                Spacer()
                Text("每日箴言")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.left").opacity(0)
            }
            .padding()
            
            Spacer()
            Text("暂无内容")
                .foregroundColor(.white.opacity(0.6))
            Spacer()
        }
        .background(bgColor.ignoresSafeArea())
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct MyQuotesView: View {
    @Environment(\.dismiss) private var dismiss
    private let bgColor = Color(red: 0.07, green: 0.13, blue: 0.20)
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                }
                Spacer()
                Text("心语珍藏")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.left").opacity(0)
            }
            .padding()
            
            Spacer()
            Text("暂无内容")
                .foregroundColor(.white.opacity(0.6))
            Spacer()
        }
        .background(bgColor.ignoresSafeArea())
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
}



#Preview {
    SoundView()
}
