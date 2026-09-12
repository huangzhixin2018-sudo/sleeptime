import sys
import re

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

model_code = """
struct BedtimeHabit: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var hasAlarm: Bool
    var alarmTime: Date
    var repeatDays: Set<Int> // 0: Sun, 1: Mon, ..., 6: Sat
    var checkInTime: String?
    
    var isCompleted: Bool {
        checkInTime != nil
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: alarmTime)
    }
}
"""

if "struct BedtimeHabit" not in content:
    # Add it before BlankPlanView
    content = content.replace("struct BlankPlanView: View {", model_code + "\nstruct BlankPlanView: View {")


old_habit_prop = "@Binding var meditationCheckInTime: String?"
new_habit_prop = """@Binding var habits: [BedtimeHabit]
    @Binding var isShowingAddHabitSheet: Bool"""
content = content.replace(old_habit_prop, new_habit_prop)

old_habit_plus_action = """                    Button(action: {}) {"""
new_habit_plus_action = """                    Button(action: { isShowingAddHabitSheet = true }) {"""
content = content.replace(old_habit_plus_action, new_habit_plus_action)

old_habit_list = """            VStack(spacing: 12) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("冥想")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(Color.black)

                    Text("（12:00 提醒）")
                        .font(.system(size: 15, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(Color.black.opacity(0.62))

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            meditationCheckInTime = isMeditationCompleted ? nil : currentTimeText
                        }
                    } label: {
                        Circle()
                            .fill(isMeditationCompleted ? AppTheme.accent : Color.clear)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Circle()
                                    .stroke(
                                        isMeditationCompleted ? Color.clear : Color.black.opacity(0.18),
                                        lineWidth: 1.5
                                    )
                            }
                            .overlay {
                                if isMeditationCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isMeditationCompleted ? "取消冥想打卡" : "完成冥想打卡")
                }"""

new_habit_list = """            VStack(spacing: 12) {
                ForEach($habits) { $habit in
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(habit.name)
                            .font(.system(size: 23, weight: .bold))
                            .foregroundStyle(Color.black)

                        if habit.hasAlarm {
                            Text("（\\(habit.timeString) 提醒）")
                                .font(.system(size: 15, weight: .regular))
                                .monospacedDigit()
                                .foregroundStyle(Color.black.opacity(0.62))
                        }

                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                habit.checkInTime = habit.isCompleted ? nil : currentTimeText
                            }
                        } label: {
                            Circle()
                                .fill(habit.isCompleted ? AppTheme.accent : Color.clear)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            habit.isCompleted ? Color.clear : Color.black.opacity(0.18),
                                            lineWidth: 1.5
                                        )
                                }
                                .overlay {
                                    if habit.isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(habit.isCompleted ? "取消\\(habit.name)打卡" : "完成\\(habit.name)打卡")
                    }
                }"""
content = content.replace(old_habit_list, new_habit_list)


# BlankPlanView updates
old_meditation_state = """@AppStorage("meditationCheckInTime") private var meditationCheckInTime: String?"""
new_meditation_state = """@AppStorage("meditationCheckInTime") private var meditationCheckInTime: String?
    @State private var habits: [BedtimeHabit] = [
        BedtimeHabit(name: "冥想", hasAlarm: true, alarmTime: Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date(), repeatDays: [0,1,2,3,4,5,6], checkInTime: nil)
    ]
    @State private var isShowingAddHabitSheet = false
"""
content = content.replace(old_meditation_state, new_meditation_state)

old_habit_usage = """PlanHabitSection(meditationCheckInTime: $meditationCheckInTime)"""
new_habit_usage = """PlanHabitSection(habits: $habits, isShowingAddHabitSheet: $isShowingAddHabitSheet)"""
content = content.replace(old_habit_usage, new_habit_usage)

old_sheet_usage = """            .sheet(item: $exportedPlan) { plan in
                ActivityShareSheet(items: [plan.image])
            }"""
new_sheet_usage = """            .sheet(item: $exportedPlan) { plan in
                ActivityShareSheet(items: [plan.image])
            }
            .sheet(isPresented: $isShowingAddHabitSheet) {
                AddHabitSheet(habits: $habits)
            }"""
content = content.replace(old_sheet_usage, new_sheet_usage)

# Add the AddHabitSheet at the end
sheet_code = """
struct AddHabitSheet: View {
    @Environment(\\.dismiss) private var dismiss
    @Binding var habits: [BedtimeHabit]
    
    @State private var name: String = ""
    @State private var hasAlarm: Bool = true
    @State private var alarmTime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
    @State private var repeatDays: Set<Int> = [0, 1, 2, 3, 4, 5, 6] // Default all
    
    let daysOfWeek = ["日", "一", "二", "三", "四", "五", "六"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button("取消") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("新建睡前习惯")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button("保存") {
                            let newHabit = BedtimeHabit(
                                name: name.isEmpty ? "新习惯" : name,
                                hasAlarm: hasAlarm,
                                alarmTime: alarmTime,
                                repeatDays: repeatDays,
                                checkInTime: nil
                            )
                            withAnimation {
                                habits.append(newHabit)
                            }
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            
                            // Name Input
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("习惯名称，如：冥想、拉伸、看书...", text: $name)
                                    .font(.system(size: 20, weight: .medium))
                                    .padding(.vertical, 8)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)
                            
                            // Alarm Section
                            VStack(alignment: .leading, spacing: 16) {
                                Toggle(isOn: $hasAlarm) {
                                    Text("开启提醒")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                .tint(.black)
                                
                                if hasAlarm {
                                    HStack {
                                        Text("时间")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        DatePicker("", selection: $alarmTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Repeat Days Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("重复日期")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                
                                HStack(spacing: 8) {
                                    ForEach(0..<7) { index in
                                        Button {
                                            if repeatDays.contains(index) {
                                                if repeatDays.count > 1 { // Prevent unselecting all
                                                    repeatDays.remove(index)
                                                }
                                            } else {
                                                repeatDays.insert(index)
                                            }
                                        } label: {
                                            Text(daysOfWeek[index])
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(repeatDays.contains(index) ? .white : .black)
                                                .frame(width: 40, height: 40)
                                                .background(repeatDays.contains(index) ? Color.black : Color.white)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(repeatDays.contains(index) ? Color.clear : Color.black.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                        if index < 6 { Spacer() }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
"""

content += "\n" + sheet_code

with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(content)

print("AddHabitSheet injected.")
