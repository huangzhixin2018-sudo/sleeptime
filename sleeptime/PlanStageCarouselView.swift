import SwiftUI

struct PlanStageCarouselView: View {
    let totalDays: Int
    let currentDay: Int
    
    var body: some View {
        VStack(spacing: 20) {
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(1...totalDays, id: \.self) { day in
                            StageItemView(day: day, isCurrent: day == currentDay)
                                .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                    content
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.7)
                                        // 提高未选中状态的透明度，避免看不见
                                        .opacity(phase.isIdentity ? 1.0 : 0.6)
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, geometry.size.width / 2 - 40, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
            }
            .frame(height: 90) // 给足够的高度容纳放大后的多边形
            
            // 下方文字
            VStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 1.0))
                    .frame(width: 32, height: 32)
                    .background(Color(red: 0.95, green: 0.94, blue: 0.98))
                    .clipShape(Circle())
                
                Text("\(totalDays) days")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .tracking(1)
            }
        }
        .padding(.vertical, 16)
        // 移除了白色/灰色的底层卡片背景，让它自然融入父视图
    }
}

struct StageItemView: View {
    let day: Int
    let isCurrent: Bool
    
    var body: some View {
        ZStack {
            // 使用六边形作为底板，并加上高级的渐变色
            Image(systemName: "hexagon.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.6, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(90)) // 旋转一下让六边形平放
                .shadow(color: Color(red: 0.4, green: 0.3, blue: 0.9).opacity(0.3), radius: 8, x: 0, y: 5)
            
            // 内部文案：显示第几天，或者一个星星
            VStack(spacing: 2) {
                Text("Day")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Text("\(day)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 80, height: 80)
    }
}
