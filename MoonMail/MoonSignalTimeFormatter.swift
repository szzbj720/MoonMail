// File: MoonSignalTimeFormatter.swift

import Foundation

enum MoonSignalTimeFormatter {
    static func relativeTime(
        from date: Date,
        now: Date = Date()
    ) -> String {
        let seconds = max(Int(now.timeIntervalSince(date)), 0)

        if seconds < 10 {
            return "just now"
        }

        if seconds < 60 {
            return "\(seconds)s ago"
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m ago"
        }

        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h ago"
        }

        let days = hours / 24
        if days < 7 {
            return "\(days)d ago"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
