import SwiftUI
import FirebaseCore

@main
struct MoonMailApp: App {
    init() {
        FirebaseApp.configure()

        if let options = FirebaseApp.app()?.options {
            print("🔥 Firebase projectID:", options.projectID)
            print("🔥 Firebase googleAppID:", options.googleAppID)
            print("🔥 Firebase bundleID:", options.bundleID)
        } else {
            print("❌ Firebase options could not be loaded.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
