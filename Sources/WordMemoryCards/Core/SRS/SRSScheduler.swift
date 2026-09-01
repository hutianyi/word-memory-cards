import Foundation

struct SRSDecision: Equatable {
    let newLevel: Int
    let nextReviewDate: Date
}

enum SRSScheduler {
    static let intervalsInDays = [0, 1, 3, 7, 14, 30, 60, 120, 180, 365]

    static func decision(
        level: Int,
        answer: ReviewResult,
        date: Date,
        calendar: Calendar = .current
    ) -> SRSDecision {
        let clampedLevel = min(max(level, 0), intervalsInDays.count - 1)
        let today = calendar.startOfDay(for: date)

        switch answer {
        case .known:
            let newLevel = min(clampedLevel + 1, intervalsInDays.count - 1)
            let next = calendar.date(
                byAdding: .day,
                value: intervalsInDays[newLevel],
                to: today
            ) ?? today
            return SRSDecision(newLevel: newLevel, nextReviewDate: next)

        case .unknown:
            let newLevel = clampedLevel / 2
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            return SRSDecision(newLevel: newLevel, nextReviewDate: tomorrow)
        }
    }
}
