import SwiftUI

struct PlanStageCarouselView: View {
    let totalDays: Int
    let currentDay: Int
    
    @State private var scrolledDay: Int?

    private var displayedDay: Int {
        scrolledDay ?? currentDay
    }
    
    var body: some View {
        VStack(spacing: 20) {
            stageScroller
            .frame(height: 90)
            .offset(y: -8) // 让整排鱼整体上移一点
            .onAppear {
                if scrolledDay == nil {
                    scrolledDay = currentDay
                }
            }
            
            dayDescription
            .padding(.top, 0)
            .animation(.easeInOut, value: displayedDay)
        }
        .padding(.vertical, 16)
    }

    private var stageScroller: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(1...totalDays, id: \.self) { day in
                        StageItemView(day: day, currentDay: currentDay)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.7)
                                    .opacity(phase.isIdentity ? 1.0 : 0.6)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledDay)
            .contentMargins(.horizontal, geometry.size.width / 2 - 40, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var dayDescription: some View {
        let info = getDayInfo(for: displayedDay)

        return VStack(spacing: 8) {
            Text(info.title)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.primary)

            Text(info.subtitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(info.subtitleColor)
        }
    }
    
    // 模拟数据逻辑（后续可以替换为真实的计划数据）
    private func getDayInfo(for day: Int) -> (title: String, subtitle: String, subtitleColor: Color) {
        let themeBlue = Color(red: 0.3, green: 0.4, blue: 0.7)
        if day > currentDay {
            return ("目标 24:30", "真正的平静，来源于对时间的掌控。", themeBlue)
        } else if day == currentDay {
            return ("23:30 准备 — 目标 24:45", "万物皆有回音，包括今夜的早睡。", themeBlue)
        } else {
            let isSuccess = day % 2 != 0
            if isSuccess {
                return ("实际 24:15", "每一次自律，都在雕刻更自由的自己。", themeBlue)
            } else {
                return ("实际 25:30", "接纳偶尔的失控，然后重新找回方向。", themeBlue)
            }
        }
    }
}

struct StageItemView: View {
    let day: Int
    let currentDay: Int
    
    var body: some View {
        ZStack {
            StageFishArtwork(day: day, currentDay: currentDay)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(day)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.primary.opacity(0.7))
                        .padding(5)
                        .background(Color(.systemBackground).opacity(0.95))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .offset(x: 4, y: 4)
                }
            }
        }
        .frame(width: 80, height: 80)
    }
}

private struct StageFishArtwork: View {
    let day: Int
    let currentDay: Int

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.4, green: 0.5, blue: 0.8), Color(red: 0.2, green: 0.3, blue: 0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    var body: some View {
        if day > currentDay {
            inactiveFish(systemName: "fish", opacity: 0.25)
        } else if day == currentDay {
            activeFish(shadowOpacity: 0.4, radius: 6, y: 3)
        } else if day.isMultiple(of: 2) {
            inactiveFish(systemName: "fish.fill", opacity: 0.15)
        } else {
            activeFish(shadowOpacity: 0.3, radius: 4, y: 2)
        }
    }

    private func activeFish(shadowOpacity: Double, radius: CGFloat, y: CGFloat) -> some View {
        Image(systemName: "fish.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(gradient)
            .shadow(color: Color(red: 0.2, green: 0.3, blue: 0.6).opacity(shadowOpacity), radius: radius, x: 0, y: y)
            .padding(16)
    }

    private func inactiveFish(systemName: String, opacity: Double) -> some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .foregroundColor(Color.gray.opacity(opacity))
            .padding(20)
    }
}
