import CoreData
import XCTest
@testable import WordMemoryCards

@MainActor
final class DictationRepositoryTests: XCTestCase {
    private let timezone = TimeZone(secondsFromGMT: 0)!
    private let now = Date(timeIntervalSince1970: 1_788_192_000)

    func testAnswerComparisonPreservesWordBoundariesAndPunctuation() {
        XCTAssertTrue(DictationAnswerMatcher.matches("  APPLE  ", answer: "apple"))
        XCTAssertTrue(DictationAnswerMatcher.matches("a   part", answer: "a part"))
        XCTAssertTrue(DictationAnswerMatcher.matches("don’t", answer: "don't"))
        XCTAssertFalse(DictationAnswerMatcher.matches("a p p l e", answer: "apple"))
        XCTAssertFalse(DictationAnswerMatcher.matches("apart", answer: "a part"))
        XCTAssertFalse(DictationAnswerMatcher.matches("well known", answer: "well-known"))
        XCTAssertFalse(DictationAnswerMatcher.matches("dont", answer: "don't"))
        XCTAssertFalse(DictationAnswerMatcher.matches("color", answer: "colour"))
        XCTAssertFalse(DictationAnswerMatcher.matches("neccesary", answer: "necessary"))
    }

    func testEligibilityCountsOnlyFirstFormalAnswersOnDifferentDays() {
        let calendar = DictationEligibility.calendar(timeZone: timezone)
        let events = [
            cardEvent(at: now, result: .known),
            cardEvent(at: now.addingTimeInterval(60), result: .known),
            cardEvent(at: now.addingTimeInterval(86_400), result: .unknown),
            cardEvent(at: now.addingTimeInterval(86_460), result: .known),
            cardEvent(at: now.addingTimeInterval(172_800), result: .known, mode: .extraPractice),
            cardEvent(at: now.addingTimeInterval(259_200), result: .known, retry: true)
        ]
        XCTAssertFalse(DictationEligibility.qualifies(
            events: events, currentEnglish: "apple", calendar: calendar
        ))
        XCTAssertTrue(DictationEligibility.qualifies(
            events: events + [cardEvent(at: now.addingTimeInterval(345_600), result: .known)],
            currentEnglish: "apple", calendar: calendar
        ))
        XCTAssertFalse(DictationEligibility.qualifies(
            events: events + [cardEvent(at: now.addingTimeInterval(345_600), result: .known)],
            currentEnglish: "apples", calendar: calendar
        ))
    }

    func testInitialCopyStartsNextDayAndFormalAnswerIsUnique() async throws {
        let controller = PersistenceController(inMemory: true)
        let wordID = try seedEligibleWord(in: controller.container.viewContext)
        let repository = DictationRepository(
            container: controller.container,
            calendar: DictationEligibility.calendar(timeZone: timezone)
        )

        let copyQueue = try await repository.initialCopyQueue(now: now)
        XCTAssertEqual(copyQueue.map(\.wordID), [wordID])
        for count in 1...3 {
            let progress = try await repository.recordInitialCopy(
                wordID: wordID, recognized: "apple", now: now
            )
            XCTAssertEqual(progress.completedCopies, count)
        }
        let sameDay = try await repository.loadOrCreateDay(limit: 20, now: now)
        XCTAssertTrue(sameDay.items.isEmpty)

        let tomorrow = now.addingTimeInterval(86_400)
        let day = try await repository.loadOrCreateDay(limit: 20, now: tomorrow)
        XCTAssertEqual(day.items.map(\.wordID), [wordID])
        let submitted = try await repository.submitFormal(
            dayID: day.id, wordID: wordID, recognized: "APPLE", now: tomorrow
        )
        guard case .result(let result, let correct, _) = submitted else {
            return XCTFail("Expected a formal result")
        }
        XCTAssertTrue(correct)
        XCTAssertEqual(result.phase, .complete)
        XCTAssertEqual(result.firstPassAccuracy, 1)
        do {
            _ = try await repository.submitFormal(
                dayID: day.id, wordID: wordID, recognized: "apple", now: tomorrow
            )
            XCTFail("A second rating on the same day must be rejected")
        } catch DictationRepository.DictationError.alreadyAnswered {
            // Expected.
        }
        let state = try XCTUnwrap(try controller.container.viewContext
            .fetch(DictationStateEntity.fetchRequest()).first)
        XCTAssertEqual(state.totalFormal, 1)
        XCTAssertNotNil(state.fsrsCardData)
        let events = try controller.container.viewContext.fetch(DictationEventEntity.fetchRequest())
        XCTAssertEqual(events.filter { $0.kind == "formal" }.count, 1)
        XCTAssertEqual(events.first { $0.kind == "formal" }?.recognizedText, "APPLE")
    }

    func testRemediationDoesNotRateFSRSAgain() async throws {
        let controller = PersistenceController(inMemory: true)
        let wordID = try seedEligibleWord(in: controller.container.viewContext)
        let repository = DictationRepository(
            container: controller.container,
            calendar: DictationEligibility.calendar(timeZone: timezone)
        )
        _ = try await repository.initialCopyQueue(now: now)
        for _ in 0..<3 {
            _ = try await repository.recordInitialCopy(wordID: wordID, recognized: "apple", now: now)
        }
        let tomorrow = now.addingTimeInterval(86_400)
        let day = try await repository.loadOrCreateDay(limit: 20, now: tomorrow)
        let first = try await repository.submitFormal(
            dayID: day.id, wordID: wordID, recognized: "aple", now: tomorrow
        )
        guard case .result(let afterFirst, let correct, _) = first else {
            return XCTFail("Expected first pass result")
        }
        XCTAssertFalse(correct)
        XCTAssertEqual(afterFirst.phase, .firstPassSummary)

        let context = controller.container.viewContext
        context.refreshAllObjects()
        let state = try XCTUnwrap(try context.fetch(DictationStateEntity.fetchRequest()).first)
        let cardAfterAgain = try XCTUnwrap(state.fsrsCardData)
        _ = try await repository.beginRemediation(dayID: day.id)
        for _ in 0..<3 {
            _ = try await repository.recordRemediationCopy(
                dayID: day.id, wordID: wordID, recognized: "apple", now: tomorrow
            )
        }
        let retest = try await repository.submitRetest(
            dayID: day.id, wordID: wordID, recognized: "apple", now: tomorrow
        )
        guard case .result(let finished, let passed, _) = retest else {
            return XCTFail("Expected retest result")
        }
        XCTAssertTrue(passed)
        XCTAssertEqual(finished.phase, .complete)
        XCTAssertEqual(finished.firstPassAccuracy, 0)
        context.refreshAllObjects()
        XCTAssertEqual(state.fsrsCardData, cardAfterAgain)
        XCTAssertEqual(state.totalFormal, 1)
        let events = try context.fetch(DictationEventEntity.fetchRequest())
        XCTAssertEqual(events.filter { $0.kind == "formal" }.count, 1)
        XCTAssertEqual(events.filter { $0.kind == "retest" }.count, 1)
    }

    func testInterruptedWritingRestartsThirtySecondsButPausedQuestionKeepsTime() async throws {
        let controller = PersistenceController(inMemory: true)
        let wordID = try seedEligibleWord(in: controller.container.viewContext)
        let repository = DictationRepository(
            container: controller.container,
            calendar: DictationEligibility.calendar(timeZone: timezone)
        )
        _ = try await repository.initialCopyQueue(now: now)
        for _ in 0..<3 {
            _ = try await repository.recordInitialCopy(wordID: wordID, recognized: "apple", now: now)
        }
        let tomorrow = now.addingTimeInterval(86_400)
        let day = try await repository.loadOrCreateDay(limit: 20, now: tomorrow)
        try await repository.setTimerState(
            dayID: day.id, wordID: wordID, remaining: 17, isWriting: true, now: tomorrow
        )
        let recovered = try await repository.loadOrCreateDay(limit: 20, now: tomorrow)
        XCTAssertEqual(recovered.items.first?.remainingSeconds, 30)
        XCTAssertEqual(recovered.items.first?.interruptionCount, 1)
        try await repository.setTimerState(
            dayID: day.id, wordID: wordID, remaining: 20, isWriting: false, now: tomorrow
        )
        let paused = try await repository.loadOrCreateDay(limit: 20, now: tomorrow)
        XCTAssertEqual(paused.items.first?.remainingSeconds, 20)
        XCTAssertEqual(paused.items.first?.interruptionCount, 1)
    }

    func testAutomaticBaselineExcludesTodaysWordsAndUsesFiftyPerDay() async throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let oldIDs = try (0..<51).map { index in
            try seedBareWord("word\(index)", chinese: "旧词\(index)",
                             at: now.addingTimeInterval(-86_400 + Double(index)), in: context)
        }
        let newWord = try seedBareWord("melon", chinese: "甜瓜", at: now, in: context)
        try context.save()
        let repository = DictationRepository(
            container: controller.container,
            calendar: DictationEligibility.calendar(timeZone: timezone)
        )
        let initiallyEmpty = try await repository.loadOrCreateDay(limit: 20, now: now)
        XCTAssertTrue(initiallyEmpty.items.isEmpty)
        let campaign = try await repository.automaticBaselineCampaign(now: now)
        XCTAssertEqual(campaign.selectedWordIDs, oldIDs)
        XCTAssertFalse(campaign.selectedWordIDs.contains(newWord))
        let firstDay = try await repository.loadOrCreateDay(
            limit: 20, campaign: campaign, now: now
        )
        XCTAssertEqual(firstDay.id, initiallyEmpty.id)
        XCTAssertEqual(firstDay.limit, 50)
        XCTAssertEqual(firstDay.items.map(\.wordID), Array(oldIDs.prefix(50)))
        XCTAssertTrue(firstDay.items.allSatisfy(\.belongsToBaseline))
        for index in 0..<50 {
            let answer = try await repository.submitFormal(
                dayID: firstDay.id, wordID: oldIDs[index],
                recognized: "word\(index)", now: now
            )
            guard case .result = answer else { return XCTFail("Expected a baseline result") }
        }
        let progress = try await repository.baselineProgress(for: campaign)
        XCTAssertEqual(progress, BaselineProgress(total: 51, completed: 50))
        let sameDay = try await repository.loadOrCreateDay(
            limit: 20, campaign: campaign, now: now
        )
        XCTAssertEqual(sameDay.items.count, 50)
        let tomorrow = now.addingTimeInterval(86_400)
        let secondDay = try await repository.loadOrCreateDay(
            limit: 20, campaign: campaign, now: tomorrow
        )
        XCTAssertEqual(secondDay.limit, 50)
        XCTAssertEqual(secondDay.items.map(\.wordID), [oldIDs[50]])
        XCTAssertFalse(secondDay.items.contains { $0.wordID == newWord })
        let wrong = try await repository.submitFormal(
            dayID: secondDay.id, wordID: oldIDs[50], recognized: "incorrect", now: tomorrow
        )
        guard case .result(let needsPractice, let passed, _) = wrong else {
            return XCTFail("Expected a wrong baseline result")
        }
        XCTAssertFalse(passed)
        XCTAssertEqual(needsPractice.phase, .firstPassSummary)
        let completedProgress = try await repository.baselineProgress(for: campaign)
        XCTAssertEqual(completedProgress, BaselineProgress(total: 51, completed: 51))
        _ = try await repository.beginRemediation(dayID: secondDay.id, now: tomorrow)
        for _ in 0..<3 {
            _ = try await repository.recordRemediationCopy(
                dayID: secondDay.id, wordID: oldIDs[50],
                recognized: "word50", now: tomorrow
            )
        }
        _ = try await repository.submitRetest(
            dayID: secondDay.id, wordID: oldIDs[50], recognized: "word50", now: tomorrow
        )
        context.refreshAllObjects()
        let state = try XCTUnwrap(try context.fetch(DictationStateEntity.fetchRequest())
            .first { $0.wordID == oldIDs[50] })
        XCTAssertEqual(state.totalFormal, 1)
        let formal = try context.fetch(DictationEventEntity.fetchRequest())
            .filter { $0.kind == "baselineFormal" }
        XCTAssertEqual(formal.count, 51)
        let copies = try await repository.initialCopyQueue(campaign: campaign, now: tomorrow)
        XCTAssertTrue(copies.isEmpty)
        let regularDay = try await repository.loadOrCreateDay(
            limit: 20, campaign: campaign, now: tomorrow.addingTimeInterval(86_400)
        )
        XCTAssertEqual(regularDay.limit, 20)
        XCTAssertFalse(regularDay.items.contains(where: \.belongsToBaseline))
    }

    func testMasteredTermIsExcludedFromExistingDayAndFutureDictation() async throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let tv = try seedBareWord("TV", chinese: "电视", at: now.addingTimeInterval(-86_400), in: context)
        let phone = try seedBareWord("phone", chinese: "电话", at: now.addingTimeInterval(-86_399), in: context)
        let apple = try seedBareWord("apple", chinese: "苹果", at: now.addingTimeInterval(-86_398), in: context)
        try context.save()
        let repository = DictationRepository(
            container: controller.container,
            calendar: DictationEligibility.calendar(timeZone: timezone)
        )
        let campaign = try await repository.automaticBaselineCampaign(now: now)
        let originalDay = try await repository.loadOrCreateDay(limit: 20, campaign: campaign, now: now)
        XCTAssertEqual(originalDay.items.map(\.wordID), [tv, phone, apple])

        let mastered: Set<String> = ["tv", "phone", "computer"]
        let updatedDay = try await repository.loadOrCreateDay(
            limit: 20, campaign: campaign, masteredTerms: mastered, now: now
        )
        XCTAssertEqual(updatedDay.id, originalDay.id)
        XCTAssertEqual(updatedDay.items.map(\.wordID), [apple])
        let progress = try await repository.baselineProgress(
            for: campaign, masteredTerms: mastered
        )
        XCTAssertEqual(progress, BaselineProgress(total: 1, completed: 0))
        let freshCampaign = try await repository.automaticBaselineCampaign(
            masteredTerms: mastered, now: now
        )
        XCTAssertEqual(freshCampaign.selectedWordIDs, [apple])
    }

    func testMasteredTermNeverStartsInitialCopy() async throws {
        let controller = PersistenceController(inMemory: true)
        let wordID = try seedEligibleWord(in: controller.container.viewContext)
        let repository = DictationRepository(
            container: controller.container,
            calendar: DictationEligibility.calendar(timeZone: timezone)
        )
        let queue = try await repository.initialCopyQueue(
            masteredTerms: ["apple"], now: now
        )
        XCTAssertTrue(queue.isEmpty)
        XCTAssertEqual(try controller.container.viewContext
            .count(for: DictationStateEntity.fetchRequest()), 0)
        XCTAssertNotNil(try controller.container.viewContext
            .fetch(WordEntity.fetchRequest()).first { $0.id == wordID })
    }

    private func seedBareWord(
        _ english: String, chinese: String, at date: Date,
        in context: NSManagedObjectContext
    ) throws -> UUID {
        let word = WordEntity(context: context)
        word.id = UUID()
        word.english = english
        word.normalizedEnglish = english
        word.chinese = chinese
        word.importPosition = 0
        word.createdAt = date
        word.updatedAt = date
        return word.id
    }

    private func cardEvent(
        at date: Date, result: ReviewResult,
        mode: PracticeMode = .scheduled, retry: Bool = false
    ) -> DictationCardEvent {
        DictationCardEvent(
            reviewedAt: date, direction: .chineseToEnglish, result: result,
            mode: mode, isSameSessionRetry: retry, englishSnapshot: "apple"
        )
    }

    private func seedEligibleWord(in context: NSManagedObjectContext) throws -> UUID {
        let word = WordEntity(context: context)
        word.id = UUID()
        word.english = "apple"
        word.normalizedEnglish = "apple"
        word.chinese = "苹果"
        word.importPosition = 0
        word.createdAt = now
        word.updatedAt = now

        let state = ReviewStateEntity(context: context)
        state.id = UUID()
        state.word = word
        state.direction = ReviewDirection.chineseToEnglish.rawValue
        state.level = 0
        state.nextReviewDate = now
        state.totalReviews = 2
        state.knownCount = 2
        state.unknownCount = 0
        state.consecutiveKnown = 2
        state.lapseCount = 0
        state.createdAt = now
        state.updatedAt = now

        let session = StudySessionEntity(context: context)
        session.id = UUID()
        session.mode = PracticeMode.scheduled.rawValue
        session.startedAt = now.addingTimeInterval(-172_800)
        session.completed = true
        session.baseTaskCount = 2
        session.formalAnswered = 2
        session.formalKnown = 2

        for daysAgo in [2.0, 1.0] {
            let event = ReviewEventEntity(context: context)
            event.id = UUID()
            event.word = word
            event.reviewState = state
            event.session = session
            event.sessionID = session.id
            event.reviewedAt = now.addingTimeInterval(-daysAgo * 86_400)
            event.direction = ReviewDirection.chineseToEnglish.rawValue
            event.result = ReviewResult.known.rawValue
            event.practiceMode = PracticeMode.scheduled.rawValue
            event.levelBefore = 0
            event.levelAfter = 0
            event.isSameSessionRetry = false
            event.wordEnglishSnapshot = "apple"
            event.wordChineseSnapshot = "苹果"
        }
        try context.save()
        return word.id
    }
}
