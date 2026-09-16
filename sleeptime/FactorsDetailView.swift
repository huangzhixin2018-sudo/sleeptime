import SwiftUI

struct SleepFactor: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
}

struct FactorsDetailView: View {
    @State private var factors: [SleepFactor] = [
        SleepFactor(title: "喝了咖啡", date: Date()),
        SleepFactor(title: "睡前运动过量", date: Date().addingTimeInterval(-86400)),
        SleepFactor(title: "卧室太热", date: Date().addingTimeInterval(-86400 * 2))
    ]
    @State private var showAddSheet = false
    @State private var newFactorTitle = ""
    @State private var newFactorDate = Date()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // 放大的标题
                Text("影响因素")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 10)
                    .padding(.horizontal, 24)

                // 因素列表
                VStack(spacing: 12) {
                    ForEach(factors) { factor in
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(factor.date.formatted(.dateTime.month(.wide).day().hour().minute().locale(Locale(identifier: "zh_CN"))))
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.gray)

                                Text(factor.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black.opacity(0.85))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color.clear)
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    newFactorTitle = ""
                    newFactorDate = Date()
                    showAddSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.orange.opacity(0.8))
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationView {
                Form {
                    Section {
                        TextField("请输入影响睡眠的因素", text: $newFactorTitle)
                        DatePicker("发生时间", selection: $newFactorDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                .navigationTitle("添加影响因素")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            showAddSheet = false
                        }
                        .foregroundColor(.black.opacity(0.6))
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("添加") {
                            addFactor()
                        }
                        .fontWeight(.bold)
                        .foregroundColor(Color.orange.opacity(0.8))
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func addFactor() {
        let title = newFactorTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        factors.insert(SleepFactor(title: title, date: newFactorDate), at: 0)
        showAddSheet = false
    }
}

struct FactorsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FactorsDetailView()
        }
    }
}
