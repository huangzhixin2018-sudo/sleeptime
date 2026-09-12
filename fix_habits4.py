import re

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

# 1. Fix TodayWorkCardView state and actions
today_work_card_pattern = r"(struct TodayWorkCardView: View \{.*?)(var body: some View \{)"

# We will inject the two @State variables
def add_state(match):
    prefix = match.group(1)
    body_decl = match.group(2)
    new_state = """    @State private var isShowingWorthIt = false
    @State private var isShowingReason = false
    
    """
    return prefix + new_state + body_decl

content = re.sub(today_work_card_pattern, add_state, content, flags=re.DOTALL)

# Fix the button actions in TodayWorkCardView
# Button 1 (熬夜觉察)
old_btn1 = """                    Button(action: { isShowingAddHabitSheet = true }) {
                        Text("熬夜觉察")"""
new_btn1 = """                    Button(action: { isShowingWorthIt = true }) {
                        Text("熬夜觉察")"""
content = content.replace(old_btn1, new_btn1)

# Button 2 (记录熬夜原因)
old_btn2 = """                    Button(action: { isShowingAddHabitSheet = true }) {
                        Text("记录熬夜原因")"""
new_btn2 = """                    Button(action: { isShowingReason = true }) {
                        Text("记录熬夜原因")"""
content = content.replace(old_btn2, new_btn2)

# Now, attach the .sheet modifiers to the VStack inside TodayWorkCardView
# Find the end of TodayWorkCardView body and add the sheets.
# This might be tricky, so let's just append it to the background or clipShape of the main VStack
# Actually, the view has:
#         VStack(alignment: .leading, spacing: 18) {
# ...
#         }
#         .padding(.horizontal, 20)
#         .padding(.vertical, 24)
#         .background(
#            ...
#         )
# We can just replace ".clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))" with
# ".clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))\n        .sheet(isPresented: $isShowingWorthIt) {\n            StayUpLateEvaluationView()\n        }\n        .sheet(isPresented: $isShowingReason) {\n            StayUpLateReasonView()\n        }"

old_clipshape = ".clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))"
new_clipshape = """.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .sheet(isPresented: $isShowingWorthIt) {
            StayUpLateEvaluationView()
        }
        .sheet(isPresented: $isShowingReason) {
            StayUpLateReasonView()
        }"""
# Note: clipShape appears multiple times in ContentView. We only want to replace the one in TodayWorkCardView.
# Let's do a targeted replace.
today_work_card_full = re.search(r"struct TodayWorkCardView: View \{.*?\n\}", content, flags=re.DOTALL)
if today_work_card_full:
    twc_str = today_work_card_full.group(0)
    # Replace only the last occurrence of old_clipshape in twc_str
    if old_clipshape in twc_str:
        parts = twc_str.rsplit(old_clipshape, 1)
        new_twc_str = parts[0] + new_clipshape + parts[1]
        content = content.replace(twc_str, new_twc_str)

with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(content)

print("TodayWorkCardView fixed.")
