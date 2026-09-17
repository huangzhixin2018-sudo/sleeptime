import SwiftUI
import Combine

enum AlarmItemType {
    case alarm
    case countdown
}

struct AlarmItem: Identifiable {
    let id = UUID()
    var type: AlarmItemType
    var title: String
    var targetDate: Date
    var isActive: Bool
}

struct AlarmDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    
    @State private var items: [AlarmItem] = [
        AlarmItem(type: .alarm, title: "早起", targetDate: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date(), isActive: true),
        AlarmItem(type: .countdown, title: "新年", targetDate: Calendar.current.date(byAdding: .day, value: 50, to: Date()) ?? Date(), isActive: true)
    ]
    
    @State private var showingAddSheet = false
    
    // 强制触发 UI 刷新倒计时
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Text("闹钟提醒")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.92))
                
                Divider()
                    .background(Color(white: 0.9))

                // List
                ScrollView(showsIndicators: false) {
                    if items.isEmpty {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 100)
                            Image(systemName: "alarm")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("暂无提醒事项")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    } else {
                        VStack(spacing: 16) {
                            ForEach($items) { $item in
                                if item.type == .alarm {
                                    AlarmCardView(item: $item)
                                } else {
                                    CountdownCardView(item: $item, currentTime: currentTime)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 120) // Space for button
                    }
                }
            }
            
            // Fixed Add Button
            Button(action: {
                showingAddSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.black)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 34) // Safe area equivalent
        }
        .background(Color(red: 247/255, green: 247/255, blue: 249/255).ignoresSafeArea())
        .navigationBarHidden(true)
        .onReceive(timer) { input in
            currentTime = input
        }
        .sheet(isPresented: $showingAddSheet) {
            AddEditAlarmSheet { newItem in
                items.append(newItem)
            }
        }
    }
}

// MARK: - Cards

struct AlarmCardView: View {
    @Binding var item: AlarmItem
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: item.targetDate)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeString)
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(item.isActive ? .primary : .gray)
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(item.isActive ? .gray : .gray.opacity(0.5))
            }
            Spacer()
            Toggle("", isOn: $item.isActive)
                .labelsHidden()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 2)
    }
}

struct CountdownCardView: View {
    @Binding var item: AlarmItem
    let currentTime: Date
    
    var timeRemainingString: String {
        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: currentTime, to: item.targetDate)
        
        if item.targetDate <= currentTime {
            return "已结束"
        }
        
        if let days = components.day, days > 0 {
            return "\(days) 天"
        } else {
            let h = components.hour ?? 0
            let m = components.minute ?? 0
            let s = components.second ?? 0
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.isActive ? .primary : .gray)
                
                let formatter = DateFormatter()
                let _ = formatter.dateFormat = "yyyy-MM-dd"
                Text(formatter.string(from: item.targetDate))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
            }
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeRemainingString)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(item.isActive ? (item.targetDate <= currentTime ? .gray : .blue) : .gray)
                    .monospacedDigit()
            }
            
            // Delete button could go here or swipe to delete, keep clean for now
            // Or toggle
            Toggle("", isOn: $item.isActive)
                .labelsHidden()
                .padding(.leading, 12)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 2)
    }
}

// MARK: - Add Sheet

struct AddEditAlarmSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: AlarmItemType = .alarm
    @State private var title: String = ""
    @State private var targetDate: Date = Date()
    
    var onSave: (AlarmItem) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Picker("类型", selection: $selectedType) {
                    Text("闹钟").tag(AlarmItemType.alarm)
                    Text("倒计时").tag(AlarmItemType.countdown)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .padding(.vertical, 8)
                
                Section {
                    TextField(selectedType == .alarm ? "标签 (如: 起床)" : "事件名称 (如: 生日)", text: $title)
                    
                    if selectedType == .alarm {
                        DatePicker("时间", selection: $targetDate, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                    } else {
                        DatePicker("目标时间", selection: $targetDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle(selectedType == .alarm ? "添加闹钟" : "添加倒计时")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let finalTitle = title.isEmpty ? (selectedType == .alarm ? "闹钟" : "倒计时") : title
                        let newItem = AlarmItem(type: selectedType, title: finalTitle, targetDate: targetDate, isActive: true)
                        onSave(newItem)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    AlarmDetailView()
}
