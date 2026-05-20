// File: MoonSignalsViewModel.swift

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class MoonSignalsViewModel: ObservableObject {
    @Published var signals: [MoonSignalStatus] = []
    @Published var isSending = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var successMessage = ""
    @Published var showSuccess = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var activeCoupleId: String?

    deinit {
        listener?.remove()
    }

    func startListening(coupleId: String?) {
        guard let coupleId else {
            show(message: "No Moon Room found for this account.")
            return
        }

        guard activeCoupleId != coupleId else {
            return
        }

        listener?.remove()
        activeCoupleId = coupleId

        listener = db.collection("couples")
            .document(coupleId)
            .collection("signals")
            .order(by: "createdAt", descending: true)
            .limit(to: 8)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        self.show(message: error.localizedDescription)
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        self.signals = []
                        return
                    }

                    self.signals = documents.map { document in
                        let data = document.data()
                        let timestamp = data["createdAt"] as? Timestamp

                        return MoonSignalStatus(
                            id: document.documentID,
                            title: data["title"] as? String ?? "Moon Signal",
                            icon: data["icon"] as? String ?? "moon.stars.fill",
                            senderId: data["senderId"] as? String ?? "",
                            senderName: data["senderName"] as? String ?? "Unknown",
                            createdAt: timestamp?.dateValue() ?? Date()
                        )
                    }
                }
            }
    }

    func sendSignal(_ signal: MoonSignal, profile: MoonMailUserProfile) async {
        guard let coupleId = profile.coupleId else {
            show(message: "No Moon Room found for this account.")
            return
        }

        isSending = true

        do {
            try await db.collection("couples")
                .document(coupleId)
                .collection("signals")
                .addDocument(data: [
                    "title": signal.title,
                    "icon": signal.icon,
                    "senderId": profile.uid,
                    "senderName": profile.displayName,
                    "createdAt": FieldValue.serverTimestamp()
                ])

            isSending = false
            successMessage = "\(signal.title) sent!"
            showSuccess = true
        } catch {
            isSending = false
            show(message: error.localizedDescription)
        }
    }

    private func show(message: String) {
        errorMessage = message
        showError = true
    }
}
