// File: CoupleSettingsViewModel.swift

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class CoupleSettingsViewModel: ObservableObject {
    @Published var couple: MoonCoupleProfile?
    @Published var isLoading = false
    @Published var isSaving = false
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
        isLoading = true

        listener = db.collection("couples")
            .document(coupleId)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        self.isLoading = false
                        self.show(message: error.localizedDescription)
                        return
                    }

                    guard let snapshot, let data = snapshot.data() else {
                        self.isLoading = false
                        self.couple = nil
                        return
                    }

                    let reunionTimestamp = data["reunionDate"] as? Timestamp
                    let createdTimestamp = data["createdAt"] as? Timestamp

                    self.couple = MoonCoupleProfile(
                        coupleId: data["coupleId"] as? String ?? snapshot.documentID,
                        inviteCode: data["inviteCode"] as? String ?? "",
                        partnerOneId: data["partnerOneId"] as? String ?? "",
                        partnerOneName: data["partnerOneName"] as? String ?? "",
                        partnerTwoId: data["partnerTwoId"] as? String ?? "",
                        partnerTwoName: data["partnerTwoName"] as? String ?? "",
                        reunionDate: reunionTimestamp?.dateValue(),
                        createdAt: createdTimestamp?.dateValue()
                    )

                    self.isLoading = false
                }
            }
    }

    func saveReunionDate(_ date: Date, coupleId: String?) async {
        guard let coupleId else {
            show(message: "No Moon Room found for this account.")
            return
        }

        isSaving = true

        do {
            try await db.collection("couples")
                .document(coupleId)
                .updateData([
                    "reunionDate": Timestamp(date: date)
                ])

            isSaving = false
            successMessage = "Reunion date saved!"
            showSuccess = true
        } catch {
            isSaving = false
            show(message: error.localizedDescription)
        }
    }

    private func show(message: String) {
        errorMessage = message
        showError = true
    }
}
