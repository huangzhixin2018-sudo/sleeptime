import SwiftUI

struct EmptyPlanFrameworkCard: View {
    let segments: [SleepTrajectorySegment]
    let planName: String

    private var isEmpty: Bool { segments.isEmpty }

    var body: some View {
        if isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("看见每段作息的变化")
                    .font(.system(size: 17, weight: .semibold))
                Text("完成睡眠记录后，早睡与熬夜将会分段呈现，让作息变化清晰可见")
                    .font(.system(size: 16, weight: .regular))
                    .lineSpacing(6)
            }
            .foregroundStyle(Color.black)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            VStack(spacing: 12) {
                HStack(alignment: .lastTextBaseline) {
                    Text("作息轨迹")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.black)
                    Spacer()
                    Text(planName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.gray)
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 4)

                ForEach(segments) { segment in
                    trajectorySegmentCard(for: segment)
                }
            }
        }
    }

    private func trajectorySegmentCard(for segment: SleepTrajectorySegment) -> some View {
        let isEarly = segment.isEarlySleep
        let tierIndex = min(segment.days - 1, 5)
        let tier = isEarly ? FISH_TIERS[max(0, tierIndex)] : nil
        let accent = isEarly ? Color(red: 102/255, green: 137/255, blue: 226/255) : Color(red: 150/255, green: 160/255, blue: 170/255)

        return VStack(spacing: 16) {
            HStack {
                Text(segment.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isEarly ? accent : .primary)
                Spacer()
                Text(dateRange(for: segment.dates))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(segment.days)")
                        .font(.custom("AvenirNextCondensed-Bold", size: 32))
                        .foregroundStyle(.primary)
                    Text("天")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if let tier {
                    HStack(spacing: 6) {
                        Image("custom_fish")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                        Text(tier.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(tier.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tier.color.opacity(0.1))
                    .clipShape(Capsule())
                } else {
                    Image("cat_paw")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.black.opacity(0.8))
                        .padding(8)
                        .background(Color.black.opacity(0.06))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isEarly ? accent.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }

    private func dateRange(for dates: [Date]) -> String {
        guard let first = dates.first, let last = dates.last else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M.d"
        let firstText = formatter.string(from: first)
        let lastText = formatter.string(from: last)
        return Calendar.current.isDate(first, inSameDayAs: last) ? firstText : "\(firstText)–\(lastText)"
    }
}
