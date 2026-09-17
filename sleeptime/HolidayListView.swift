import SwiftUI

struct HolidayItem: Identifiable {
    let id = UUID()
    var name: String
    var date: String
    var detail: String
    var days: String
}

struct HolidayListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility

    @State private var holidays = [
        HolidayItem(name: "元旦", date: "1月1日 至 1月3日", detail: "周四 至 周六", days: "3天"),
        HolidayItem(name: "春节", date: "2月15日 至 2月23日", detail: "腊月廿八 至 正月初七", days: "9天"),
        HolidayItem(name: "清明节", date: "4月4日 至 4月6日", detail: "周六 至 周一", days: "3天"),
        HolidayItem(name: "劳动节", date: "5月1日 至 5月5日", detail: "周五 至 周二", days: "5天"),
        HolidayItem(name: "端午节", date: "6月19日 至 6月21日", detail: "周五 至 周日", days: "3天"),
        HolidayItem(name: "中秋节", date: "9月25日 至 9月27日", detail: "周五 至 周日", days: "3天"),
        HolidayItem(name: "国庆节", date: "10月1日 至 10月7日", detail: "周四 至 周三", days: "7天")
    ]
    
    @State private var showingAddSheet = false
    @State private var newHolidayName = ""
    @State private var newHolidayStartDate = Date()
    @State private var newHolidayEndDate = Date()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 17/255, green: 17/255, blue: 17/255))
                    }
                    Spacer()
                    Text("法定节假日")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 17/255, green: 17/255, blue: 17/255))
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.92))
                
                Divider()
                    .background(Color(red: 240/255, green: 240/255, blue: 242/255))

                // List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(holidays.indices, id: \.self) { index in
                            let item = holidays[index]
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text(item.name)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(Color(red: 17/255, green: 17/255, blue: 17/255))
                                        Text(item.date)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(Color(red: 68/255, green: 68/255, blue: 68/255))
                                    }
                                    Text(item.detail)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                                }
                                Spacer()
                                Text(item.days)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 29/255, green: 29/255, blue: 31/255))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 10)
                                    .background(Color(red: 245/255, green: 245/255, blue: 247/255))
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 16)
                            
                            if index < holidays.count - 1 {
                                Divider()
                                    .background(Color(red: 240/255, green: 240/255, blue: 242/255))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Space for button
                }
            }
            
            // Fixed Add Button
            Button(action: {
                newHolidayName = ""
                newHolidayStartDate = Date()
                newHolidayEndDate = Date()
                showingAddSheet = true
            }) {
                Text("添加假期")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.black)
                    .cornerRadius(27)
                    .padding(.horizontal, 20)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, 34) // Safe area equivalent
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddSheet) {
            NavigationView {
                Form {
                    Section {
                        TextField("假期名称", text: $newHolidayName)
                        DatePicker("开始日期", selection: $newHolidayStartDate, displayedComponents: .date)
                        DatePicker("结束日期", selection: $newHolidayEndDate, displayedComponents: .date)
                    }
                }
                .navigationTitle("添加假期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            showingAddSheet = false
                        }
                        .foregroundColor(.gray)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("添加") {
                            addCustomHoliday()
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .disabled(newHolidayName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private func addCustomHoliday() {
        guard !newHolidayName.isEmpty else { return }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        
        let startStr = formatter.string(from: newHolidayStartDate)
        let endStr = formatter.string(from: newHolidayEndDate)
        let dateRangeStr = (startStr == endStr) ? startStr : "\(startStr) 至 \(endStr)"
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "zh_CN")
        weekdayFormatter.dateFormat = "E" // 会输出周一等
        let startWeekday = weekdayFormatter.string(from: newHolidayStartDate)
        let endWeekday = weekdayFormatter.string(from: newHolidayEndDate)
        let detailStr = (startWeekday == endWeekday) ? startWeekday : "\(startWeekday) 至 \(endWeekday)"
        
        let calendar = Calendar.current
        let startOfStart = calendar.startOfDay(for: newHolidayStartDate)
        let startOfEnd = calendar.startOfDay(for: newHolidayEndDate)
        let components = calendar.dateComponents([.day], from: startOfStart, to: startOfEnd)
        let daysCount = max(1, (components.day ?? 0) + 1)
        let daysStr = "\(daysCount)天"
        
        let newHoliday = HolidayItem(name: newHolidayName, date: dateRangeStr, detail: detailStr, days: daysStr)
        holidays.append(newHoliday)
        
        // 可选：按日期重新排序
        // 这里为了简单，目前默认加在最后，你可以自己根据业务调整
        
        showingAddSheet = false
    }
}

#Preview {
    HolidayListView()
}
