import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class MoonMoodViewModel: ObservableObject {
    @Published var moods: [MoonMoodStatus] = []
    @Published var isSaving = false
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
            .collection("moods")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        self.show(message: error.localizedDescription)
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        self.moods = []
                        return
                    }

                    self.moods = documents.map { document in
                        let data = document.data()
                        let timestamp = data["updatedAt"] as? Timestamp

                        return MoonMoodStatus(
                            id: document.documentID,
                            userId: data["userId"] as? String ?? "",
                            userName: data["userName"] as? String ?? "Unknown",
                            moodTitle: data["moodTitle"] as? String ?? "Not set",
                            moodIcon: data["moodIcon"] as? String ?? "moon.stars.fill",
                            updatedAt: timestamp?.dateValue() ?? Date()
                        )
                    }
                }
            }
    }

    func updateMood(mood: MoodOption, profile: MoonMailUserProfile) async {
        guard let coupleId = profile.coupleId else {
            show(message: "No Moon Room found for this account.")
            return
        }

        isSaving = true

        do {
            try await db.collection("couples")
                .document(coupleId)
                .collection("moods")
                .document(profile.uid)
                .setData([
                    "userId": profile.uid,
                    "userName": profile.displayName,
                    "moodTitle": mood.title,
                    "moodIcon": mood.icon,
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)

            isSaving = false
        } catch {
            isSaving = false
            show(message: error.localizedDescription)
        }
    }

    func moodForUser(_ userId: String) -> MoonMoodStatus? {
        moods.first { $0.userId == userId }
    }

    func partnerMood(currentUserId: String) -> MoonMoodStatus? {
        moods.first { $0.userId != currentUserId }
    }

    private func show(message: String) {
        errorMessage = message
        showError = true
    }
}
