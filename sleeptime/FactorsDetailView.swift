import SwiftUI

struct SleepFactorRecord: Identifiable {
    var id: Date { date }
    let date: Date
    let factor: String?
    var note: String? = nil
}

struct FactorsDetailView: View {
    @State private var selectedDate = Date()
    @State private var showingFactorSheet = false
    @State private var todayFactor: String? = nil
    @State private var todayNote: String? = nil

    private var records: [SleepFactorRecord] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: selectedDate) else { return [] }
        let numberOfDays = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 0
        let today = calendar.startOfDay(for: Date())

        return (0..<numberOfDays).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: interval.start), date <= today else {
                return nil
            }
            let daysAgo = calendar.dateComponents([.day], from: date, to: today).day
            if daysAgo == 0 {
                return SleepFactorRecord(date: date, factor: todayFactor ?? "是什么影响了你熬夜", note: todayNote)
            } else if daysAgo == 2 {
                return SleepFactorRecord(date: date, factor: "刷视频")
            } else if daysAgo == 4 {
                return SleepFactorRecord(date: date, factor: "聚会")
            } else {
                return nil
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 列表
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(records) { record in
                        Button(action: {
                            // 如果是今天，则弹出选择器
                            if Calendar.current.isDateInToday(record.date) {
                                showingFactorSheet = true
                            }
                        }) {
                            SleepFactorRowView(record: record)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("熬夜原因")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFactorSheet) {
            FactorSelectionSheet(selectedFactor: $todayFactor, selectedNote: $todayNote)
        }
    }
}

struct SleepFactorRowView: View {
    let record: SleepFactorRecord

    var dateString: String {
        record.date.formatted(.dateTime.month(.wide).day().locale(Locale(identifier: "zh_CN")))
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(record.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dateString)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(record.factor == nil ? .gray : .black.opacity(0.6))

            if let factor = record.factor {
                let isOrange = (isToday && factor == "是什么影响了你熬夜")
                let fColor = isOrange ? Color.orange : Color.blue
                let factorText = Text(factor)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(fColor)
                    
                if let note = record.note, !note.isEmpty {
                    HStack(alignment: .top, spacing: 12) {
                        factorText
                            .fixedSize(horizontal: true, vertical: false)
                        
                        Text(note)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.black.opacity(0.8))
                            .lineSpacing(8)
                    }
                } else {
                    factorText
                }
            } else if let note = record.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black.opacity(0.8))
                    .lineSpacing(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            (isToday && record.factor == "是什么影响了你熬夜") ? Color.orange.opacity(0.05) : Color.clear
        )
        .cornerRadius(12)
    }
}

struct FactorSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFactor: String?
    @Binding var selectedNote: String?

    @State private var localFactor: String?
    @State private var localNote: String = ""

    let options = ["玩游戏", "刷视频", "聚会", "生理期", "加班", "失眠", "看书", "聊天"]
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 编辑框
                    ZStack(alignment: .topLeading) {
                        if localNote.isEmpty {
                            Text("补充说明 (可选编辑)")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color.black.opacity(0.35))
                                .padding(.top, 16)
                                .padding(.leading, 12)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $localNote)
                            .font(.system(size: 15, weight: .regular))
                            .frame(minHeight: 100)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                    .padding(.top, 16)

                    // 标题和标签网格
                    VStack(alignment: .leading, spacing: 16) {
                        Text("选择影响你熬夜的因素")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black.opacity(0.8))
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(options, id: \.self) { option in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        localFactor = option
                                    }
                                }) {
                                    Text(option)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(localFactor == option ? .white : .black.opacity(0.7))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            Capsule()
                                                .fill(localFactor == option ? Color.orange : Color(white: 0.95))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("添加熬夜原因")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        selectedFactor = localFactor
                        selectedNote = localNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : localNote
                        dismiss()
                    }
                    .foregroundColor(.orange)
                    .disabled(localFactor == nil && localNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                localFactor = selectedFactor
                localNote = selectedNote ?? ""
            }
        }
        .presentationDetents([.fraction(0.85), .large])
    }
}

struct FactorsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FactorsDetailView()
        }
    }
}
