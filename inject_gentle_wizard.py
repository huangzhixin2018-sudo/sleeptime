import re

with open('sleeptime/ContentView.swift', 'r') as f:
    content = f.read()

# StayUpLateEvaluationView is the very last struct in the file.
# Let's find it and replace it.
pattern = r"struct StayUpLateEvaluationView: View \{.*"
new_view = """struct StayUpLateEvaluationView: View {
    @Environment(\\.dismiss) private var dismiss
    @State private var step = 0
    @State private var reasonText: String = ""
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
                        Text("今晚打算熬夜做什么呢？")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        TextField("比如：刷短视频、看剧、赶工作...", text: $reasonText)
                            .font(.system(size: 18))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(white: 0.95))
                            .cornerRadius(12)
                            .focused($isInputFocused)
                            .padding(.horizontal, 30)
                            .transition(.opacity)
                        
                    } else if step == 1 {
                        Text("做这件事，你觉得大概要花多长时间？到点能停下来吗？")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        VStack(spacing: 16) {
                            stepButton(title: "很快，半小时内搞定") { advanceStep() }
                            stepButton(title: "有点久，可能要 1-2 小时") { advanceStep() }
                            stepButton(title: "说不好，很容易停不下来...") { advanceStep() }
                        }
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                        
                    } else if step == 2 {
                        Text("想一想，昨晚或者最近，是不是已经连续熬夜好几天了呀？")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        VStack(spacing: 16) {
                            stepButton(title: "是的，最近都在熬夜 🥺") { advanceStep() }
                            stepButton(title: "没有啦，今晚是偶尔破例") { advanceStep() }
                        }
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                        
                    } else if step == 3 {
                        Text("回想一下之前熬夜的第二天，精神和身体感觉好吗？那是你真正期待的自己吗？")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .lineSpacing(8)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            
                        VStack(spacing: 16) {
                            Button {
                                dismiss()
                            } label: {
                                Text("确实很难受，今晚还是放过自己去睡吧")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.black)
                                    .cornerRadius(28)
                            }
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("不太好，但我今晚还是决定做完它")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.black.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.clear)
                            }
                        }
                        .padding(.horizontal, 30)
                        .transition(.opacity)
                    }
                }
                
                Spacer()
                
                // Bottom Button Action for Step 0
                if step == 0 {
                    Button {
                        if !reasonText.trimmingCharacters(in: .whitespaces).isEmpty {
                            isInputFocused = false
                            advanceStep()
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
                } else if step < 3 {
                    // Empty space filler to keep the layout consistent
                    Color.clear.frame(height: 96)
                } else {
                    Color.clear.frame(height: 40)
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
    
    private func stepButton(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
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

new_content = re.sub(pattern, new_view, content, flags=re.DOTALL)

with open('sleeptime/ContentView.swift', 'w') as f:
    f.write(new_content)

print("Replacement done.")
