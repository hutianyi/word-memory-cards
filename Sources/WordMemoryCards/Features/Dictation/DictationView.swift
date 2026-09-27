import CoreData
import PencilKit
import SwiftUI

struct DictationView: View {
    @StateObject private var viewModel: DictationViewModel
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    @State private var drawing = PKDrawing()
    @State private var remaining: TimeInterval = 30
    @State private var budgetAtStart: TimeInterval = 30
    @State private var startedUptime: TimeInterval?
    @State private var isClockRunning = false
    @State private var isSubmitting = false
    @State private var timerPersistenceTask: Task<Void, Never>?

    init(container: NSPersistentContainer, settings: SettingsStore) {
        _viewModel = StateObject(
            wrappedValue: DictationViewModel(container: container, settings: settings)
        )
    }

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()
            content
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.start() }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            tick()
        }
        .onChange(of: viewModel.questionKey) { _, _ in
            drawing = PKDrawing()
            pauseClock()
            remaining = viewModel.activeItem?.remainingSeconds ?? 30
            if viewModel.isTimed && viewModel.feedback == nil && scenePhase == .active {
                startClock()
            }
        }
        .onChange(of: viewModel.feedback?.id) { _, newValue in
            if newValue == nil && viewModel.isTimed && scenePhase == .active {
                startClock()
            } else {
                pauseClock()
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue != .active {
                pauseClock()
                persistTimerState(isWriting: false)
            }
        }
        .alert("默写暂时无法继续", isPresented: errorBinding) {
            Button("好", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "发生未知错误。")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("正在准备默写…")
        } else if let feedback = viewModel.feedback {
            feedbackView(feedback)
        } else if viewModel.isInitialCopy {
            if viewModel.activeCopy != nil { practiceView }
            else { initialCopyCompleteView }
        } else if let day = viewModel.day {
            switch day.phase {
            case .firstPass, .remediationCopy, .retest:
                practiceView
            case .firstPassSummary:
                firstPassSummary(day)
            case .complete:
                completeView(day)
            }
        } else {
            statusView("暂时无法载入默写任务", symbol: "exclamationmark.triangle")
        }
    }

    private var practiceView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button(action: returnHome) {
                            Image(systemName: "xmark")
                                .font(.title2.bold())
                                .frame(width: 52, height: 52)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("暂停并返回首页")
                        .disabled(viewModel.isBusy)
                        Spacer()
                        Text(progressTitle)
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(AppPalette.textSecondary)
                    }

                    Text(prompt?.chinese ?? "")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppPalette.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(minHeight: 72)

                    if isCopyStage {
                        Text(prompt?.english ?? "")
                            .font(.system(size: 31, weight: .medium, design: .rounded))
                            .foregroundStyle(AppPalette.accent)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("dictation.copyAnswer")
                    }

                    PencilCanvas(drawing: $drawing)
                        .allowsHitTesting(!isSubmitting && !viewModel.isBusy)
                        .frame(maxWidth: 820)
                        .frame(height: max(280, min(440, geometry.size.height * 0.52)))
                        .background(AppPalette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(AppPalette.textSecondary.opacity(0.2))
                        )

                    if viewModel.isTimed {
                        HStack(spacing: 18) {
                            Text(String(format: "%02d:%02d", Int(remaining) / 60, Int(remaining) % 60))
                                .font(.title2.monospacedDigit().bold())
                                .foregroundStyle(remaining < 10 ? .red : AppPalette.textPrimary)
                                .accessibilityIdentifier("dictation.timer")
                            if !isClockRunning && !viewModel.isBusy && !isSubmitting {
                                Button("继续计时", action: startClock)
                                    .buttonStyle(.bordered)
                            }
                        }
                    }

                    if let notice = viewModel.notice {
                        Text(notice)
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.textSecondary)
                            .accessibilityIdentifier("dictation.notice")
                    }

                    HStack(spacing: 16) {
                        Button("清除") { drawing = PKDrawing() }
                            .buttonStyle(LargeSecondaryButtonStyle())
                            .disabled(drawing.strokes.isEmpty || viewModel.isBusy || isSubmitting)
                        Button("确认") { submit() }
                            .buttonStyle(LargePrimaryButtonStyle())
                            .disabled(drawing.strokes.isEmpty || viewModel.isBusy || isSubmitting ||
                                      (viewModel.isTimed && !isClockRunning))
                            .accessibilityIdentifier("dictation.confirm")
                    }
                    .frame(maxWidth: 620)

                    if viewModel.isTimed {
                        Button("不会") { submit(reason: .unknown) }
                            .font(.headline)
                            .foregroundStyle(.red)
                            .disabled(viewModel.isBusy || isSubmitting || !isClockRunning)
                            .accessibilityIdentifier("dictation.unknown")
                    }
                }
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
    }

    private var prompt: (chinese: String, english: String)? {
        if let copy = viewModel.activeCopy { return (copy.chinese, copy.english) }
        if let item = viewModel.activeItem { return (item.chinese, item.english) }
        return nil
    }

    private var isCopyStage: Bool {
        viewModel.isInitialCopy || viewModel.day?.phase == .remediationCopy
    }

    private var progressTitle: String {
        if let copy = viewModel.activeCopy {
            return "首次抄写 · 第 \(copy.completedCopies + 1) / 3 遍"
        }
        guard let day = viewModel.day, let item = viewModel.activeItem else { return "默写" }
        switch day.phase {
        case .firstPass:
            let title = item.belongsToBaseline ? "旧词摸底" : "正式默写"
            return "\(title) · 第 \(day.firstPassAnswered + 1) / \(day.items.count) 题"
        case .remediationCopy:
            return "错词抄写 · 第 \(item.remediationCopyCount + 1) / 3 遍"
        case .retest:
            let finished = day.items.filter { $0.formalResult == false && $0.retestAttempted }.count
            return "错词重默 · 第 \(finished + 1) 题"
        case .firstPassSummary, .complete:
            return "默写"
        }
    }

    private func firstPassSummary(_ day: DictationDay) -> some View {
        VStack(spacing: 20) {
            Text("今日第一轮完成").font(.largeTitle.bold())
            Text("\(day.items.count) 个单词 · 首次正确 \(day.firstPassCorrect) · 需要强化 \(day.firstPassWrong)")
            if day.items.contains(where: \.belongsToBaseline) {
                Text("本轮旧词摸底 \(day.items.filter(\.belongsToBaseline).count) 个；首次结果已记录。")
            }
            Text(accuracyText(day))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.accent)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(day.items.filter { $0.formalResult == false }) { item in
                        Text(item.english).font(.title3)
                    }
                }
            }
            .frame(maxHeight: 240)
            Button("开始错词抄写") { Task { await viewModel.beginRemediation() } }
                .buttonStyle(LargePrimaryButtonStyle())
                .frame(maxWidth: 400)
            Button("稍后继续", action: returnHome)
        }
        .padding(28)
    }

    private func completeView(_ day: DictationDay) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 58))
                .foregroundStyle(AppPalette.accent)
            Text(day.items.isEmpty ? "今天没有到期的默写词" : "今天的默写已完成")
                .font(.title.bold())
            if !day.items.isEmpty {
                Text("首次正确 \(day.firstPassCorrect) / \(day.items.count) · \(accuracyText(day))")
                    .font(.title3)
            }
            if let progress = viewModel.baselineProgress, progress.total > 0 {
                Text("旧词摸底已测 \(progress.completed) / \(progress.total) 个")
                    .foregroundStyle(AppPalette.textSecondary)
                if progress.remaining > 0 {
                    Text(day.limit > 0 && day.items.count >= day.limit
                         ? "今天已达到默写上限，剩余旧词下一个学习日继续。"
                         : "剩余旧词会按每日默写额度继续安排。")
                        .foregroundStyle(AppPalette.textSecondary)
                }
            }
            Button("开始新词抄写") { Task { await viewModel.startInitialCopy() } }
                .buttonStyle(LargePrimaryButtonStyle())
                .frame(maxWidth: 400)
            Button("返回首页", action: returnHome)
        }
        .padding(28)
    }

    private var initialCopyCompleteView: some View {
        statusView("今天可开始的首次抄写已完成", symbol: "checkmark.circle.fill")
    }

    private func statusView(_ title: String, symbol: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: symbol).font(.system(size: 56)).foregroundStyle(AppPalette.accent)
            Text(title).font(.title2.bold())
            Button("返回首页", action: returnHome)
                .buttonStyle(LargePrimaryButtonStyle())
                .frame(maxWidth: 400)
        }
        .padding(28)
    }

    private func feedbackView(_ feedback: DictationViewModel.Feedback) -> some View {
        VStack(spacing: 20) {
            Text("需要强化").font(.title.bold())
            Text(feedback.answer)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(AppPalette.accent)
            if let recognized = feedback.recognized, !recognized.isEmpty {
                Text("识别为：\(recognized)")
                    .foregroundStyle(AppPalette.textSecondary)
            }
            Text("约 5 秒后进入下一题")
                .foregroundStyle(AppPalette.textSecondary)
        }
        .padding(28)
    }

    private func accuracyText(_ day: DictationDay) -> String {
        guard let accuracy = day.firstPassAccuracy else { return "暂无首次成绩" }
        return "首次正确率 \(Int((accuracy * 100).rounded()))%"
    }

    private func submit(reason: DictationFailureReason? = nil) {
        guard !isSubmitting else { return }
        isSubmitting = true
        pauseClock()
        let effectiveReason: DictationFailureReason? = viewModel.isTimed && remaining <= 0
            ? .timeout : reason
        let submittedAt = Date()
        let snapshot = drawing
        Task {
            if viewModel.isTimed {
                persistTimerState(isWriting: false)
                await timerPersistenceTask?.value
            }
            let retry = await viewModel.submit(
                drawing: snapshot, explicitReason: effectiveReason, submittedAt: submittedAt
            )
            if viewModel.errorMessage == nil { drawing = PKDrawing() }
            isSubmitting = false
            if retry && viewModel.errorMessage == nil && scenePhase == .active {
                startClock()
            } else if viewModel.feedback == nil && viewModel.isTimed
                        && viewModel.errorMessage == nil && scenePhase == .active {
                startClock()
            }
        }
    }

    private func startClock() {
        guard viewModel.isTimed, viewModel.activeItem != nil,
              viewModel.feedback == nil, !viewModel.isBusy, !isSubmitting,
              !isClockRunning, remaining > 0 else { return }
        budgetAtStart = remaining
        startedUptime = ProcessInfo.processInfo.systemUptime
        isClockRunning = true
        persistTimerState(isWriting: true)
    }

    private func pauseClock() {
        guard isClockRunning, let startedUptime else { return }
        remaining = max(0, budgetAtStart - (ProcessInfo.processInfo.systemUptime - startedUptime))
        isClockRunning = false
        self.startedUptime = nil
    }

    private func tick() {
        guard isClockRunning, let startedUptime else { return }
        remaining = max(0, budgetAtStart - (ProcessInfo.processInfo.systemUptime - startedUptime))
        if remaining <= 0 { submit(reason: .timeout) }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private func returnHome() {
        pauseClock()
        Task {
            persistTimerState(isWriting: false)
            await timerPersistenceTask?.value
            router.reset()
        }
    }

    private func persistTimerState(isWriting: Bool) {
        guard let dayID = viewModel.day?.id,
              let wordID = viewModel.activeItem?.wordID,
              viewModel.isTimed else { return }
        let previous = timerPersistenceTask
        let savedRemaining = remaining
        timerPersistenceTask = Task {
            await previous?.value
            await viewModel.setTimerState(
                dayID: dayID, wordID: wordID,
                remaining: savedRemaining, isWriting: isWriting
            )
        }
    }
}
