import SwiftUI
import UIKit

struct CuteSymbol: View {
    let name: String
    let size: CGFloat
    var color: Color = MoonMailTheme.softPurple

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
            .symbolRenderingMode(.hierarchical)
    }
}

struct CuteCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(MoonMailTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(MoonMailTheme.softPurple.opacity(0.35), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct DoodleBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    MoonMailTheme.moonCream,
                    MoonMailTheme.blush,
                    MoonMailTheme.lavender
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    CuteSymbol(name: "cloud.fill", size: 34, color: .white.opacity(0.75))
                    Spacer()
                    CuteSymbol(name: "moon.stars.fill", size: 36)
                    Spacer()
                    CuteSymbol(name: "star.fill", size: 28, color: MoonMailTheme.moonCream)
                }
                .opacity(0.5)
                .padding(.horizontal, 35)
                .padding(.top, 55)

                Spacer()

                HStack {
                    CuteSymbol(name: "envelope.fill", size: 30)
                    Spacer()
                    CuteSymbol(name: "sparkles", size: 32)
                    Spacer()
                    CuteSymbol(name: "cloud.moon.fill", size: 34, color: .white.opacity(0.75))
                }
                .opacity(0.38)
                .padding(.horizontal, 35)

                Spacer()

                HStack {
                    CuteSymbol(name: "star.circle.fill", size: 30)
                    Spacer()
                    CuteSymbol(name: "moon.fill", size: 34)
                    Spacer()
                    CuteSymbol(name: "heart.fill", size: 28, color: MoonMailTheme.blush)
                }
                .opacity(0.38)
                .padding(.horizontal, 35)
                .padding(.bottom, 70)
            }
        }
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.3)

                Text("Loading MoonMail...")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)
            }
            .padding(24)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

struct CuteTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(MoonMailTheme.softPurple)
                .frame(width: 24)

            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct CuteSecureField: View {
    let title: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(MoonMailTheme.softPurple)
                .frame(width: 24)

            SecureField(title, text: $text)
        }
        .padding()
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct MoonButton: View {
    let title: String
    let icon: String
    let background: Color
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Image(systemName: icon)
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding()
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }
}

struct AuthNavButton: View {
    let title: String
    let icon: String
    let background: Color
    let foreground: Color

    var body: some View {
        HStack {
            Text(title)
            Image(systemName: icon)
        }
        .font(.system(size: 17, weight: .bold, design: .rounded))
        .frame(maxWidth: .infinity)
        .padding()
        .background(background)
        .foregroundStyle(foreground)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

struct AuthHeaderView: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 14) {
            CuteSymbol(name: icon, size: 76)

            Text(title)
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(MoonMailTheme.ink)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 35)
    }
}

struct PartnerBubble: View {
    let icon: String
    let name: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(MoonMailTheme.softPurple)
                .frame(width: 78, height: 78)
                .background(MoonMailTheme.cloud)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(MoonMailTheme.softPurple.opacity(0.35), lineWidth: 2)
                }

            Text(name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(MoonMailTheme.ink)
                .lineLimit(1)
        }
    }
}

struct MoodStatusRow: View {
    let title: String
    let moodTitle: String
    let moodIcon: String

    var body: some View {
        HStack {
            Image(systemName: moodIcon)
                .foregroundStyle(MoonMailTheme.softPurple)
                .frame(width: 26)

            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MoonMailTheme.ink)

            Spacer()

            Text(moodTitle)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct SignalRow: View {
    let signal: MoonSignalStatus
    let isMe: Bool

    var body: some View {
        HStack {
            Image(systemName: signal.icon)
                .foregroundStyle(MoonMailTheme.softPurple)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(signal.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Text(isMe ? "Sent by me" : "Sent by \(signal.senderName)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(shortTime(signal.createdAt))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(isMe ? MoonMailTheme.blush.opacity(0.55) : Color.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

struct EmptyNotesCard: View {
    var body: some View {
        CuteCard {
            VStack(spacing: 12) {
                CuteSymbol(name: "envelope.open.fill", size: 42)

                Text("No Moon Notes yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)

                Text("Send the first sweet note and it will appear here.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct NoteRow: View {
    let note: MoonNote
    let isMe: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(isMe ? "Me" : note.senderName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.softPurple)

                Spacer()

                Text(formattedDate(note.createdAt))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Text(note.text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(MoonMailTheme.ink)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isMe ? MoonMailTheme.blush.opacity(0.65) : Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(isMe ? MoonMailTheme.softPurple.opacity(0.25) : Color.white.opacity(0.4), lineWidth: 1.5)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MemoryTile: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(MoonMailTheme.softPurple)

            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MoonMailTheme.ink)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Color.white.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(MoonMailTheme.softPurple.opacity(0.35), lineWidth: 2)
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(MoonMailTheme.softPurple)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MoonMailTheme.ink)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding()
        .background(Color.white.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
