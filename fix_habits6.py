import re

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

# Fix 1: Add habits to CurrentPlanExportView instantiation at line ~857 if missing
# In PlanSnapshotView:
#                 CurrentPlanExportView(
#                    targetEarlySleepStreak: 3,
#                    currentEarlySleepStreak: 1,
#                    meditationCheckInTime: meditationCheckInTime
#                )
# We need to add habits: [] there since we added `let habits: [BedtimeHabit]` to `CurrentPlanExportView`.
old_snapshot_export = """                CurrentPlanExportView(
                    targetEarlySleepStreak: 3,
                    currentEarlySleepStreak: 1,
                    meditationCheckInTime: meditationCheckInTime
                )"""
new_snapshot_export = """                CurrentPlanExportView(
                    targetEarlySleepStreak: 3,
                    currentEarlySleepStreak: 1,
                    meditationCheckInTime: meditationCheckInTime,
                    habits: [BedtimeHabit(name: "冥想", hasAlarm: true, alarmTime: Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date(), repeatDays: [0,1,2,3,4,5,6], checkInTime: nil)]
                )"""
content = content.replace(old_snapshot_export, new_snapshot_export)


# Let's fix TodayWorkCardView state first
today_work_card_pattern = r"(struct TodayWorkCardView: View \{.*?)(var body: some View \{)"

def add_state(match):
    prefix = match.group(1)
    body_decl = match.group(2)
    if "isShowingWorthIt" not in prefix:
        new_state = "    @State private var isShowingWorthIt = false\n    @State private var isShowingReason = false\n    \n    "
        return prefix + new_state + body_decl
    return match.group(0)

content = re.sub(today_work_card_pattern, add_state, content, flags=re.DOTALL)

old_clipshape = ".clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))"
new_clipshape = """.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .sheet(isPresented: $isShowingWorthIt) {
            StayUpLateEvaluationView()
        }
        .sheet(isPresented: $isShowingReason) {
            StayUpLateReasonView()
        }"""
today_work_card_full = re.search(r"struct TodayWorkCardView: View \{.*?\n\}", content, flags=re.DOTALL)
if today_work_card_full:
    twc_str = today_work_card_full.group(0)
    if ".sheet(isPresented: $isShowingWorthIt)" not in twc_str:
        if old_clipshape in twc_str:
            parts = twc_str.rsplit(old_clipshape, 1)
            new_twc_str = parts[0] + new_clipshape + parts[1]
            content = content.replace(twc_str, new_twc_str)

with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(content)
