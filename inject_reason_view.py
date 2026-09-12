import sys

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

# 1. Update Navigation Destination in BlankPlanView
old_nav_dest = """.navigationDestination(item: $planDestination) { dest in
                switch dest {
                case .empty, .reasons:
                    EmptyProfileDetailView().sleepDetailChrome(tabBarVisibility)
                case .worthIt:
                    StayUpLateEvaluationView().sleepDetailChrome(tabBarVisibility)
                }
            }"""

new_nav_dest = """.navigationDestination(item: $planDestination) { dest in
                switch dest {
                case .empty:
                    EmptyProfileDetailView().sleepDetailChrome(tabBarVisibility)
                case .reasons:
                    StayUpLateReasonView().sleepDetailChrome(tabBarVisibility)
                case .worthIt:
                    StayUpLateEvaluationView().sleepDetailChrome(tabBarVisibility)
                }
            }"""

content = content.replace(old_nav_dest, new_nav_dest)


# 2. Add StayUpLateReasonView at the very end of the file
reason_view_code = """
struct StayUpLateReasonView: View {
    @Environment(\\.dismiss) private var dismiss
    @State private var step = 0
    
    // Step 1 Multi-selection
    @State private var selectedTags: Set<String> = []
    let tags = [
        "📺 剧太上头了",
        "🎮 连败不甘心/连胜停不下来",
        "📱 漫无目的刷短视频",
        "💻 报复性工作/学习",
        "🤯 心事重重睡不着",
        "🍻 聚会/应酬/夜生活"
    ]
    
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
                        Text("昨晚是怎么被“熬夜魔”绊住的？")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        // Tag Grid
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                            ForEach(tags, id: \\.self) { tag in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    }
                                } label: {
                                    Text(tag)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedTags.contains(tag) ? .white : .black)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedTags.contains(tag) ? Color.black : Color.clear)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedTags.contains(tag) ? Color.clear : Color.black.opacity(0.8), lineWidth: 1.5)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .transition(.opacity)
                        
                    } else if step == 1 {
                        Text("剖析一下，当时最真实的心理状态是什么？")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        VStack(spacing: 16) {
                            stepButton(title: "白天太忙，想找回一点属于自己的时间") { advanceStep() }
                            stepButton(title: "当时完全沉浸进去了，没意识到时间流逝") { advanceStep() }
                            stepButton(title: "情绪不太好，就是不想结束这一天") { advanceStep() }
                            stepButton(title: "客观原因，硬着头皮也得熬") { advanceStep() }
                        }
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                        
                    } else if step == 2 {
                        Text("发现原因就是最大的进步！今晚如果它再来，我们怎么反击？")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .lineSpacing(6)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        VStack(spacing: 16) {
                            stepButton(title: "提前定个“断电”闹钟，响了绝不碰手机") { advanceStep() }
                            stepButton(title: "睡前把最大的诱惑源（手机/平板）放远点") { advanceStep() }
                            stepButton(title: "换个放松方式，今晚睡前改听播客/白噪音") { advanceStep() }
                        }
                        .padding(.horizontal, 30)
                        .transition(.opacity)
                        
                    } else if step == 3 {
                        VStack(spacing: 24) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.black)
                                .transition(.scale.combined(with: .opacity))
                            
                            Text("很好！\\n熬夜魔的弱点已记录在案。")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .lineSpacing(8)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        .padding(.horizontal, 30)
                    }
                }
                
                Spacer()
                
                // Bottom Button Action
                if step == 0 {
                    Button {
                        if !selectedTags.isEmpty {
                            advanceStep()
                        }
                    } label: {
                        Text("下一步")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(selectedTags.isEmpty ? Color.gray : Color.black)
                            .cornerRadius(28)
                            .padding(.horizontal, 30)
                    }
                    .disabled(selectedTags.isEmpty)
                    .padding(.bottom, 40)
                    .transition(.opacity)
                } else if step == 3 {
                    Button {
                        dismiss()
                    } label: {
                        Text("收起档案，今天好好过")
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
                } else {
                    // Empty space filler to keep the layout consistent for step 1 & 2
                    Color.clear.frame(height: 96)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func stepButton(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.8), lineWidth: 1.5)
                )
        }
    }
    
    private func advanceStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            step += 1
        }
    }
}
"""

content += "\n" + reason_view_code

with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(content)

print("Reason view injected.")
