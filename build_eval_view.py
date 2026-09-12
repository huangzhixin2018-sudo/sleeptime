import sys

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

# 1. Add Enum for PlanDetailDestination
enum_code = """
enum PlanDetailDestination: Hashable {
    case empty
    case worthIt
    case reasons
}
"""

target_blank_plan = "struct BlankPlanView: View {"
content = content.replace(target_blank_plan, enum_code + "\n" + target_blank_plan)

# 2. Update BlankPlanView State and Navigation
old_blank_state = """    @State private var exportedPlan: ExportedPlanImage?
    @State private var meditationCheckInTime: String?
    @State private var showEmptyDetail = false"""

new_blank_state = """    @State private var exportedPlan: ExportedPlanImage?
    @State private var meditationCheckInTime: String?
    @State private var planDestination: PlanDetailDestination? = nil"""

content = content.replace(old_blank_state, new_blank_state)

# Replace the navigation destination block
old_nav_dest = """.navigationDestination(isPresented: $showEmptyDetail) {
                EmptyProfileDetailView().sleepDetailChrome(tabBarVisibility)
            }"""

new_nav_dest = """.navigationDestination(item: $planDestination) { dest in
                switch dest {
                case .empty, .reasons:
                    EmptyProfileDetailView().sleepDetailChrome(tabBarVisibility)
                case .worthIt:
                    StayUpLateEvaluationView().sleepDetailChrome(tabBarVisibility)
                }
            }"""

content = content.replace(old_nav_dest, new_nav_dest)

# Replace button callbacks in TodayWorkCardView invocation
old_today_card = """                    TodayWorkCardView(
                        planDurationDays: planDurationDays,
                        maxLateStreak: maxLateStreak,
                        currentDay: currentDay,
                        planStartedAt: planStartedAt,
                        isShorterPlanActive: isShorterPlanActive,
                        onWorthItTapped: { showEmptyDetail = true },
                        onReasonTapped: { showEmptyDetail = true }
                    )"""

new_today_card = """                    TodayWorkCardView(
                        planDurationDays: planDurationDays,
                        maxLateStreak: maxLateStreak,
                        currentDay: currentDay,
                        planStartedAt: planStartedAt,
                        isShorterPlanActive: isShorterPlanActive,
                        onWorthItTapped: { planDestination = .worthIt },
                        onReasonTapped: { planDestination = .reasons }
                    )"""

content = content.replace(old_today_card, new_today_card)

# Fix PlanPatternCard navigation links
# These currently use boolean state navigation which was wrong anyway (they used EmptyProfileDetailView directly without programmatic push)
# Oh wait, earlier I wrapped them in NavigationLink { EmptyProfileDetailView().sleepDetailChrome... } label: { PlanPatternCard(...) }
# That is completely fine and doesn't need to change, because it's a direct NavigationLink.
# Let's leave PlanPatternCard NavigationLinks alone.

# 3. Add StayUpLateEvaluationView
evaluation_view = """
struct StayUpLateEvaluationView: View {
    @Environment(\\.dismiss) private var dismiss
    @State private var step = 0
    @State private var reasonText: String = ""
    @State private var isUrgent: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar with Close Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Content Area
                VStack(spacing: 40) {
                    if step == 0 {
                        Text("今晚打算熬夜做什么？")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        TextField("例如：看剧、打排位、赶PPT...", text: $reasonText)
                            .font(.system(size: 18))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(white: 0.95))
                            .cornerRadius(12)
                            .focused($isInputFocused)
                            .padding(.horizontal, 30)
                            .transition(.opacity)
                        
                    } else if step == 1 {
                        Text("这件事，如果留到明天做，天会塌下来吗？")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        VStack(spacing: 16) {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isUrgent = true
                                    step = 2
                                }
                            } label: {
                                Text("会，非常紧急，必须今晚做完")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: 1.5)
                                    )
                            }
                            
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isUrgent = false
                                    step = 2
                                }
                            } label: {
                                Text("不会，其实明天做也行")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: 1.5)
                                    )
                            }
                        }
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                        
                    } else if step == 2 {
                        if isUrgent {
                            Text("既然是必须要做的，那就安心去做吧。不要有负罪感，但尽量早点结束。")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .lineSpacing(8)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            Text("既然如此，放过自己吧。现在的你需要的是休息。")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .lineSpacing(8)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                
                Spacer()
                
                // Bottom Button Action
                if step == 0 {
                    Button {
                        if !reasonText.trimmingCharacters(in: .whitespaces).isEmpty {
                            isInputFocused = false
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                step = 1
                            }
                        }
                    } label: {
                        Text("下一步")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(reasonText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.black)
                            .cornerRadius(28)
                            .padding(.horizontal, 30)
                    }
                    .disabled(reasonText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.bottom, 40)
                    .transition(.opacity)
                } else if step == 2 {
                    Button {
                        dismiss()
                    } label: {
                        Text(isUrgent ? "知道了，我会尽快睡" : "去睡觉，获取掌控力")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(28)
                            .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 40)
                    .transition(.opacity)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if step == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInputFocused = true
                }
            }
        }
    }
}
"""

content += "\n" + evaluation_view

with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(content)

print("Update complete")
