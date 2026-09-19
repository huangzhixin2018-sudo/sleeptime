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
                Text("规律作息")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.accent)

                Spacer()

                Text("第 \(day) 天")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
            
            // Timeline (Horizontal)
            HStack(spacing: 0) {
                // Node 1
                HStack(spacing: 6) {
                    Circle()
                        .fill(day < currentDay ? AppTheme.accent : Color.black.opacity(0.2))
                        .frame(width: 8, height: 8)
                    Text("23:00")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.8))
                    Text("入睡准备")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.6))
                }

                Spacer()

                // Line connecting them
                Rectangle()
                    .fill(day < currentDay ? AppTheme.accent.opacity(0.5) : Color.black.opacity(0.1))
                    .frame(width: 24, height: 2)
                    .padding(.horizontal, 8)
                
                Spacer()

                // Node 2
                HStack(spacing: 6) {
                    Circle()
                        .fill(day < currentDay ? AppTheme.accent : Color.black.opacity(0.2))
                        .frame(width: 8, height: 8)
                    Text("23:30")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.8))
                    Text("目标入睡")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
