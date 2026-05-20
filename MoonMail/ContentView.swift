import SwiftUI

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
