import SwiftUI

struct ProgressItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let count: Int
}

struct ProgressDetailView: View {
    let progressItems: [ProgressItem] = [
        ProgressItem(title: "睡得比昨天早", subtitle: "入睡时间比前一天更早", count: 3),
        ProgressItem(title: "强大的调整力", subtitle: "熬夜后第二天主动调整，未连续熬夜", count: 2),
        ProgressItem(title: "早睡连胜", subtitle: "连续 3 天以上按计划时间入睡", count: 1)
    ]

    private let pageBackground = Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    private let ink = Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("哪怕只提前了一分钟，也是方向的胜利；\n每一个微小的进步，都在为身体重筑秩序。")
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundStyle(ink.opacity(0.62))
                        .lineSpacing(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.top, 8)

                VStack(spacing: 20) {
                    ForEach(progressItems) { item in
                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(ink.opacity(0.92))
                                
                                Text(item.subtitle)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.black.opacity(0.5))
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(item.count)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(ink)
                                    .monospacedDigit()

                                Text("次")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.black.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(pageBackground.ignoresSafeArea())
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
