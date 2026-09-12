import sys

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

# 1. Fix BlankPlanView state
old_blank_state = """    @State private var meditationCheckInTime: String?"""
new_blank_state = """    @State private var meditationCheckInTime: String?
    @State private var habits: [BedtimeHabit] = [
        BedtimeHabit(name: "冥想", hasAlarm: true, alarmTime: Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date(), repeatDays: [0,1,2,3,4,5,6], checkInTime: nil)
    ]
    @State private var isShowingAddHabitSheet = false"""
if new_blank_state not in content:
    content = content.replace(old_blank_state, new_blank_state)


# 2. Fix PlanSnapshotView
old_snapshot_props = """    let targetEarlySleepStreak: Int
    let currentEarlySleepStreak: Int
    let meditationCheckInTime: String?"""
new_snapshot_props = """    let targetEarlySleepStreak: Int
    let currentEarlySleepStreak: Int
    let meditationCheckInTime: String?
    let habits: [BedtimeHabit]"""
if "let habits: [BedtimeHabit]" not in content.split("struct PlanSnapshotView: View {")[1]:
    content = content.replace(old_snapshot_props, new_snapshot_props)

old_snapshot_init = """                targetEarlySleepStreak: targetEarlySleepStreak,
                currentEarlySleepStreak: currentEarlySleepStreak,
                meditationCheckInTime: meditationCheckInTime
            )"""
new_snapshot_init = """                targetEarlySleepStreak: targetEarlySleepStreak,
                currentEarlySleepStreak: currentEarlySleepStreak,
                meditationCheckInTime: meditationCheckInTime,
                habits: habits
            )"""
content = content.replace(old_snapshot_init, new_snapshot_init)

old_snapshot_call = """            PlanHabitSection(
                meditationCheckInTime: .constant(meditationCheckInTime),
                showsAddButton: false
            )"""
new_snapshot_call = """            PlanHabitSection(
                habits: .constant(habits),
                isShowingAddHabitSheet: .constant(false),
                showsAddButton: false
            )"""
content = content.replace(old_snapshot_call, new_snapshot_call)

old_snapshot_display = """                        Group {
                            if day == 1 && isMeditationCompleted {
                                Text(meditationCheckInTime ?? "")
                                    .font(.system(size: 13, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.black.opacity(0.8))
                                    .padding(.top, 4)
                            }
                        }"""
new_snapshot_display = """                        Group {
                            if day == 1, let firstHabit = habits.first, firstHabit.isCompleted {
                                Text(firstHabit.checkInTime ?? "")
                                    .font(.system(size: 13, weight: .semibold))
                                    .monospacedDigit()
                                    .foregroundColor(Color.black.opacity(0.8))
                                    .padding(.top, 4)
                            }
                        }"""
content = content.replace(old_snapshot_display, new_snapshot_display)

# Remove isMeditationCompleted from PlanSnapshotView
old_is_meditation_completed_snapshot = """    private var isMeditationCompleted: Bool {
        meditationCheckInTime != nil
    }"""
content = content.replace(old_is_meditation_completed_snapshot, "")


# 3. Fix PlanHabitSection internals
import re
plan_habit_section_pattern = r"private struct PlanHabitSection: View \{.*?\n        \}\n    \}\n\}"
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
            }
        }
    }
}"""
content = re.sub(plan_habit_section_pattern, new_plan_habit_section, content, flags=re.DOTALL)


# 4. Fix AddHabitSheet usage if any.
# In inject_add_habit, it did replace ActivityShareSheet with AddHabitSheet. Let's make sure it's valid.

with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(content)

print("Fixed again.")
