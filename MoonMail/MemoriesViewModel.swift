// File: MemoriesViewModel.swift

import Foundation
import Combine
import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class MemoriesViewModel: ObservableObject {
    @Published var memories: [MoonMemory] = []
    @Published var isUploading = false
    @Published var isDeleting = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var successMessage = ""
    @Published var showSuccess = false

    private let db = Firestore.firestore()
    private let storage: Storage
    private var listener: ListenerRegistration?
    private var activeCoupleId: String?

    init() {
        let bucket = FirebaseApp.app()?.options.storageBucket ?? ""

        if bucket.hasPrefix("gs://") {
            storage = Storage.storage(url: bucket)
        } else if !bucket.isEmpty {
            storage = Storage.storage(url: "gs://\(bucket)")
        } else {
            storage = Storage.storage()
        }
    }

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
            .collection("memories")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let error {
                        self.show(message: error.localizedDescription)
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        self.memories = []
                        return
                    }

                    self.memories = documents.map { document in
                        let data = document.data()
                        let timestamp = data["createdAt"] as? Timestamp

                        return MoonMemory(
                            id: document.documentID,
                            title: data["title"] as? String ?? "Moon Memory",
                            caption: data["caption"] as? String ?? "",
                            imageURL: data["imageURL"] as? String ?? "",
                            storagePath: data["storagePath"] as? String ?? "",
                            senderId: data["senderId"] as? String ?? "",
                            senderName: data["senderName"] as? String ?? "Unknown",
                            createdAt: timestamp?.dateValue() ?? Date()
                        )
                    }
                }
            }
    }

    func uploadMemory(
        title: String,
        caption: String,
        image: UIImage,
        profile: MoonMailUserProfile
    ) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            show(message: "Please add a title for your memory.")
            return
        }

        guard let coupleId = profile.coupleId else {
            show(message: "No Moon Room found for this account.")
            return
        }

        guard let imageData = image.jpegData(compressionQuality: 0.82) else {
            show(message: "Could not prepare the image for upload.")
            return
        }

        isUploading = true

        do {
            let memoryDocument = db.collection("couples")
                .document(coupleId)
                .collection("memories")
                .document()

            let storagePath = "couples/\(coupleId)/memories/\(memoryDocument.documentID).jpg"
            let storageRef = storage.reference(withPath: storagePath)

            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()

            try await memoryDocument.setData([
                "title": trimmedTitle,
                "caption": trimmedCaption,
                "imageURL": downloadURL.absoluteString,
                "storagePath": storagePath,
                "senderId": profile.uid,
                "senderName": profile.displayName,
                "createdAt": FieldValue.serverTimestamp()
            ])

            isUploading = false
            successMessage = "Memory saved!"
            showSuccess = true
        } catch {
            isUploading = false
            show(message: error.localizedDescription)
        }
    }

    func deleteMemory(_ memory: MoonMemory, profile: MoonMailUserProfile) async {
        guard let coupleId = profile.coupleId else {
            show(message: "No Moon Room found for this account.")
            return
        }

        guard memory.senderId == profile.uid else {
            show(message: "You can only delete memories you uploaded.")
            return
        }

        isDeleting = true

        do {
            if !memory.storagePath.isEmpty {
                let storageRef = storage.reference(withPath: memory.storagePath)
                try await storageRef.delete()
            } else if !memory.imageURL.isEmpty {
                let storageRef = storage.reference(forURL: memory.imageURL)
                try await storageRef.delete()
            }

            try await db.collection("couples")
                .document(coupleId)
                .collection("memories")
                .document(memory.id)
                .delete()

            isDeleting = false
            successMessage = "Memory deleted."
            showSuccess = true
        } catch {
            isDeleting = false
            show(message: error.localizedDescription)
        }
    }

    private func show(message: String) {
        errorMessage = message
        showError = true
    }
}
