import SwiftUI

struct FactorsDetailView: View {
    @State private var factors: [String] = [
        "喝了咖啡",
        "睡前运动过量",
        "卧室太热"
    ]
    @State private var showAddAlert = false
    @State private var newFactor = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    // 放大的标题，放在详情页内容里
                    Text("影响因素")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 10)
                        .padding(.horizontal, 24)

                    // 因素列表
                    VStack(spacing: 16) {
                        ForEach(factors, id: \.self) { factor in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(Color.orange.opacity(0.8))
                                    .font(.system(size: 10))

                                Text(factor)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.black.opacity(0.8))

                                Spacer()
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 100) // 为底部的悬浮按钮留出空间
                }
            }

            // 页面底部的、放大的 + 号按钮
            Button(action: {
                showAddAlert = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.orange.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .padding(.bottom, 40)
        }
        .background(Color(red: 243.0 / 255.0, green: 244.0 / 255.0, blue: 246.0 / 255.0).ignoresSafeArea()) // AppTheme.homeBackground
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("添加影响因素", isPresented: $showAddAlert) {
            TextField("请输入影响睡眠的因素", text: $newFactor)
            Button("取消", role: .cancel) {
                newFactor = ""
            }
            Button("添加") {
                addFactor()
            }
        }
    }

    private func addFactor() {
        let factor = newFactor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !factor.isEmpty, !factors.contains(factor) else { return }
        factors.append(factor)
        newFactor = ""
    }
}

struct FactorsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FactorsDetailView()
        }
    }
}
