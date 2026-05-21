// File: MoonCoreLogicTests.swift
// Add this to the MoonMailTests target.

import XCTest
@testable import MoonMail

final class MoonCoreLogicTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testPartnerNameReturnsPartnerTwoWhenCurrentUserIsPartnerOne() {
        let couple = makeCouple(
            partnerOneId: "user-1",
            partnerOneName: "Selena",
            partnerTwoId: "user-2",
            partnerTwoName: "Adam"
        )

        XCTAssertEqual(couple.partnerName(for: "user-1"), "Adam")
    }

    func testPartnerNameReturnsPartnerOneWhenCurrentUserIsPartnerTwo() {
        let couple = makeCouple(
            partnerOneId: "user-1",
            partnerOneName: "Selena",
            partnerTwoId: "user-2",
            partnerTwoName: "Adam"
        )

        XCTAssertEqual(couple.partnerName(for: "user-2"), "Selena")
    }

    func testPartnerNameReturnsWaitingWhenPartnerTwoNameMissingForPartnerOne() {
        let couple = makeCouple(
            partnerOneId: "user-1",
            partnerOneName: "Selena",
            partnerTwoId: "",
            partnerTwoName: ""
        )

        XCTAssertEqual(couple.partnerName(for: "user-1"), "Waiting for partner")
    }

    func testPartnerNameFallsBackToPartnerTwoNameForUnknownUserWhenAvailable() {
        let couple = makeCouple(
            partnerOneId: "user-1",
            partnerOneName: "Selena",
            partnerTwoId: "user-2",
            partnerTwoName: "Adam"
        )

        XCTAssertEqual(couple.partnerName(for: "unknown-user"), "Adam")
    }

    func testPartnerNameFallsBackToPartnerOneNameForUnknownUserWhenPartnerTwoMissing() {
        let couple = makeCouple(
            partnerOneId: "user-1",
            partnerOneName: "Selena",
            partnerTwoId: "",
            partnerTwoName: ""
        )

        XCTAssertEqual(couple.partnerName(for: "unknown-user"), "Selena")
    }

    func testPartnerNameFallsBackToWaitingWhenNoNamesAreAvailable() {
        let couple = makeCouple(
            partnerOneId: "",
            partnerOneName: "",
            partnerTwoId: "",
            partnerTwoName: ""
        )

        XCTAssertEqual(couple.partnerName(for: "unknown-user"), "Waiting for partner")
    }

    func testSignalRelativeTimeReturnsJustNowForUnderTenSeconds() {
        let now = fixedDate(2026, 5, 21, 12, 0, 0)
        let date = now.addingTimeInterval(-8)

        XCTAssertEqual(
            MoonSignalTimeFormatter.relativeTime(from: date, now: now),
            "just now"
        )
    }

    func testSignalRelativeTimeReturnsSecondsAgo() {
        let now = fixedDate(2026, 5, 21, 12, 0, 0)
        let date = now.addingTimeInterval(-42)

        XCTAssertEqual(
            MoonSignalTimeFormatter.relativeTime(from: date, now: now),
            "42s ago"
        )
    }

    func testSignalRelativeTimeReturnsMinutesAgo() {
        let now = fixedDate(2026, 5, 21, 12, 0, 0)
        let date = now.addingTimeInterval(-12 * 60)

        XCTAssertEqual(
            MoonSignalTimeFormatter.relativeTime(from: date, now: now),
            "12m ago"
        )
    }

    func testSignalRelativeTimeReturnsHoursAgo() {
        let now = fixedDate(2026, 5, 21, 12, 0, 0)
        let date = now.addingTimeInterval(-3 * 60 * 60)

        XCTAssertEqual(
            MoonSignalTimeFormatter.relativeTime(from: date, now: now),
            "3h ago"
        )
    }

    func testSignalRelativeTimeReturnsDaysAgo() {
        let now = fixedDate(2026, 5, 21, 12, 0, 0)
        let date = now.addingTimeInterval(-4 * 24 * 60 * 60)

        XCTAssertEqual(
            MoonSignalTimeFormatter.relativeTime(from: date, now: now),
            "4d ago"
        )
    }

    func testSignalRelativeTimeReturnsFormattedDateAfterAWeek() {
        let now = fixedDate(2026, 5, 21, 12, 0, 0)
        let date = fixedDate(2026, 5, 10, 12, 0, 0)

        let result = MoonSignalTimeFormatter.relativeTime(from: date, now: now)

        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, "just now")
        XCTAssertFalse(result.hasSuffix("s ago"))
        XCTAssertFalse(result.hasSuffix("m ago"))
        XCTAssertFalse(result.hasSuffix("h ago"))
        XCTAssertFalse(result.hasSuffix("d ago"))
    }

    func testSignalRelativeTimeDoesNotGoNegativeForFutureDate() {
        let now = fixedDate(2026, 5, 21, 12, 0, 0)
        let futureDate = now.addingTimeInterval(30)

        XCTAssertEqual(
            MoonSignalTimeFormatter.relativeTime(from: futureDate, now: now),
            "just now"
        )
    }

    private func makeCouple(
        partnerOneId: String,
        partnerOneName: String,
        partnerTwoId: String,
        partnerTwoName: String
    ) -> MoonCoupleProfile {
        MoonCoupleProfile(
            coupleId: "couple-1",
            inviteCode: "MOON-1234",
            partnerOneId: partnerOneId,
            partnerOneName: partnerOneName,
            partnerTwoId: partnerTwoId,
            partnerTwoName: partnerTwoName,
            reunionDate: nil,
            relationshipStartDate: nil,
            createdAt: nil
        )
    }

    private func fixedDate(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        _ second: Int
    ) -> Date {
        let components = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )

        guard let date = calendar.date(from: components) else {
            XCTFail("Could not create fixed test date.")
            return Date()
        }

        return date
    }
}
