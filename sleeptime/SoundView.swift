import SwiftUI

struct SoundTrack: Identifiable {
    let id = UUID()
    let trackNumber: String
    let title: String
    let color: Color
}

struct SoundView: View {
    private let bgColor = Color(red: 0.07, green: 0.13, blue: 0.20) // Midnight Dark Blue
    
    // 主题切换状态
    @AppStorage("selectedSoundThemeIndex") private var selectedThemeIndex = 0
    @State private var showingThemeSelection = false
    
    // 分类模块
    let categories = ["睡眠", "声音", "冥想", "心境"]
    @State private var selectedCategory = "睡眠"
    
    let tracks = [
        SoundTrack(trackNumber: "01", title: "窗外淅沥", color: Color(red: 0.15, green: 0.20, blue: 0.30)), // 幽暗的雨夜蓝
        SoundTrack(trackNumber: "02", title: "晚班列车", color: Color(red: 0.22, green: 0.22, blue: 0.25)), // 铁轨的深灰色
        SoundTrack(trackNumber: "03", title: "炉火噼啪", color: Color(red: 0.45, green: 0.20, blue: 0.10)), // 温暖的暗橙/棕色
        SoundTrack(trackNumber: "04", title: "盛夏旧风扇", color: Color(red: 0.18, green: 0.28, blue: 0.25)) // 复古的暗青色
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                
                // 顶部：左侧管理，右侧声音库
                HStack {
                    Button(action: {
                        showingThemeSelection = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .sheet(isPresented: $showingThemeSelection) {
                        SoundThemeSelectionView(selectedThemeIndex: $selectedThemeIndex)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Open sound library
                    }) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                // 情绪签名文案
                let currentTheme = soundThemes[selectedThemeIndex < soundThemes.count ? selectedThemeIndex : 0]
                VStack(alignment: .leading, spacing: 16) {
                    Text(currentTheme.title)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.easeInOut, value: selectedThemeIndex)
                    
                    Text(currentTheme.content)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)
                        .animation(.easeInOut, value: selectedThemeIndex)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20) // 微调间距，让每行能多放一个字
                .padding(.bottom, 32)
                
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
                if selectedCategory == "睡眠" {
                    VStack(spacing: 24) {
                        ForEach(tracks) { track in
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
                } else {
                    // 其他分类暂时显示空白（或者可以放一个空状态提示）
                    VStack {
                        Spacer().frame(height: 80)
                        Text("暂无内容")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Spacer(minLength: 60)
            }
        }
        .background(bgColor.ignoresSafeArea())
        .navigationBarHidden(true)
        // 使底部 TabBar 适配暗黑模式，并融为一体
        .toolbarBackground(bgColor, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    SoundView()
}
