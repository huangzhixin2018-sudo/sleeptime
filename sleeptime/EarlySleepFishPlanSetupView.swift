import SwiftUI
import UIKit

struct EarlySleepFishPlanSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("shorterPlan.isActive") private var isActive = false
    @AppStorage("shorterPlan.startedAt") private var startedAt = 0.0
    @AppStorage("earlySleepPlan.activeType") private var activePlanType = "shorter"
    @AppStorage("earlySleepPlan.activeName") private var activePlanName = "连续熬夜越来越短"
    @AppStorage("shorterPlan.durationDays") private var savedDurationDays = 7

    @State private var durationDays = 7

    let onPlanStarted: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("养鱼计划")
                        .font(.system(size: 30, weight: .bold))
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 6)

                planSettingCard(
                    title: "计划天数",
                    value: durationDays
                ) { newValue in
                    durationDays = newValue
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("创建计划")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: startPlan) {
                Text("开始计划")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(red: 0.65, green: 0.32, blue: 0.32), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 110)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            durationDays = savedDurationDays
        }
    }

    private func planSettingCard(
        title: String,
        value: Int,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)

            HStack(spacing: 0) {
                let options = [7, 14, 21, 30]
                ForEach(options.indices, id: \.self) { index in
                    let option = options[index]
                    let isSelected = value == option

                    Button {
                        onChange(option)
                    } label: {
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text("\(option)")
                                .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                            Text("天")
                                .font(.system(size: 12, weight: .regular))
                        }
                        .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isSelected ? Color(red: 0.65, green: 0.32, blue: 0.32) : Color.clear)
                    }
                    .buttonStyle(.plain)

                    if index < options.count - 1 {
                        Divider()
                            .background(Color.gray.opacity(0.2))
                    }
                }
            }
            .background(Color.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(20)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func startPlan() {
        savedDurationDays = durationDays
        activePlanType = "fish"
        activePlanName = "养鱼计划"
        startedAt = Date().timeIntervalSince1970
        isActive = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
        dismiss()
        DispatchQueue.main.async {
            onPlanStarted()
        }
    }
}
