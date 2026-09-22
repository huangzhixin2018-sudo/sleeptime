import SwiftUI

struct EarlySleepMethodsView: View {
    @AppStorage("earlySleep.freeMethods.v2") private var encodedMethods = "[]"
    @State private var methods: [FreeSleepMethod] = []
    @State private var activeModal: MethodModal?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.965, green: 0.965, blue: 0.955).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Text("我的早睡方法")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 24)

                    if methods.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 18) {
                            ForEach(methods) { method in
                                Button {
                                    activeModal = .detail(method.id)
                                } label: {
                                    MethodStickyNoteCard(method: method, palette: notePalette(for: method))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                }
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                activeModal = .composer
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold))
                    Text("添加方法")
                        .font(.system(size: 15, weight: .semibold))
                }
                    .foregroundStyle(.white)
                    .frame(width: 190, height: 48)
                    .background(Color(red: 0.17, green: 0.17, blue: 0.19), in: Capsule())
                    .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 7)
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeModal) { modal in
            Group {
                switch modal {
                case .composer:
                    EarlySleepMethodComposerView { content in
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            methods.insert(
                                FreeSleepMethod(id: UUID(), content: content, createdAt: Date()),
                                at: 0
                            )
                        }
                        persistMethods()
                    }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                case .detail(let id):
                    if let methodBinding = binding(for: id) {
                        EarlySleepMethodDetailView(
                            method: methodBinding,
                            onSave: persistMethods,
                            onDelete: {
                                methods.removeAll { $0.id == id }
                                persistMethods()
                                activeModal = nil
                            }
                        )
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                    }
                }
            }
        }
        .onAppear(perform: loadMethods)
    }

    private func binding(for id: UUID) -> Binding<FreeSleepMethod>? {
        guard let index = methods.firstIndex(where: { $0.id == id }) else { return nil }
        return $methods[index]
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "lightbulb.max")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Color(red: 0.74, green: 0.57, blue: 0.18))
                .frame(width: 56, height: 56)
                .background(Color(red: 0.99, green: 0.95, blue: 0.76), in: Circle())

            VStack(spacing: 6) {
                Text("还没有早睡方法")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.78))
                Text("记下今晚想尝试的一件小事")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.black.opacity(0.42))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
    }

    private func notePalette(for method: FreeSleepMethod) -> MethodNotePalette {
        let palettes: [MethodNotePalette] = [
            .init(paper: Color(red: 0.91, green: 0.88, blue: 0.99)),
            .init(paper: Color(red: 0.87, green: 0.95, blue: 0.92)),
            .init(paper: Color(red: 0.89, green: 0.94, blue: 0.99)),
            .init(paper: Color(red: 0.99, green: 0.91, blue: 0.92))
        ]
        let seed = method.id.uuidString.unicodeScalars.reduce(UInt(0)) { ($0 &* 31) &+ UInt($1.value) }
        return palettes[Int(seed % UInt(palettes.count))]
    }

    private func loadMethods() {
        guard let data = encodedMethods.data(using: .utf8) else { return }
        methods = (try? JSONDecoder().decode([FreeSleepMethod].self, from: data)) ?? []
    }

    private func persistMethods() {
        guard let data = try? JSONEncoder().encode(methods),
              let value = String(data: data, encoding: .utf8) else { return }
        encodedMethods = value
    }
}

private struct MethodNotePalette {
    let paper: Color
}

private enum MethodModal: Identifiable {
    case composer
    case detail(UUID)

    var id: String {
        switch self {
        case .composer: return "composer"
        case .detail(let id): return "detail-\(id.uuidString)"
        }
    }
}

private struct MethodStickyNoteCard: View {
    let method: FreeSleepMethod
    let palette: MethodNotePalette

    var body: some View {
        Text(method.content)
            .font(.system(size: 19, weight: .medium))
            .foregroundStyle(Color.black.opacity(0.80))
            .lineSpacing(8)
            .lineLimit(4)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 138, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.vertical, 22)
            .background(palette.paper)
            .clipShape(SleepMethodCardShape())
            .overlay {
                SleepMethodCardShape()
                    .stroke(Color.black.opacity(0.035), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.055), radius: 12, x: 0, y: 6)
            .contentShape(SleepMethodCardShape())
    }
}

private struct SleepMethodCardShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 22
        let notchRadius: CGFloat = 11
        let notchY = rect.midY
        var path = Path()

        path.move(to: CGPoint(x: radius, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: radius), control: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: notchY - notchRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: notchY + notchRadius),
            control: CGPoint(x: rect.maxX - notchRadius * 1.35, y: notchY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.maxY - radius), control: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: notchY + notchRadius))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: notchY - notchRadius),
            control: CGPoint(x: notchRadius * 1.35, y: notchY)
        )
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addQuadCurve(to: CGPoint(x: radius, y: 0), control: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

private struct EarlySleepMethodDetailView: View {
    @Binding var method: FreeSleepMethod
    let onSave: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var draft = ""
    @State private var isConfirmingDelete = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isEditing ? "编辑方法" : "早睡方法")
                            .font(.system(size: 20, weight: .semibold))

                        Text(chineseDate(method.createdAt))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, height: 34)
                            .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    }
                    .accessibilityLabel("关闭")
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 18)

                Group {
                    if isEditing {
                        TextEditor(text: $draft)
                            .scrollContentBackground(.hidden)
                            .textContentType(.none)
                            .focused($isFocused)
                    } else {
                        ScrollView(showsIndicators: false) {
                            Text(method.content)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .font(.system(size: 18))
                .foregroundStyle(Color.primary.opacity(0.86))
                .lineSpacing(7)
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 100)
            }

            actionBar
                .padding(.horizontal, 20)
                .padding(.bottom, 22)
        }
        .interactiveDismissDisabled(isEditing)
        .confirmationDialog("删除这个方法？", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("取消", role: .cancel) { }
        }
    }

    @ViewBuilder
    private var actionBar: some View {
        if isEditing {
            HStack(spacing: 12) {
                Button("取消") {
                    draft = method.content
                    isFocused = false
                    isEditing = false
                }
                .foregroundStyle(.primary)
                .frame(width: 88, height: 52)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                Button("保存修改", action: saveChanges)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color(red: 0.17, green: 0.17, blue: 0.19), in: RoundedRectangle(cornerRadius: 8))
                    .disabled(trimmedDraft.isEmpty)
            }
        } else {
            HStack(spacing: 12) {
                Button("编辑", action: beginEditing)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color(red: 0.17, green: 0.17, blue: 0.19), in: RoundedRectangle(cornerRadius: 8))

                Button("删除", role: .destructive) {
                    isConfirmingDelete = true
                }
                .frame(width: 52, height: 52)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func beginEditing() {
        draft = method.content
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isFocused = true
        }
    }

    private func saveChanges() {
        guard !trimmedDraft.isEmpty else { return }
        method.content = trimmedDraft
        onSave()
        isFocused = false
        isEditing = false
    }

    private func chineseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

private struct EarlySleepMethodComposerView: View {
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @FocusState private var isFocused: Bool

    private var trimmedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("写下一个真正对你有效的方法")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("例如：睡前半小时把手机放到客厅")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.secondary.opacity(0.65))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                        }

                    TextEditor(text: $content)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.primary.opacity(0.86))
                        .lineSpacing(7)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .textContentType(.none)
                        .focused($isFocused)
                }
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("写下方法")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onComplete(trimmedContent)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(trimmedContent.isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isFocused = true
                }
            }
        }
    }

}

private struct FreeSleepMethod: Codable, Identifiable, Equatable {
    let id: UUID
    var content: String
    let createdAt: Date

    private enum CodingKeys: String, CodingKey { case id, content, createdAt, title, details, text }

    init(id: UUID, content: String, createdAt: Date) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        if let value = try container.decodeIfPresent(String.self, forKey: .content) {
            content = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: .text) {
            content = value
        } else {
            let title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            let details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
            content = [title, details].filter { !$0.isEmpty }.joined(separator: "\n")
        }
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

private struct EarlySleepMethodsViewPreview: PreviewProvider {
    static var previews: some View {
        NavigationStack { EarlySleepMethodsView() }
    }
}
