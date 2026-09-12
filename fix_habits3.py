import re

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

# 1. BlankPlanView State
old_blank_state = """    @State private var meditationCheckInTime: String?"""
new_blank_state = """    @State private var meditationCheckInTime: String?
    @State private var habits: [BedtimeHabit] = [
        BedtimeHabit(name: "冥想", hasAlarm: true, alarmTime: Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date(), repeatDays: [0,1,2,3,4,5,6], checkInTime: nil)
    ]
    @State private var isShowingAddHabitSheet = false"""
if new_blank_state not in content:
    content = content.replace(old_blank_state, new_blank_state)

# 2. CurrentPlanExportView
old_export_props = """    let currentEarlySleepStreak: Int
    let meditationCheckInTime: String?"""
new_export_props = """    let currentEarlySleepStreak: Int
    let meditationCheckInTime: String?
    let habits: [BedtimeHabit]"""
content = content.replace(old_export_props, new_export_props)

old_export_init = """                targetEarlySleepStreak: targetEarlySleepStreak,
                currentEarlySleepStreak: currentEarlySleepStreak,
                meditationCheckInTime: meditationCheckInTime
            )"""
new_export_init = """                targetEarlySleepStreak: targetEarlySleepStreak,
                currentEarlySleepStreak: currentEarlySleepStreak,
                meditationCheckInTime: meditationCheckInTime,
                habits: habits
            )"""
content = content.replace(old_export_init, new_export_init)

old_export_call = """            PlanHabitSection(
                meditationCheckInTime: .constant(meditationCheckInTime),
                showsAddButton: false
            )"""
new_export_call = """            PlanHabitSection(
                habits: .constant(habits),
                isShowingAddHabitSheet: .constant(false),
                showsAddButton: false
            )"""
content = content.replace(old_export_call, new_export_call)

# 3. PlanHabitSection definition
# Need to remove `private var isMeditationCompleted: Bool { meditationCheckInTime != nil }`
old_is_meditation = """    private var isMeditationCompleted: Bool {
        meditationCheckInTime != nil
    }"""
content = content.replace(old_is_meditation, "")

# 4. In CurrentPlanExportView, remove usage of isMeditationCompleted
old_export_display = """                        Group {
                            if day == 1 && isMeditationCompleted {
                                Text(meditationCheckInTime ?? "")
                                    .font(.system(size: 13, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.black.opacity(0.8))
                                    .padding(.top, 4)
                            }
                        }"""
new_export_display = """                        Group {
                            if day == 1, let firstHabit = habits.first, firstHabit.isCompleted {
                                Text(firstHabit.checkInTime ?? "")
                                    .font(.system(size: 13, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.black.opacity(0.8))
                                    .padding(.top, 4)
                            }
                        }"""
content = content.replace(old_export_display, new_export_display)

# 5. Fix CalendarView or other places using isMeditationCompleted (line 1025)
# Wait, line 1025 in the error was: "cannot find meditationCheckInTime in scope"
# Let's see what is at line 1025 in the next run. For now, replace `isMeditationCompleted` with `firstHabit.isCompleted` in CalendarView or ExportView

with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(content)

print("Fixed CurrentPlanExportView.")
