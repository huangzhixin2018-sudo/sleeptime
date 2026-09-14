import SwiftUI

struct EarlySleepMethodsView: View {
    @State private var methods: [String] = [
        "睡前放下手机，看半小时书",
        "听一些白噪音或舒缓的音乐",
        "泡个热水澡或热水泡脚",
        "睡前做简单的拉伸或瑜伽",
        "卧室保持昏暗和凉爽"
    ]

    @State private var showAddAlert = false
    @State private var newMethod = ""

    @AppStorage("earlySleep.ifCondition") private var ifCondition = ""
    @AppStorage("earlySleep.thenAction") private var thenAction = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 熬夜破局卡 (If-Then 策略)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 20))
                        Text("我的熬夜破局卡")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                        Spacer()
                    }

                    Text("当诱惑出现时，我有对策：")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("如果")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.30, green: 0.52, blue: 0.78))
                            TextField("过了23点还在刷短视频", text: $ifCondition)
                                .font(.system(size: 16))
                                .textFieldStyle(.plain)
                        }

                        Divider()

                        HStack {
                            Text("我就")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.orange)
                            TextField("马上把手机插在客厅去洗漱", text: $thenAction)
                                .font(.system(size: 16))
                                .textFieldStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.97))
                    .cornerRadius(12)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)

                // 原有的早睡方法列表
                ForEach(methods, id: \.self) { method in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.30, green: 0.52, blue: 0.78))
                            .font(.system(size: 20))
                        
                        Text(method)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
                }
            }
            .padding(20)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97).ignoresSafeArea())
        .navigationTitle("早睡方法")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddAlert = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
            }
        }
        .alert("添加早睡方法", isPresented: $showAddAlert) {
            TextField("请输入...", text: $newMethod)
            Button("取消", role: .cancel) {
                newMethod = ""
            }
            Button("添加") {
                if !newMethod.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    methods.append(newMethod.trimmingCharacters(in: .whitespacesAndNewlines))
                    newMethod = ""
                }
            }
        }
    }
}

struct EarlySleepMethodsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EarlySleepMethodsView()
        }
    }
}
