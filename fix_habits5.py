import re

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

# Fix Button(action: {}) in TodayWorkCardView
# Because it's hard to target, let's just replace Button(action: {}) { Text("熬夜觉察") with the new action
old_btn1 = """                    Button(action: {}) {
                        Text("熬夜觉察")"""
new_btn1 = """                    Button(action: { isShowingWorthIt = true }) {
                        Text("熬夜觉察")"""
content = content.replace(old_btn1, new_btn1)

old_btn2 = """                    Button(action: {}) {
                        Text("记录熬夜原因")"""
new_btn2 = """                    Button(action: { isShowingReason = true }) {
                        Text("记录熬夜原因")"""
content = content.replace(old_btn2, new_btn2)

with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(content)
