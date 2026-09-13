import SwiftUI

struct SoundTrack: Identifiable {
    let id = UUID()
    let trackNumber: String
    let title: String
    let color: Color
}

struct SoundView: View {
    private let bgColor = Color(red: 0.07, green: 0.13, blue: 0.20) // Midnight Dark Blue
    
    // 分类模块
    let categories = ["睡眠", "冥想", "声音", "呼吸"]
    @State private var selectedCategory = "声音"
    
    let tracks = [
        SoundTrack(trackNumber: "01", title: "Heartbeat", color: Color(red: 0.2, green: 0.1, blue: 0.05)),
        SoundTrack(trackNumber: "02", title: "Lover's Spit", color: Color(red: 0.6, green: 0.7, blue: 0.8)),
        SoundTrack(trackNumber: "03", title: "Wait", color: Color(red: 0.25, green: 0.35, blue: 0.25)),
        SoundTrack(trackNumber: "04", title: "Sunrise", color: Color(red: 0.8, green: 0.7, blue: 0.6))
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                
                // 顶部：设置图标
                HStack {
                    Spacer()
                    
                    Button(action: {
                        // Open settings
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16) // 修正：移除多余的60pt，直接贴近安全区顶部
                .padding(.bottom, 16)
                
                // 情绪签名文案
                VStack(alignment: .leading, spacing: 16) {
                    Text("周末治愈空间")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("这套歌单专为居家专注而设计，融合了温暖的卧室流行与轻快独立流行，用温柔的律动陪伴你度过一个惬意的上午。")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(6)
                }
                .padding(.horizontal, 24)
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
                        
                        // 自定义添加分类按钮
                        Button(action: {
                            // Add category action
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text("分类")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
                
                // 专属音频列表
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
