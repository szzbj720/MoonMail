// File: MoonDateLogic.swift

import Foundation

enum MoonDateLogic {
    static func daysTogether(
        since relationshipStartDate: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int? {
        guard let relationshipStartDate else { return nil }

        let start = calendar.startOfDay(for: relationshipStartDate)
        let end = calendar.startOfDay(for: now)

        guard let days = calendar.dateComponents([.day], from: start, to: end).day else {
            return nil
        }

        return max(days + 1, 1)
    }

    static func reunionCountdownDays(
        until reunionDate: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int? {
        guard let reunionDate else { return nil }

        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: reunionDate)

        return calendar.dateComponents([.day], from: start, to: end).day
    }

    static func reunionProgress(
        until reunionDate: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Double {
        guard
            let days = reunionCountdownDays(until: reunionDate, now: now, calendar: calendar),
            days > 0
        else {
            return 0
        }

        let totalWindow = max(days + 30, 1)
        let elapsed = totalWindow - days
        let progress = Double(elapsed) / Double(totalWindow)

        return min(max(progress, 0), 1)
    }

    static func officialDateText(
        for relationshipStartDate: Date?,
        calendar: Calendar = .current
    ) -> String {
        guard let relationshipStartDate else {
            return "Set your official date in the Us tab"
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return "Official since \(formatter.string(from: relationshipStartDate))"
    }

    static func reunionDateText(
        for reunionDate: Date?,
        calendar: Calendar = .current
    ) -> String {
        guard let reunionDate else {
            return "Set your reunion date in the Us tab"
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: reunionDate)
    }

    static func togetherSubtitle(for daysTogether: Int?) -> String {
        guard let daysTogether else {
            return "days together"
        }

        return daysTogether == 1 ? "day together" : "days together"
    }

    static func reunionSubtitle(for countdownDays: Int?) -> String {
        guard let countdownDays else {
            return "days until we meet again"
        }

        if countdownDays <= 0 {
            return "your moonrise is here"
        }

        return countdownDays == 1 ? "day until we meet again" : "days until we meet again"
    }
}
