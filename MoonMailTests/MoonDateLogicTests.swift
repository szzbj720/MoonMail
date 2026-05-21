// File: MoonDateLogicTests.swift
// Add this to your test target, not the main app target.

import XCTest
@testable import MoonMail

final class MoonDateLogicTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()

        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testDaysTogetherReturnsNilWhenDateMissing() {
        XCTAssertNil(
            MoonDateLogic.daysTogether(
                since: nil,
                now: fixedDate(2026, 5, 20),
                calendar: calendar
            )
        )
    }

    func testDaysTogetherCountsSameDayAsOne() {
        XCTAssertEqual(
            MoonDateLogic.daysTogether(
                since: fixedDate(2026, 5, 20),
                now: fixedDate(2026, 5, 20),
                calendar: calendar
            ),
            1
        )
    }

    func testDaysTogetherCountsAcrossMultipleDays() {
        XCTAssertEqual(
            MoonDateLogic.daysTogether(
                since: fixedDate(2026, 5, 1),
                now: fixedDate(2026, 5, 20),
                calendar: calendar
            ),
            20
        )
    }

    func testReunionCountdownReturnsNilWhenDateMissing() {
        XCTAssertNil(
            MoonDateLogic.reunionCountdownDays(
                until: nil,
                now: fixedDate(2026, 5, 20),
                calendar: calendar
            )
        )
    }

    func testReunionCountdownReturnsFutureDayDifference() {
        XCTAssertEqual(
            MoonDateLogic.reunionCountdownDays(
                until: fixedDate(2026, 5, 25),
                now: fixedDate(2026, 5, 20),
                calendar: calendar
            ),
            5
        )
    }

    func testReunionCountdownReturnsZeroForSameDay() {
        XCTAssertEqual(
            MoonDateLogic.reunionCountdownDays(
                until: fixedDate(2026, 5, 20),
                now: fixedDate(2026, 5, 20),
                calendar: calendar
            ),
            0
        )
    }

    func testReunionCountdownCanBeNegativeForPastDates() {
        XCTAssertEqual(
            MoonDateLogic.reunionCountdownDays(
                until: fixedDate(2026, 5, 18),
                now: fixedDate(2026, 5, 20),
                calendar: calendar
            ),
            -2
        )
    }

    func testReunionProgressReturnsZeroWhenDateMissing() {
        XCTAssertEqual(
            MoonDateLogic.reunionProgress(
                until: nil,
                now: fixedDate(2026, 5, 20),
                calendar: calendar
            ),
            0
        )
    }

    func testReunionProgressReturnsZeroForSameDayOrPastDate() {
        XCTAssertEqual(
            MoonDateLogic.reunionProgress(
                until: fixedDate(2026, 5, 20),
                now: fixedDate(2026, 5, 20),
                calendar: calendar
            ),
            0
        )

        XCTAssertEqual(
            MoonDateLogic.reunionProgress(
                until: fixedDate(2026, 5, 18),
                now: fixedDate(2026, 5, 20),
                calendar: calendar
            ),
            0
        )
    }

    func testReunionProgressReturnsValueBetweenZeroAndOne() {
        let progress = MoonDateLogic.reunionProgress(
            until: fixedDate(2026, 5, 30),
            now: fixedDate(2026, 5, 20),
            calendar: calendar
        )

        XCTAssertGreaterThan(progress, 0)
        XCTAssertLessThan(progress, 1)
    }

    func testTogetherSubtitleHandlesNilSingularAndPlural() {
        XCTAssertEqual(MoonDateLogic.togetherSubtitle(for: nil), "days together")
        XCTAssertEqual(MoonDateLogic.togetherSubtitle(for: 1), "day together")
        XCTAssertEqual(MoonDateLogic.togetherSubtitle(for: 12), "days together")
    }

    func testReunionSubtitleHandlesNilPastSingularAndPlural() {
        XCTAssertEqual(MoonDateLogic.reunionSubtitle(for: nil), "days until we meet again")
        XCTAssertEqual(MoonDateLogic.reunionSubtitle(for: 0), "your moonrise is here")
        XCTAssertEqual(MoonDateLogic.reunionSubtitle(for: -2), "your moonrise is here")
        XCTAssertEqual(MoonDateLogic.reunionSubtitle(for: 1), "day until we meet again")
        XCTAssertEqual(MoonDateLogic.reunionSubtitle(for: 7), "days until we meet again")
    }

    private func fixedDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let components = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day
        )

        guard let date = calendar.date(from: components) else {
            XCTFail("Could not create fixed test date.")
            return Date()
        }

        return date
    }
}
