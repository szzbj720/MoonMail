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
        ZStack {
            DoodleBackground()

            ScrollView {
                VStack(spacing: 22) {
                    header
                    TogetherSinceCard(
                        currentUserName: profile.displayName,
                        partnerName: partnerName,
                        relationshipStartDate: coupleViewModel.couple?.relationshipStartDate
                    )
                    NextMoonriseCard(reunionDate: coupleViewModel.couple?.reunionDate)
                    MoonMoodCard(profile: profile, moods: moods, viewModel: moodViewModel)
                    MoonSignalsGrid(profile: profile, viewModel: signalsViewModel)
                    RecentMoonSignalsCard(profile: profile, viewModel: signalsViewModel)
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
        .alert("Moon Signals Error", isPresented: $signalsViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(signalsViewModel.errorMessage)
        }
        .alert("Moon Signals", isPresented: $signalsViewModel.showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(signalsViewModel.successMessage)
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
}

struct TogetherSinceCard: View {
    let currentUserName: String
    let partnerName: String
    let relationshipStartDate: Date?

    private var daysTogether: Int? {
        guard let relationshipStartDate else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: relationshipStartDate)
        let end = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: start, to: end).day.map { max($0 + 1, 1) }
    }

    private var officialDateText: String {
        guard let relationshipStartDate else {
            return "Set your official date in the Us tab"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return "Official since \(formatter.string(from: relationshipStartDate))"
    }

    private var countText: String {
        guard let daysTogether else {
            return "—"
        }
        return "\(daysTogether)"
    }

    private var subtitleText: String {
        guard let daysTogether else {
            return "days together"
        }
        return daysTogether == 1 ? "day together" : "days together"
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

                    PartnerBubble(icon: "person.crop.circle.fill.badge.heart", name: partnerName)
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
        guard let reunionDate else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: reunionDate)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    private var reunionDateText: String {
        guard let reunionDate else {
            return "Set your reunion date in the Us tab"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: reunionDate)
    }

    private var countdownText: String {
        guard let countdownDays else {
            return "—"
        }
        return "\(max(countdownDays, 0))"
    }

    private var subtitleText: String {
        guard let countdownDays else {
            return "days until we meet again"
        }

        if countdownDays <= 0 {
            return "your moonrise is here"
        }

        return countdownDays == 1 ? "day until we meet again" : "days until we meet again"
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
                    ProgressView(value: progressValue(until: reunionDate))
                        .tint(MoonMailTheme.blush)
                        .scaleEffect(x: 1, y: 1.5)
                }
            }
        }
    }

    private func progressValue(until reunionDate: Date?) -> Double {
        guard
            let reunionDate,
            let days = countdownDays,
            days > 0
        else {
            return 0
        }

        let totalWindow = max(days + 30, 1)
        let elapsed = totalWindow - days
        return min(max(Double(elapsed) / Double(totalWindow), 0), 1)
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

                    CuteSymbol(name: "sparkles", size: 26)
                }

                if viewModel.signals.isEmpty {
                    Text("No Moon Signals yet. Send one to make your partner smile.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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

private func moonSignalRelativeTime(from date: Date) -> String {
    let seconds = Int(Date().timeIntervalSince(date))

    if seconds < 10 {
        return "just now"
    }

    if seconds < 60 {
        return "\(seconds)s ago"
    }

    let minutes = seconds / 60
    if minutes < 60 {
        return "\(minutes)m ago"
    }

    let hours = minutes / 60
    if hours < 24 {
        return "\(hours)h ago"
    }

    let days = hours / 24
    if days < 7 {
        return "\(days)d ago"
    }

    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
}
