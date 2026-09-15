import SwiftUI

struct PlanDualStatsCard: View {
    @AppStorage("activePlanType") private var activePlanType = "streak"
    
    private var isOceanTheme: Bool {
        activePlanType == "fish"
    }

    var body: some View {
        HStack(spacing: 0) {
            // 左半边：日间连胜
            VStack(spacing: 12) {
                Text("1")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(isOceanTheme ? .blue : Color(red: 0.1, green: 0.1, blue: 0.15))
                    .frame(height: 60)
                
                Text("当前连续早睡")
                    .font(.system(size: 15))
                    .foregroundColor(isOceanTheme ? .blue : .primary)
                
                // 进度条部分
                VStack(spacing: 8) {
                    // 进度条
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(isOceanTheme ? Color.blue.opacity(0.1) : Color(red: 0.93, green: 0.93, blue: 0.95))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(isOceanTheme ? Color.blue : Color(red: 0.45, green: 0.35, blue: 0.75))
                            .frame(width: 80 * (1.0 / 3.0), height: 8) // 假设总宽度80，当前三分之一
                    }
                    .frame(width: 80)
                    
                    Text("1/3天")
                        .font(.system(size: 13))
                        .foregroundColor(isOceanTheme ? Color.blue.opacity(0.6) : Color.gray)
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
                Text("0")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(isOceanTheme ? .blue : Color(red: 0.1, green: 0.1, blue: 0.15))
                    .frame(height: 60)
                
                Text("行动进度")
                    .font(.system(size: 15))
                    .foregroundColor(isOceanTheme ? .blue : .primary)
                
                // 进度条部分
                VStack(spacing: 8) {
                    // 进度条
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(isOceanTheme ? Color.blue.opacity(0.1) : Color(red: 0.93, green: 0.93, blue: 0.95))
                            .frame(height: 8)
                        
                        // 进度为0，所以没有紫色/蓝色填充层
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
