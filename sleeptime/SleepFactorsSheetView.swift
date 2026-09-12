import SwiftUI

struct SleepFactorItem: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let name: String
}

struct SleepFactorCategory: Identifiable {
    let id = UUID()
    let title: String
    let isPro: Bool
    let items: [SleepFactorItem]
}

struct SleepFactorsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedItems: Set<String>
    
    let categories: [SleepFactorCategory] = [
        SleepFactorCategory(title: "饮食", isPro: false, items: [
            SleepFactorItem(icon: "🍸", name: "喝酒"),
            SleepFactorItem(icon: "☕️", name: "咖啡和茶"),
            SleepFactorItem(icon: "🧋", name: "奶茶"),
            SleepFactorItem(icon: "🍗", name: "吃撑了")
        ]),
        SleepFactorCategory(title: "心情", isPro: false, items: [
            SleepFactorItem(icon: "😋", name: "开心"),
            SleepFactorItem(icon: "🤩", name: "兴奋"),
            SleepFactorItem(icon: "🥰", name: "感受爱意"),
            SleepFactorItem(icon: "😞", name: "沮丧"),
            SleepFactorItem(icon: "😰", name: "焦虑")
        ]),
        SleepFactorCategory(title: "生活", isPro: true, items: [
            SleepFactorItem(icon: "🧑‍💻", name: "加班"),
            SleepFactorItem(icon: "🩸", name: "月经期"),
            SleepFactorItem(icon: "🎮", name: "打游戏"),
            SleepFactorItem(icon: "🧘‍♀️", name: "冥想"),
            SleepFactorItem(icon: "💭", name: "做梦"),
            SleepFactorItem(icon: "🤧", name: "生病了")
        ])
    ]
    
    var body: some View {
        let homeBackground = Color(red: 243.0 / 255.0, green: 244.0 / 255.0, blue: 246.0 / 255.0)
        ZStack {
            // Background blur or color
            homeBackground.ignoresSafeArea()
            
            // Abstract colorful blobs for background
            Circle()
                .fill(Color.pink.opacity(0.15))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color.yellow.opacity(0.15))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: 150, y: 100)
                
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("记录熬夜原因")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        ForEach(categories) { category in
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 8) {
                                    Text(category.title)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color.black.opacity(0.8))
                                    
                                    if category.isPro {
                                        Text("PRO")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                FlowLayout(spacing: 12, lineSpacing: 12) {
                                    ForEach(category.items) { item in
                                        let isSelected = selectedItems.contains(item.name)
                                        
                                        Button(action: {
                                            if isSelected {
                                                selectedItems.remove(item.name)
                                            } else {
                                                selectedItems.insert(item.name)
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Text(item.icon)
                                                    .font(.system(size: 16))
                                                Text(item.name)
                                                    .font(.system(size: 15, weight: .medium))
                                            }
                                            .foregroundColor(isSelected ? .white : .black.opacity(0.7))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(isSelected ? Color.black : Color.white)
                                            .clipShape(Capsule())
                                            .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.05), radius: 5, x: 0, y: 2)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            
            VStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Text("保存")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0), homeBackground]), startPoint: .top, endPoint: .bottom)
                        .frame(height: 100)
                        .offset(y: 20)
                )
            }
        }
    }
}

struct SleepFactorsSheetView_Previews: PreviewProvider {
    static var previews: some View {
        SleepFactorsSheetView(selectedItems: .constant([]))
    }
}
