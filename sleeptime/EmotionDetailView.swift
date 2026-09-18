import SwiftUI
import UIKit

struct EmotionDetailView: View {
    var body: some View {
        ZStack(alignment: .top) {
            SleepJournalPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    ForEach(SleepJournalCategory.samples) { category in
                        NavigationLink {
                            SleepJournalCategoryDetailView(category: category)
                        } label: {
                            SleepJournalCategoryCard(category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("睡眠札记")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .preferredColorScheme(.light)
    }
}

private struct SleepJournalCategoryDetailView: View {
    let category: SleepJournalCategory

    var body: some View {
        ZStack(alignment: .top) {
            SleepJournalPalette.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 18) {
                    ForEach(category.records) { record in
                        SleepJournalHistoryCard(record: record)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .preferredColorScheme(.light)
    }
}

private struct SleepJournalCategoryCard: View {
    let category: SleepJournalCategory

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 30, y: 15)

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(category.eyebrow)
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color.black.opacity(0.25))
                            .tracking(2)

                        Text(category.title)
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(Color.black.opacity(0.95))
                            .tracking(6)

                        Rectangle()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 36, height: 1)
                            .padding(.top, 4)
                    }

                    Text(category.description)
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .lineSpacing(8)
                        .tracking(0.5)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.top, 24)

                Spacer(minLength: 16)

                HStack {
                    Text("\(category.title)记录\(category.records.count)次")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SleepJournalPalette.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(SleepJournalPalette.accentBackground)
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(SleepJournalPalette.accent)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .stroke(SleepJournalPalette.accent.opacity(0.24), lineWidth: 1)
                        }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
    }
}

private struct SleepJournalHistoryCard: View {
    let record: SleepJournalRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text(record.date)
                    .font(.system(size: 15, weight: .light, design: .rounded).monospacedDigit())
                    .tracking(1)

                Spacer()

                Text(record.sleepTime)
                    .font(.system(size: 14, weight: .light, design: .rounded).monospacedDigit())
            }
            .foregroundStyle(Color.black.opacity(0.42))

            SleepJournalJustifiedText(record.note)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color.black.opacity(0.035), radius: 18, y: 10)
    }
}

private struct SleepJournalJustifiedText: UIViewRepresentable {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.lineSpacing = 8
        paragraphStyle.lineBreakMode = .byWordWrapping
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 19, weight: .light),
                .foregroundColor: UIColor.black.withAlphaComponent(0.82),
                .paragraphStyle: paragraphStyle,
                .kern: 0.5
            ]
        )
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        return uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
}

private struct SleepJournalCategory: Identifiable {
    let id: String
    let eyebrow: String
    let title: String
    let description: String
    let icon: String
    let records: [SleepJournalRecord]

    static let samples: [SleepJournalCategory] = [
        .init(
            id: "dream",
            eyebrow: "DREAMSCAPE",
            title: "梦境",
            description: "梦境像夜里的线索，映照真实的情感、在意的人事，以及清醒生活中尚未被看见的挑战。",
            icon: "heart",
            records: [
                .init(date: "07月01日 周三", sleepTime: "入睡12:00", note: "梦见自己走在一条很长的走廊里，尽头有光，但一直没有真正走到。醒来后还记得那种安静又迟疑的感觉。"),
                .init(date: "06月28日 周日", sleepTime: "入睡23:48", note: "梦里回到熟悉的房间，窗外很亮，桌上放着一封没有写完的信。"),
                .init(date: "06月24日 周三", sleepTime: "入睡00:16", note: "梦见在夜色里等一班很慢的车，身边的人都很安静，只有风声特别清楚。")
            ]
        ),
        .init(
            id: "insomnia",
            eyebrow: "SLEEPLESS HOURS",
            title: "失眠",
            description: "失眠记录下那些难以入睡的夜晚，帮助你看见反复出现的思绪、压力和身体发出的提醒。",
            icon: "moon",
            records: [
                .init(date: "07月02日 周四", sleepTime: "入睡02:18", note: "很早就躺下了，但脑子一直停不下来，反复想着白天没处理完的事情，越想睡越清醒。"),
                .init(date: "06月29日 周一", sleepTime: "入睡01:42", note: "身体很累，闭上眼却没有困意，翻身很多次后开始有点烦躁，后来听了一会儿白噪音才慢慢安静下来。"),
                .init(date: "06月23日 周二", sleepTime: "入睡02:05", note: "临睡前看手机太久，放下以后眼睛酸，但精神还很兴奋，感觉入睡被拖得很晚。")
            ]
        ),
        .init(
            id: "hard-to-sleep",
            eyebrow: "SLOW TO SLEEP",
            title: "入睡难",
            description: "记录那些躺下后迟迟无法入睡的夜晚，看见睡前思绪、习惯和身体状态留下的线索。",
            icon: "bed.double",
            records: [
                .init(date: "07月03日 周五", sleepTime: "入睡01:26", note: "躺下后一直在调整姿势，明明已经困了，却总觉得差一点才能睡着，呼吸也比平时更急一些。"),
                .init(date: "06月30日 周二", sleepTime: "入睡00:58", note: "睡前喝了茶，入睡变得很慢，心里没有特别焦虑，但身体像还没有准备好进入睡眠。"),
                .init(date: "06月25日 周四", sleepTime: "入睡01:12", note: "关灯后房间很安静，注意力反而集中在细小声音上，越听越清醒，过了很久才睡着。")
            ]
        ),
        .init(
            id: "midnight-wake",
            eyebrow: "MIDNIGHT WAKE",
            title: "半夜醒",
            description: "记录夜间醒来的时刻、醒后的感受和再次入睡的难度，帮助你理解睡眠被打断的原因。",
            icon: "alarm",
            records: [
                .init(date: "07月04日 周六", sleepTime: "入睡23:55", note: "半夜醒来一次，大概停留了二十多分钟，醒来时没有明显原因，只是觉得口渴和心里有点空。"),
                .init(date: "06月27日 周六", sleepTime: "入睡00:08", note: "凌晨醒来后看了一眼时间，之后就有点担心睡不够，反而更难重新入睡。"),
                .init(date: "06月21日 周日", sleepTime: "入睡23:36", note: "夜里醒来时做过梦的感觉还在，身体没有完全紧张，但思绪断断续续飘了很久。")
            ]
        )
    ]
}

private struct SleepJournalRecord: Identifiable {
    let id = UUID()
    let date: String
    let sleepTime: String
    let note: String
}

private enum SleepJournalPalette {
    static let accent = Color(red: 217 / 255, green: 119 / 255, blue: 6 / 255)
    static let accentBackground = Color(red: 255 / 255, green: 237 / 255, blue: 213 / 255)
    static let background = LinearGradient(
        colors: [
            Color(red: 255 / 255, green: 241 / 255, blue: 242 / 255),
            Color(red: 255 / 255, green: 247 / 255, blue: 237 / 255),
            Color.white
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct EmotionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EmotionDetailView()
        }
    }
}
