// File: CoupleSettingsView.swift

import SwiftUI
import UIKit

struct CoupleSettingsView: View {
    @EnvironmentObject var appState: MoonMailAppState

    let profile: MoonMailUserProfile

    @StateObject private var viewModel = CoupleSettingsViewModel()
    @State private var reunionDate = Date()
    @State private var hasLoadedInitialDate = false
    @State private var copiedCode = false

    private var currentInviteCode: String {
        viewModel.couple?.inviteCode.isEmpty == false
            ? (viewModel.couple?.inviteCode ?? "")
            : (profile.inviteCode ?? "No Code")
    }

    private var connectionText: String {
        viewModel.couple?.isConnected == true ? "Connected" : "Waiting for partner"
    }

    private var partnerOneName: String {
        let name = viewModel.couple?.partnerOneName ?? ""
        return name.isEmpty ? "Waiting..." : name
    }

    private var partnerTwoName: String {
        let name = viewModel.couple?.partnerTwoName ?? ""
        return name.isEmpty ? "Waiting..." : name
    }

    private var partnerName: String {
        viewModel.couple?.partnerName(for: profile.uid) ?? "Waiting for partner"
    }

    var body: some View {
        ZStack {
            DoodleBackground()

            ScrollView {
                VStack(spacing: 22) {
                    Text("Our Moon Room")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)
                        .padding(.top, 20)

                    moonCodeCard
                    partnerCard
                    reunionCard
                    accountCard
                    signOutButton
                }
                .padding(.bottom, 24)
            }
        }
        .task {
            viewModel.startListening(coupleId: profile.coupleId)
        }
        .onChange(of: viewModel.couple?.reunionDate) { _, newValue in
            guard let newValue else { return }
            guard !hasLoadedInitialDate else { return }
            reunionDate = newValue
            hasLoadedInitialDate = true
        }
        .alert("Moon Room", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Moon Room", isPresented: $viewModel.showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.successMessage)
        }
    }

    private var moonCodeCard: some View {
        CuteCard {
            VStack(spacing: 16) {
                Text("Moon Code")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Text(currentInviteCode)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(MoonMailTheme.softPurple)
                    .multilineTextAlignment(.center)

                Button {
                    UIPasteboard.general.string = currentInviteCode
                    copiedCode = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        copiedCode = false
                    }
                } label: {
                    HStack {
                        Text(copiedCode ? "Copied!" : "Copy Code")
                        Image(systemName: copiedCode ? "checkmark.circle.fill" : "doc.on.doc.fill")
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MoonMailTheme.blush)
                    .foregroundStyle(MoonMailTheme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
            }
        }
        .padding(.horizontal)
    }

    private var partnerCard: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Connected Hearts")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)

                    Spacer()

                    Text(connectionText)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.couple?.isConnected == true ? .green : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.75))
                        .clipShape(Capsule())
                }

                SettingRow(icon: "person.fill", title: "You", value: profile.displayName)
                SettingRow(icon: "heart.fill", title: "Partner", value: partnerName)
                SettingRow(icon: "person.2.fill", title: "Partner One", value: partnerOneName)
                SettingRow(icon: "person.2.circle.fill", title: "Partner Two", value: partnerTwoName)
            }
        }
        .padding(.horizontal)
    }

    private var reunionCard: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Next Moonrise")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)

                    Spacer()

                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        CuteSymbol(name: "calendar", size: 24)
                    }
                }

                DatePicker(
                    "Reunion Date",
                    selection: $reunionDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(MoonMailTheme.softPurple)

                Button {
                    Task {
                        await viewModel.saveReunionDate(reunionDate, coupleId: profile.coupleId)
                    }
                } label: {
                    HStack {
                        Text(viewModel.isSaving ? "Saving..." : "Save Reunion Date")
                        Image(systemName: "sparkles")
                    }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MoonMailTheme.softPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                .disabled(viewModel.isSaving)
            }
        }
        .padding(.horizontal)
    }

    private var accountCard: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 14) {
                SettingRow(icon: "person.fill", title: "Signed in as", value: profile.displayName)
                SettingRow(icon: "envelope.fill", title: "Email", value: profile.email)
                SettingRow(icon: "person.2.fill", title: "Moon Room", value: connectionText)
                SettingRow(icon: "moon.stars.fill", title: "Couple ID", value: profile.coupleId ?? "Not connected")
            }
        }
        .padding(.horizontal)
    }

    private var signOutButton: some View {
        Button {
            appState.signOut()
        } label: {
            Text("Sign Out")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.85))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding(.horizontal)
    }
}
