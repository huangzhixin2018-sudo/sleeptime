import SwiftUI

struct ProgressItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let count: Int
    let icon: String
    let color: Color
}

struct ProgressDetailView: View {
    let progressItems: [ProgressItem] = [
        ProgressItem(title: "睡得比昨天早", subtitle: "睡眠时间正在逐步向前推移", count: 3, icon: "arrow.up.left.circle.fill", color: .blue),
        ProgressItem(title: "强大的调整力", subtitle: "熬夜后第二天主动调整，未连续熬夜", count: 2, icon: "arrow.uturn.up.circle.fill", color: .green),
        ProgressItem(title: "早睡连胜", subtitle: "连续3天以上按计划时间早睡", count: 1, icon: "flame.fill", color: .red)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                
                // 顶部文案 (无卡片背景)
                VStack(alignment: .leading, spacing: 0) {
                    Text("哪怕只提前了一分钟，也是方向的胜利；\n每一个微小的进步，都在为身体重筑秩序。")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundColor(.black.opacity(0.6))
                        .lineSpacing(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // 进步表现列表
                VStack(spacing: 20) {
                    ForEach(progressItems) { item in
                        HStack(spacing: 16) {
                            
                            // 中间文案
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black.opacity(0.85))
                                
                                Text(item.subtitle)
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                                    .lineSpacing(4)
                            }
                            
                            Spacer()
                            
                            // 右侧次数统计
                            VStack(spacing: 4) {
                                Text("\(item.count)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(item.color)
                                Text("次")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 50)
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 6)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97).ignoresSafeArea())
        .navigationTitle("进步")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProgressDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProgressDetailView()
        }
    }
}
