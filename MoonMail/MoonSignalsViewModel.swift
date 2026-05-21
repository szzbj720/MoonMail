// File: MoonSignalsViewModel.swift

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class MoonSignalsViewModel: ObservableObject {
    @Published var signals: [MoonSignalStatus] = []
    @Published var isInitialLoading = false
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
            show(message: "Your account is not connected to a Moon Room yet.")
            return
        }

        if activeCoupleId == coupleId, listener != nil {
            return
        }

        listener?.remove()
        activeCoupleId = coupleId
        isInitialLoading = true

        listener = db.collection("couples")
            .document(coupleId)
            .collection("signals")
            .order(by: "createdAt", descending: true)
            .limit(to: 8)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    self.isInitialLoading = false

                    if let error {
                        self.show(message: self.userFacingMessage(for: error))
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

    func retryLoading(coupleId: String?) {
        listener?.remove()
        listener = nil
        activeCoupleId = nil
        startListening(coupleId: coupleId)
    }

    func sendSignal(_ signal: MoonSignal, profile: MoonMailUserProfile) async {
        guard let coupleId = profile.coupleId else {
            show(message: "Your account is not connected to a Moon Room yet.")
            return
        }

        isSending = true
        clearTransientMessages()

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
            showSuccess(message: "\(signal.title) sent!")
        } catch {
            isSending = false
            show(message: userFacingMessage(for: error))
        }
    }

    func dismissMessages() {
        showError = false
        errorMessage = ""
        showSuccess = false
        successMessage = ""
    }

    private func clearTransientMessages() {
        errorMessage = ""
        showError = false
        successMessage = ""
        showSuccess = false
    }

    private func show(message: String) {
        errorMessage = message
        showError = true
    }

    private func showSuccess(message: String) {
        successMessage = message
        showSuccess = true
    }

    private func userFacingMessage(for error: Error) -> String {
        let nsError = error as NSError

        if nsError.domain == FirestoreErrorDomain {
            return "We couldn't sync your Moon Signals right now. Please try again in a moment."
        }

        if !error.localizedDescription.isEmpty {
            return error.localizedDescription
        }

        return "Something went wrong. Please try again."
    }
}
