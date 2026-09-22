import SwiftUI
import UIKit

// MARK: - 情绪感知模型

enum EmotionGuidanceType: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case cognitive = "认知维度"
    case microBehavior = "微行为建议"
    case acceptance = "接纳练习"

    var themeColor: Color {
        switch self {
        case .cognitive: return Color(hex: "007AFF")
        case .microBehavior: return Color(hex: "34C759")
        case .acceptance: return Color(hex: "AF52DE")
        }
    }
}

struct EmotionPerceptionItem: Identifiable {
    let id: String
    let title: String
    let englishTheme: String
    let guidanceTitle: String
    let allGuidance: [EmotionGuidanceType: [[String]]]
    let subtitle: String
}

private let emotionPerceptionItems: [EmotionPerceptionItem] = [
    .init(
        id: "dream",
        title: "梦境",
        englishTheme: "DREAMSCAPE",
        guidanceTitle: "奇幻梦境",
        allGuidance: [:],
        subtitle: "潜意识的轻语"
    ),
    .init(
        id: "insomnia",
        title: "失眠",
        englishTheme: "SLEEPLESS",
        guidanceTitle: "辗转反侧",
        allGuidance: [:],
        subtitle: "思绪不停转"
    ),
    .init(
        id: "hard-to-sleep",
        title: "入睡难",
        englishTheme: "SLOW TO SLEEP",
        guidanceTitle: "难以入睡",
        allGuidance: [:],
        subtitle: "躺下后难以入睡"
    ),
    .init(
        id: "midnight-wake",
        title: "半夜醒",
        englishTheme: "MIDNIGHT WAKE",
        guidanceTitle: "中途醒来",
        allGuidance: [:],
        subtitle: "睡眠被打断"
    ),
    .init(
        id: "early-sleep",
        title: "早睡时刻",
        englishTheme: "EARLY SLEEP",
        guidanceTitle: "准备就绪",
        allGuidance: [:],
        subtitle: "每一次早睡的选择"
    ),
    .init(
        id: "late-night",
        title: "熬夜反思",
        englishTheme: "LATE NIGHT",
        guidanceTitle: "熬夜反思",
        allGuidance: [:],
        subtitle: "不舍得睡"
    )
]

// MARK: - 情绪感知详情页（主入口）

struct SleepStatusDetailView: View {
    @State private var showingRecordSheet = false
    @State private var selectedEmotionID: String? = nil
    @State private var recordedIDs: Set<String> = []

    var body: some View {
        EmotionSelectionInnerView(
            recordedIDs: recordedIDs,
            onSelect: { id in
                selectedEmotionID = id
                showingRecordSheet = true
            }
        )
        .sheet(isPresented: $showingRecordSheet) {
            EmotionRecordSheetView(onRecordComplete: {
                if let id = selectedEmotionID {
                    recordedIDs.insert(id)
                }
            })
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
    }
}

// MARK: - 情绪选择页

private struct EmotionSelectionInnerView: View {
    var recordedIDs: Set<String>
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "FFF1F2"),
                    Color(hex: "FFF7ED"),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {


                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 44) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("此刻的睡眠")
                                .font(.system(size: 34, weight: .light))
                                .foregroundColor(Color.black.opacity(0.9))
                                .tracking(2)
                            Text("记录并接纳状态，是愈合的开始。")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(Color.black.opacity(0.4))
                                .tracking(1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(emotionPerceptionItems) { item in
                                emotionButton(item: item)
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 80)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func emotionButton(item: EmotionPerceptionItem) -> some View {
        let isRecorded = recordedIDs.contains(item.id)
        return Button(action: { onSelect(item.id) }) {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.title)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.85))
                
                Spacer(minLength: 0)
                
                Text(isRecorded ? "已记录" : item.subtitle)
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(isRecorded ? Color(hex: "007AFF") : Color.black.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .frame(height: 140, alignment: .topLeading)
            .background(Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 情绪感知详情页

private struct EmotionPerceptionDetailView: View {
    let emotionID: String
    let onBack: () -> Void

    @State private var currentGuidanceType: EmotionGuidanceType = .cognitive
    @State private var refreshRotation: Double = 0
    @State private var contentSeed = 0
    @State private var showingRecordSheet = false

    private var selectedEmotion: EmotionPerceptionItem {
        emotionPerceptionItems.first { $0.id == emotionID } ?? emotionPerceptionItems[0]
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [
                    Color(hex: "FFF1F2"),
                    Color(hex: "FFF7ED"),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 80) {
                        mainInteractiveGuidanceCard
                            .padding(.top, 32)

                        VStack(alignment: .leading, spacing: 28) {
                            bottomInfoSection

                            VStack(spacing: 28) {
                                ForEach(mockEmotionHistoryItems) { item in
                                    historyCardView(item: item)
                                }
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 100)
                    }
                }
            }
            .zIndex(100)
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showingRecordSheet) {
            EmotionRecordSheetView()
        }
    }

    private var header: some View {
        HStack {
            Button(action: { onBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.06)))
            }

            Spacer()

            Menu {
                ForEach(EmotionGuidanceType.allCases) { type in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            currentGuidanceType = type
                            contentSeed = 0
                        }
                    }) {
                        Label(type.rawValue, systemImage: currentGuidanceType == type ? "checkmark" : "")
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(currentGuidanceType.rawValue)
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(Color.black.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.black.opacity(0.06)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var mainInteractiveGuidanceCard: some View {
        let sidePadding: CGFloat = 28

        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 30, x: 0, y: 15)

            VStack(alignment: .leading, spacing: 0) {
                cardContentView(for: currentGuidanceType)
                    .frame(maxHeight: .infinity)

                HStack {
                    HStack(spacing: 4) {
                        Text("\(currentGuidanceType.rawValue)卡")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color.black.opacity(0.6))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.04))
                    .clipShape(Capsule())

                    Spacer()

                    Button(action: refreshCurrentContent) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .ultraLight))
                            .foregroundColor(Color.black.opacity(0.3))
                            .rotationEffect(.degrees(refreshRotation))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 480)
        .padding(.horizontal, sidePadding)
    }

    private func cardContentView(for type: EmotionGuidanceType) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 14) {
                Text(selectedEmotion.englishTheme)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Color.black.opacity(0.25))
                    .tracking(2)

                Text(selectedEmotion.guidanceTitle)
                    .font(.system(size: 34, weight: .light))
                    .foregroundColor(Color.black.opacity(0.95))
                    .tracking(6)

                Rectangle()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: 36, height: 1)
                    .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(getGuidanceText(for: type), id: \.self) { line in
                    Text(line)
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(Color.black.opacity(0.8))
                        .lineSpacing(8)
                        .tracking(0.5)
                }
            }
            .id("\(emotionID)-\(type.rawValue)-\(contentSeed)")
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity
            ))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 32)
        .padding(.horizontal, 40)
    }

    private func getGuidanceText(for type: EmotionGuidanceType) -> [String] {
        let variants = selectedEmotion.allGuidance[type] ?? [["内容加载中..."]]
        let index = contentSeed % variants.count
        return variants[index]
    }

    private func refreshCurrentContent() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            refreshRotation += 360
            contentSeed += 1
        }
    }

    private var bottomInfoSection: some View {
        VStack(alignment: .leading, spacing: 64) {
            Text("风会停，乱糟糟的心也会，你可以好好歇着，等一切安静下来。")
                .font(.system(size: 21, weight: .light))
                .foregroundColor(Color.black.opacity(0.85))
                .lineSpacing(10)
                .tracking(0.5)
                .multilineTextAlignment(.leading)

            VStack(alignment: .leading, spacing: 16) {
                Button(action: { showingRecordSheet = true }) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("记录变化")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color.black.opacity(0.9))
                            Text("记录此刻的心情，开启今晚的愈合之旅")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color.black.opacity(0.4))
                        }
                        Spacer()
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "007AFF"))
                            .frame(width: 32, height: 32)
                            .background(Circle().stroke(Color(hex: "007AFF").opacity(0.2), lineWidth: 1.5))
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.03), radius: 20, x: 0, y: 10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func historyCardView(item: EmotionHistoryRecord) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(item.date)
                .font(.system(size: 16, weight: .ultraLight).monospacedDigit())
                .foregroundColor(Color.black.opacity(0.5))
                .tracking(1)

            Text(item.note)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(Color.black.opacity(0.85))
                .lineSpacing(8)
                .tracking(0.5)
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .shadow(color: Color.black.opacity(0.01), radius: 10, x: 0, y: 5)
    }
}

// MARK: - 记录变化 Sheet

private struct EmotionRecordSheetView: View {
    var onRecordComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var noteText: String = ""
    @State private var showConfirmation = false
    @FocusState private var isNoteFocused: Bool
    @State private var selectedTags: Set<String> = []

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FFF1F2"), Color(hex: "FFF7ED"), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.black.opacity(0.6))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.08)))
                    }
                    Spacer()
                    Text("记录状态")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.black.opacity(0.85))
                        .tracking(2)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(["平静", "开心", "焦虑", "难过", "疲惫", "清醒"], id: \.self) { tag in
                                    Button(action: {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    }) {
                                        Text(tag)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(selectedTags.contains(tag) ? .white : Color.black.opacity(0.6))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(selectedTags.contains(tag) ? Color.black.opacity(0.8) : Color.black.opacity(0.05))
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 4)

                        ZStack(alignment: .topLeading) {
                            if noteText.isEmpty {
                                Text("用几个词描述现在的感受，不用完整的句子…")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(Color.black.opacity(0.22))
                                    .lineSpacing(8)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $noteText)
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(Color.black.opacity(0.82))
                                .lineSpacing(8)
                                .frame(height: 180)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .focused($isNoteFocused)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.black.opacity(0.07), lineWidth: 1)
                        )

                        Button(action: {
                            isNoteFocused = false
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showConfirmation = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.3)) { showConfirmation = false }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { 
                                    onRecordComplete?()
                                    dismiss() 
                                }
                            }
                        }) {
                            Text("完成记录")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.black.opacity(0.82))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                }
                .onTapGesture {
                    isNoteFocused = false
                }
            }

            if showConfirmation {
                LinearGradient(
                    colors: [Color(hex: "FFF1F2"), Color(hex: "FFF7ED"), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 28) {
                        ZStack {
                            Circle()
                                .stroke(Color.black.opacity(0.07), lineWidth: 1)
                                .frame(width: 64, height: 64)
                            Image(systemName: "checkmark")
                                .font(.system(size: 22, weight: .ultraLight))
                                .foregroundColor(Color.black.opacity(0.4))
                        }
                        VStack(spacing: 12) {
                            Text("写下来了")
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(Color.black.opacity(0.75))
                                .tracking(6)
                            Text("感谢你今晚愿意和自己待一会儿")
                                .font(.system(size: 15, weight: .light))
                                .foregroundColor(Color.black.opacity(0.35))
                                .tracking(1)
                                .multilineTextAlignment(.center)
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(999)
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - 历史记录模型

private struct EmotionHistoryRecord: Identifiable {
    let id = UUID()
    let date: String
    let note: String
}

private let mockEmotionHistoryItems: [EmotionHistoryRecord] = [
    .init(date: "05月10日 周日", note: "感觉身体的重量被大地承接，焦虑感减轻了许多。"),
    .init(date: "05月08日 周五", note: "瞬间清醒，从繁乱的思绪中跳了出来。"),
    .init(date: "05月05日 周二", note: "在长椅上坐了一会儿，看着日落，心跳慢了下来。")
]

// MARK: - Preview

struct SleepStatusDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SleepStatusDetailView()
        }
    }
}

// MARK: - Extensions

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
