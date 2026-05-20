import SwiftUI
import UIKit
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - App State

struct MoonMailUserProfile {
    let uid: String
    let displayName: String
    let email: String
    let coupleId: String?
    let inviteCode: String?
}

struct MoonNote: Identifiable, Hashable {
    let id: String
    let text: String
    let senderId: String
    let senderName: String
    let createdAt: Date
}

@MainActor
final class MoonMailAppState: ObservableObject {
    @Published var currentUser: MoonMailUserProfile?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let db = Firestore.firestore()
    
    init() {
        listenForAuthChanges()
    }
    
    private func listenForAuthChanges() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            
            Task {
                if let user {
                    await self.loadUserProfile(uid: user.uid)
                } else {
                    self.currentUser = nil
                }
            }
        }
    }
    
    func createMoonRoom(displayName: String, email: String, password: String) async {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard validateAccount(displayName: trimmedName, email: trimmedEmail, password: trimmedPassword) else {
            return
        }
        
        isLoading = true
        
        do {
            let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPassword)
            let uid = result.user.uid
            let coupleId = UUID().uuidString
            let inviteCode = generateMoonCode()
            
            try await db.collection("couples").document(coupleId).setData([
                "coupleId": coupleId,
                "inviteCode": inviteCode,
                "partnerOneId": uid,
                "partnerOneName": trimmedName,
                "partnerTwoId": "",
                "partnerTwoName": "",
                "reunionDate": "",
                "createdAt": FieldValue.serverTimestamp()
            ])
            
            try await db.collection("users").document(uid).setData([
                "uid": uid,
                "displayName": trimmedName,
                "email": trimmedEmail,
                "coupleId": coupleId,
                "inviteCode": inviteCode,
                "createdAt": FieldValue.serverTimestamp()
            ])
            
            currentUser = MoonMailUserProfile(
                uid: uid,
                displayName: trimmedName,
                email: trimmedEmail,
                coupleId: coupleId,
                inviteCode: inviteCode
            )
            
            isLoading = false
        } catch {
            isLoading = false
            show(message: error.localizedDescription)
        }
    }
    
    func joinMoonRoom(displayName: String, email: String, password: String, inviteCode: String) async {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard validateAccount(displayName: trimmedName, email: trimmedEmail, password: trimmedPassword) else {
            return
        }
        
        guard trimmedCode.hasPrefix("MOON-") && trimmedCode.count == 9 else {
            show(message: "Please enter a valid moon code like MOON-4829.")
            return
        }
        
        isLoading = true
        
        do {
            let snapshot = try await db.collection("couples")
                .whereField("inviteCode", isEqualTo: trimmedCode)
                .limit(to: 1)
                .getDocuments()
            
            guard let coupleDocument = snapshot.documents.first else {
                isLoading = false
                show(message: "No Moon Room found with that code.")
                return
            }
            
            let coupleId = coupleDocument.documentID
            let data = coupleDocument.data()
            let partnerTwoId = data["partnerTwoId"] as? String ?? ""
            
            guard partnerTwoId.isEmpty else {
                isLoading = false
                show(message: "This Moon Room already has two people connected.")
                return
            }
            
            let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPassword)
            let uid = result.user.uid
            
            try await db.collection("couples").document(coupleId).updateData([
                "partnerTwoId": uid,
                "partnerTwoName": trimmedName
            ])
            
            try await db.collection("users").document(uid).setData([
                "uid": uid,
                "displayName": trimmedName,
                "email": trimmedEmail,
                "coupleId": coupleId,
                "inviteCode": trimmedCode,
                "createdAt": FieldValue.serverTimestamp()
            ])
            
            currentUser = MoonMailUserProfile(
                uid: uid,
                displayName: trimmedName,
                email: trimmedEmail,
                coupleId: coupleId,
                inviteCode: trimmedCode
            )
            
            isLoading = false
        } catch {
            isLoading = false
            show(message: error.localizedDescription)
        }
    }
    
    func signIn(email: String, password: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            show(message: "Please enter your email and password.")
            return
        }
        
        isLoading = true
        
        do {
            let result = try await Auth.auth().signIn(withEmail: trimmedEmail, password: trimmedPassword)
            await loadUserProfile(uid: result.user.uid)
            isLoading = false
        } catch {
            isLoading = false
            show(message: error.localizedDescription)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            show(message: error.localizedDescription)
        }
    }
    
    private func loadUserProfile(uid: String) async {
        isLoading = true
        
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            
            guard let data = document.data() else {
                isLoading = false
                currentUser = nil
                return
            }
            
            let displayName = data["displayName"] as? String ?? "Me"
            let email = data["email"] as? String ?? ""
            let coupleId = data["coupleId"] as? String
            let inviteCode = data["inviteCode"] as? String
            
            currentUser = MoonMailUserProfile(
                uid: uid,
                displayName: displayName,
                email: email,
                coupleId: coupleId,
                inviteCode: inviteCode
            )
            
            isLoading = false
        } catch {
            isLoading = false
            show(message: error.localizedDescription)
        }
    }
    
    private func validateAccount(displayName: String, email: String, password: String) -> Bool {
        guard !displayName.isEmpty else {
            show(message: "Please enter your display name.")
            return false
        }
        
        guard email.contains("@") && email.contains(".") else {
            show(message: "Please enter a valid email address.")
            return false
        }
        
        guard password.count >= 6 else {
            show(message: "Your password should be at least 6 characters.")
            return false
        }
        
        return true
    }
    
    private func generateMoonCode() -> String {
        let number = Int.random(in: 1000...9999)
        return "MOON-\(number)"
    }
    
    private func show(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Moon Notes View Model

@MainActor
final class MoonNotesViewModel: ObservableObject {
    @Published var notes: [MoonNote] = []
    @Published var isSending = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var activeCoupleId: String?
    
    deinit {
        listener?.remove()
    }
    
    func startListening(coupleId: String?) {
        guard let coupleId else {
            show(message: "No Moon Room found for this account.")
            return
        }
        
        guard activeCoupleId != coupleId else {
            return
        }
        
        listener?.remove()
        activeCoupleId = coupleId
        
        listener = db.collection("couples")
            .document(coupleId)
            .collection("notes")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    
                    if let error {
                        self.show(message: error.localizedDescription)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.notes = []
                        return
                    }
                    
                    self.notes = documents.map { document in
                        let data = document.data()
                        let timestamp = data["createdAt"] as? Timestamp
                        
                        return MoonNote(
                            id: document.documentID,
                            text: data["text"] as? String ?? "",
                            senderId: data["senderId"] as? String ?? "",
                            senderName: data["senderName"] as? String ?? "Unknown",
                            createdAt: timestamp?.dateValue() ?? Date()
                        )
                    }
                }
            }
    }
    
    func sendNote(text: String, profile: MoonMailUserProfile) async -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else {
            show(message: "Please write a Moon Note before sending.")
            return false
        }
        
        guard let coupleId = profile.coupleId else {
            show(message: "No Moon Room found for this account.")
            return false
        }
        
        isSending = true
        
        do {
            try await db.collection("couples")
                .document(coupleId)
                .collection("notes")
                .addDocument(data: [
                    "text": trimmedText,
                    "senderId": profile.uid,
                    "senderName": profile.displayName,
                    "createdAt": FieldValue.serverTimestamp()
                ])
            
            isSending = false
            return true
        } catch {
            isSending = false
            show(message: error.localizedDescription)
            return false
        }
    }
    
    private func show(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Root

enum AuthRoute: Hashable {
    case create
    case join
    case login
}

struct ContentView: View {
    @StateObject private var appState = MoonMailAppState()
    
    var body: some View {
        ZStack {
            if let currentUser = appState.currentUser {
                MainTabView(profile: currentUser)
                    .environmentObject(appState)
            } else {
                AuthRootView()
                    .environmentObject(appState)
            }
            
            if appState.isLoading {
                LoadingOverlay()
            }
        }
        .alert("MoonMail", isPresented: $appState.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appState.errorMessage)
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Theme

struct MoonMailTheme {
    static let night = Color(red: 0.22, green: 0.22, blue: 0.42)
    static let lavender = Color(red: 0.82, green: 0.78, blue: 0.95)
    static let softPurple = Color(red: 0.70, green: 0.63, blue: 0.88)
    static let blush = Color(red: 1.00, green: 0.86, blue: 0.90)
    static let moonCream = Color(red: 1.00, green: 0.96, blue: 0.82)
    static let cloud = Color(red: 0.96, green: 0.96, blue: 1.00)
    static let ink = Color(red: 0.28, green: 0.23, blue: 0.36)
    static let card = Color.white.opacity(0.82)
}

// MARK: - Reusable Components

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

// MARK: - Auth Flow

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

// MARK: - Main App

struct MainTabView: View {
    let profile: MoonMailUserProfile
    
    var body: some View {
        TabView {
            HomeView(profile: profile)
                .tabItem {
                    Image(systemName: "moon.stars.fill")
                    Text("Home")
                }
            
            NotesView(profile: profile)
                .tabItem {
                    Image(systemName: "envelope.fill")
                    Text("Notes")
                }
            
            MemoriesView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Memories")
                }
            
            CoupleSettingsView(profile: profile)
                .tabItem {
                    Image(systemName: "heart.circle.fill")
                    Text("Us")
                }
        }
        .tint(MoonMailTheme.softPurple)
    }
}

// MARK: - Home

struct HomeView: View {
    let profile: MoonMailUserProfile
    
    @State private var selectedMood = "Loved"
    
    let moods = [
        MoodOption(title: "Loved", icon: "heart.fill"),
        MoodOption(title: "Missing", icon: "face.smiling.inverse"),
        MoodOption(title: "Dreamy", icon: "moon.stars.fill"),
        MoodOption(title: "Soft", icon: "cloud.fill"),
        MoodOption(title: "Excited", icon: "sparkles")
    ]
    
    var body: some View {
        ZStack {
            DoodleBackground()
            
            ScrollView {
                VStack(spacing: 22) {
                    header
                    MoonbeamDistanceCard(profile: profile)
                    NextMoonriseCard()
                    MoonMoodCard(selectedMood: $selectedMood, moods: moods)
                    MoonSignalsGrid()
                    LatestMoonNoteCard()
                }
                .padding()
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("MoonMail")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(MoonMailTheme.ink)
            
            Text("\(profile.displayName)  ♡  Partner")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(MoonMailTheme.softPurple)
            
            Text("connected under the same moon")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 15)
    }
}

struct MoonbeamDistanceCard: View {
    let profile: MoonMailUserProfile
    
    var body: some View {
        CuteCard {
            VStack(spacing: 16) {
                HStack {
                    PartnerBubble(icon: "person.crop.circle.fill", name: profile.displayName)
                    
                    Spacer()
                    
                    VStack(spacing: 6) {
                        CuteSymbol(name: "moon.fill", size: 28)
                        
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
                    
                    PartnerBubble(icon: "person.crop.circle.fill.badge.heart", name: "Partner")
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(MoonMailTheme.softPurple)
                    
                    Text("Moonbeam Distance 543 miles")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)
                }
            }
        }
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

struct NextMoonriseCard: View {
    var body: some View {
        CuteCard {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Next Moonrise")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(MoonMailTheme.ink)
                        
                        Text("June 18, 2026")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    CuteSymbol(name: "airplane.departure", size: 36)
                }
                
                Text("29")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(MoonMailTheme.softPurple)
                
                Text("days until we meet again")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MoonMailTheme.ink)
                
                ProgressView(value: 0.62)
                    .tint(MoonMailTheme.blush)
                    .scaleEffect(x: 1, y: 1.5)
            }
        }
    }
}

// MARK: - Mood

struct MoodOption: Hashable {
    let title: String
    let icon: String
}

struct MoonMoodCard: View {
    @Binding var selectedMood: String
    let moods: [MoodOption]
    
    var body: some View {
        CuteCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Moon Mood")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)
                    
                    Spacer()
                    
                    CuteSymbol(name: "moon.stars.fill", size: 28)
                }
                
                HStack {
                    ForEach(moods, id: \.self) { mood in
                        Button {
                            selectedMood = mood.title
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
                            .background(selectedMood == mood.title ? MoonMailTheme.lavender : Color.white.opacity(0.82))
                            .clipShape(Circle())
                        }
                    }
                }
                
                HStack {
                    Text("Me: \(selectedMood)")
                    Spacer()
                    Text("Partner: Missing")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MoonMailTheme.ink)
            }
        }
    }
}

// MARK: - Moon Signals

struct MoonSignal: Hashable {
    let title: String
    let icon: String
}

struct MoonSignalsGrid: View {
    let actions = [
        MoonSignal(title: "Moon Hug", icon: "hands.sparkles.fill"),
        MoonSignal(title: "Leave Star", icon: "star.fill"),
        MoonSignal(title: "Dream of Me", icon: "cloud.moon.fill"),
        MoonSignal(title: "Moon Kiss", icon: "heart.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Moon Signals")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(MoonMailTheme.ink)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(actions, id: \.self) { action in
                    Button {
                        
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

// MARK: - Notes

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

// MARK: - Memories

struct MemoriesView: View {
    var body: some View {
        ZStack {
            DoodleBackground()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Moon Memories")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(MoonMailTheme.ink)
                        .padding(.top, 20)
                    
                    CuteCard {
                        VStack(spacing: 14) {
                            CuteSymbol(name: "moon.stars.fill", size: 60)
                            
                            Text("Save your favorite moonlit moments here")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(MoonMailTheme.ink)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                
                            } label: {
                                HStack {
                                    Text("Add Memory")
                                    Image(systemName: "camera.fill")
                                }
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(MoonMailTheme.softPurple)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        MemoryTile(icon: "cup.and.saucer.fill", title: "Cafe Date")
                        MemoryTile(icon: "ferriswheel", title: "First Trip")
                        MemoryTile(icon: "moon.stars.fill", title: "Late Call")
                        MemoryTile(icon: "birthday.cake.fill", title: "Birthday")
                    }
                    .padding(.horizontal)
                }
            }
        }
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

// MARK: - Settings

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
