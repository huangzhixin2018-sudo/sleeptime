import SwiftUI

struct KeywordItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var quote: String
}

struct KeywordCategory {
    let id: String
    let title: String
    let desc: String
    var items: [KeywordItem]
    var library: [KeywordItem]
}

struct LifeKeywordsView: View {
    @State private var categories: [KeywordCategory] = [
        KeywordCategory(
            id: "self",
            title: "自我",
            desc: "聚焦核心特质与本质解析，命名即觉察。",
            items: [
                KeywordItem(name: "先动后定", quote: "先以 60 分的姿态进入行动，答案永远在推进中自然显现。"),
                KeywordItem(name: "事实归因", quote: "分清客观事实与不可控变数，只对能改变的变量全力以赴。")
            ],
            library: [
                KeywordItem(name: "拒绝内耗", quote: "不在尚未发生的事情上预支焦虑，专注于当下具体行动。"),
                KeywordItem(name: "主动配得", quote: "坦然接住成果与赞赏，信任自己的投入自带对等的价值。"),
                KeywordItem(name: "主体意识", quote: "清楚自己的核心底线，把人生的优先权拿回自己手中。"),
                KeywordItem(name: "拒绝盲从", quote: "不为了迎合群体预期而削足适履，坚守自己的思考与步调。"),
                KeywordItem(name: "情绪直面", quote: "允许真实感受自然流过，看清背后的真实需求而不压抑。")
            ]
        ),
        KeywordCategory(
            id: "daily",
            title: "生活日常",
            desc: "日常微小惯性背后，是无意识的注意流向与能量损耗。",
            items: [
                KeywordItem(name: "主动清晨", quote: "醒来先锚定自己的主干任务，把最好的脑力留给自己。")
            ],
            library: [
                KeywordItem(name: "拒绝假忙", quote: "不做低价值的琐碎忙碌，只在产生真实增量的事情上投放时间。"),
                KeywordItem(name: "秩序自洽", quote: "理顺眼前的物理空间，让大脑以最低的阻尼高效运转。"),
                KeywordItem(name: "拒绝晚睡", quote: "夜间是对系统的深度滋养，不再用熬夜去换取虚幻的掌控感。"),
                KeywordItem(name: "深层专注", quote: "一次只做一件事，彻底切断多线程切换带来的认知摩擦。")
            ]
        ),
        KeywordCategory(
            id: "relation",
            title: "亲密关系",
            desc: "在交互中保持坦率与自洽，做真实而有温度的连接。",
            items: [
                KeywordItem(name: "同频在场", quote: "放下评判与指导欲，给予全然的听见，理解本身就是解法。")
            ],
            library: [
                KeywordItem(name: "拒绝讨好", quote: "真实的拒绝带来长久的轻松，含混不清的应承才是最大的损耗。"),
                KeywordItem(name: "坦白期待", quote: "把愿望清晰直接地表达出来，不再让沉默与猜疑制造摩擦。"),
                KeywordItem(name: "拒绝冷战", quote: "发生分歧时直面问题本身，不用冷漠与封闭筑墙防卫。"),
                KeywordItem(name: "温和边界", quote: "清晰表达自己的底线，边界完整才能建立对等的尊重。")
            ]
        )
    ]

    @State private var currentTabId: String = "self"

    @State private var showingPickSheet = false
    @State private var showingEditSheet = false

    @State private var editName: String = ""
    @State private var editQuote: String = ""
    @State private var editModalTitle: String = ""
    @State private var editingIndex: Int? = nil
    @State private var currentLibraryIndex: Int? = nil

    private var currentCategoryIndex: Int {
        categories.firstIndex(where: { $0.id == currentTabId }) ?? 0
    }

    private var currentCategory: KeywordCategory {
        categories[currentCategoryIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    headerBox
                    tabsRow
                    cardList
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color(hex: "f7f9fa").ignoresSafeArea())
        .navigationTitle("心之所向")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("挑选", action: openPickModal)
                Button("自定", action: openCreateModal)
            }
        }
        .sheet(isPresented: $showingPickSheet) {
            pickSheetContent
                .presentationDetents([.fraction(0.92)])
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingEditSheet) {
            editSheetContent
                .presentationDetents([.fraction(0.92)])
                .presentationDragIndicator(.hidden)
        }
    }

    private var headerBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currentCategory.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "0f172a"))

            Text(currentCategory.desc)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "64748b"))
                .lineSpacing(4)
        }
    }

    private var tabsRow: some View {
        HStack(spacing: 8) {
            ForEach(["self", "daily", "relation"], id: \.self) { tabId in
                let tabName = tabId == "self" ? "关于自我" : (tabId == "daily" ? "生活日常" : "亲密关系")
                let isActive = currentTabId == tabId

                Button(action: { currentTabId = tabId }) {
                    Text(tabName)
                        .font(.system(size: 13))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .foregroundColor(isActive ? .white : Color(hex: "64748b"))
                        .background(isActive ? Color(hex: "0f172a") : Color.white)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isActive ? Color.clear : Color(hex: "e2e8f0"), lineWidth: 1)
                        )
                }
            }
        }
    }

    private var cardList: some View {
        VStack(spacing: 12) {
            if currentCategory.items.isEmpty {
                Text("尚未收录特质，点击右上角挑选或自定")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "94a3b8"))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
            } else {
                ForEach(currentCategory.items.indices, id: \.self) { index in
                    let item = currentCategory.items[index]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.name)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Color(hex: "0f172a"))

                            Spacer()

                            HStack(spacing: 12) {
                                Button("编辑") {
                                    editExisting(index: index)
                                }
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "94a3b8"))

                                Button("移除") {
                                    deleteItem(index: index)
                                }
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "ef4444"))
                            }
                        }

                        Text("“\(item.quote)”")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "334155"))
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "edf1f5"), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
                }
            }
        }
    }

    private var pickSheetContent: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(hex: "cbd5e1"))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            HStack {
                Text("挑选特质")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "0f172a"))
                Spacer()
                Button("取消") { showingPickSheet = false }
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "94a3b8"))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if currentCategory.library.isEmpty {
                        Text("该维度的推荐特质已全部挑选完毕")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "94a3b8"))
                            .padding(.top, 30)
                    } else {
                        ForEach(currentCategory.library.indices, id: \.self) { index in
                            let libItem = currentCategory.library[index]
                            Button(action: { selectFromLibrary(index: index) }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(libItem.name)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(hex: "0f172a"))
                                    Text(libItem.quote)
                                        .font(.system(size: 13.5))
                                        .foregroundColor(Color(hex: "475569"))
                                        .lineSpacing(2)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .background(Color(hex: "f8fafc"))
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(hex: "edf2f7"), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    private var editSheetContent: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(hex: "cbd5e1"))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            HStack {
                Text(editModalTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "0f172a"))
                Spacer()
                Button("取消") { showingEditSheet = false }
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "94a3b8"))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("特质名称")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "64748b"))

                    TextField("例如：先动后定", text: $editName)
                        .font(.system(size: 15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(Color(hex: "f8fafc"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("一句话本质解析")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "64748b"))

                    TextEditor(text: $editQuote)
                        .font(.system(size: 14.5))
                        .scrollContentBackground(.hidden)
                        .frame(height: 140)
                        .padding(8)
                        .background(Color(hex: "f8fafc"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                        )
                        .overlay(
                            editQuote.isEmpty ? Text("一句话写清楚它的本质行为指令...").foregroundColor(Color(hex: "94a3b8")).font(.system(size: 14.5)).padding(.horizontal, 14).padding(.vertical, 16).allowsHitTesting(false) : nil,
                            alignment: .topLeading
                        )
                }

                Button(action: saveEdit) {
                    Text("确认保存")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "0f172a"))
                        .cornerRadius(12)
                }
                .padding(.top, 12)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: - Actions

    private func openPickModal() {
        showingPickSheet = true
    }

    private func openCreateModal() {
        editingIndex = nil
        currentLibraryIndex = nil
        editModalTitle = "自定特质"
        editName = ""
        editQuote = ""
        showingEditSheet = true
    }

    private func selectFromLibrary(index: Int) {
        currentLibraryIndex = index
        let item = currentCategory.library[index]

        showingPickSheet = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            editingIndex = nil
            editModalTitle = "编辑并确认收录"
            editName = item.name
            editQuote = item.quote
            showingEditSheet = true
        }
    }

    private func editExisting(index: Int) {
        editingIndex = index
        currentLibraryIndex = nil
        let item = currentCategory.items[index]

        editModalTitle = "修改特质描述"
        editName = item.name
        editQuote = item.quote
        showingEditSheet = true
    }

    private func saveEdit() {
        let name = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        let quote = editQuote.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty, !quote.isEmpty else { return }

        let catIndex = currentCategoryIndex

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if let editIdx = editingIndex {
            categories[catIndex].items[editIdx] = KeywordItem(name: name, quote: quote)
        } else {
            categories[catIndex].items.insert(KeywordItem(name: name, quote: quote), at: 0)

            if let libIdx = currentLibraryIndex {
                categories[catIndex].library.remove(at: libIdx)
            }
        }

        showingEditSheet = false
    }

    private func deleteItem(index: Int) {
        let catIndex = currentCategoryIndex
        categories[catIndex].items.remove(at: index)

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LifeKeywordsView()
}
