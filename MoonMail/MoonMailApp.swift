import SwiftUI
import FirebaseCore

@main
struct MoonMailApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
