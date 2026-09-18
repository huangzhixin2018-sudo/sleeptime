import SwiftUI

struct StickyNote: Identifiable {
    let id = UUID()
    let content: String
    let date: String
    let theme: NoteTheme
    let rotation: Double
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
        StickyNote(content: "去河边散步吹了吹风，晚霞特别温柔，心情瞬间放晴了。", date: "09-17", theme: .pink, rotation: -1.8),
        StickyNote(content: "新换的深烘咖啡豆风味很正，早起做手冲确实能定下心。", date: "09-15", theme: .yellow, rotation: 2.4),
        StickyNote(content: "把书架重新归类整理了一遍，扔掉三袋陈旧杂物，呼吸都轻快了。", date: "09-11", theme: .green, rotation: 1.2),
        StickyNote(content: "专注写完核心模块，没有被打断的两个小时效率真高。", date: "09-08", theme: .blue, rotation: -3.5),
        StickyNote(content: "买了束白色洋桔梗插在书桌前，抬头看一眼就很安静。", date: "09-02", theme: .yellow, rotation: -0.8),
        StickyNote(content: "慢跑 5 公里，配速不重要，重要的是完全放空的大脑。", date: "08-28", theme: .pink, rotation: 3.6),
        StickyNote(content: "重新审视了一下近期的生活节奏，学会对非必要事务说不。", date: "08-22", theme: .blue, rotation: 2.4),
        StickyNote(content: "尝试做了一道新菜，番茄炖牛腩特别入味，做饭也是一种冥想。", date: "08-16", theme: .green, rotation: -1.8),
        StickyNote(content: "读完了一整本书，记录了三条很有启发的笔记，满足。", date: "08-09", theme: .yellow, rotation: 1.2),
        StickyNote(content: "立秋后的第一场暴雨，躲在室内听雨声看书，安全感拉满。", date: "08-01", theme: .pink, rotation: -3.5)
    ]
    @State private var isShowingComposer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "f6f6f4").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header Section
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 12) {
                            // 标题及其底部的波浪/下划线装饰
                            ZStack(alignment: .topLeading) {
                                // 左上角的星星点缀
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
                            .padding(.leading, 8)

                            HStack(spacing: 6) {
                                Text("共 \(notes.count) 张")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "8c8c8c"))

                                Image(systemName: "play.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(Color(hex: "ffe299"))
                                    .rotationEffect(.degrees(90))
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    // 便利贴瀑布流网格 (双列)
                    HStack(alignment: .top, spacing: 14) {
                        let leftNotes = notes.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }
                        let rightNotes = notes.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }

                        VStack(spacing: 20) {
                            ForEach(leftNotes) { note in
                                NoteCardView(note: note)
                            }
                        }

                        VStack(spacing: 20) {
                            ForEach(rightNotes) { note in
                                NoteCardView(note: note)
                            }
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
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    isShowingComposer = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
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
        let rotations = [-1.4, 1.6, -0.8, 1.2, -1.0, 0.9]
        let newNote = StickyNote(
            content: content,
            date: Self.noteDateFormatter.string(from: Date()),
            theme: themes[notes.count % themes.count],
            rotation: rotations[notes.count % rotations.count]
        )

        withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
            notes.insert(newNote, at: 0)
        }
    }

    private static let noteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter
    }()
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
        VStack(alignment: .leading, spacing: 14) {
            Text(note.content)
                .font(.system(size: 17, weight: .regular))
                .lineSpacing(6)
                .foregroundColor(Color(hex: "2b2b2b"))
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Text(note.date)
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.65)
                    .tracking(0.3)
            }
        }
        .foregroundColor(note.theme.textColor)
        .padding(.horizontal, 14)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .frame(minHeight: 154, alignment: .topLeading)
        .background(note.theme.gradient)
        .cornerRadius(4)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.03), radius: 1.5, x: 0, y: 1)
        .rotationEffect(.degrees(note.rotation)) // 模拟真实贴纸的轻微旋转
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
