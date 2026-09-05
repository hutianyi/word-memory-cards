import CoreData
import Foundation

enum BackupService {
    enum BackupError: LocalizedError {
        case wrongApp
        case unsupportedFormat(Int)
        case unsupportedSchema(Int)
        case invalidData(String)
        case brokenRelationship(String)

        var errorDescription: String? {
            switch self {
            case .wrongApp:
                return "这不是单词卡片 App 的备份文件。"
            case .unsupportedFormat(let version):
                return "不支持这个备份格式版本（\(version)）。"
            case .unsupportedSchema(let version):
                return "不支持这个数据库版本（\(version)）。"
            case .invalidData(let detail):
                return "备份内容不完整：\(detail)"
            case .brokenRelationship(let detail):
                return "备份中的数据关联无效：\(detail)"
            }
        }
    }

    static func makeEnvelope(
        container: NSPersistentContainer,
        settings: BackupSettings,
        appVersion: String
    ) async throws -> BackupEnvelope {
        let context = container.newBackgroundContext()
        context.undoManager = nil

        let body: BackupData = try await context.perform {
            _ = try FSRSMigrationService.migrateAll(in: context)
            let words = try context.fetch(WordEntity.fetchRequest()).map {
                BackupWord(
                    id: $0.id,
                    english: $0.english,
                    normalizedEnglish: $0.normalizedEnglish,
                    chinese: $0.chinese,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            }

            let states = try context.fetch(ReviewStateEntity.fetchRequest()).map { state in
                guard let wordID = state.word?.id else {
                    throw BackupError.brokenRelationship("复习状态缺少单词")
                }
                return BackupReviewState(
                    id: state.id,
                    wordID: wordID,
                    direction: state.direction,
                    level: state.level,
                    nextReviewDate: state.nextReviewDate,
                    lastReviewDate: state.lastReviewDate,
                    totalReviews: state.totalReviews,
                    knownCount: state.knownCount,
                    unknownCount: state.unknownCount,
                    consecutiveKnown: state.consecutiveKnown,
                    lapseCount: state.lapseCount,
                    lastResult: state.lastResult,
                    fsrsCardData: state.fsrsCardData,
                    fsrsMigrationVersion: state.fsrsMigrationVersion,
                    createdAt: state.createdAt,
                    updatedAt: state.updatedAt
                )
            }

            let sessions = try context.fetch(StudySessionEntity.fetchRequest()).map {
                BackupStudySession(
                    id: $0.id,
                    mode: $0.mode,
                    startedAt: $0.startedAt,
                    finishedAt: $0.finishedAt,
                    completed: $0.completed,
                    baseTaskCount: $0.baseTaskCount,
                    formalAnswered: $0.formalAnswered,
                    formalKnown: $0.formalKnown,
                    formalUnknown: $0.formalUnknown,
                    retryAnswered: $0.retryAnswered,
                    extraAnswered: $0.extraAnswered,
                    extraKnown: $0.extraKnown,
                    extraUnknown: $0.extraUnknown
                )
            }

            let events = try context.fetch(ReviewEventEntity.fetchRequest()).map { event in
                guard let wordID = event.word?.id else {
                    throw BackupError.brokenRelationship("学习记录缺少单词")
                }
                return BackupReviewEvent(
                    id: event.id,
                    wordID: wordID,
                    reviewStateID: event.reviewState.id,
                    sessionID: event.session.id,
                    reviewedAt: event.reviewedAt,
                    direction: event.direction,
                    result: event.result,
                    practiceMode: event.practiceMode,
                    levelBefore: event.levelBefore,
                    levelAfter: event.levelAfter,
                    isSameSessionRetry: event.isSameSessionRetry,
                    wordEnglishSnapshot: event.wordEnglishSnapshot,
                    wordChineseSnapshot: event.wordChineseSnapshot
                )
            }

            return BackupData(
                words: words.sorted { $0.normalizedEnglish < $1.normalizedEnglish },
                reviewStates: states.sorted { $0.id.uuidString < $1.id.uuidString },
                reviewEvents: events.sorted { $0.reviewedAt < $1.reviewedAt },
                studySessions: sessions.sorted { $0.startedAt < $1.startedAt },
                settings: settings
            )
        }

        return BackupEnvelope(
            app: BackupEnvelope.appMarker,
            backupFormatVersion: BackupEnvelope.currentBackupFormatVersion,
            schemaVersion: BackupEnvelope.currentSchemaVersion,
            appVersion: appVersion,
            exportedAt: Date(),
            data: body
        )
    }

    static func encode(_ envelope: BackupEnvelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(envelope)
    }

    static func decodeAndValidate(_ data: Data) throws -> BackupEnvelope {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(BackupEnvelope.self, from: data)
        try validate(envelope)
        return envelope
    }

    static func validate(_ envelope: BackupEnvelope) throws {
        guard envelope.app == BackupEnvelope.appMarker else { throw BackupError.wrongApp }
        guard envelope.backupFormatVersion == BackupEnvelope.currentBackupFormatVersion else {
            throw BackupError.unsupportedFormat(envelope.backupFormatVersion)
        }
        guard (1...BackupEnvelope.currentSchemaVersion).contains(envelope.schemaVersion) else {
            throw BackupError.unsupportedSchema(envelope.schemaVersion)
        }

        let data = envelope.data
        let wordIDs = Set(data.words.map(\.id))
        guard wordIDs.count == data.words.count else {
            throw BackupError.invalidData("存在重复的单词 ID")
        }
        let normalizedWords = data.words.map(\.normalizedEnglish)
        guard Set(normalizedWords).count == normalizedWords.count,
              data.words.allSatisfy({
                  !$0.normalizedEnglish.isEmpty && !$0.english.isEmpty && !$0.chinese.isEmpty
              }) else {
            throw BackupError.invalidData("单词为空或 normalizedEnglish 重复")
        }

        let stateIDs = Set(data.reviewStates.map(\.id))
        guard stateIDs.count == data.reviewStates.count else {
            throw BackupError.invalidData("存在重复的复习状态 ID")
        }
        var stateKeys = Set<String>()
        for state in data.reviewStates {
            guard wordIDs.contains(state.wordID) else {
                throw BackupError.brokenRelationship("复习状态引用了不存在的单词")
            }
            guard ReviewDirection(rawValue: state.direction) != nil,
                  (0...9).contains(Int(state.level)),
                  state.knownCount >= 0,
                  state.unknownCount >= 0 else {
                throw BackupError.invalidData("复习状态的方向、Level 或计数无效")
            }
            if let cardData = state.fsrsCardData {
                guard (try? SRSScheduler.decodeCard(cardData)) != nil else {
                    throw BackupError.invalidData("复习状态中的调度数据无效")
                }
            }
            let key = "\(state.wordID.uuidString)|\(state.direction)"
            guard stateKeys.insert(key).inserted else {
                throw BackupError.invalidData("同一个单词存在重复方向状态")
            }
        }
        for wordID in wordIDs {
            let directions = Set(
                data.reviewStates
                    .filter { $0.wordID == wordID }
                    .map(\.direction)
            )
            guard directions == Set(ReviewDirection.allCases.map(\.rawValue)) else {
                throw BackupError.invalidData("每个单词必须正好包含两个复习方向")
            }
        }

        let sessionIDs = Set(data.studySessions.map(\.id))
        guard sessionIDs.count == data.studySessions.count,
              data.studySessions.allSatisfy({
                  PracticeMode(rawValue: $0.mode) != nil
                      && $0.baseTaskCount >= 0
                      && $0.formalAnswered >= 0
                      && $0.extraAnswered >= 0
              }) else {
            throw BackupError.invalidData("Session ID、模式或计数无效")
        }

        let eventIDs = Set(data.reviewEvents.map(\.id))
        guard eventIDs.count == data.reviewEvents.count else {
            throw BackupError.invalidData("存在重复的学习记录 ID")
        }
        for event in data.reviewEvents {
            guard wordIDs.contains(event.wordID),
                  stateIDs.contains(event.reviewStateID),
                  sessionIDs.contains(event.sessionID) else {
                throw BackupError.brokenRelationship("学习记录引用了不存在的数据")
            }
            guard ReviewDirection(rawValue: event.direction) != nil,
                  ReviewResult(rawValue: event.result) != nil,
                  PracticeMode(rawValue: event.practiceMode) != nil else {
                throw BackupError.invalidData("学习记录的方向、答案或模式无效")
            }
        }

        guard SessionLimitOption(rawValue: data.settings.sessionLimit) != nil,
              ExtraPracticeScope(rawValue: data.settings.extraPracticeScope) != nil,
              (0.30...0.62).contains(data.settings.englishSpeechRate),
              (0.30...0.62).contains(data.settings.chineseSpeechRate) else {
            throw BackupError.invalidData("设置值无效")
        }
    }

    static func restore(
        _ envelope: BackupEnvelope,
        into container: NSPersistentContainer
    ) async throws {
        try validate(envelope)
        let context = container.newBackgroundContext()
        context.mergePolicy = NSErrorMergePolicy
        context.undoManager = nil

        try await context.perform {
            do {
                try deleteAll(ReviewEventEntity.fetchRequest(), in: context)
                try deleteAll(ReviewStateEntity.fetchRequest(), in: context)
                try deleteAll(StudySessionEntity.fetchRequest(), in: context)
                try deleteAll(WordEntity.fetchRequest(), in: context)

                var words: [UUID: WordEntity] = [:]
                for item in envelope.data.words {
                    let word = WordEntity(context: context)
                    word.id = item.id
                    word.english = item.english
                    word.normalizedEnglish = item.normalizedEnglish
                    word.chinese = item.chinese
                    word.createdAt = item.createdAt
                    word.updatedAt = item.updatedAt
                    words[item.id] = word
                }

                var states: [UUID: ReviewStateEntity] = [:]
                for item in envelope.data.reviewStates {
                    guard let word = words[item.wordID] else {
                        throw BackupError.brokenRelationship("恢复复习状态时找不到单词")
                    }
                    let state = ReviewStateEntity(context: context)
                    state.id = item.id
                    state.word = word
                    state.direction = item.direction
                    state.level = item.level
                    state.nextReviewDate = item.nextReviewDate
                    state.lastReviewDate = item.lastReviewDate
                    state.totalReviews = item.totalReviews
                    state.knownCount = item.knownCount
                    state.unknownCount = item.unknownCount
                    state.consecutiveKnown = item.consecutiveKnown
                    state.lapseCount = item.lapseCount
                    state.lastResult = item.lastResult
                    state.fsrsCardData = item.fsrsCardData
                    state.fsrsMigrationVersion = item.fsrsMigrationVersion ?? 0
                    state.createdAt = item.createdAt
                    state.updatedAt = item.updatedAt
                    states[item.id] = state
                }

                var sessions: [UUID: StudySessionEntity] = [:]
                for item in envelope.data.studySessions {
                    let session = StudySessionEntity(context: context)
                    session.id = item.id
                    session.mode = item.mode
                    session.startedAt = item.startedAt
                    session.finishedAt = item.finishedAt
                    session.completed = item.completed
                    session.baseTaskCount = item.baseTaskCount
                    session.formalAnswered = item.formalAnswered
                    session.formalKnown = item.formalKnown
                    session.formalUnknown = item.formalUnknown
                    session.retryAnswered = item.retryAnswered
                    session.extraAnswered = item.extraAnswered
                    session.extraKnown = item.extraKnown
                    session.extraUnknown = item.extraUnknown
                    sessions[item.id] = session
                }

                for item in envelope.data.reviewEvents {
                    guard let word = words[item.wordID],
                          let state = states[item.reviewStateID],
                          let session = sessions[item.sessionID] else {
                        throw BackupError.brokenRelationship("恢复学习记录时找不到关联数据")
                    }
                    let event = ReviewEventEntity(context: context)
                    event.id = item.id
                    event.word = word
                    event.reviewState = state
                    event.session = session
                    event.sessionID = item.sessionID
                    event.reviewedAt = item.reviewedAt
                    event.direction = item.direction
                    event.result = item.result
                    event.practiceMode = item.practiceMode
                    event.levelBefore = item.levelBefore
                    event.levelAfter = item.levelAfter
                    event.isSameSessionRetry = item.isSameSessionRetry
                    event.wordEnglishSnapshot = item.wordEnglishSnapshot
                    event.wordChineseSnapshot = item.wordChineseSnapshot
                }

                _ = try FSRSMigrationService.migrateAll(in: context)

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    private static func deleteAll<T: NSManagedObject>(
        _ request: NSFetchRequest<T>,
        in context: NSManagedObjectContext
    ) throws {
        for object in try context.fetch(request) {
            context.delete(object)
        }
    }
}
