//
//  TimeTravelDetailView.swift
//  sleeptime
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing, lineSpacing: lineSpacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing, lineSpacing: lineSpacing)
        for (index, subview) in subviews.enumerated() {
            let point = result.frames[index].origin
            subview.place(at: CGPoint(x: point.x + bounds.minX, y: point.y + bounds.minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat, lineSpacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + lineSpacing
                    lineHeight = 0
                }
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                maxX = max(maxX, currentX - spacing)
            }
            size = CGSize(width: maxX, height: currentY + lineHeight)
        }
    }
}

struct TimeTravelDetailView: View {
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    let tags = ["吾日三省吾身", "真诚", "不拖延", "不要被同一块石头绊倒两次", "提前计划"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // 卡片说明
                VStack(alignment: .leading, spacing: 16) {
                    Text("「原则库」收集了常见的原则，为您提供灵感，帮助您快速创建新的原则。")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                    
                    Text("点击图标，即可创建新的原则；原则会出现在我的原则列表中。")
                        .font(.system(size: 15))
                        .foregroundColor(Color.secondary)
                        .lineSpacing(4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(12)
                
                // 标签流式布局
                FlowLayout(spacing: 12, lineSpacing: 16) {
                    ForEach(tags, id: \.self) { tag in
                        NavigationLink(destination: PrincipleDetailView(title: tag)) {
                            HStack(spacing: 6) {
                                Text("#")
                                    .font(.system(size: 15, weight: .light))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Text(tag)
                                    .font(.system(size: 16, weight: .medium, design: .serif))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .cornerRadius(24)
                        }
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(20)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97).ignoresSafeArea())
        .navigationTitle("原则库")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TimeTravelDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TimeTravelDetailView()
        }
    }
}
