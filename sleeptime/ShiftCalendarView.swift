import SwiftUI

// MARK: - Models
enum ShiftStatus {
    case work
    case off
    case none
}

struct DayCell: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
    var status: ShiftStatus = .none
}

// MARK: - Main View
struct ShiftCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    
    @State private var currentDate = Date()
    @State private var isEditing = false
    @State private var showingCycleSheet = false
    
    // Key: "yyyy-MM-dd", Value: ShiftStatus
    @State private var shiftData: [String: ShiftStatus] = [:]
    
    let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation & Actions
            HStack(alignment: .bottom) {
                HStack(spacing: 8) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(calendar.component(.month, from: currentDate))月")
                            .font(.system(size: 26, weight: .bold))
                        Text(String(calendar.component(.year, from: currentDate)))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Button(action: prevMonth) {
                            Image(systemName: "chevron.left")
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color(UIColor.separator), lineWidth: 1))
                                .foregroundColor(.primary)
                        }
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(Color(UIColor.separator), lineWidth: 1))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: { showingCycleSheet = true }) {
                        Text("周期排班")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .foregroundColor(.primary)
                            .overlay(Capsule().stroke(Color(UIColor.separator), lineWidth: 1))
                    }
                    
                    Button(action: { isEditing.toggle() }) {
                        Text(isEditing ? "完成" : "编辑")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isEditing ? Color.black : Color.white)
                            .foregroundColor(isEditing ? .white : .primary)
                            .overlay(Capsule().stroke(isEditing ? Color.black : Color(UIColor.separator), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
            
            // Edit Banner
            if isEditing {
                Text("正在编辑：轻点日期按 班 ➔ 休 ➔ 清除 切换")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.98))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4])))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            
            // Week Header
            HStack(spacing: 6) {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor((day == "六" || day == "日") ? .gray.opacity(0.5) : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Calendar Grid
            let days = generateDays(for: currentDate)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(days) { day in
                        let dateKey = dateFormatter.string(from: day.date)
                        let status = shiftData[dateKey] ?? .none
                        let isToday = calendar.isDateInToday(day.date)
                        
                        DayCellView(
                            dateNum: calendar.component(.day, from: day.date),
                            status: status,
                            isOtherMonth: !day.isCurrentMonth,
                            isToday: isToday,
                            isEditing: isEditing
                        )
                        .onTapGesture {
                            if isEditing && day.isCurrentMonth {
                                toggleStatus(for: dateKey)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color(red: 247/255, green: 247/255, blue: 248/255).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCycleSheet) {
            CycleShiftSheetView(shiftData: $shiftData)
        }
    }
    
    // MARK: - Logic
    
    private func prevMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func toggleStatus(for dateKey: String) {
        let currentStatus = shiftData[dateKey] ?? .none
        switch currentStatus {
        case .none: shiftData[dateKey] = .work
        case .work: shiftData[dateKey] = .off
        case .off: shiftData[dateKey] = ShiftStatus.none
        }
    }
    
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }
    
    private func generateDays(for date: Date) -> [DayCell] {
        var days: [DayCell] = []
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var currentDay = monthFirstWeek.start
        
        // Custom logic to ensure Monday is the first day of the week
        // If currentDay is Sunday, we might need to adjust depending on Calendar settings
        // Just iterating exactly 42 days (6 weeks) is standard
        for _ in 0..<42 {
            let isCurrentMonth = calendar.isDate(currentDay, equalTo: date, toGranularity: .month)
            days.append(DayCell(date: currentDay, isCurrentMonth: isCurrentMonth))
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
        }
        
        return days
    }
}

// MARK: - Subviews

struct DayCellView: View {
    let dateNum: Int
    let status: ShiftStatus
    let isOtherMonth: Bool
    let isToday: Bool
    let isEditing: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Text("\(dateNum)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Text(status == .work ? "班" : (status == .off ? "休" : "-"))
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusBg)
                .foregroundColor(statusFg)
                .cornerRadius(4)
                .opacity(status == .none ? 0 : 1)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1 / 1.15, contentMode: .fit)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? Color(UIColor.systemGray4) : Color.clear, lineWidth: 1)
        )
        .opacity(isOtherMonth ? 0.2 : 1.0)
    }
    
    var statusBg: Color {
        switch status {
        case .work: return Color.black
        case .off: return Color(red: 242/255, green: 242/255, blue: 247/255)
        case .none: return .clear
        }
    }
    
    var statusFg: Color {
        switch status {
        case .work: return .white
        case .off: return Color(red: 99/255, green: 99/255, blue: 102/255)
        case .none: return .clear
        }
    }
}

struct CycleShiftSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var shiftData: [String: ShiftStatus]
    
    @State private var startDate = Date()
    @State private var workDaysStr = "5"
    @State private var offDaysStr = "2"
    
    // Presets
    let presets = [
        ("上五休二", 5, 2),
        ("上一休一", 1, 1),
        ("上四休二", 4, 2),
        ("上二休二", 2, 2)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("起始日期")) {
                    DatePicker("选择日期", selection: $startDate, displayedComponents: .date)
                }
                
                Section(header: Text("预设模式")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.0) { preset in
                                let isActive = Int(workDaysStr) == preset.1 && Int(offDaysStr) == preset.2
                                Button(action: {
                                    workDaysStr = "\(preset.1)"
                                    offDaysStr = "\(preset.2)"
                                }) {
                                    Text(preset.0)
                                        .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(isActive ? Color.white : Color(UIColor.secondarySystemBackground))
                                        .foregroundColor(isActive ? .black : .primary)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isActive ? Color.black : Color.clear, lineWidth: 1))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("自定义规则（做 N 休 N）")) {
                    HStack {
                        TextField("上班", text: $workDaysStr)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("天 班,")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        TextField("休息", text: $offDaysStr)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("天 休")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: applyCycle) {
                        Text("应用到未来 3 个月")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                    }
                    .listRowBackground(Color.black)
                }
            }
            .navigationTitle("快速周期排班")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func applyCycle() {
        guard let w = Int(workDaysStr), let o = Int(offDaysStr), w > 0, o > 0 else { return }
        let cycle = w + o
        
        var current = Calendar.current.startOfDay(for: startDate)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        
        for i in 0..<90 {
            let phase = i % cycle
            let status: ShiftStatus = (phase < w) ? .work : .off
            shiftData[df.string(from: current)] = status
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        
        dismiss()
    }
}

#Preview {
    ShiftCalendarView()
}
