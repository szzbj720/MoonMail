// File: CoupleSettingsView.swift

import SwiftUI
import UIKit

struct CoupleSettingsView: View {
    @EnvironmentObject var appState: MoonMailAppState

    let profile: MoonMailUserProfile

    @StateObject private var viewModel = CoupleSettingsViewModel()
    @State private var reunionDate = Date()
    @State private var relationshipStartDate = Date()
    @State private var hasLoadedInitialReunionDate = false
    @State private var hasLoadedInitialRelationshipDate = false
    @State private var copiedCode = false
    @State private var expandedSection: ExpandedDateSection?

    private enum ExpandedDateSection {
        case relationship
        case reunion
    }

    private var currentInviteCode: String {
        if let inviteCode = viewModel.couple?.inviteCode, !inviteCode.isEmpty {
            return inviteCode
        }
        return profile.inviteCode ?? "No Code"
    }

    private var connectionText: String {
        viewModel.couple?.isConnected == true ? "Connected" : "Waiting for partner"
    }

    private var partnerName: String {
        viewModel.couple?.partnerName(for: profile.uid) ?? "Waiting for partner"
    }

    private var officialDateText: String {
        formattedDate(viewModel.couple?.relationshipStartDate, emptyText: "Not set")
    }

    private var reunionDateText: String {
        formattedDate(viewModel.couple?.reunionDate, emptyText: "Not set")
    }

    var body: some View {
        ZStack(alignment: .top) {
            DoodleBackground()

            ScrollView {
                VStack(spacing: 22) {
                    Text("Our Moon Room")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)
                        .padding(.top, 20)

                    statusBanner
                    moonCodeCard
                    contentSection
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
            guard !hasLoadedInitialReunionDate else { return }
            reunionDate = newValue
            hasLoadedInitialReunionDate = true
        }
        .onChange(of: viewModel.couple?.relationshipStartDate) { _, newValue in
            guard let newValue else { return }
            guard !hasLoadedInitialRelationshipDate else { return }
            relationshipStartDate = newValue
            hasLoadedInitialRelationshipDate = true
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

    private var contentSection: some View {
        Group {
            if viewModel.isLoading && viewModel.couple == nil {
                loadingStateCard
                    .padding(.horizontal)
            } else if viewModel.couple == nil {
                unavailableStateCard
                    .padding(.horizontal)
            } else {
                VStack(spacing: 22) {
                    partnerCard
                    relationshipCard
                    reunionCard
                    accountCard
                }
            }
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

    private var loadingStateCard: some View {
        CuteCard {
            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.2)

                Text("Loading your Moon Room...")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Text("Your shared details will appear here in just a second.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    private var unavailableStateCard: some View {
        CuteCard {
            VStack(spacing: 12) {
                CuteSymbol(name: "moon.zzz.fill", size: 44)

                Text("Moon Room unavailable")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Text("We couldn't load your shared room details right now.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.retryLoading(coupleId: profile.coupleId)
                } label: {
                    HStack {
                        Text("Try Again")
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
            }
        }
        .padding(.horizontal)
    }

    private var relationshipCard: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Together Since")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)

                    Spacer()

                    if viewModel.isSaving && expandedSection == .relationship {
                        ProgressView()
                    } else {
                        CuteSymbol(name: "heart.fill", size: 24, color: MoonMailTheme.blush)
                    }
                }

                dateSummaryRow(
                    icon: "heart.circle.fill",
                    title: "Official Date",
                    value: officialDateText,
                    isExpanded: expandedSection == .relationship
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedSection = expandedSection == .relationship ? nil : .relationship
                    }
                }

                if expandedSection == .relationship {
                    VStack(spacing: 14) {
                        DatePicker(
                            "Official Date",
                            selection: $relationshipStartDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(MoonMailTheme.softPurple)

                        Button {
                            Task {
                                await viewModel.saveRelationshipStartDate(
                                    relationshipStartDate,
                                    coupleId: profile.coupleId
                                )
                                if !viewModel.showError {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedSection = nil
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.isSaving ? "Saving..." : "Save Official Date")
                                Image(systemName: "heart.circle.fill")
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
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
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

                    if viewModel.isSaving && expandedSection == .reunion {
                        ProgressView()
                    } else {
                        CuteSymbol(name: "calendar", size: 24)
                    }
                }

                dateSummaryRow(
                    icon: "calendar",
                    title: "Reunion Date",
                    value: reunionDateText,
                    isExpanded: expandedSection == .reunion
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedSection = expandedSection == .reunion ? nil : .reunion
                    }
                }

                if expandedSection == .reunion {
                    VStack(spacing: 14) {
                        DatePicker(
                            "Reunion Date",
                            selection: $reunionDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(MoonMailTheme.softPurple)

                        Button {
                            Task {
                                await viewModel.saveReunionDate(reunionDate, coupleId: profile.coupleId)
                                if !viewModel.showError {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedSection = nil
                                    }
                                }
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
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(.horizontal)
    }

    private var accountCard: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 14) {
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

    private func dateSummaryRow(
        icon: String,
        title: String,
        value: String,
        isExpanded: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MoonMailTheme.softPurple)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)

                    Text(value)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MoonMailTheme.softPurple)
            }
            .padding()
            .background(Color.white.opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func formattedDate(_ date: Date?, emptyText: String) -> String {
        guard let date else {
            return emptyText
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
