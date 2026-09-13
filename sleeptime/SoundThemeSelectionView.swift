import SwiftUI

struct SoundTheme: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let content: String
}

let soundThemes = [
    SoundTheme(title: "此刻就是生活", content: "我们总以为生活在别处，等忙完这一阵，等赚到更多的钱，等成为更好的自己，等一切终于准备妥当。其实此刻就是生活本身，无论喜悦还是疲惫，用心感受当下的每一秒，才是真实存在的意义。"),
    SoundTheme(title: "与自己相处", content: "一个人在这个世界上最重要的关系，始终是与自己的关系。能够静下心来理解自己的每一次选择，接纳自己的不完美，也允许自己随时重新开始。当你不再与自己内耗，便拥有了更从容前行的力量。"),
    SoundTheme(title: "去成为想成为的人", content: "不必急着向外界证明自己，也不必勉强活成别人期待的样子。人生真正重要的事情，是在一次次微小的选择里，听从内心的声音，按照自己的节奏，慢慢靠近那个你真正愿意成为的自己。"),
    SoundTheme(title: "听见自己的声音", content: "世界有太多声音，教导我们该如何生活。与其向外寻找答案，不如停下来听听自己。你内心细微的情绪与感受，都在告诉你，什么才是真正重要的。")
]

struct SoundThemeSelectionView: View {
    @Binding var selectedThemeIndex: Int
    @Environment(\.dismiss) var dismiss
    private let bgColor = Color(red: 0.07, green: 0.13, blue: 0.20)
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach(soundThemes.indices, id: \.self) { index in
                        let theme = soundThemes[index]
                        Button(action: {
                            withAnimation(.spring()) {
                                selectedThemeIndex = index
                            }
                            // 稍微延迟一下关闭，让用户看到选中的动画
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                dismiss()
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(theme.title)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if selectedThemeIndex == index {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
                                    }
                                }
                                
                                Text(theme.content)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.white.opacity(0.75))
                                    .lineSpacing(6)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedThemeIndex == index ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selectedThemeIndex == index ? Color.white.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .background(bgColor.ignoresSafeArea())
            .navigationTitle("主题切换")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 24))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
