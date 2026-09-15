import SwiftUI

struct PlanTimelineCarouselView: View {
    let totalDays: Int
    let currentDay: Int
    
    @State private var scrolledDay: Int = 1
    
    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $scrolledDay) {
                ForEach(1...totalDays, id: \.self) { day in
                    TimelineCard(day: day, currentDay: currentDay)
                        .padding(.horizontal, 4) // Small padding just for edge neatness
                        .tag(day)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 128) // Height significantly reduced to remove empty bottom space
            
            // Custom simple black dots
            HStack(spacing: 6) {
                ForEach(1...totalDays, id: \.self) { day in
                    Circle()
                        .fill(day == scrolledDay ? Color.black.opacity(0.8) : Color.black.opacity(0.2))
                        .frame(width: 5, height: 5)
                }
            }
        }
        .onAppear {
            scrolledDay = currentDay
        }
        .onChange(of: scrolledDay) { oldValue, newValue in
            if oldValue != newValue {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

private struct TimelineCard: View {
    let day: Int
    let currentDay: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text("改变，从一次选择开始")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                
                Spacer()
                
                Text("第 \(day) 天")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Timeline
            VStack(alignment: .leading, spacing: 0) {
                TimelineNode(
                    time: "23:00",
                    title: "入睡准备",
                    isLast: false,
                    isCompleted: day < currentDay
                )
                TimelineNode(
                    time: "23:30",
                    title: "目标入睡",
                    isLast: true,
                    isCompleted: day < currentDay
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 24) // Increased spacing between header and timeline
            .padding(.bottom, 8) // Reduced bottom padding
            
            Spacer(minLength: 0)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct TimelineNode: View {
    let time: String
    let title: String
    let isLast: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Time
            Text(time)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.black.opacity(0.8))
                .frame(width: 50, alignment: .leading)
            
            // Node and Line
            VStack(spacing: 0) {
                Circle()
                    .fill(isCompleted ? AppTheme.accent : Color.black.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .padding(.top, 4)
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? AppTheme.accent.opacity(0.5) : Color.black.opacity(0.1))
                        .frame(width: 2)
                        .frame(height: 24)
                }
            }
            
            // Title
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.6))
                .padding(.top, -1)
            
            Spacer()
        }
    }
}
