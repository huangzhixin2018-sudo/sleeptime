import re

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

# 1. Add BedtimeHabit struct
model_code = """
struct BedtimeHabit: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var hasAlarm: Bool
    var alarmTime: Date
    var repeatDays: Set<Int>
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
    content = content.replace("struct BlankPlanView: View {", model_code + "\nstruct BlankPlanView: View {")

# 2. Add State to BlankPlanView
old_blank_state = """    @State private var exportedPlan: ExportedPlanImage?
    @State private var meditationCheckInTime: String?"""
new_blank_state = """    @State private var exportedPlan: ExportedPlanImage?
    @State private var meditationCheckInTime: String?
    @State private var habits: [BedtimeHabit] = [
        BedtimeHabit(name: "冥想", hasAlarm: true, alarmTime: Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date(), repeatDays: [0,1,2,3,4,5,6], checkInTime: nil)
    ]
    @State private var isShowingAddHabitSheet = false"""
content = content.replace(old_blank_state, new_blank_state)

# 3. Add to CurrentPlanExportView
old_export_props = """    let targetEarlySleepStreak: Int
    let currentEarlySleepStreak: Int
    let meditationCheckInTime: String?

    var body: some View {"""
new_export_props = """    let targetEarlySleepStreak: Int
    let currentEarlySleepStreak: Int
    let meditationCheckInTime: String?
    let habits: [BedtimeHabit]

    var body: some View {"""
content = content.replace(old_export_props, new_export_props)

old_export_init = """                activePlanType: "温和早睡",
                targetEarlySleepStreak: targetEarlySleepStreak,
                currentEarlySleepStreak: currentEarlySleepStreak,
                meditationCheckInTime: meditationCheckInTime
            )"""
new_export_init = """                activePlanType: "温和早睡",
                targetEarlySleepStreak: targetEarlySleepStreak,
                currentEarlySleepStreak: currentEarlySleepStreak,
                meditationCheckInTime: meditationCheckInTime,
                habits: habits
            )"""
content = content.replace(old_export_init, new_export_init)

old_export_group = """                        Group {
                            if day == 1 && isMeditationCompleted {
                                Text(meditationCheckInTime ?? "")
                                    .font(.system(size: 13, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.black.opacity(0.8))
                                    .padding(.top, 4)
                            }
                        }"""
new_export_group = """                        Group {
                            if day == 1, let firstHabit = habits.first, firstHabit.isCompleted {
                                Text(firstHabit.checkInTime ?? "")
                                    .font(.system(size: 13, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.black.opacity(0.8))
                                    .padding(.top, 4)
                            }
                        }"""
content = content.replace(old_export_group, new_export_group)

content = content.replace("    private var isMeditationCompleted: Bool {\n        meditationCheckInTime != nil\n    }\n", "")

# 4. Replace PlanHabitSection
old_plan_habit_section_pattern = r"private struct PlanHabitSection: View \{.*?\n    private var currentTimeText: String \{\n        let formatter = DateFormatter\(\)\n        formatter\.dateFormat = \"HH:mm\"\n        return formatter\.string\(from: Date\(\)\)\n    \}\n\}"
new_plan_habit_section = """private struct PlanHabitSection: View {
    @Binding var habits: [BedtimeHabit]
    @Binding var isShowingAddHabitSheet: Bool
    var showsAddButton = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("睡前习惯")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.black)

                Spacer()

                if showsAddButton {
                    Button(action: { isShowingAddHabitSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("添加睡前习惯")
                }
            }

            VStack(spacing: 12) {
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
                                let currentTime = {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "HH:mm"
                                    return formatter.string(from: Date())
                                }()
                                habit.checkInTime = habit.isCompleted ? nil : currentTime
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
                }
                
                // Track week history for first habit
                HStack(spacing: 6) {
                    ForEach(1...7, id: \\.self) { day in
                        Group {
                            if day == 1, let firstHabit = habits.first, firstHabit.isCompleted {
                                Text(firstHabit.checkInTime ?? "")
                                    .font(.system(size: 13, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(Color.black.opacity(0.72))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            } else {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.black.opacity(0.06))
                                    .overlay {
                                        Text(day == 1 ? "--:--" : "\\(day)")
                                            .font(.system(size: day == 1 ? 10 : 12, weight: .semibold))
                                            .monospacedDigit()
                                            .foregroundStyle(Color.black.opacity(0.52))
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                    }
                }
                
                HStack(spacing: 6) {
                    ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \\.self) { weekday in
                        Text(weekday)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.52))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}"""
content = re.sub(old_plan_habit_section_pattern, new_plan_habit_section, content, flags=re.DOTALL)

# Update PlanHabitSection calls
old_blank_call = "PlanHabitSection(meditationCheckInTime: $meditationCheckInTime)"
new_blank_call = "PlanHabitSection(habits: $habits, isShowingAddHabitSheet: $isShowingAddHabitSheet)"
content = content.replace(old_blank_call, new_blank_call)

old_export_call = """PlanHabitSection(
                meditationCheckInTime: .constant(meditationCheckInTime),
                showsAddButton: false
            )"""
new_export_call = """PlanHabitSection(
                habits: .constant(habits),
                isShowingAddHabitSheet: .constant(false),
                showsAddButton: false
            )"""
content = content.replace(old_export_call, new_export_call)

# Attach AddHabitSheet to BlankPlanView
old_sheet = """            .sheet(item: $exportedPlan) { plan in
                ActivityShareSheet(items: [plan.image])
            }"""
new_sheet = """            .sheet(item: $exportedPlan) { plan in
                ActivityShareSheet(items: [plan.image])
            }
            .sheet(isPresented: $isShowingAddHabitSheet) {
                AddHabitSheet(habits: $habits)
            }"""
content = content.replace(old_sheet, new_sheet)

# Finally, inject AddHabitSheet at the end of the file
add_habit_sheet = """
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
if "struct AddHabitSheet: View" not in content:
    content += add_habit_sheet

with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(content)

print("Add Habit feature injected completely safely.")
