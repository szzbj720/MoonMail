import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class MoonNotesViewModel: ObservableObject {
    @Published var notes: [MoonNote] = []
    @Published var isSending = false
    @Published var errorMessage = ""
    @Published var showError = false

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
            .collection("notes")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        self.show(message: error.localizedDescription)
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        self.notes = []
                        return
                    }

                    self.notes = documents.map { document in
                        let data = document.data()
                        let timestamp = data["createdAt"] as? Timestamp

                        return MoonNote(
                            id: document.documentID,
                            text: data["text"] as? String ?? "",
                            senderId: data["senderId"] as? String ?? "",
                            senderName: data["senderName"] as? String ?? "Unknown",
                            createdAt: timestamp?.dateValue() ?? Date()
                        )
                    }
                }
            }
    }

    func sendNote(text: String, profile: MoonMailUserProfile) async -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            show(message: "Please write a Moon Note before sending.")
            return false
        }

        guard let coupleId = profile.coupleId else {
            show(message: "No Moon Room found for this account.")
            return false
        }

        isSending = true

        do {
            try await db.collection("couples")
                .document(coupleId)
                .collection("notes")
                .addDocument(data: [
                    "text": trimmedText,
                    "senderId": profile.uid,
                    "senderName": profile.displayName,
                    "createdAt": FieldValue.serverTimestamp()
                ])

            isSending = false
            return true
        } catch {
            isSending = false
            show(message: error.localizedDescription)
            return false
        }
    }

    private func show(message: String) {
        errorMessage = message
        showError = true
    }
}
