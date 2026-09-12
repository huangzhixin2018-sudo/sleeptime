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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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
