import Foundation

struct BackupEnvelope: Codable {
    static let appMarker = "WordMemoryCards"
    static let currentBackupFormatVersion = 1
    static let currentSchemaVersion = 2

    let app: String
    let backupFormatVersion: Int
    let schemaVersion: Int
    let appVersion: String
    let exportedAt: Date
    let data: BackupData
}

struct BackupData: Codable {
    let words: [BackupWord]
    let reviewStates: [BackupReviewState]
    let reviewEvents: [BackupReviewEvent]
    let studySessions: [BackupStudySession]
    let settings: BackupSettings
}

struct BackupWord: Codable {
    let id: UUID
    let english: String
    let normalizedEnglish: String
    let chinese: String
    let createdAt: Date
    let updatedAt: Date
}

struct BackupReviewState: Codable {
    let id: UUID
    let wordID: UUID
    let direction: String
    let level: Int16
    let nextReviewDate: Date
    let lastReviewDate: Date?
    let totalReviews: Int64
    let knownCount: Int64
    let unknownCount: Int64
    let consecutiveKnown: Int32
    let lapseCount: Int64
    let lastResult: String?
    let fsrsCardData: Data?
    let fsrsMigrationVersion: Int16?
    let createdAt: Date
    let updatedAt: Date
}

struct BackupReviewEvent: Codable {
    let id: UUID
    let wordID: UUID
    let reviewStateID: UUID
    let sessionID: UUID
    let reviewedAt: Date
    let direction: String
    let result: String
    let practiceMode: String
    let levelBefore: Int16
    let levelAfter: Int16
    let isSameSessionRetry: Bool
    let wordEnglishSnapshot: String
    let wordChineseSnapshot: String
}

struct BackupStudySession: Codable {
    let id: UUID
    let mode: String
    let startedAt: Date
    let finishedAt: Date?
    let completed: Bool
    let baseTaskCount: Int32
    let formalAnswered: Int32
    let formalKnown: Int32
    let formalUnknown: Int32
    let retryAnswered: Int32
    let extraAnswered: Int32
    let extraKnown: Int32
    let extraUnknown: Int32
}

struct BackupSettings: Codable {
    let sessionLimit: Int
    let englishVoiceIdentifier: String?
    let chineseVoiceIdentifier: String?
    let englishSpeechRate: Double
    let chineseSpeechRate: Double
    let autoSpeakFront: Bool
    let autoSpeakBack: Bool
    let hapticsEnabled: Bool
    let extraPracticeScope: String
}

struct BackupSummary {
    let exportedAt: Date
    let wordCount: Int
    let stateCount: Int
    let eventCount: Int
    let sessionCount: Int
    let appVersion: String

    init(envelope: BackupEnvelope) {
        exportedAt = envelope.exportedAt
        wordCount = envelope.data.words.count
        stateCount = envelope.data.reviewStates.count
        eventCount = envelope.data.reviewEvents.count
        sessionCount = envelope.data.studySessions.count
        appVersion = envelope.appVersion
    }

    var confirmationText: String {
        """
        备份日期：\(exportedAt.formatted(date: .abbreviated, time: .shortened))
        单词：\(wordCount)
        双向复习状态：\(stateCount)
        学习记录：\(eventCount)
        Session：\(sessionCount)
        App 版本：\(appVersion)

        恢复会替换当前本地数据。
        """
    }
}
