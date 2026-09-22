import SwiftUI

struct MorningFeelingRecord: Identifiable {
    var id: Date { date }
    let date: Date
    let feeling: String?
}

struct MorningFeelingDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var showingFeelingSheet = false
    @State private var todayFeeling: String? = nil

    private var records: [MorningFeelingRecord] {
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
                return MorningFeelingRecord(date: date, feeling: todayFeeling ?? "你今天早睡感觉如何？")
            } else if daysAgo == 2 {
                return MorningFeelingRecord(date: date, feeling: "恼火")
            } else if daysAgo == 3 {
                return MorningFeelingRecord(date: date, feeling: "神清气爽")
            } else {
                // 不再返回无记录的卡片
                return nil
            }
        }
    }

    var monthString: String {
        selectedDate.formatted(.dateTime.year().month(.wide).locale(Locale(identifier: "zh_CN")))
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
                                showingFeelingSheet = true
                            }
                        }) {
                            MorningFeelingRowView(record: record)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFeelingSheet) {
            MorningFeelingSelectionSheet(selectedFeeling: $todayFeeling)
        }
    }

    private func changeMonth(by value: Int) {
        guard let date = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) else { return }
        selectedDate = min(date, Date())
    }
}

struct MorningFeelingRowView: View {
    let record: MorningFeelingRecord

    var dateString: String {
        record.date.formatted(.dateTime.month(.wide).day().locale(Locale(identifier: "zh_CN")))
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(record.date)
    }

    var body: some View {
        HStack(spacing: 16) {
            // 移除了头像图标

            // 文本
            VStack(alignment: .leading, spacing: 6) {
                Text(dateString)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(record.feeling == nil ? .gray : .black.opacity(0.8))

                if let feeling = record.feeling {
                    Text(feeling)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isToday && feeling == "你今天早睡感觉如何？" ? .blue : .black)
                }
            }

            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            (isToday && record.feeling == "你今天早睡感觉如何？") ? Color.blue.opacity(0.05) : Color.clear
        )
        .cornerRadius(12)
    }
}

struct MorningFeelingSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFeeling: String?

    let options = ["神清气爽", "精力充沛", "有点累", "很困", "烦躁"]

    var body: some View {
        NavigationView {
            List {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selectedFeeling = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedFeeling == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("清晨的感觉")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
