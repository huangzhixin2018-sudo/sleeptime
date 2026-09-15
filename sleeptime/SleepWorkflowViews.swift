import SwiftUI
import UIKit

struct SettingsManagementView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProfileSection {
                    NavigationLink {
                        EarlySleepPlan1DetailView()
                    } label: {
                        ProfileRowView(icon: "star", title: "早睡方案1", showDivider: true)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        EmptyProfileDetailView()
                    } label: {
                        ProfileRowView(icon: "tag", title: "标签管理", showDivider: true)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        EmptyProfileDetailView()
                    } label: {
                        ProfileRowView(icon: "icloud", title: "iCloud 备份", trailingText: "未备份", showDivider: false)
                    }
                    .buttonStyle(.plain)
                }

                ProfileSection {
                    NavigationLink {
                        SleepTrackingDetailView()
                    } label: {
                        ProfileRowView(icon: "chart.xyaxis.line", title: "睡眠追踪", showDivider: false)
                    }
                    .buttonStyle(.plain)
                }

                ProfileSection {
                    NavigationLink {
                        EmptyProfileDetailView()
                    } label: {
                        ProfileRowView(icon: "globe", title: "语言", trailingText: "简体中文", showDivider: true)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        EmptyProfileDetailView()
                    } label: {
                        ProfileRowView(icon: "circle.lefthalf.filled", title: "主题外观", trailingText: "浅色模式", showDivider: false)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .navigationTitle("管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct SleepOnsetRoute: Identifiable, Hashable {
    let date: Date
    var id: Date { date }
}

struct SleepOnsetEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    var state: HomeSleepState
    var bedtime: String
    var note: String
}

struct SleepOnsetRecordView: View {
    private enum EditStage {
        case type
        case note
    }

    let date: Date
    let entry: SleepOnsetEntry?
    let onSave: (SleepOnsetEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tabBarVisibility: SleepTabBarVisibility
    @State private var selectedState: HomeSleepState?
    @State private var note = ""
    @State private var isEditing: Bool
    @State private var editStage: EditStage
    @FocusState private var noteIsFocused: Bool

    init(date: Date, entry: SleepOnsetEntry?, onSave: @escaping (SleepOnsetEntry) -> Void) {
        self.date = date
        self.entry = entry
        self.onSave = onSave
        _selectedState = State(initialValue: entry?.state)
        _note = State(initialValue: entry?.note ?? "")
        _isEditing = State(initialValue: entry == nil)
        _editStage = State(initialValue: .type)
    }

    var body: some View {
        Group {
            if isEditing {
                editor
            } else if let entry {
                detail(entry)
            }
        }
        .background(AppTheme.homeBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("编辑") {
                        editStage = .type
                        isEditing = true
                    }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black)
                }
            }
        }
        .sleepDetailChrome(tabBarVisibility)
    }

    private var editor: some View {
        Group {
            switch editStage {
            case .type:
                typePicker
            case .note:
                noteEditor
            }
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("昨晚的入睡情况怎么样？")
                .font(.system(size: 31, weight: .bold))
                .foregroundStyle(Color.black)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(HomeSleepState.allCases) { state in
                    Button {
                        selectedState = state
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            editStage = .note
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            noteIsFocused = true
                        }
                    } label: {
                        Text(state.title)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.78))
                            .frame(width: 126, height: 126)
                            .background(state.selectionColor)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
                                    .padding(5)
                            }
                            .shadow(color: state.color.opacity(0.12), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 30)

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 20)
    }

    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(notePrompt)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.72))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 30)

            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("开始记录...")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.32))
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $note)
                    .font(.system(size: 20, weight: .regular))
                    .lineSpacing(6)
                    .scrollContentBackground(.hidden)
                    .focused($noteIsFocused)
                    .padding(.horizontal, -5)
                    .background(Color.clear)
            }
            .padding(.top, 18)

            Button(action: save) {
                Text("保存")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(selectedState == nil ? Color.black.opacity(0.22) : Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selectedState == nil)
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 20)
    }

    private func detail(_ entry: SleepOnsetEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.state.title)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color.black)

                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(dateTitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.black)

                        Text("入睡时间")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.48))

                        Spacer()

                        Text(entry.bedtime)
                            .font(.system(size: 20, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color.black)
                    }
                    .padding(.top, 20)

                    if !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Divider()
                            .padding(.vertical, 24)

                        Text(entry.note)
                            .font(.system(size: 19, weight: .regular))
                            .foregroundStyle(Color.black.opacity(0.84))
                            .lineSpacing(7)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(22)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 18)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    private var recordHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(dateTitle)
                .font(.system(size: 18, weight: .semibold))
            Text("昨晚")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.48))
            Spacer()
            Text("入睡情况")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(Color.black)
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private var notePrompt: String {
        guard let selectedState else {
            return "记录下昨晚入睡时的想法和感受。"
        }
        switch selectedState {
        case .insomnia:
            return "记录下昨晚让你失眠的事情，以及当时的想法和感受。"
        case .allNight:
            return "记录下昨晚通宵时在做什么，以及为什么没有停下来休息。"
        case .midnightWake:
            return "记录下昨晚醒来的时间和身体感受，以及后来有没有再次入睡。"
        case .difficulty:
            return "记录下昨晚睡前的情绪、环境，或者让你迟迟没有睡着的事情。"
        case .poorSleep:
            return "记录下昨晚睡眠中的感受，以及醒来后身体和精神的状态。"
        case .dream:
            return "记录下昨晚梦里的人、事情和情绪，以及醒来后的感受。"
        }
    }

    private func save() {
        guard let selectedState else { return }
        let savedEntry = SleepOnsetEntry(
            id: entry?.id ?? UUID(),
            date: date,
            state: selectedState,
            bedtime: entry?.bedtime ?? "23:30",
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        onSave(savedEntry)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}


struct BedtimeDecisionView: View {
    private enum Step: Int, CaseIterable {
        case activity
        case habit
        case duration
        case control
        case tomorrow
        case choice
        case result
    }

    private enum Choice {
        case sleepNow
        case limitedContinue
        case continueTonight
    }

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .activity
    @State private var activity = ""
    @State private var activityDraft = ""
    @State private var habit = ""
    @State private var duration = ""
    @State private var control = ""
    @State private var tomorrow = ""
    @State private var finalChoice: Choice?
    @FocusState private var activityIsFocused: Bool

    private let background = AppTheme.homeBackground
    private let foreground = Color.black
    private let accent = Color(red: 0.72, green: 0.30, blue: 0.29)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Group {
                    if step == .result {
                        resultView
                    } else {
                        questionView
                    }
                }
                .id(step)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                activityIsFocused = true
            }
        }
    }

    private var topBar: some View {
        HStack {
            if step.rawValue > Step.activity.rawValue && step != .result {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(foreground)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            if step != .result {
                Text("\(step.rawValue + 1) / 6")
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(foreground.opacity(0.42))
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(foreground)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var questionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(question)
                .font(.system(size: 31, weight: .bold))
                .foregroundStyle(foreground)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 72)

            if let supportingText {
                Text(supportingText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(foreground.opacity(0.55))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
            }

            Spacer(minLength: 36)

            optionLayout
                .padding(.bottom, 44)
        }
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var optionLayout: some View {
        let options = currentOptions
        if step == .activity {
            VStack(spacing: 18) {
                TextField("比如刷手机、追剧，或者处理工作", text: $activityDraft, axis: .vertical)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.black)
                    .lineLimit(2...4)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 17)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .focused($activityIsFocused)
                    .submitLabel(.done)
                    .onSubmit(saveActivity)

                Button(action: saveActivity) {
                    Text("继续想一想")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(activityDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.black.opacity(0.16) : accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(activityDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } else if step == .duration {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 18
            ) {
                ForEach(options, id: \.self) { option in
                    circularOption(option)
                }
            }
            .frame(maxWidth: .infinity)
        } else if options.count == 2 {
            HStack(spacing: 26) {
                ForEach(options, id: \.self) { option in
                    circularOption(option)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button {
                        choose(option)
                    } label: {
                        Text(option)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.84))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .frame(minHeight: 58)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func circularOption(_ title: String) -> some View {
        Button {
            choose(title)
        } label: {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(foreground)
                .multilineTextAlignment(.center)
                .frame(width: 136, height: 136)
                .background(accent)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var question: String {
        switch step {
        case .activity: return "今晚熬夜想做什么？"
        case .habit: return "睡前想做的小习惯，今天完成了吗？"
        case .duration: return "\(activity)，你还想继续多久？"
        case .control: return "到了刚才选的时间，你觉得自己能停下来吗？"
        case .tomorrow: return "如果今晚睡晚一点，你觉得明天会怎么样？"
        case .choice: return "想过这些以后，今晚准备怎么安排？"
        case .result: return ""
        }
    }

    private var supportingText: String? {
        switch step {
        case .habit:
            return "先看看今晚想照顾好的事情，有没有已经完成。"
        case .duration:
            return "选一个差不多的时间，给今晚留个容易做到的小约定。"
        case .control:
            return activity.contains("手机")
                ? "想想平时刷手机的情况，按自己的真实感受来选。"
                : "回想一下以前做这件事时，通常能不能按时结束。"
        case .tomorrow:
            return "不用想得太严重，只要回想一下平时睡晚后的状态。"
        case .choice:
            return summary
        default:
            return nil
        }
    }

    private var currentOptions: [String] {
        switch step {
        case .activity: return []
        case .habit: return ["已经完成", "还没有", "今晚没有安排"]
        case .duration: return ["10 分钟", "20 分钟", "30 分钟", "还没想好"]
        case .control: return ["能停下来", "可能停不下来", "通常停不下来"]
        case .tomorrow: return ["早上不太想起床", "白天可能有点困", "注意力不太集中", "应该没太大影响"]
        case .choice: return ["现在去睡", "再待一小会儿", "今晚想继续"]
        case .result: return []
        }
    }

    private var summary: String {
        var parts: [String] = []
        if habit == "还没有" { parts.append("睡前的小习惯还没完成") }
        if control != "能停下来" { parts.append("到时间后可能还想继续") }
        if tomorrow != "应该没太大影响", !tomorrow.isEmpty { parts.append("明天\(tomorrow)") }
        return parts.isEmpty ? "现在已经想得更清楚了，选一个让自己舒服的安排。" : parts.joined(separator: "，") + "。再看看今晚怎么安排更合适。"
    }

    private var resultView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text(resultTitle)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(foreground)
                .lineSpacing(7)

            Text(resultMessage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(foreground.opacity(0.68))
                .lineSpacing(7)
                .padding(.top, 18)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("好的")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(foreground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 44)
        }
        .padding(.horizontal, 30)
    }

    private var resultTitle: String {
        switch finalChoice {
        case .sleepNow: return "那就安心结束今天吧。"
        case .limitedContinue: return "再待一小会儿，也记得回来休息。"
        case .continueTonight: return "今晚想多留一会儿，也照顾好自己。"
        case nil: return "选择已经记下。"
        }
    }

    private var resultMessage: String {
        switch finalChoice {
        case .sleepNow:
            return habit == "还没有"
                ? "先做一个最简单的版本，不必追求完整，然后安心结束今天。"
                : "放下正在做的事，简单洗漱、关灯，让今天停在这里。"
        case .limitedContinue:
            let limit = duration == "还没想好" ? "10 分钟" : duration
            return "可以设置一个 \(limit) 的计时器。响起以后，就给今天一个温柔的结束。"
        case .continueTonight:
            return "给自己留一个最晚休息时间。想停的时候就停，不需要把今晚安排得太满。"
        case nil:
            return ""
        }
    }

    private func choose(_ answer: String) {
        switch step {
        case .activity: activity = answer
        case .habit: habit = answer
        case .duration: duration = answer
        case .control: control = answer
        case .tomorrow: tomorrow = answer
        case .choice:
            switch answer {
            case "现在去睡": finalChoice = .sleepNow
            case "再待一小会儿": finalChoice = .limitedContinue
            default: finalChoice = .continueTonight
            }
        case .result: break
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        advance()
    }

    private func saveActivity() {
        let value = activityDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        activity = value
        activityIsFocused = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        advance()
    }

    private func advance() {
        let next = Step(rawValue: step.rawValue + 1)
        guard let next else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            step = next
        }
    }

    private func goBack() {
        let previous = Step(rawValue: step.rawValue - 1)
        guard let previous else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            step = previous
        }
    }
}

struct StayUpLateReasonView: View {
    @Environment(\.dismiss) private var dismiss
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
                            ForEach(tags, id: \.self) { tag in
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

                            Text("很好！\n熬夜魔的弱点已记录在案。")
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

struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var habits: [BedtimeHabit]

    @State private var name: String = ""
    @State private var hasAlarm: Bool = true
    @State private var alarmTime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
    @State private var repeatDays: Set<Int> = [0, 1, 2, 3, 4, 5, 6] // Default all

    let daysOfWeek = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button("取消") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)

                        Spacer()

                        Text("新建睡前习惯")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)

                        Spacer()

                        Button("保存") {
                            let newHabit = BedtimeHabit(
                                name: name.isEmpty ? "新习惯" : name,
                                hasAlarm: hasAlarm,
                                alarmTime: alarmTime,
                                repeatDays: repeatDays,
                                checkInTime: nil
                            )
                            withAnimation {
                                habits.append(newHabit)
                            }
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {

                            // Name Input
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("习惯名称，如：冥想、拉伸、看书...", text: $name)
                                    .font(.system(size: 20, weight: .medium))
                                    .padding(.vertical, 8)

                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)

                            // Alarm Section
                            VStack(alignment: .leading, spacing: 16) {
                                Toggle(isOn: $hasAlarm) {
                                    Text("开启提醒")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                .tint(.black)

                                if hasAlarm {
                                    HStack {
                                        Text("时间")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(.gray)
                                        Spacer()
                                        DatePicker("", selection: $alarmTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(.horizontal, 20)

                            // Repeat Days Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("重复日期")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)

                                HStack {
                                    ForEach(0..<7, id: \.self) { index in
                                        Button {
                                            if repeatDays.contains(index) {
                                                if repeatDays.count > 1 { // Prevent unselecting all
                                                    repeatDays.remove(index)
                                                }
                                            } else {
                                                repeatDays.insert(index)
                                            }
                                        } label: {
                                            Text(daysOfWeek[index])
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(repeatDays.contains(index) ? .white : .black)
                                                .frame(width: 36, height: 36)
                                                .background(repeatDays.contains(index) ? Color.black : Color.white)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(repeatDays.contains(index) ? Color.clear : Color.black.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                        }
                        .padding(.top, 10)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct BlankDetailView: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color.black.opacity(0.3))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SleepStreakShelfView: View {
    @AppStorage("sleepCheckIn.records") private var encodedSleepCheckIns = "[]"

    private var streakCounts: [Int: Int] {
        let segments = SleepCheckInStore.segments(
            from: SleepCheckInStore.decode(encodedSleepCheckIns),
            startedAt: 0.0
        ).filter { $0.isEarlySleep }

        var counts: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for segment in segments {
            let d = segment.days
            if d == 1 { counts[1, default: 0] += 1 }
            else if d == 2 { counts[2, default: 0] += 1 }
            else if d == 3 { counts[3, default: 0] += 1 }
            else if d == 4 { counts[4, default: 0] += 1 }
            else if d >= 5 { counts[5, default: 0] += 1 }
        }
        return counts
    }

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .padding(.top, 20)

                    Text("连睡收集架")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("每一次坚持，都是一座耀眼的里程碑")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 16)

                LazyVGrid(columns: columns, spacing: 16) {
                    ShelfBadgeCard(daysLabel: "早睡 1 天", daysValue: 1, count: streakCounts[1] ?? 0, iconName: "star.fill", tintColor: .blue)
                    ShelfBadgeCard(daysLabel: "连续 2 天", daysValue: 2, count: streakCounts[2] ?? 0, iconName: "sparkles", tintColor: .green)
                    ShelfBadgeCard(daysLabel: "连续 3 天", daysValue: 3, count: streakCounts[3] ?? 0, iconName: "flame.fill", tintColor: .orange)
                    ShelfBadgeCard(daysLabel: "连续 4 天", daysValue: 4, count: streakCounts[4] ?? 0, iconName: "bolt.fill", tintColor: .pink)
                }

                // 5天及以上徽章单独横跨占满
                ShelfBadgeCard(daysLabel: "连续 5+ 天", daysValue: 5, count: streakCounts[5] ?? 0, iconName: "crown.fill", tintColor: .purple, isWide: true)
            }
            .padding(20)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.97).ignoresSafeArea())
        .navigationTitle("收集架")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ShelfBadgeCard: View {
    let daysLabel: String
    let daysValue: Int
    let count: Int
    let iconName: String
    let tintColor: Color
    var isWide: Bool = false

    private var isUnlocked: Bool {
        count > 0
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? tintColor.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 64, height: 64)

                Image(systemName: isUnlocked ? iconName : "lock.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(isUnlocked ? tintColor : .gray.opacity(0.4))
            }

            VStack(spacing: 4) {
                Text(daysLabel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isUnlocked ? .primary : .secondary)

                if isUnlocked {
                    Text("已收集 \(count) 次")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(tintColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tintColor.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Text("未解锁")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(isUnlocked ? 0.05 : 0.02), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUnlocked ? tintColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct SleepStreakShelfView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SleepStreakShelfView()
        }
    }
}
