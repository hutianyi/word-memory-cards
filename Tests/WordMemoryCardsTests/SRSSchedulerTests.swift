import XCTest
@testable import WordMemoryCards

final class SRSSchedulerTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
        return value
    }

    private var date: Date {
        DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 9,
            day: 1,
            hour: 23
        ).date!
    }

    func testKnownMovesUpOneLevelUsingCalendarDays() {
        let decision = SRSScheduler.decision(level: 3, answer: .known, date: date, calendar: calendar)

        XCTAssertEqual(decision.newLevel, 4)
        XCTAssertEqual(
            decision.nextReviewDate,
            calendar.date(byAdding: .day, value: 14, to: calendar.startOfDay(for: date))
        )
    }

    func testKnownAtMaximumStaysAtLevelNine() {
        let decision = SRSScheduler.decision(level: 9, answer: .known, date: date, calendar: calendar)
        XCTAssertEqual(decision.newLevel, 9)
        XCTAssertEqual(
            decision.nextReviewDate,
            calendar.date(byAdding: .day, value: 365, to: calendar.startOfDay(for: date))
        )
    }

    func testUnknownHalvesLevelAndReturnsTomorrow() {
        let decision = SRSScheduler.decision(level: 8, answer: .unknown, date: date, calendar: calendar)
        XCTAssertEqual(decision.newLevel, 4)
        XCTAssertEqual(
            decision.nextReviewDate,
            calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))
        )
    }

    func testUnknownAtLevelOneReturnsToZero() {
        XCTAssertEqual(
            SRSScheduler.decision(level: 1, answer: .unknown, date: date, calendar: calendar).newLevel,
            0
        )
    }
}
