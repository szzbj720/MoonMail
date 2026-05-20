import SwiftUI

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
