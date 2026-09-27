import CoreData
import Foundation
import PencilKit

@MainActor
final class DictationViewModel: ObservableObject {
    struct Feedback: Identifiable {
        let id = UUID()
        let answer: String
        let recognized: String?
        let reason: DictationFailureReason?
    }

    enum RecognitionError: LocalizedError {
        case englishUnavailable

        var errorDescription: String? {
            "这台 iPad 当前不支持英文手写识别，默写已暂停。"
        }
    }

    @Published private(set) var day: DictationDay?
    @Published private(set) var copyQueue: [InitialCopyPrompt] = []
    @Published private(set) var baselineProgress: BaselineProgress?
    @Published private(set) var isInitialCopy = false
    @Published private(set) var isLoading = true
    @Published private(set) var isBusy = false
    @Published private(set) var feedback: Feedback?
    @Published private(set) var notice: String?
    @Published var errorMessage: String?

    private let repository: DictationRepository
    private let settings: SettingsStore
    private let dailyLimit: Int
    private var feedbackTask: Task<Void, Never>?

    init(container: NSPersistentContainer, settings: SettingsStore) {
        repository = DictationRepository(container: container)
        self.settings = settings
        dailyLimit = settings.dictationLimit.rawValue
    }

    var activeItem: DictationItem? {
        guard !isInitialCopy, let day else { return nil }
        switch day.phase {
        case .firstPass:
            return day.items.first { $0.formalResult == nil }
        case .remediationCopy:
            return day.items.first { $0.needsRemediation && $0.remediationCopyCount < 3 }
        case .retest:
            return day.items.first { $0.needsRemediation && !$0.retestAttempted }
        case .firstPassSummary, .complete:
            return nil
        }
    }

    var activeCopy: InitialCopyPrompt? {
        isInitialCopy ? copyQueue.first : nil
    }

    var isTimed: Bool {
        !isInitialCopy && (day?.phase == .firstPass || day?.phase == .retest)
    }

    var questionKey: String? {
        if let copy = activeCopy {
            return "initial|\(copy.wordID)|\(copy.completedCopies)"
        }
        guard let day, let item = activeItem else { return nil }
        return "\(day.phase.rawValue)|\(item.wordID)|\(item.remediationRound)|\(item.remediationCopyCount)"
    }

    func start() async {
        guard day == nil else { return }
        isLoading = true
        do {
            if settings.baselineCampaign == nil {
                settings.baselineCampaign = try await repository.automaticBaselineCampaign(
                    masteredTerms: settings.masteredDictationTerms
                )
            }
            day = try await repository.loadOrCreateDay(
                limit: dailyLimit, campaign: settings.baselineCampaign,
                masteredTerms: settings.masteredDictationTerms
            )
            await refreshBaselineProgress()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func refreshBaselineProgress() async {
        guard let campaign = settings.baselineCampaign else {
            baselineProgress = nil
            return
        }
        do {
            baselineProgress = try await repository.baselineProgress(
                for: campaign, masteredTerms: settings.masteredDictationTerms
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startInitialCopy() async {
        guard !isBusy else { return }
        isBusy = true
        do {
            copyQueue = try await repository.initialCopyQueue(
                campaign: settings.baselineCampaign,
                masteredTerms: settings.masteredDictationTerms
            )
            isInitialCopy = true
            notice = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    func beginRemediation() async {
        guard !isBusy, let day else { return }
        isBusy = true
        do {
            self.day = try await repository.beginRemediation(dayID: day.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isBusy = false
    }

    func setTimerState(
        dayID: UUID, wordID: UUID, remaining: Double, isWriting: Bool
    ) async {
        do {
            try await repository.setTimerState(
                dayID: dayID, wordID: wordID,
                remaining: remaining, isWriting: isWriting
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submit(
        drawing: PKDrawing,
        explicitReason: DictationFailureReason? = nil,
        submittedAt: Date = Date()
    ) async -> Bool {
        guard !isBusy else { return false }
        isBusy = true
        defer { isBusy = false }
        do {
            let recognized = explicitReason == nil ? try await recognize(drawing) : nil
            if isInitialCopy, let copy = activeCopy {
                let updated = try await repository.recordInitialCopy(
                    wordID: copy.wordID, recognized: recognized ?? "", now: submittedAt
                )
                if updated.completedCopies >= 3 {
                    copyQueue.removeFirst()
                    notice = "已完成 3 遍；明天起可以正式默写。"
                } else {
                    copyQueue[0] = updated
                    notice = DictationAnswerMatcher.matches(recognized ?? "", answer: copy.english)
                        ? "这一遍正确，继续下一遍。" : "这一遍未通过，请照着答案重新抄写。"
                }
                return false
            }
            guard let day, let item = activeItem else { return false }
            switch day.phase {
            case .firstPass:
                let outcome = try await repository.submitFormal(
                    dayID: day.id, wordID: item.wordID,
                    recognized: recognized, explicitReason: explicitReason, now: submittedAt
                )
                let retry = handle(outcome, answer: item.english, recognized: recognized)
                if item.belongsToBaseline, case .result = outcome {
                    await refreshBaselineProgress()
                }
                return retry
            case .remediationCopy:
                self.day = try await repository.recordRemediationCopy(
                    dayID: day.id, wordID: item.wordID, recognized: recognized ?? "",
                    now: submittedAt
                )
                notice = DictationAnswerMatcher.matches(recognized ?? "", answer: item.english)
                    ? "这一遍正确。" : "这一遍未通过，请照着答案重新抄写。"
                return false
            case .retest:
                let outcome = try await repository.submitRetest(
                    dayID: day.id, wordID: item.wordID,
                    recognized: recognized, explicitReason: explicitReason, now: submittedAt
                )
                return handle(outcome, answer: item.english, recognized: recognized)
            case .firstPassSummary, .complete:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func handle(
        _ outcome: DictationSubmission, answer: String, recognized: String?
    ) -> Bool {
        switch outcome {
        case .retry(let day):
            self.day = day
            notice = "无法识别，请用剩余时间重新书写。"
            return true
        case .result(let day, let correct, let reason):
            self.day = day
            notice = nil
            if !correct {
                let item = Feedback(answer: answer, recognized: recognized, reason: reason)
                feedback = item
                feedbackTask?.cancel()
                feedbackTask = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(5))
                    guard !Task.isCancelled, self?.feedback?.id == item.id else { return }
                    self?.feedback = nil
                }
            }
            return false
        }
    }

    private func recognize(_ drawing: PKDrawing) async throws -> String? {
        guard !drawing.strokes.isEmpty else { return nil }
        guard let english = PKStrokeRecognizer.supportedLanguages.first(where: {
            $0.languageCode?.identifier == "en"
        }) else {
            throw RecognitionError.englishUnavailable
        }
        let recognizer = PKStrokeRecognizer(preferredLanguages: [english])
        await recognizer.updateDrawing(drawing)
        return await recognizer.recognizedText()
    }
}
