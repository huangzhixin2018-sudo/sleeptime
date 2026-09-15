import SwiftUI
import UIKit

struct PlanStageCarouselView: View {
    let totalDays: Int
    let currentDay: Int
    
    @State private var scrolledDay: Int?

    private var displayedDay: Int {
        scrolledDay ?? currentDay
    }
    
    var body: some View {
        VStack(spacing: 0) {
            stageScroller
            .frame(height: 150)
            .onAppear {
                if scrolledDay == nil {
                    scrolledDay = currentDay
                }
            }
            
            dayDescription
            .padding(.top, -20) // Pull text up and reduce layout spacing
            .animation(.easeInOut, value: displayedDay)
        }
        .padding(.vertical, 16)
    }

    private var stageScroller: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 45) {
                    ForEach(1...totalDays, id: \.self) { day in
                        StageItemView(day: day, currentDay: currentDay)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.25 : 0.8)
                                    .opacity(phase.isIdentity ? 1.0 : 0.4)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledDay)
            .scrollClipDisabled()
            .contentMargins(.horizontal, geometry.size.width / 2 - 45, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .onChange(of: scrolledDay) { oldValue, newValue in
                if oldValue != newValue && newValue != nil {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }

    private var dayDescription: some View {
        let info = getDayInfo(for: displayedDay)

        return VStack(spacing: 12) {
            Text(info.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text(info.subtitle)
                .font(.system(size: displayedDay == currentDay ? 18 : 16, weight: displayedDay == currentDay ? .bold : .medium))
                .foregroundColor(info.subtitleColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }
    
    @AppStorage("activePlanType") private var activePlanType = "streak"
    
    // 模拟数据逻辑（后续可以替换为真实的计划数据）
    private func getDayInfo(for day: Int) -> (title: String, subtitle: String, subtitleColor: Color) {
        let themeColor = Color(red: 120/255, green: 130/255, blue: 150/255) // 大气沉稳的灰蓝色
        let highlightColor = Color(red: 102/255, green: 137/255, blue: 226/255) // 品牌蓝
        
        if day == 2 {
            return ("实际 25:30", "接纳偶尔的失控，然后重新找回方向。", themeColor)
        } else if day > currentDay {
            return ("目标 24:30", "真正的平静，来源于对时间的掌控。", themeColor)
        } else if day == currentDay {
            return ("23:30 准备 — 目标 24:45", "改变，从一次选择开始", highlightColor)
        } else {
            return ("实际 24:15", "每一次自律，都在雕刻更自由的自己。", themeColor)
        }
    }
}

struct StageItemView: View {
    let day: Int
    let currentDay: Int
    
    @AppStorage("activePlanType") private var activePlanType = "streak"
    
    var body: some View {
        ZStack {
            let isFuture = day > currentDay
            let isToday = day == currentDay
            let baseColor = isFuture ? Color(white: 0.95) : Color(red: 230/255, green: 238/255, blue: 254/255)
            let shadowColor = isFuture ? Color.black.opacity(0.05) : Color(red: 230/255, green: 238/255, blue: 254/255).opacity(0.5)
            let strokeColor = isFuture ? Color.gray.opacity(0.2) : Color(red: 102/255, green: 137/255, blue: 226/255).opacity(isToday ? 0.8 : 0.3)

            Circle()
                .fill(baseColor)
                .shadow(color: shadowColor, radius: isToday ? 8 : 4, x: 0, y: isToday ? 4 : 2)
                .overlay(
                    Circle()
                        .strokeBorder(strokeColor, lineWidth: isToday ? 3 : 1.5)
                )

            VStack(spacing: 2) {
                StageFishArtwork(day: day, currentDay: currentDay)
                    .frame(height: 54)

                Text("\(day)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 140/255, green: 160/255, blue: 210/255))
            }
            .offset(y: 2) // slightly shift down to balance the visual center
        }
        .frame(width: 90, height: 90)
    }
}

private struct StageFishArtwork: View {
    let day: Int
    let currentDay: Int

    @AppStorage("activePlanType") private var activePlanType = "streak"

    private var gradient: LinearGradient {
        if activePlanType == "fish" {
            return LinearGradient(
                colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(red: 0.4, green: 0.5, blue: 0.8), Color(red: 0.2, green: 0.3, blue: 0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    var body: some View {
        if day == 2 {
            Image("cat_paw")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.black.opacity(0.8))
                .shadow(color: Color.black.opacity(0.15), radius: 3, y: 1)
                .padding(8)
        } else if day > currentDay {
            inactiveFish(name: "custom_fish", opacity: 0.3)
                .grayscale(1.0) // 去色变灰，表示未解锁
        } else if day == currentDay {
            activeFish(shadowOpacity: 0.4, radius: 6, y: 3)
        } else {
            activeFish(shadowOpacity: 0.3, radius: 4, y: 2)
        }
    }

    private func activeFish(shadowOpacity: Double, radius: CGFloat, y: CGFloat) -> some View {
        Image("custom_fish")
            .resizable()
            .scaledToFit()
            .shadow(color: Color(red: 0.2, green: 0.3, blue: 0.6).opacity(shadowOpacity), radius: radius, x: 0, y: y)
            .padding(.horizontal, 4)
    }

    private func inactiveFish(name: String, opacity: Double) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .opacity(opacity)
            .padding(.horizontal, 4)
    }
}
