import SwiftUI

struct EarlySleepMethodsView: View {
    @AppStorage("earlySleep.freeMethods") private var encodedMethods = "[]"
    @State private var methods: [FreeSleepMethod] = []
    @State private var activeModal: MethodModal?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.965, green: 0.965, blue: 0.955).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Text("我的早睡方法")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.9))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 28)

                    VStack(spacing: 14) {
                        ForEach(Array(methods.enumerated()), id: \.element.id) { index, method in
                            Button {
                                activeModal = .detail(method.id)
                            } label: {
                                MethodStickyNoteCard(method: method, color: noteColor(for: index))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                activeModal = .composer
            } label: {
                Text("写一张")
                    .font(.system(size: 15, weight: .medium))
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
                        methods.insert(
                            FreeSleepMethod(id: UUID(), content: content, createdAt: Date()),
                            at: 0
                        )
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

    private func noteColor(for index: Int) -> Color {
        let colors = [
            Color(red: 0.99, green: 0.97, blue: 0.84),
            Color(red: 0.92, green: 0.96, blue: 0.90),
            Color(red: 0.91, green: 0.95, blue: 0.98),
            Color(red: 0.98, green: 0.92, blue: 0.93)
        ]
        return colors[index % colors.count]
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
    let color: Color

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text(method.content)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.black.opacity(0.8))
                    .lineSpacing(7)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .background(color, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            }

        }
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
            Color(red: 0.965, green: 0.965, blue: 0.955).ignoresSafeArea()

            ZStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(chineseDate(method.createdAt))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    if isEditing {
                        TextEditor(text: $draft)
                            .font(.system(size: 20))
                            .lineSpacing(8)
                            .scrollContentBackground(.hidden)
                            .textContentType(.none)
                            .focused($isFocused)
                    } else {
                        Text(method.content)
                            .font(.system(size: 20))
                            .lineSpacing(8)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 36)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, minHeight: 430, alignment: .topLeading)
                .background(Color(red: 1.00, green: 0.98, blue: 0.84))

            }
            .padding(.top, 10)
            .padding(.bottom, 92)

            actionBar
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .interactiveDismissDisabled(isEditing)
        .confirmationDialog("删除这张便利贴？", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
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
                    isFocused = false
                    isEditing = false
                }
                .foregroundStyle(.primary)
                .frame(width: 88, height: 52)

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
                .frame(width: 72, height: 52)
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
            ZStack {
                Color(red: 0.965, green: 0.965, blue: 0.955).ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(chineseDate(Date()))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.38))

                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("写下你的早睡方法")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.black.opacity(0.25))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $content)
                                .font(.system(size: 18))
                                .foregroundStyle(Color.black.opacity(0.82))
                                .lineSpacing(7)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .textContentType(.none)
                                .focused($isFocused)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 18)
                    .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
                    .background(Color(red: 0.99, green: 0.97, blue: 0.84), in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.04), lineWidth: 1)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }
            .navigationTitle("写一张")
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

    private func chineseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
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
