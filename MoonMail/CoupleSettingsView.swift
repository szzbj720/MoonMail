import SwiftUI
import UIKit

struct CoupleSettingsView: View {
    @EnvironmentObject var appState: MoonMailAppState
    let profile: MoonMailUserProfile

    var body: some View {
        ZStack {
            DoodleBackground()

            VStack(spacing: 22) {
                Text("Our Moon Room")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)
                    .padding(.top, 20)

                CuteCard {
                    VStack(spacing: 16) {
                        Text("Moon Code")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(MoonMailTheme.ink)

                        Text(profile.inviteCode ?? "No Code")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(MoonMailTheme.softPurple)

                        Button {
                            UIPasteboard.general.string = profile.inviteCode ?? ""
                        } label: {
                            HStack {
                                Text("Copy Code")
                                Image(systemName: "doc.on.doc.fill")
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

                CuteCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SettingRow(icon: "person.fill", title: "Signed in as", value: profile.displayName)
                        SettingRow(icon: "envelope.fill", title: "Email", value: profile.email)
                        SettingRow(icon: "person.2.fill", title: "Moon Room", value: profile.coupleId == nil ? "Not connected" : "Connected")
                        SettingRow(icon: "calendar", title: "Next Moonrise", value: "June 18")
                        SettingRow(icon: "bell.fill", title: "Notifications", value: "On")
                    }
                }
                .padding(.horizontal)

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

                Spacer()
            }
        }
    }
}
