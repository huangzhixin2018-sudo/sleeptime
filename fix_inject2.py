import re

with open('inject_add_habit_final.py', 'r') as f:
    content = f.read()

# Fix the regex pattern for PlanHabitSection
old_pattern = r'old_plan_habit_section_pattern = r"\(private struct PlanHabitSection: View \\{.*?\\n        \\}\\n    \\}\\n\\}\\)\\n\\nprivate struct PlanPatternCard: View"'
new_pattern = r'old_plan_habit_section_pattern = r"private struct PlanHabitSection: View \{.*?\n    private var currentTimeText: String \{.*?\n    \}\n\}"'
content = content.replace(old_pattern, new_pattern)

old_end = r'private struct PlanPatternCard: View"""'
new_end = r'"""'
content = content.replace(old_end, new_end)

with open('inject_add_habit_final.py', 'w') as f:
    f.write(content)
