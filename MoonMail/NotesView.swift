import SwiftUI

struct NotesView: View {
    let profile: MoonMailUserProfile

    @StateObject private var viewModel = MoonNotesViewModel()
    @State private var noteText = ""

    var body: some View {
        ZStack {
            DoodleBackground()

            VStack(spacing: 20) {
                Text("Moon Notes")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)
                    .padding(.top, 20)

                CuteCard {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Write something sweet")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(MoonMailTheme.ink)

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

                if viewModel.notes.isEmpty {
                    EmptyNotesCard()
                        .padding(.horizontal)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
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
        }
        .task {
            viewModel.startListening(coupleId: profile.coupleId)
        }
        .alert("Moon Notes", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
