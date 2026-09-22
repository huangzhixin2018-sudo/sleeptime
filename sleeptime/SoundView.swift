import SwiftUI
import UIKit

private struct SoundTrack: Identifiable {
    var id: String { trackNumber + title }
    let trackNumber: String
    let title: String
    let color: Color
}

private struct MoodCard<Destination: View>: View {
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility

    let title: String
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
                .sleepDetailChrome(tabBarVisibility)
        } label: {
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .frame(height: 112)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white)
                )
                .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SoundView: View {
    private let bgColor = Color(red: 0.945, green: 0.95, blue: 0.957)

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
                
                // 顶部文案
                VStack(alignment: .leading, spacing: 20) {
                    Text("听见自己的声音")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("世界有太多声音，教导我们该如何生活。与其向外寻找答案，不如停下来听听自己。你内心细微的情绪与感受，都在告诉你，什么才是真正重要的。")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black.opacity(0.75))
                        .lineSpacing(8)
                        .multilineTextAlignment(.leading)
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
                                .foregroundColor(selectedCategory == category ? .white : .black.opacity(0.9))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == category ? Color.black : Color.clear)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory == category ? Color.clear : Color.black.opacity(0.3), lineWidth: 1)
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
                            if track.title == "呼吸法" {
                                NavigationLink(destination: CreativeBreathingView()) {
                                    trackRow(for: track)
                                }
                            } else {
                                trackRow(for: track)
                            }
                        }
                    }
                } else if selectedCategory == "心境" {
                    // 心境专有卡片列表
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        // 小期待
                        MoodCard(
                            title: "小期待",
                            destination: SmallExpectationsView()
                        )

                        // 系统推荐的名言
                        MoodCard(
                            title: "语录专辑",
                            destination: QuoteAlbumView()
                        )

                        // 自己收集的名言
                        MoodCard(
                            title: "我的语录",
                            destination: MyQuotesView()
                        )

                        // 睡眠札记
                        MoodCard(
                            title: "睡眠札记",
                            destination: EmotionDetailView()
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
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
        .toolbarColorScheme(.light, for: .tabBar)
    }

    private var currentTracks: [SoundTrack] {
        switch selectedCategory {
        case "睡眠": return sleepTracks
        case "声音": return soundTracks
        case "冥想": return meditationTracks
        default: return []
        }
    }
    
    private func trackRow(for track: SoundTrack) -> some View {
        HStack(spacing: 16) {
            // Mock Album Art
            Rectangle()
                .fill(track.color)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(track.title.prefix(1))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black.opacity(0.5))
                )
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            Text(track.trackNumber)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black.opacity(0.6))
                .frame(width: 28, alignment: .leading)
            
            Text(track.title)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.black.opacity(0.9))
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}







#Preview {
    SoundView()
        .environmentObject(SleepTabBarVisibility())
}
