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
            show(message: "Your account is not connected to a Moon Room yet.")
            return
        }

        if activeCoupleId == coupleId, listener != nil {
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

                    self.isLoading = false

                    if let error {
                        self.show(message: self.userFacingMessage(for: error))
                        return
                    }

                    guard let snapshot, let data = snapshot.data() else {
                        self.couple = nil
                        return
                    }

                    let reunionTimestamp = data["reunionDate"] as? Timestamp
                    let relationshipStartTimestamp = data["relationshipStartDate"] as? Timestamp
                    let createdTimestamp = data["createdAt"] as? Timestamp

                    self.couple = MoonCoupleProfile(
                        coupleId: data["coupleId"] as? String ?? snapshot.documentID,
                        inviteCode: data["inviteCode"] as? String ?? "",
                        partnerOneId: data["partnerOneId"] as? String ?? "",
                        partnerOneName: data["partnerOneName"] as? String ?? "",
                        partnerTwoId: data["partnerTwoId"] as? String ?? "",
                        partnerTwoName: data["partnerTwoName"] as? String ?? "",
                        reunionDate: reunionTimestamp?.dateValue(),
                        relationshipStartDate: relationshipStartTimestamp?.dateValue(),
                        createdAt: createdTimestamp?.dateValue()
                    )
                }
            }
    }

    func retryLoading(coupleId: String?) {
        listener?.remove()
        listener = nil
        activeCoupleId = nil
        startListening(coupleId: coupleId)
    }

    func saveReunionDate(_ date: Date, coupleId: String?) async {
        guard let coupleId else {
            show(message: "Your account is not connected to a Moon Room yet.")
            return
        }

        isSaving = true
        clearTransientMessages()

        do {
            let normalizedDate = Calendar.current.startOfDay(for: date)

            try await db.collection("couples")
                .document(coupleId)
                .setData([
                    "reunionDate": Timestamp(date: normalizedDate)
                ], merge: true)

            isSaving = false
            showSuccess(message: "Reunion date saved!")
        } catch {
            isSaving = false
            show(message: userFacingMessage(for: error))
        }
    }

    func saveRelationshipStartDate(_ date: Date, coupleId: String?) async {
        guard let coupleId else {
            show(message: "Your account is not connected to a Moon Room yet.")
            return
        }

        isSaving = true
        clearTransientMessages()

        do {
            let normalizedDate = Calendar.current.startOfDay(for: date)

            try await db.collection("couples")
                .document(coupleId)
                .setData([
                    "relationshipStartDate": Timestamp(date: normalizedDate)
                ], merge: true)

            isSaving = false
            showSuccess(message: "Official date saved!")
        } catch {
            isSaving = false
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
            return "We couldn't update your Moon Room right now. Please try again in a moment."
        }

        if !error.localizedDescription.isEmpty {
            return error.localizedDescription
        }

        return "Something went wrong. Please try again."
    }
}
