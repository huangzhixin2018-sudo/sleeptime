//
//  TimeTravelDetailView.swift
//  sleeptime
//

import SwiftUI

private struct PersonalPrinciple: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let tag: String?
    let createdAt: Date
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing, lineSpacing: lineSpacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing, lineSpacing: lineSpacing)
        for (index, subview) in subviews.enumerated() {
            let point = result.frames[index].origin
            subview.place(at: CGPoint(x: point.x + bounds.minX, y: point.y + bounds.minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat, lineSpacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + lineSpacing
                    lineHeight = 0
                }
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                maxX = max(maxX, currentX - spacing)
            }
            size = CGSize(width: maxX, height: currentY + lineHeight)
        }
    }
}

struct TimeTravelDetailView: View {
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    @AppStorage("earlySleep.personalPrinciples") private var encodedPrinciples = "[]"
    @State private var principles: [PersonalPrinciple] = []
    @State private var isShowingAddPrinciple = false

    private let principleLimit = 5
    private let tags = ["保持固定起床时间", "10点后不玩手机", "睡前不碰宵夜", "不拖延", "提前计划", "吾日三省吾身"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // 卡片说明
                VStack(alignment: .leading, spacing: 16) {
                    Text("早睡原则")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                    
                    Text("① 识别你的晚睡诱因\n        ↓\n② 建立你的早睡原则\n        ↓\n③ 每日强化原则理念\n        ↓\n④ 查看睡眠反馈并调整原则")
                        .font(.system(size: 15))
                        .foregroundColor(Color.secondary)
                        .lineSpacing(4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(12)

                // 标签流式布局
                FlowLayout(spacing: 12, lineSpacing: 16) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 6) {
                            Text("#")
                                .font(.system(size: 15, weight: .light))
                                .foregroundColor(Color.white.opacity(0.6))
                            Text(tag)
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black)
                        .cornerRadius(24)
                    }
                }
                .padding(.top, 10)

                if !principles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(Calendar.current.component(.month, from: Date()))月")
                            .font(.system(size: 17, weight: .semibold))

                        ForEach(principles) { principle in
                            PersonalPrincipleCard(principle: principle) {
                                deletePrinciple(principle)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding(20)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97).ignoresSafeArea())
        .navigationTitle("原则")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAddPrinciple = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(principles.count >= principleLimit)
                .accessibilityLabel("新增原则")
            }
        }
        .sheet(isPresented: $isShowingAddPrinciple) {
            AddPrincipleSheet(tags: tags) { text, tag in
                let principle = PersonalPrinciple(
                    id: UUID(),
                    text: text,
                    tag: tag,
                    createdAt: Date()
                )
                principles.insert(principle, at: 0)
                persistPrinciples()
            }
        }
        .onAppear(perform: loadPrinciples)
    }

    private func loadPrinciples() {
        guard let data = encodedPrinciples.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([PersonalPrinciple].self, from: data) else {
            principles = []
            return
        }
        principles = Array(decoded.prefix(principleLimit))
    }

    private func persistPrinciples() {
        guard let data = try? JSONEncoder().encode(principles),
              let value = String(data: data, encoding: .utf8) else { return }
        encodedPrinciples = value
    }

    private func deletePrinciple(_ principle: PersonalPrinciple) {
        withAnimation {
            principles.removeAll { $0.id == principle.id }
        }
        persistPrinciples()
    }
}

private struct PersonalPrincipleCard: View {
    let principle: PersonalPrinciple
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(principle.text)
                .font(.system(size: 16))
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 32)

            HStack(alignment: .center, spacing: 10) {
                Text(principle.createdAt.formatted(.dateTime.month(.twoDigits).day(.twoDigits).hour(.defaultDigits(amPM: .omitted)).minute()))
                    .font(.system(size: 14))
                    .foregroundStyle(Color.secondary)

                if let tag = principle.tag {
                    Text("# \(tag)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.blue)
                }

                Spacer()

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 28, height: 28)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct AddPrincipleSheet: View {
    @Environment(\.dismiss) private var dismiss
    let tags: [String]
    let onSave: (String, String?) -> Void

    @State private var text = ""
    @State private var selectedTag: String?

    private let textLimit = 120

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("内容")
                            .font(.system(size: 16, weight: .semibold))

                        TextEditor(text: $text)
                            .font(.system(size: 18))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 130)
                            .padding(12)
                            .background(
                                Color(uiColor: .secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .onChange(of: text) {
                                if text.count > textLimit {
                                    text = String(text.prefix(textLimit))
                                }
                            }

                        Text("\(text.count)/\(textLimit)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("原则标签")
                                .font(.system(size: 16, weight: .semibold))
                            Text("可选")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        FlowLayout(spacing: 8, lineSpacing: 10) {
                            ForEach(tags, id: \.self) { tag in
                                Button {
                                    selectedTag = selectedTag == tag ? nil : tag
                                } label: {
                                    Text("# \(tag)")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(selectedTag == tag ? Color.white : Color.black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedTag == tag ? Color.black : Color(uiColor: .secondarySystemBackground),
                                            in: Capsule()
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(text.trimmingCharacters(in: .whitespacesAndNewlines), selectedTag)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct TimeTravelDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TimeTravelDetailView()
        }
    }
}
