import SwiftUI

struct HabitDetailView: View {
    @Binding var habit: BedtimeHabit
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 48))
                        .foregroundStyle(habit.isCompleted ? AppTheme.accent : Color.gray.opacity(0.3))
                    
                    Text(habit.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.primary)
                }
                .padding(.top, 40)
                
                VStack(spacing: 0) {
                    HStack {
                        Text("提醒时间")
                            .font(.system(size: 16, weight: .regular))
                        Spacer()
                        if habit.hasAlarm {
                            Text(habit.timeString)
                                .font(.system(size: 16, weight: .semibold))
                                .monospacedDigit()
                        } else {
                            Text("无")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    HStack {
                        Text("打卡状态")
                            .font(.system(size: 16, weight: .regular))
                        Spacer()
                        Text(habit.isCompleted ? "已完成" : "未完成")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(habit.isCompleted ? AppTheme.accent : .secondary)
                    }
                    .padding()
                }
                .background(Color(white: 0.96))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("习惯详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive, action: {
                    onDelete()
                    dismiss()
                }) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.red)
                }
            }
        }
    }
}
