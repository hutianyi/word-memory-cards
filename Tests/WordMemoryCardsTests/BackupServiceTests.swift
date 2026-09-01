import CoreData
import XCTest
@testable import WordMemoryCards

@MainActor
final class BackupServiceTests: XCTestCase {
    func testRoundTripRestoresAllEntitiesAndRelationships() async throws {
        let source = PersistenceController(inMemory: true)
        let fixture = try seedFixture(in: source.container.viewContext)
        let settings = BackupSettings(
            sessionLimit: 30,
            englishVoiceIdentifier: nil,
            chineseVoiceIdentifier: nil,
            englishSpeechRate: 0.46,
            chineseSpeechRate: 0.46,
            autoSpeakFront: true,
            autoSpeakBack: true,
            hapticsEnabled: true,
            extraPracticeScope: ExtraPracticeScope.weakest20.rawValue
        )

        let envelope = try await BackupService.makeEnvelope(
            container: source.container,
            settings: settings,
            appVersion: "1.1"
        )
        let decoded = try BackupService.decodeAndValidate(BackupService.encode(envelope))

        let destination = PersistenceController(inMemory: true)
        try await BackupService.restore(decoded, into: destination.container)

        let context = destination.container.viewContext
        let words = try context.fetch(WordEntity.fetchRequest())
        let states = try context.fetch(ReviewStateEntity.fetchRequest())
        let events = try context.fetch(ReviewEventEntity.fetchRequest())
        let sessions = try context.fetch(StudySessionEntity.fetchRequest())

        XCTAssertEqual(words.map(\.id), [fixture.wordID])
        XCTAssertEqual(states.count, 2)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.word?.id, fixture.wordID)
        XCTAssertEqual(events.first?.reviewState.id, fixture.stateID)
        XCTAssertEqual(sessions.map(\.id), [fixture.sessionID])
    }

    func testRejectsWrongAppMarkerBeforeRestore() async throws {
        let controller = PersistenceController(inMemory: true)
        let settings = BackupSettings(
            sessionLimit: 30,
            englishVoiceIdentifier: nil,
            chineseVoiceIdentifier: nil,
            englishSpeechRate: 0.46,
            chineseSpeechRate: 0.46,
            autoSpeakFront: true,
            autoSpeakBack: true,
            hapticsEnabled: true,
            extraPracticeScope: ExtraPracticeScope.weakest20.rawValue
        )
        let valid = try await BackupService.makeEnvelope(
            container: controller.container,
            settings: settings,
            appVersion: "1.1"
        )
        let wrong = BackupEnvelope(
            app: "AnotherApp",
            backupFormatVersion: valid.backupFormatVersion,
            schemaVersion: valid.schemaVersion,
            appVersion: valid.appVersion,
            exportedAt: valid.exportedAt,
            data: valid.data
        )

        XCTAssertThrowsError(try BackupService.validate(wrong))
    }

    private func seedFixture(
        in context: NSManagedObjectContext
    ) throws -> (wordID: UUID, stateID: UUID, sessionID: UUID) {
        let now = Date()
        let word = WordEntity(context: context)
        word.id = UUID()
        word.english = "apple"
        word.normalizedEnglish = "apple"
        word.chinese = "苹果"
        word.createdAt = now
        word.updatedAt = now

        var firstState: ReviewStateEntity?
        for direction in ReviewDirection.allCases {
            let state = ReviewStateEntity(context: context)
            state.id = UUID()
            state.word = word
            state.direction = direction.rawValue
            state.level = direction == .englishToChinese ? 2 : 1
            state.nextReviewDate = now
            state.totalReviews = 1
            state.knownCount = 1
            state.unknownCount = 0
            state.consecutiveKnown = 1
            state.lapseCount = 0
            state.lastResult = ReviewResult.known.rawValue
            state.createdAt = now
            state.updatedAt = now
            if firstState == nil { firstState = state }
        }

        let session = StudySessionEntity(context: context)
        session.id = UUID()
        session.mode = PracticeMode.scheduled.rawValue
        session.startedAt = now
        session.finishedAt = now
        session.completed = true
        session.baseTaskCount = 1
        session.formalAnswered = 1
        session.formalKnown = 1

        guard let state = firstState else { throw CocoaError(.validationMissingMandatoryProperty) }
        let event = ReviewEventEntity(context: context)
        event.id = UUID()
        event.word = word
        event.reviewState = state
        event.session = session
        event.sessionID = session.id
        event.reviewedAt = now
        event.direction = state.direction
        event.result = ReviewResult.known.rawValue
        event.practiceMode = PracticeMode.scheduled.rawValue
        event.levelBefore = 1
        event.levelAfter = 2
        event.isSameSessionRetry = false
        event.wordEnglishSnapshot = word.english
        event.wordChineseSnapshot = word.chinese

        try context.save()
        return (word.id, state.id, session.id)
    }
}
