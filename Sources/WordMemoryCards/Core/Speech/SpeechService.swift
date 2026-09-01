import AVFoundation
import Foundation

@MainActor
final class SpeechService: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false
    @Published private(set) var speakingText: String?
    @Published private(set) var englishVoices: [SpeechVoiceOption] = []
    @Published private(set) var chineseVoices: [SpeechVoiceOption] = []

    private struct Request {
        let id: UUID
        let text: String
        let language: SpeechLanguage
        let preferredIdentifier: String?
        let rate: Double
    }

    private var synthesizer = AVSpeechSynthesizer()
    private var activeUtterance: AVSpeechUtterance?
    private var pendingRequest: Request?
    private var didTryBasicFallback = false
    private var watchdogTask: Task<Void, Never>?
    private var notificationTokens: [NSObjectProtocol] = []

    override init() {
        super.init()
        synthesizer.delegate = self
        refreshVoices()
        observeAudioSystem()
    }

    deinit {
        watchdogTask?.cancel()
        for token in notificationTokens {
            NotificationCenter.default.removeObserver(token)
        }
    }

    func refreshVoices() {
        englishVoices = VoiceResolver.options(for: .english)
        chineseVoices = VoiceResolver.options(for: .chinese)
    }

    func speak(
        _ text: String,
        language: SpeechLanguage,
        preferredIdentifier: String?,
        rate: Double
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        stop(clearPending: true)
        let request = Request(
            id: UUID(),
            text: trimmed,
            language: language,
            preferredIdentifier: preferredIdentifier,
            rate: min(max(rate, 0.30), 0.62)
        )
        pendingRequest = request
        didTryBasicFallback = false
        perform(request, forceBasicFallback: false)
    }

    func stop() {
        stop(clearPending: true)
    }

    private func stop(clearPending: Bool) {
        watchdogTask?.cancel()
        watchdogTask = nil
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        activeUtterance = nil
        isSpeaking = false
        speakingText = nil
        if clearPending { pendingRequest = nil }
    }

    private func perform(_ request: Request, forceBasicFallback: Bool) {
        configureAudioSession()

        let utterance = AVSpeechUtterance(string: request.text)
        utterance.voice = VoiceResolver.resolve(
            language: request.language,
            preferredIdentifier: request.preferredIdentifier,
            forceBasicFallback: forceBasicFallback
        )
        utterance.rate = Float(request.rate)
        utterance.pitchMultiplier = 1
        utterance.postUtteranceDelay = 0

        speakingText = request.text
        activeUtterance = utterance
        synthesizer.speak(utterance)
        startWatchdog(for: request)
    }

    private func startWatchdog(for request: Request) {
        watchdogTask?.cancel()
        watchdogTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled, let self else { return }
            guard self.pendingRequest?.id == request.id, !self.isSpeaking else { return }

            if !self.didTryBasicFallback {
                self.didTryBasicFallback = true
                self.rebuildSynthesizer()
                self.perform(request, forceBasicFallback: true)
            } else {
                self.stop(clearPending: true)
            }
        }
    }

    private func rebuildSynthesizer() {
        if synthesizer.isSpeaking || synthesizer.isPaused {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.delegate = nil
        synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        activeUtterance = nil
        isSpeaking = false
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("[WordMemorySpeech] Audio session setup failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func observeAudioSystem() {
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            AVAudioSession.mediaServicesWereResetNotification,
            AVAudioSession.interruptionNotification,
            AVAudioSession.routeChangeNotification,
        ]

        notificationTokens = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, let request = self.pendingRequest else { return }
                    self.rebuildSynthesizer()
                    self.perform(request, forceBasicFallback: self.didTryBasicFallback)
                }
            }
        }
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            guard let self, self.activeUtterance === utterance else { return }
            self.watchdogTask?.cancel()
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            guard let self, self.activeUtterance === utterance else { return }
            self.isSpeaking = false
            self.speakingText = nil
            self.pendingRequest = nil
            self.activeUtterance = nil
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            guard let self, self.activeUtterance === utterance else { return }
            self.isSpeaking = false
            self.speakingText = nil
            self.activeUtterance = nil
        }
    }
}
