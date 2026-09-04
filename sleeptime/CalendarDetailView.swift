// CalendarDetailView.swift
import SwiftUI

/// A calendar view that mimics the calendar component from the reference
/// `cike-sleepwell-ios` project. It shows the current month in a grid, highlights
/// today's date and adapts to Light/Dark mode.
struct CalendarDetailView: View {
    // The month currently displayed. Users can swipe later to change month –
    // for now we keep it simple and show the current month.
    @State private var displayedMonth: Date = Date()
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    // MARK: - Date helpers
    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return [] }
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    // Offset so the first day aligns with the correct weekday (Monday = 0).
    private var firstWeekdayOffset: Int {
        let calendar = Calendar.current
        guard let firstDay = daysInMonth.first else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDay) // 1 = Sunday
        // Convert to Monday‑based index (Monday = 0 … Sunday = 6).
        return (weekday + 5) % 7
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 M 月"
        return formatter.string(from: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        var symbols = DateFormatter().shortWeekdaySymbols ?? [] // Sun … Sat
        // Re‑order so Monday comes first.
        let sunday = symbols.removeFirst()
        symbols.append(sunday)
        return symbols
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header – month and year.
                HStack {
                    Text(monthYearString)
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal)

                // Weekday titles.
                HStack {
                    ForEach(weekdaySymbols, id: \ .self) { symbol in
                        Text(symbol)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                // Calendar grid.
                LazyVGrid(columns: columns, spacing: 12) {
                    // Empty cells before the first day of the month.
                    ForEach(0..<firstWeekdayOffset, id: \ .self) { _ in
                        Color.clear.frame(height: 40)
                    }
                    // Day cells.
                    ForEach(daysInMonth, id: \ .self) { date in
                        dayCell(for: date)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.95),
                    Color(red: 0.94, green: 0.92, blue: 0.90)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("日历")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Day cell view
    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let day = Calendar.current.component(.day, from: date)
        let isToday = Calendar.current.isDateInToday(date)
        Text("\(day)")
            .font(.system(size: 16, weight: .medium))
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(isToday ? Color.blue.opacity(0.2) : Color.clear)
            )
            .overlay(
                Circle()
                    .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
            )
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
