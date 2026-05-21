// File: NotesView.swift

import SwiftUI

struct NotesView: View {
    let profile: MoonMailUserProfile

    @StateObject private var viewModel = MoonNotesViewModel()
    @State private var noteText = ""

    var body: some View {
        ZStack(alignment: .top) {
            DoodleBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Moon Notes")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)
                        .padding(.top, 20)

                    statusBanner

                    CuteCard {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Write something sweet")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(MoonMailTheme.ink)

                                Spacer()

                                if viewModel.isSending {
                                    ProgressView()
                                } else {
                                    CuteSymbol(name: "envelope.fill", size: 24)
                                }
                            }

                            TextField("Dear moon...", text: $noteText, axis: .vertical)
                                .padding()
                                .frame(minHeight: 110, alignment: .top)
                                .background(Color.white.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 20))

                            Button {
                                Task {
                                    let sent = await viewModel.sendNote(text: noteText, profile: profile)
                                    if sent {
                                        noteText = ""
                                    }
                                }
                            } label: {
                                HStack {
                                    if viewModel.isSending {
                                        ProgressView()
                                            .tint(.white)
                                    }

                                    Text(viewModel.isSending ? "Sending..." : "Send Moon Note")
                                    Image(systemName: "paperplane.fill")
                                }
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(MoonMailTheme.softPurple)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                            }
                            .disabled(viewModel.isSending)
                        }
                    }
                    .padding(.horizontal)

                    contentSection
                }
                .padding(.bottom, 24)
            }
        }
        .task {
            viewModel.startListening(coupleId: profile.coupleId)
        }
    }

    private var contentSection: some View {
        Group {
            if viewModel.isInitialLoading && viewModel.notes.isEmpty {
                loadingStateCard
                    .padding(.horizontal)
            } else if viewModel.notes.isEmpty {
                emptyStateCard
                    .padding(.horizontal)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.notes) { note in
                        NoteRow(
                            note: note,
                            isMe: note.senderId == profile.uid
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }

    private var statusBanner: some View {
        Group {
            if viewModel.showError {
                InlineStatusBanner(
                    icon: "exclamationmark.triangle.fill",
                    message: viewModel.errorMessage,
                    isError: true,
                    dismiss: viewModel.dismissMessages
                )
                .padding(.horizontal)
            } else if viewModel.showSuccess {
                InlineStatusBanner(
                    icon: "checkmark.circle.fill",
                    message: viewModel.successMessage,
                    isError: false,
                    dismiss: viewModel.dismissMessages
                )
                .padding(.horizontal)
            }
        }
    }

    private var loadingStateCard: some View {
        CuteCard {
            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.2)

                Text("Loading your Moon Notes...")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Text("Your shared notes will appear here in just a second.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    private var emptyStateCard: some View {
        CuteCard {
            VStack(spacing: 12) {
                CuteSymbol(name: "envelope.open.fill", size: 42)

                Text("No Moon Notes yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Text("Send your first sweet note and it will appear here for both of you.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.retryLoading(coupleId: profile.coupleId)
                } label: {
                    HStack {
                        Text("Refresh")
                        Image(systemName: "arrow.clockwise")
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.85))
                    .foregroundStyle(MoonMailTheme.ink)
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
