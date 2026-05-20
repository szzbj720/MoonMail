import SwiftUI

struct AuthRootView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                DoodleBackground()

                ScrollView {
                    VStack(spacing: 26) {
                        VStack(spacing: 12) {
                            CuteSymbol(name: "moon.stars.fill", size: 82)

                            Text("MoonMail")
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundStyle(MoonMailTheme.ink)

                            Text("A private moon room for two hearts, no matter how far apart.")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 55)

                        CuteCard {
                            VStack(spacing: 16) {
                                Text("Welcome to your moon room")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(MoonMailTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Create a new Moon Room, join your partner’s room, or log back into an existing account.")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                NavigationLink(value: AuthRoute.create) {
                                    AuthNavButton(title: "Create Moon Room", icon: "envelope.fill", background: MoonMailTheme.softPurple, foreground: .white)
                                }

                                NavigationLink(value: AuthRoute.join) {
                                    AuthNavButton(title: "Join with Moon Code", icon: "moon.stars.fill", background: MoonMailTheme.blush, foreground: MoonMailTheme.ink)
                                }

                                NavigationLink(value: AuthRoute.login) {
                                    AuthNavButton(title: "Log In", icon: "person.crop.circle.fill", background: Color.white.opacity(0.85), foreground: MoonMailTheme.ink)
                                }
                            }
                        }
                        .padding(.horizontal)

                        Text("The first partner creates the room and receives a Moon Code. The second partner joins using that code.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .create:
                    CreateMoonRoomView()
                case .join:
                    JoinMoonRoomView()
                case .login:
                    LoginView()
                }
            }
        }
    }
}

struct CreateMoonRoomView: View {
    @EnvironmentObject var appState: MoonMailAppState

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            DoodleBackground()

            ScrollView {
                VStack(spacing: 24) {
                    AuthHeaderView(
                        title: "Create Moon Room",
                        subtitle: "Start a private space and share your Moon Code with your partner.",
                        icon: "moon.stars.fill"
                    )

                    CuteCard {
                        VStack(spacing: 18) {
                            CuteTextField(title: "Display name", text: $displayName, icon: "person.fill")
                            CuteTextField(title: "Email", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                            CuteSecureField(title: "Password", text: $password, icon: "lock.fill")

                            MoonButton(
                                title: "Create Moon Room",
                                icon: "envelope.fill",
                                background: MoonMailTheme.softPurple,
                                foreground: .white
                            ) {
                                Task {
                                    await appState.createMoonRoom(
                                        displayName: displayName,
                                        email: email,
                                        password: password
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Text("After creating your room, your Moon Code will appear in the Us tab.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct JoinMoonRoomView: View {
    @EnvironmentObject var appState: MoonMailAppState

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var inviteCode = ""

    var body: some View {
        ZStack {
            DoodleBackground()

            ScrollView {
                VStack(spacing: 24) {
                    AuthHeaderView(
                        title: "Join MoonMail",
                        subtitle: "Create your account and enter the Moon Code your partner sent you.",
                        icon: "moon.stars.fill"
                    )

                    CuteCard {
                        VStack(spacing: 18) {
                            CuteTextField(title: "Display name", text: $displayName, icon: "person.fill")
                            CuteTextField(title: "Email", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                            CuteSecureField(title: "Password", text: $password, icon: "lock.fill")

                            TextField("MOON-XXXX", text: $inviteCode)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 20))

                            MoonButton(
                                title: "Join Moon Room",
                                icon: "moon.stars.fill",
                                background: MoonMailTheme.softPurple,
                                foreground: .white
                            ) {
                                Task {
                                    await appState.joinMoonRoom(
                                        displayName: displayName,
                                        email: email,
                                        password: password,
                                        inviteCode: inviteCode
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Text("This is for the second partner. Ask your partner for the Moon Code shown in their Moon Room settings.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LoginView: View {
    @EnvironmentObject var appState: MoonMailAppState

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            DoodleBackground()

            ScrollView {
                VStack(spacing: 24) {
                    AuthHeaderView(
                        title: "Log In",
                        subtitle: "Welcome back. Enter your email and password to return to your Moon Room.",
                        icon: "person.crop.circle.fill"
                    )

                    CuteCard {
                        VStack(spacing: 18) {
                            CuteTextField(title: "Email", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                            CuteSecureField(title: "Password", text: $password, icon: "lock.fill")

                            MoonButton(
                                title: "Log In",
                                icon: "person.crop.circle.fill",
                                background: MoonMailTheme.softPurple,
                                foreground: .white
                            ) {
                                Task {
                                    await appState.signIn(email: email, password: password)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
