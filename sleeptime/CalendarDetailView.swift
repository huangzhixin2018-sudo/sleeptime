// CalendarDetailView.swift
import SwiftUI

// MARK: - Hex color helper (file-private)
private extension Color {
    init(hex string: String) {
        let hex = string.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >>  8) & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}

// MARK: - Month metadata
private struct MonthInfo: Identifiable {
    var id: Int { index }
    let index: Int
    let fullName: String
}

private let kAllMonths: [MonthInfo] = [
    .init(index:  0, fullName: "一月"),
    .init(index:  1, fullName: "二月"),
    .init(index:  2, fullName: "三月"),
    .init(index:  3, fullName: "四月"),
    .init(index:  4, fullName: "五月"),
    .init(index:  5, fullName: "六月"),
    .init(index:  6, fullName: "七月"),
    .init(index:  7, fullName: "八月"),
    .init(index:  8, fullName: "九月"),
    .init(index:  9, fullName: "十月"),
    .init(index: 10, fullName: "十一月"),
    .init(index: 11, fullName: "十二月"),
]

private let kWeekdayLabels = ["一", "二", "三", "四", "五", "六", "日"]

// MARK: - Main View
struct CalendarDetailView: View {

    @State private var viewMode: CalendarViewMode = .year
    private let displayYear: Int = 2026 // Currently hardcoded for the annual view
    private let initialMonth: Int = Calendar.current.component(.month, from: Date()) - 1

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(kAllMonths) { month in
                            monthSection(month)
                                .id(month.index)
                        }
                        Color.clear.frame(height: 100) // Padding for bottom picker
                    }
                }
                .onAppear {
                    proxy.scrollTo(initialMonth, anchor: .top)
                }
            }
            
            ViewModePicker(selectedMode: $viewMode)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // 分享逻辑
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
    }

    // MARK: - [3] Month Section
    @ViewBuilder
    private func monthSection(_ month: MonthInfo) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Month header
            HStack {
                Text(month.fullName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)

            // 7-column day grid
            let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: gridColumns, spacing: 0) {
                // Weekday header row
                ForEach(kWeekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                        .frame(height: 22)
                }
                // Leading empty cells (Monday-based offset)
                let offset = weekdayOffset(year: displayYear, monthIndex: month.index)
                ForEach(0 ..< offset, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }
                // Day cells
                let total = daysInMonth(year: displayYear, monthIndex: month.index)
                ForEach(1 ... max(1, total), id: \.self) { day in
                    if day <= total {
                        dayCell(day: day, monthIndex: month.index)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            Divider()
        }
    }

    // MARK: - Day Cell
    @ViewBuilder
    private func dayCell(day: Int, monthIndex: Int) -> some View {
        let isToday: Bool = {
            var c = DateComponents()
            c.year  = displayYear
            c.month = monthIndex + 1
            c.day   = day
            guard let d = Calendar.current.date(from: c) else { return false }
            return Calendar.current.isDateInToday(d)
        }()

        ZStack {
            if isToday {
                Circle()
                    .fill(Color.primary)
                    .frame(width: 32, height: 32)
            }
            Text("\(day)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? Color(UIColor.systemBackground) : .primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
    }

    // MARK: - Calendar Helpers
    private func daysInMonth(year: Int, monthIndex: Int) -> Int {
        var c = DateComponents()
        c.year  = year
        c.month = monthIndex + 1
        guard let date  = Calendar.current.date(from: c),
              let range = Calendar.current.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }

    /// Empty leading cells so day 1 lands on the correct column (Monday = 0, Sunday = 6).
    private func weekdayOffset(year: Int, monthIndex: Int) -> Int {
        var c = DateComponents()
        c.year  = year
        c.month = monthIndex + 1
        c.day   = 1
        guard let date = Calendar.current.date(from: c) else { return 0 }
        let weekday = Calendar.current.component(.weekday, from: date) // 1 = Sunday
        return (weekday + 5) % 7
    }
}

enum CalendarViewMode: String, CaseIterable {
    case day = "日"
    case month = "月"
    case year = "年"
    case total = "总"
}

struct ViewModePicker: View {
    @Binding var selectedMode: CalendarViewMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue)
                    .font(.system(size: 15, weight: selectedMode == mode ? .medium : .regular))
                    .foregroundColor(selectedMode == mode ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedMode == mode ? Color(.systemBackground) : Color.clear)
                            .shadow(color: Color.black.opacity(selectedMode == mode ? 0.05 : 0), radius: 2, x: 0, y: 1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMode = mode
                        }
                    }
            }
        }
        .padding(4)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal, 40)
        .padding(.bottom, 24)
    }
}

// MARK: - Preview
struct CalendarDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CalendarDetailView()
        }
        .preferredColorScheme(.light)
        NavigationStack {
            CalendarDetailView()
        }
        .preferredColorScheme(.dark)
    }
}
