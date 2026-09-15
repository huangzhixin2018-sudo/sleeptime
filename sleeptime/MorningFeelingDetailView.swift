import SwiftUI

struct MorningFeelingRecord: Identifiable {
    var id: Date { date }
    let date: Date
    let feeling: String? // nil means "无记录"
    let iconName: String?
    let iconColor: Color?
}

struct MorningFeelingDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()

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
                return MorningFeelingRecord(date: date, feeling: "您今天早上感觉如何？", iconName: "face.dashed", iconColor: .gray)
            } else if daysAgo == 2 {
                return MorningFeelingRecord(date: date, feeling: "恼火", iconName: "face.smiling", iconColor: .purple)
            } else if daysAgo == 3 {
                return MorningFeelingRecord(date: date, feeling: "神清气爽", iconName: "face.smiling", iconColor: .orange)
            } else {
                return MorningFeelingRecord(date: date, feeling: nil, iconName: "face.dashed", iconColor: .gray.opacity(0.5))
            }
        }
    }

    var monthString: String {
        selectedDate.formatted(.dateTime.year().month(.wide).locale(Locale(identifier: "zh_CN")))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                }

                Spacer()

                Text("早晨的感觉")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                // 占位，保持标题居中
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)

            // 月份选择器
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(monthString)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.black)
                }

                Spacer()

                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .month))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // 列表
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(records) { record in
                        MorningFeelingRowView(record: record)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
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

    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(record.iconColor ?? .clear)
                    .frame(width: 44, height: 44)

                if let iconName = record.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(record.feeling == nil ? .gray.opacity(0.5) : (record.iconColor == .gray ? .gray : .white))
                }
            }

            // 文本
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(record.feeling == nil ? .gray : .black.opacity(0.8))

                if let feeling = record.feeling {
                    Text(feeling)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                } else {
                    Text("无记录")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            record.feeling == "您今天早上感觉如何？" ? Color.gray.opacity(0.1) : Color.clear
        )
        .cornerRadius(12)
    }
}
