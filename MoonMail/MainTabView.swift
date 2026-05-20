import SwiftUI

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
