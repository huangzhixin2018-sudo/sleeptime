import SwiftUI

struct StickyNote: Identifiable {
    let id = UUID()
    var content: String
    let date: String
    let theme: NoteTheme
}

enum NoteTheme {
    case yellow, pink, green, blue

    var gradient: LinearGradient {
        switch self {
        case .yellow: return LinearGradient(colors: [Color(hex: "fffdf2"), Color(hex: "fbf7da")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pink: return LinearGradient(colors: [Color(hex: "fff1f4"), Color(hex: "ffd9e2")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .green: return LinearGradient(colors: [Color(hex: "f3fcf4"), Color(hex: "dff4e3")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blue: return LinearGradient(colors: [Color(hex: "f2f8ff"), Color(hex: "dceaff")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var textColor: Color {
        switch self {
        case .yellow: return Color(hex: "7d7249")
        case .pink: return Color(hex: "9d5d6e")
        case .green: return Color(hex: "557d5e")
        case .blue: return Color(hex: "526f98")
        }
    }
}

struct MyStickyNotesView: View {
    @State private var notes: [StickyNote] = [
        StickyNote(content: "去河边散步吹了吹风，晚霞特别温柔，心情瞬间放晴了。", date: "09-17", theme: .yellow),
        StickyNote(content: "新换的深烘咖啡豆风味很正，早起做手冲确实能定下心。", date: "09-15", theme: .pink),
        StickyNote(content: "把书架重新归类整理了一遍，扔掉三袋陈旧杂物，呼吸都轻快了。", date: "09-11", theme: .green),
        StickyNote(content: "专注写完核心模块，没有被打断的两个小时效率真高。", date: "09-08", theme: .blue),
        StickyNote(content: "买了束白色洋桔梗插在书桌前，抬头看一眼就很安静。", date: "09-02", theme: .yellow),
        StickyNote(content: "慢跑 5 公里，配速不重要，重要的是完全放空的大脑。", date: "08-28", theme: .pink),
        StickyNote(content: "重新审视了一下近期的生活节奏，学会对非必要事务说不。", date: "08-22", theme: .blue),
        StickyNote(content: "尝试做了一道新菜，番茄炖牛腩特别入味，做饭也是一种冥想。", date: "08-16", theme: .green),
        StickyNote(content: "读完了一整本书，记录了三条很有启发的笔记，满足。", date: "08-09", theme: .yellow),
        StickyNote(content: "立秋后的第一场暴雨，躲在室内听雨声看书，安全感拉满。", date: "08-01", theme: .pink)
    ]
    @State private var isShowingComposer = false
    @State private var selectedNoteID: StickyNote.ID?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "f6f6f4").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header Section
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        ZStack(alignment: .topLeading) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "fcd077"))
                                .offset(x: -8, y: -8)

                            Text("我的便利贴")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(Color(hex: "1a1a1a"))
                                .background(
                                    GeometryReader { geo in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color(hex: "fdf3a7"))
                                            .frame(width: geo.size.width * 1.08, height: 12)
                                            .offset(x: 0, y: geo.size.height - 12)
                                    }
                                )
                                .zIndex(1)
                        }
                        .padding(.top, 6)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 28)

                    VStack(spacing: 14) {
                        ForEach(notes) { note in
                                Button {
                                    selectedNoteID = note.id
                                } label: {
                                    NoteCardView(note: note)
                                }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // 留出底部悬浮按钮的空间
                }
            }

            // 悬浮“写一张”按钮
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                isShowingComposer = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                    Text("写一张")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(width: 190, height: 48)
                .background(Color(hex: "2b2b2f"))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.22), radius: 12, x: 0, y: 8)
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            isPresented: Binding(
                get: { selectedNoteID != nil },
                set: { if !$0 { selectedNoteID = nil } }
            )
        ) {
            if let noteID = selectedNoteID,
               let noteBinding = binding(for: noteID) {
                StickyNoteDetailView(
                    note: noteBinding,
                    onDelete: {
                        deleteNote(id: noteID)
                        selectedNoteID = nil
                    }
                )
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $isShowingComposer) {
            StickyNoteComposerView { content in
                addNote(content)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func addNote(_ content: String) {
        let themes: [NoteTheme] = [.yellow, .pink, .green, .blue]
        let newNote = StickyNote(
            content: content,
            date: Self.noteDateFormatter.string(from: Date()),
            theme: themes[notes.count % themes.count]
        )

        withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
            notes.insert(newNote, at: 0)
        }
    }

    private func deleteNote(id: StickyNote.ID) {
        withAnimation(.easeInOut(duration: 0.24)) {
            notes.removeAll { $0.id == id }
        }
    }

    private func binding(for id: StickyNote.ID) -> Binding<StickyNote>? {
        guard let index = notes.firstIndex(where: { $0.id == id }) else { return nil }
        return $notes[index]
    }

    private static let noteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter
    }()
}

private struct StickyNoteDetailView: View {
    @Binding var note: StickyNote
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var draftText = ""
    @FocusState private var isFocused: Bool

    private var trimmedDraft: String {
        draftText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "f6f6f4").ignoresSafeArea()

            VStack(spacing: 0) {
                expandedNote

                Spacer(minLength: 96)
            }

            actionBar
                .padding(.horizontal, 20)
                .padding(.bottom, 22)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            draftText = note.content
        }
    }

    private var expandedNote: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Circle()
                    .fill(note.theme.textColor.opacity(0.55))
                    .frame(width: 6, height: 6)

                Text(note.date)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(note.theme.textColor.opacity(0.7))
                    .tracking(0.6)
            }

            if isEditing {
                TextEditor(text: $draftText)
                    .font(.system(size: 21, weight: .regular))
                    .foregroundColor(Color(hex: "2b2b2b"))
                    .lineSpacing(9)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
            } else {
                ScrollView(showsIndicators: false) {
                    Text(note.content)
                        .font(.system(size: 21, weight: .regular))
                        .foregroundColor(Color(hex: "2b2b2b"))
                        .lineSpacing(9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 30)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 430, alignment: .topLeading)
        .background(note.theme.gradient.opacity(0.48))
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                if isEditing {
                    guard !trimmedDraft.isEmpty else { return }
                    note.content = trimmedDraft
                    isFocused = false
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = false
                    }
                } else {
                    draftText = note.content
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                        isFocused = true
                    }
                }
            } label: {
                Text(isEditing ? "完成" : "编辑")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(hex: "2b2b2f"))
                    )
            }
            .disabled(isEditing && trimmedDraft.isEmpty)

            Button(role: .destructive) {
                onDelete()
                dismiss()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "e05757"))
                    .frame(width: 52, height: 52)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("删除")
        }
    }
}

private struct StickyNoteComposerView: View {
    let onComplete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var noteText = ""
    @FocusState private var isFocused: Bool

    private var trimmedText: String {
        noteText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("把此刻想到的，轻轻贴在这里。")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.black.opacity(0.48))
                    .padding(.horizontal, 2)

                ZStack(alignment: .topLeading) {
                    if noteText.isEmpty {
                        Text("写一张便利贴…")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color.black.opacity(0.24))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 17)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $noteText)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(Color.black.opacity(0.84))
                        .lineSpacing(6)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($isFocused)
                }
                .frame(minHeight: 184)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .background(Color(hex: "f6f6f4").ignoresSafeArea())
            .navigationTitle("写一张")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(Color.black.opacity(0.62))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        onComplete(trimmedText)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(trimmedText.isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    isFocused = true
                }
            }
        }
    }
}

struct NoteCardView: View {
    let note: StickyNote

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(note.content)
                .font(.system(size: 18, weight: .regular))
                .lineSpacing(8)
                .foregroundColor(Color(hex: "303033"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)

            HStack {
                Spacer(minLength: 0)
                Text(note.date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(note.theme.textColor.opacity(0.6))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(note.theme.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
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
    MyStickyNotesView()
}
