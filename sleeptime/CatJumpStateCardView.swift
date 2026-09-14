import SwiftUI

struct CatJumpStateCardView: View {
    @AppStorage("sleepCheckIn.records") private var encodedSleepCheckIns = "[]"
    @AppStorage("shorterPlan.startedAt") private var planStartedAt = 0.0

    private var currentStreak: Int {
        let segments = SleepCheckInStore.segments(
            from: SleepCheckInStore.decode(encodedSleepCheckIns),
            startedAt: planStartedAt
        )
        guard let last = segments.last, last.isEarlySleep else { return 0 }
        return last.days
    }

    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                statusCard(
                    caption: currentStreak == 0 ? "昨晚" : "当前",
                    value: currentStreak == 0 ? "熬夜" : "连续 \(currentStreak) 天",
                    color: currentStreak == 0 ? .gray : .primary
                )

                statusCard(
                    caption: "今晚目标",
                    value: currentStreak == 0 ? "早睡 1 天" : "连续 \(currentStreak + 1) 天",
                    color: .orange
                )
            }
            .padding(.top, 30)

            Image(systemName: "cat.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50)
                .foregroundStyle(.black)
                .offset(y: -20)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 10)
    }

    private func statusCard(caption: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(caption)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}
