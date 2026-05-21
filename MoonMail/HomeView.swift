// File: HomeView.swift

import SwiftUI

struct HomeView: View {
    let profile: MoonMailUserProfile

    @StateObject private var moodViewModel = MoonMoodViewModel()
    @StateObject private var signalsViewModel = MoonSignalsViewModel()
    @StateObject private var coupleViewModel = CoupleSettingsViewModel()

    let moods = [
        MoodOption(title: "Loved", icon: "heart.fill"),
        MoodOption(title: "Missing", icon: "face.smiling.inverse"),
        MoodOption(title: "Dreamy", icon: "moon.stars.fill"),
        MoodOption(title: "Soft", icon: "cloud.fill"),
        MoodOption(title: "Excited", icon: "sparkles")
    ]

    private var partnerName: String {
        coupleViewModel.couple?.partnerName(for: profile.uid) ?? "Partner"
    }

    var body: some View {
        ZStack(alignment: .top) {
            DoodleBackground()

            ScrollView {
                VStack(spacing: 22) {
                    header
                    signalsStatusBanner
                    TogetherSinceCard(
                        currentUserName: profile.displayName,
                        partnerName: partnerName,
                        relationshipStartDate: coupleViewModel.couple?.relationshipStartDate
                    )
                    NextMoonriseCard(reunionDate: coupleViewModel.couple?.reunionDate)
                    MoonMoodCard(profile: profile, moods: moods, viewModel: moodViewModel)
                    MoonSignalsGrid(profile: profile, viewModel: signalsViewModel)
                    signalsContentSection
                    LatestMoonNoteCard()
                }
                .padding()
            }
        }
        .task {
            moodViewModel.startListening(coupleId: profile.coupleId)
            signalsViewModel.startListening(coupleId: profile.coupleId)
            coupleViewModel.startListening(coupleId: profile.coupleId)
        }
        .alert("Moon Mood", isPresented: $moodViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(moodViewModel.errorMessage)
        }
        .alert("Moon Room", isPresented: $coupleViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(coupleViewModel.errorMessage)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("MoonMail")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(MoonMailTheme.ink)

            Text("\(profile.displayName)  ♡  \(partnerName)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(MoonMailTheme.softPurple)

            Text("connected under the same moon")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 15)
    }

    private var signalsStatusBanner: some View {
        Group {
            if signalsViewModel.showError {
                InlineStatusBanner(
                    icon: "exclamationmark.triangle.fill",
                    message: signalsViewModel.errorMessage,
                    isError: true,
                    dismiss: signalsViewModel.dismissMessages
                )
            } else if signalsViewModel.showSuccess {
                InlineStatusBanner(
                    icon: "checkmark.circle.fill",
                    message: signalsViewModel.successMessage,
                    isError: false,
                    dismiss: signalsViewModel.dismissMessages
                )
            }
        }
    }

    private var signalsContentSection: some View {
        Group {
            if signalsViewModel.isInitialLoading && signalsViewModel.signals.isEmpty {
                signalsLoadingCard
            } else {
                RecentMoonSignalsCard(profile: profile, viewModel: signalsViewModel)
            }
        }
    }

    private var signalsLoadingCard: some View {
        CuteCard {
            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.2)

                Text("Loading recent signals...")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Text("Your latest little moments will appear here in just a second.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
}

struct TogetherSinceCard: View {
    let currentUserName: String
    let partnerName: String
    let relationshipStartDate: Date?

    private var daysTogether: Int? {
        MoonDateLogic.daysTogether(since: relationshipStartDate)
    }

    private var officialDateText: String {
        MoonDateLogic.officialDateText(for: relationshipStartDate)
    }

    private var countText: String {
        guard let daysTogether else {
            return "—"
        }
        return "\(daysTogether)"
    }

    private var subtitleText: String {
        MoonDateLogic.togetherSubtitle(for: daysTogether)
    }

    var body: some View {
        CuteCard {
            VStack(spacing: 16) {
                HStack {
                    PartnerBubble(icon: "person.crop.circle.fill", name: currentUserName)

                    Spacer()

                    VStack(spacing: 6) {
                        CuteSymbol(name: "heart.fill", size: 28, color: MoonMailTheme.blush)

                        RoundedRectangle(cornerRadius: 10)
                            .fill(MoonMailTheme.softPurple.opacity(0.45))
                            .frame(width: 110, height: 8)

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                            Image(systemName: "star.fill")
                            Image(systemName: "star.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(MoonMailTheme.softPurple.opacity(0.8))
                    }

                    Spacer()

                    PartnerBubble(icon: "person.crop.circle.fill", name: partnerName)
                }

                Text(countText)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(MoonMailTheme.softPurple)

                Text(subtitleText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Text(officialDateText)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct NextMoonriseCard: View {
    let reunionDate: Date?

    private var countdownDays: Int? {
        MoonDateLogic.reunionCountdownDays(until: reunionDate)
    }

    private var reunionDateText: String {
        MoonDateLogic.reunionDateText(for: reunionDate)
    }

    private var countdownText: String {
        guard let countdownDays else {
            return "—"
        }
        return "\(max(countdownDays, 0))"
    }

    private var subtitleText: String {
        MoonDateLogic.reunionSubtitle(for: countdownDays)
    }

    var body: some View {
        CuteCard {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Next Moonrise")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(MoonMailTheme.ink)

                        Text(reunionDateText)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    CuteSymbol(name: "airplane.departure", size: 36)
                }

                Text(countdownText)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(MoonMailTheme.softPurple)

                Text(subtitleText)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                if let countdownDays, countdownDays > 0 {
                    ProgressView(value: MoonDateLogic.reunionProgress(until: reunionDate))
                        .tint(MoonMailTheme.blush)
                        .scaleEffect(x: 1, y: 1.5)
                }
            }
        }
    }
}

struct MoonMoodCard: View {
    let profile: MoonMailUserProfile
    let moods: [MoodOption]
    @ObservedObject var viewModel: MoonMoodViewModel

    private var myMood: MoonMoodStatus? {
        viewModel.moodForUser(profile.uid)
    }

    private var partnerMood: MoonMoodStatus? {
        viewModel.partnerMood(currentUserId: profile.uid)
    }

    var body: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Moon Mood")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)

                    Spacer()

                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        CuteSymbol(name: "moon.stars.fill", size: 28)
                    }
                }

                HStack {
                    ForEach(moods, id: \.self) { mood in
                        Button {
                            Task {
                                await viewModel.updateMood(mood: mood, profile: profile)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: mood.icon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(MoonMailTheme.softPurple)

                                Text(mood.title)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(MoonMailTheme.ink)
                            }
                            .frame(width: 58, height: 58)
                            .background(myMood?.moodTitle == mood.title ? MoonMailTheme.lavender : Color.white.opacity(0.82))
                            .clipShape(Circle())
                        }
                        .disabled(viewModel.isSaving)
                    }
                }

                VStack(spacing: 10) {
                    MoodStatusRow(
                        title: "Me",
                        moodTitle: myMood?.moodTitle ?? "Not set",
                        moodIcon: myMood?.moodIcon ?? "moon.stars.fill"
                    )

                    MoodStatusRow(
                        title: partnerMood?.userName ?? "Partner",
                        moodTitle: partnerMood?.moodTitle ?? "Not set",
                        moodIcon: partnerMood?.moodIcon ?? "moon.stars.fill"
                    )
                }
            }
        }
    }
}

struct MoonSignalsGrid: View {
    let profile: MoonMailUserProfile
    @ObservedObject var viewModel: MoonSignalsViewModel

    let actions = [
        MoonSignal(title: "Moon Hug", icon: "hands.sparkles.fill"),
        MoonSignal(title: "Leave Star", icon: "star.fill"),
        MoonSignal(title: "Dream of Me", icon: "cloud.moon.fill"),
        MoonSignal(title: "Moon Kiss", icon: "heart.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Moon Signals")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Spacer()

                if viewModel.isSending {
                    ProgressView()
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(actions, id: \.self) { action in
                    Button {
                        Task {
                            await viewModel.sendSignal(action, profile: profile)
                        }
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: action.icon)
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(MoonMailTheme.softPurple)

                            Text(action.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(MoonMailTheme.ink)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .overlay {
                            RoundedRectangle(cornerRadius: 26)
                                .stroke(MoonMailTheme.softPurple.opacity(0.35), lineWidth: 2)
                        }
                    }
                    .disabled(viewModel.isSending)
                }
            }
        }
    }
}

struct RecentMoonSignalsCard: View {
    let profile: MoonMailUserProfile
    @ObservedObject var viewModel: MoonSignalsViewModel

    var body: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Recent Signals")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)

                    Spacer()

                    HStack(spacing: 8) {
                        if viewModel.isInitialLoading && viewModel.signals.isEmpty {
                            ProgressView()
                                .scaleEffect(0.9)
                        } else {
                            CuteSymbol(name: "sparkles", size: 26)
                        }

                        if viewModel.signals.isEmpty {
                            Button {
                                viewModel.retryLoading(coupleId: profile.coupleId)
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(MoonMailTheme.softPurple)
                                    .padding(8)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if viewModel.signals.isEmpty {
                    VStack(spacing: 12) {
                        Text("No Moon Signals yet")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(MoonMailTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Send a little signal above to make your partner smile.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.white.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.signals.prefix(4)) { signal in
                            SignalRow(
                                signal: signal,
                                isMe: signal.senderId == profile.uid
                            )
                        }
                    }
                }
            }
        }
    }
}

struct LatestMoonNoteCard: View {
    var body: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Latest Moon Note")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)

                    Spacer()

                    CuteSymbol(name: "envelope.fill", size: 28)
                }

                Text("Your newest Moon Note will appear in the Notes tab.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)
                    .padding()
                    .background(MoonMailTheme.cloud.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
            }
        }
    }
}
