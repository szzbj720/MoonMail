// File: Models.swift

import Foundation

struct MoonMailUserProfile {
    let uid: String
    let displayName: String
    let email: String
    let coupleId: String?
    let inviteCode: String?
}

struct MoonNote: Identifiable, Hashable {
    let id: String
    let text: String
    let senderId: String
    let senderName: String
    let createdAt: Date
}

struct MoonMoodStatus: Identifiable, Hashable {
    let id: String
    let userId: String
    let userName: String
    let moodTitle: String
    let moodIcon: String
    let updatedAt: Date
}

struct MoonSignalStatus: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let senderId: String
    let senderName: String
    let createdAt: Date
}

struct MoodOption: Hashable {
    let title: String
    let icon: String
}

struct MoonSignal: Hashable {
    let title: String
    let icon: String
}

struct MoonCoupleProfile: Equatable {
    let coupleId: String
    let inviteCode: String
    let partnerOneId: String
    let partnerOneName: String
    let partnerTwoId: String
    let partnerTwoName: String
    let reunionDate: Date?
    let createdAt: Date?

    var isConnected: Bool {
        !partnerOneId.isEmpty && !partnerTwoId.isEmpty
    }

    func partnerName(for currentUserId: String) -> String {
        if currentUserId == partnerOneId {
            return partnerTwoName.isEmpty ? "Waiting for partner" : partnerTwoName
        }

        if currentUserId == partnerTwoId {
            return partnerOneName.isEmpty ? "Waiting for partner" : partnerOneName
        }

        if !partnerTwoName.isEmpty {
            return partnerTwoName
        }

        return partnerOneName
    }
}

enum AuthRoute: Hashable {
    case create
    case join
    case login
}
