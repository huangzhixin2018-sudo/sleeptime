import SwiftUI

private struct HomeRecordTodo: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
}

struct HomeRecordDetailView: View {
    @AppStorage("homeRecord.todos") private var storedTodos = ""
    @State private var todos: [HomeRecordTodo] = []

    private let pageBackground = Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    private let ink = Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)
    private let muted = Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255)
    private let blue = Color(red: 10 / 255, green: 132 / 255, blue: 1)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                dateHero
                sleepMetrics
                todoSection
                sleepJournalEntry
                lateSleepEntry
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(pageBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadTodos)
    }

    private var dateHero: some View {
        VStack(spacing: 12) {
            Text("二〇二六年 · 十月")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, alignment: .center)

            Text("3")
                .font(.system(size: 100, weight: .semibold, design: .default))
                .foregroundStyle(blue)
                .monospacedDigit()
                .frame(height: 104)

            HStack(spacing: 8) {
                recordStamp(title: "中秋佳节", color: Color(red: 217 / 255, green: 56 / 255, blue: 41 / 255))

                Text("早睡")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 43 / 255, green: 122 / 255, blue: 75 / 255))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color(red: 43 / 255, green: 122 / 255, blue: 75 / 255), lineWidth: 1)
                }
            }

            Text("农历八月十五 · 星期六")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ink.opacity(0.62))
                .padding(.top, 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }

    private var sleepMetrics: some View {
        HStack(spacing: 0) {
            recordMetric(title: "入睡", value: "22:45")
            Divider().frame(height: 38)
            recordMetric(title: "起床", value: "07:15")
            Divider().frame(height: 38)
            recordMetric(title: "时长", value: "8h 30m")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.bottom, 14)
    }

    private var todoSection: some View {
        VStack(spacing: 18) {
            subtleSectionHeader("习惯")

            VStack(spacing: 15) {
                ForEach(Array(todos.enumerated()), id: \.element.id) { index, todo in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white)
                            .monospacedDigit()
                            .frame(width: 20, height: 20)
                            .background(ink)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))

                        Text(todo.title)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(ink)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.bottom, 14)
    }

    private var sleepJournalEntry: some View {
        VStack(alignment: .leading, spacing: 16) {
            subtleSectionHeader("梦境")

            Text("梦见自己走在一条很长的走廊里，尽头有光，但一直没有真正走到。醒来后还记得那种安静又迟疑的感觉。")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(ink.opacity(0.82))
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var lateSleepEntry: some View {
        VStack(alignment: .leading, spacing: 16) {
            subtleSectionHeader("熬夜原因 · 玩游戏")

            Text("晚上和朋友多打了几局，结束后精神仍然很兴奋，洗漱和入睡时间都比计划晚了一些。")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(ink.opacity(0.82))
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.top, 14)
    }

    private func subtleSectionHeader(_ title: String) -> some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(ink.opacity(0.22))
                .frame(width: 6, height: 6)

            Rectangle()
                .fill(ink.opacity(0.18))
                .frame(height: 1)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ink.opacity(0.52))
                .fixedSize()

            Rectangle()
                .fill(ink.opacity(0.18))
                .frame(height: 1)

            Rectangle()
                .fill(ink.opacity(0.22))
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
    }

    private func recordStamp(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay {
                RoundedRectangle(cornerRadius: 3).stroke(color, lineWidth: 1)
            }
    }

    private func recordMetric(title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ink.opacity(0.56))
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .default))
                .foregroundStyle(ink)
                .monospacedDigit()
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadTodos() {
        guard let data = storedTodos.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([HomeRecordTodo].self, from: data) else {
            todos = [
                HomeRecordTodo(id: UUID(), title: "22:00 提前将手机放在书房", isCompleted: true),
                HomeRecordTodo(id: UUID(), title: "睡前温水泡脚 15 分钟", isCompleted: true)
            ]
            saveTodos()
            return
        }
        todos = decoded
    }

    private func saveTodos() {
        guard let data = try? JSONEncoder().encode(todos),
              let encoded = String(data: data, encoding: .utf8) else { return }
        storedTodos = encoded
    }
}
