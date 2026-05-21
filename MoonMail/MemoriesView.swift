// File: MemoriesView.swift

import SwiftUI
import PhotosUI

struct MemoriesView: View {
    let profile: MoonMailUserProfile

    @StateObject private var viewModel = MemoriesViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var title = ""
    @State private var caption = ""
    @State private var memoryToDelete: MoonMemory?

    var body: some View {
        ZStack {
            DoodleBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Moon Memories")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)
                        .padding(.top, 20)

                    uploadCard

                    if viewModel.memories.isEmpty {
                        emptyStateCard
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.memories) { memory in
                                MemoryCard(
                                    memory: memory,
                                    currentUserId: profile.uid,
                                    isDeleting: viewModel.isDeleting,
                                    onDelete: {
                                        memoryToDelete = memory
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .task {
            viewModel.startListening(coupleId: profile.coupleId)
        }
        .task(id: selectedPhotoItem) {
            await loadSelectedImage()
        }
        .alert("Moon Memories", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Moon Memories", isPresented: $viewModel.showSuccess) {
            Button("OK", role: .cancel) {
                clearDraft()
            }
        } message: {
            Text(viewModel.successMessage)
        }
        .alert("Delete Memory?", isPresented: deleteAlertBinding) {
            Button("Cancel", role: .cancel) {
                memoryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                guard let memoryToDelete else { return }

                Task {
                    await viewModel.deleteMemory(memoryToDelete, profile: profile)
                    self.memoryToDelete = nil
                }
            }
        } message: {
            Text("This will remove the photo and memory from your Moon Room.")
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { memoryToDelete != nil },
            set: { newValue in
                if !newValue {
                    memoryToDelete = nil
                }
            }
        )
    }

    private var uploadCard: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Save a Moon Memory")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)

                    Spacer()

                    if viewModel.isUploading {
                        ProgressView()
                    } else {
                        CuteSymbol(name: "photo.fill", size: 26)
                    }
                }

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(MoonMailTheme.softPurple)

                            Text("Choose a photo")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(MoonMailTheme.ink)

                            Text("Pick a sweet memory from your photo library.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .background(Color.white.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
                .buttonStyle(.plain)

                CuteTextField(title: "Memory title", text: $title, icon: "sparkles")

                TextField("Caption", text: $caption, axis: .vertical)
                    .padding()
                    .frame(minHeight: 100, alignment: .top)
                    .background(Color.white.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button {
                    Task {
                        guard let selectedImage else {
                            viewModel.errorMessage = "Please choose a photo first."
                            viewModel.showError = true
                            return
                        }

                        await viewModel.uploadMemory(
                            title: title,
                            caption: caption,
                            image: selectedImage,
                            profile: profile
                        )
                    }
                } label: {
                    HStack {
                        if viewModel.isUploading {
                            ProgressView()
                                .tint(.white)
                        }

                        Text(viewModel.isUploading ? "Uploading..." : "Save Memory")
                        Image(systemName: "moon.stars.fill")
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MoonMailTheme.softPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                .disabled(viewModel.isUploading)
            }
        }
        .padding(.horizontal)
    }

    private var emptyStateCard: some View {
        CuteCard {
            VStack(spacing: 12) {
                CuteSymbol(name: "photo.stack.fill", size: 48)

                Text("No Moon Memories yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Text("Upload your first favorite moment and it will appear here.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }

    private func loadSelectedImage() async {
        guard let selectedPhotoItem else { return }

        do {
            guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                viewModel.errorMessage = "Could not load the selected photo."
                viewModel.showError = true
                return
            }

            selectedImage = image
        } catch {
            viewModel.errorMessage = error.localizedDescription
            viewModel.showError = true
        }
    }

    private func clearDraft() {
        selectedPhotoItem = nil
        selectedImage = nil
        title = ""
        caption = ""
    }
}

struct MemoryCard: View {
    let memory: MoonMemory
    let currentUserId: String
    let isDeleting: Bool
    let onDelete: () -> Void

    private var isOwner: Bool {
        memory.senderId == currentUserId
    }

    var body: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 12) {
                AsyncImage(url: URL(string: memory.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.72))

                            ProgressView()
                        }
                        .frame(height: 220)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 24))

                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.72))

                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.secondary)

                                Text("Could not load image")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 220)

                    @unknown default:
                        EmptyView()
                    }
                }

                HStack(alignment: .top) {
                    Text(memory.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)

                    Spacer()

                    if isOwner {
                        Button(role: .destructive, action: onDelete) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.red)
                                .padding(10)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .disabled(isDeleting)
                    }
                }

                if !memory.caption.isEmpty {
                    Text(memory.caption)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(isOwner ? "Saved by me" : "Saved by \(memory.senderName)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.softPurple)

                    Spacer()

                    Text(memoryDateString(memory.createdAt))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func memoryDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
