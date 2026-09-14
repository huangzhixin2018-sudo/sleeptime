import SwiftUI

struct PlanDualStatsCard: View {
    var body: some View {
        HStack(spacing: 0) {
            // 左半边：日间连胜
            VStack(spacing: 12) {
                // 图标与数字重叠区
                ZStack {
                    // 火焰图标（使用渐变色替代截图的自定义插画）
                    Image(systemName: "flame.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.3, blue: 0.7), Color(red: 0.8, green: 0.7, blue: 1.0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .offset(y: -4)
                    
                    // 衬线体大数字
                    Text("1")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                        .offset(y: 8)
                }
                .frame(height: 60)
                
                Text("日间连胜")
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                
                // 进度条部分
                VStack(spacing: 8) {
                    // 进度条
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(Color(red: 0.45, green: 0.35, blue: 0.75))
                            .frame(width: 80 * (1.0 / 3.0), height: 8) // 假设总宽度80，当前三分之一
                    }
                    .frame(width: 80)
                    
                    Text("1/3天")
                        .font(.system(size: 13))
                        .foregroundColor(Color.gray)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            
            // 中间分割线
            Divider()
                .frame(height: 120)
                .background(Color.gray.opacity(0.1))
            
            // 右半边：完工
            VStack(spacing: 12) {
                // 图标与数字重叠区
                ZStack {
                    // 水晶球/珍珠图标（用带光泽渐变的圆和星星替代）
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(red: 0.7, green: 0.9, blue: 0.9), Color(red: 0.2, green: 0.5, blue: 0.5)],
                                    center: .topLeading,
                                    startRadius: 5,
                                    endRadius: 35
                                )
                            )
                            .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.5).opacity(0.3), radius: 5, x: 0, y: 3)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .offset(x: -8, y: -10)
                    }
                    .frame(width: 48, height: 48)
                    .offset(y: -4)
                    
                    // 衬线体大数字
                    Text("0")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                        .offset(y: 8)
                }
                .frame(height: 60)
                
                Text("完工")
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                
                // 进度条部分
                VStack(spacing: 8) {
                    // 进度条
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                            .frame(height: 8)
                        
                        // 进度为0，所以没有紫色填充层
                    }
                    .frame(width: 80)
                    
                    Text("0/1任务")
                        .font(.system(size: 13))
                        .foregroundColor(Color.gray)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(24)
        // 给卡片加一点淡淡的阴影，让它看起来浮在背景上
        .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        Color(red: 0.97, green: 0.97, blue: 0.98).ignoresSafeArea()
        PlanDualStatsCard()
            .padding()
    }
}
