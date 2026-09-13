import SwiftUI

struct AddSleepRecordSheet: View {
    let date: Date
    @Environment(\.dismiss) private var dismiss
    
    @State private var bedtime: Date
    @State private var wakeTime: Date
    
    init(date: Date) {
        self.date = date
        
        let calendar = Calendar.current
        // Default bedtime: 23:00 on the selected date
        let defaultBedtime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date) ?? date
        // Default wake time: 07:00 next day
        let defaultWakeTime = calendar.date(byAdding: .day, value: 1, to: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: date) ?? date) ?? date
        
        _bedtime = State(initialValue: defaultBedtime)
        _wakeTime = State(initialValue: defaultWakeTime)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("打卡日期").textCase(nil)) {
                    HStack {
                        Text("日期")
                        Spacer()
                        Text(dateFormatter.string(from: date))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("睡眠时间").textCase(nil)) {
                    DatePicker("入睡时间", selection: $bedtime, displayedComponents: .hourAndMinute)
                    DatePicker("起床时间", selection: $wakeTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func saveRecord() {
        // Here we would implement saving the record to AppStorage or CoreData
        // For now, it just closes the sheet.
        print("Record saved for \(dateFormatter.string(from: date)): Bedtime \(bedtime), Wake \(wakeTime)")
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        return formatter
    }
}
