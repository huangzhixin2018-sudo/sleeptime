import sys

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

# 1. Update TodayWorkCardView definition
old_today_def = """struct TodayWorkCardView: View {
    @State private var isShowingControlInfo = false

    let planDurationDays: Int
    let maxLateStreak: Int
    let currentDay: Int
    let planStartedAt: Double
    let isShorterPlanActive: Bool

    private let btnAttackBg = Color(red: 0.92, green: 0.33, blue: 0.31)"""

new_today_def = """struct TodayWorkCardView: View {
    @State private var isShowingControlInfo = false

    let planDurationDays: Int
    let maxLateStreak: Int
    let currentDay: Int
    let planStartedAt: Double
    let isShorterPlanActive: Bool
    
    var onWorthItTapped: (() -> Void)? = nil
    var onReasonTapped: (() -> Void)? = nil

    private let btnAttackBg = Color(red: 0.92, green: 0.33, blue: 0.31)"""

content = content.replace(old_today_def, new_today_def)

# 2. Update TodayWorkCardView buttons
old_buttons = """                VStack(spacing: 12) {
                    Button(action: {}) {
                        Text("熬夜值不值")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(btnAttackBg)
                            .clipShape(Capsule())
                    }

                    Button(action: {}) {
                        Text("记录熬夜原因")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(textDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(btnReviewBg)
                            .clipShape(Capsule())
                    }
                }"""

new_buttons = """                VStack(spacing: 12) {
                    Button(action: { onWorthItTapped?() }) {
                        Text("熬夜值不值")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(btnAttackBg)
                            .clipShape(Capsule())
                    }

                    Button(action: { onReasonTapped?() }) {
                        Text("记录熬夜原因")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(textDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(btnReviewBg)
                            .clipShape(Capsule())
                    }
                }"""

content = content.replace(old_buttons, new_buttons)

# 3. Update BlankPlanView definition
old_blank_def = """struct BlankPlanView: View {
    @State private var exportedPlan: ExportedPlanImage?
    @State private var meditationCheckInTime: String?
    @AppStorage("shorterPlan.isActive") private var isShorterPlanActive = false"""

new_blank_def = """struct BlankPlanView: View {
    @State private var exportedPlan: ExportedPlanImage?
    @State private var meditationCheckInTime: String?
    @State private var showEmptyDetail = false
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    @AppStorage("shorterPlan.isActive") private var isShorterPlanActive = false"""

content = content.replace(old_blank_def, new_blank_def)

# 4. Update BlankPlanView's TodayWorkCardView invocation (lines ~752)
old_blank_today = """                    TodayWorkCardView(
                        planDurationDays: planDurationDays,
                        maxLateStreak: maxLateStreak,
                        currentDay: currentDay,
                        planStartedAt: planStartedAt,
                        isShorterPlanActive: isShorterPlanActive
                    )"""

new_blank_today = """                    TodayWorkCardView(
                        planDurationDays: planDurationDays,
                        maxLateStreak: maxLateStreak,
                        currentDay: currentDay,
                        planStartedAt: planStartedAt,
                        isShorterPlanActive: isShorterPlanActive,
                        onWorthItTapped: { showEmptyDetail = true },
                        onReasonTapped: { showEmptyDetail = true }
                    )"""

content = content.replace(old_blank_today, new_blank_today)

# 5. Update BlankPlanView's HStack of PlanPatternCards (lines ~760-788)
old_blank_cards = """                    HStack(spacing: 8) {
                        PlanPatternCard(
                            title: "原则",
                            subtitle: nil,
                            icon: "checkmark.shield.fill",
                            tint: Color(red: 0.42, green: 0.56, blue: 0.16),
                            shapeStyle: .left
                        )
                        .frame(width: 100)

                        PlanPatternCard(
                            title: "早睡方法",
                            subtitle: nil,
                            icon: "lightbulb.fill",
                            tint: Color(red: 0.30, green: 0.52, blue: 0.78),
                            shapeStyle: .plain
                        )
                        .frame(maxWidth: .infinity)

                        PlanPatternCard(
                            title: "进步",
                            subtitle: nil,
                            icon: "moon.fill",
                            tint: Color(red: 0.95, green: 0.40, blue: 0.38),
                            usesFlowerIcon: true,
                            shapeStyle: .right
                        )
                        .frame(width: 100)
                    }"""

new_blank_cards = """                    HStack(spacing: 8) {
                        NavigationLink {
                            EmptyProfileDetailView().sleepDetailChrome(tabBarVisibility)
                        } label: {
                            PlanPatternCard(
                                title: "原则",
                                subtitle: nil,
                                icon: "checkmark.shield.fill",
                                tint: Color(red: 0.42, green: 0.56, blue: 0.16),
                                shapeStyle: .left
                            )
                            .frame(width: 100)
                        }.buttonStyle(.plain)

                        NavigationLink {
                            EmptyProfileDetailView().sleepDetailChrome(tabBarVisibility)
                        } label: {
                            PlanPatternCard(
                                title: "早睡方法",
                                subtitle: nil,
                                icon: "lightbulb.fill",
                                tint: Color(red: 0.30, green: 0.52, blue: 0.78),
                                shapeStyle: .plain
                            )
                            .frame(maxWidth: .infinity)
                        }.buttonStyle(.plain)

                        NavigationLink {
                            EmptyProfileDetailView().sleepDetailChrome(tabBarVisibility)
                        } label: {
                            PlanPatternCard(
                                title: "进步",
                                subtitle: nil,
                                icon: "moon.fill",
                                tint: Color(red: 0.95, green: 0.40, blue: 0.38),
                                usesFlowerIcon: true,
                                shapeStyle: .right
                            )
                            .frame(width: 100)
                        }.buttonStyle(.plain)
                    }"""

content = content.replace(old_blank_cards, new_blank_cards)

# 6. Add navigationDestination to BlankPlanView
# Add it near the end of the body, before the closing brace of `BlankPlanView`'s body.
# Let's find `.sheet(item: $exportedPlan) { plan in` and append to it.
old_sheet = """.sheet(item: $exportedPlan) { plan in
                ActivityShareSheet(items: [plan.image])
            }
        }
    }"""

new_sheet = """.sheet(item: $exportedPlan) { plan in
                ActivityShareSheet(items: [plan.image])
            }
            .navigationDestination(isPresented: $showEmptyDetail) {
                EmptyProfileDetailView().sleepDetailChrome(tabBarVisibility)
            }
        }
    }"""

content = content.replace(old_sheet, new_sheet)


with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(content)

print("Update complete")
