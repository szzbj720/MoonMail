// File: MoonMailAppState.swift

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MoonMailAppState: ObservableObject {
    @Published var currentUser: MoonMailUserProfile?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let db = Firestore.firestore()
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenForAuthChanges()
    }

    deinit {
        if let authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
        }
    }

    private func listenForAuthChanges() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            Task {
                if let user {
                    await self.loadUserProfile(uid: user.uid)
                } else {
                    self.currentUser = nil
                }
            }
        }
    }

    func createMoonRoom(displayName: String, email: String, password: String) async {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard validateAccount(displayName: trimmedName, email: trimmedEmail, password: trimmedPassword) else {
            return
        }

        isLoading = true

        do {
            let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPassword)
            let uid = result.user.uid
            let coupleId = UUID().uuidString
            let inviteCode = generateMoonCode()

            try await db.collection("couples").document(coupleId).setData([
                "coupleId": coupleId,
                "inviteCode": inviteCode,
                "partnerOneId": uid,
                "partnerOneName": trimmedName,
                "partnerTwoId": "",
                "partnerTwoName": "",
                "createdAt": FieldValue.serverTimestamp()
            ])

            try await db.collection("users").document(uid).setData([
                "uid": uid,
                "displayName": trimmedName,
                "email": trimmedEmail,
                "coupleId": coupleId,
                "inviteCode": inviteCode,
                "createdAt": FieldValue.serverTimestamp()
            ])

            currentUser = MoonMailUserProfile(
                uid: uid,
                displayName: trimmedName,
                email: trimmedEmail,
                coupleId: coupleId,
                inviteCode: inviteCode
            )

            isLoading = false
        } catch {
            isLoading = false
            show(message: error.localizedDescription)
        }
    }

    func joinMoonRoom(displayName: String, email: String, password: String, inviteCode: String) async {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard validateAccount(displayName: trimmedName, email: trimmedEmail, password: trimmedPassword) else {
            return
        }

        guard trimmedCode.hasPrefix("MOON-") && trimmedCode.count == 9 else {
            show(message: "Please enter a valid moon code like MOON-4829.")
            return
        }

        isLoading = true

        do {
            let snapshot = try await db.collection("couples")
                .whereField("inviteCode", isEqualTo: trimmedCode)
                .limit(to: 1)
                .getDocuments()

            guard let coupleDocument = snapshot.documents.first else {
                isLoading = false
                show(message: "No Moon Room found with that code.")
                return
            }

            let coupleId = coupleDocument.documentID
            let data = coupleDocument.data()
            let partnerTwoId = data["partnerTwoId"] as? String ?? ""

            guard partnerTwoId.isEmpty else {
                isLoading = false
                show(message: "This Moon Room already has two people connected.")
                return
            }

            let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPassword)
            let uid = result.user.uid

            try await db.collection("couples").document(coupleId).updateData([
                "partnerTwoId": uid,
                "partnerTwoName": trimmedName
            ])

            try await db.collection("users").document(uid).setData([
                "uid": uid,
                "displayName": trimmedName,
                "email": trimmedEmail,
                "coupleId": coupleId,
                "inviteCode": trimmedCode,
                "createdAt": FieldValue.serverTimestamp()
            ])

            currentUser = MoonMailUserProfile(
                uid: uid,
                displayName: trimmedName,
                email: trimmedEmail,
                coupleId: coupleId,
                inviteCode: trimmedCode
            )

            isLoading = false
        } catch {
            isLoading = false
            show(message: error.localizedDescription)
        }
    }

    func signIn(email: String, password: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            show(message: "Please enter your email and password.")
            return
        }

        isLoading = true

        do {
            let result = try await Auth.auth().signIn(withEmail: trimmedEmail, password: trimmedPassword)
            await loadUserProfile(uid: result.user.uid)
            isLoading = false
        } catch {
            isLoading = false
            show(message: error.localizedDescription)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            show(message: error.localizedDescription)
        }
    }

    private func loadUserProfile(uid: String) async {
        isLoading = true

        do {
            let document = try await db.collection("users").document(uid).getDocument()

            guard let data = document.data() else {
                isLoading = false
                currentUser = nil
                return
            }

            let displayName = data["displayName"] as? String ?? "Me"
            let email = data["email"] as? String ?? ""
            let coupleId = data["coupleId"] as? String
            let inviteCode = data["inviteCode"] as? String

            currentUser = MoonMailUserProfile(
                uid: uid,
                displayName: displayName,
                email: email,
                coupleId: coupleId,
                inviteCode: inviteCode
            )

            isLoading = false
        } catch {
            isLoading = false
            show(message: error.localizedDescription)
        }
    }

    private func validateAccount(displayName: String, email: String, password: String) -> Bool {
        guard !displayName.isEmpty else {
            show(message: "Please enter your display name.")
            return false
        }

        guard email.contains("@") && email.contains(".") else {
            show(message: "Please enter a valid email address.")
            return false
        }

        guard password.count >= 6 else {
            show(message: "Your password should be at least 6 characters.")
            return false
        }

        return true
    }

    private func generateMoonCode() -> String {
        let number = Int.random(in: 1000...9999)
        return "MOON-\(number)"
    }

    private func show(message: String) {
        errorMessage = message
        showError = true
    }
}
