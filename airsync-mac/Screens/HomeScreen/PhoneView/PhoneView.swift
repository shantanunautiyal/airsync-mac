//
//  PhoneView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct PhoneView: View {
    var body: some View {
        ZStack{
            GlassBoxView(
                color: .gray.opacity(0.2),
                width: 190,
                height: 410,
                radius: 25
            )

            Image("wallpaper")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: 400)
                .cornerRadius(20)

            ScreenView()

        }
    }
}

#Preview {
    PhoneView()
}

struct StatusBarView: View {
    var body: some View {
            HStack{
                Spacer()
                Circle()
                    .fill(.gray.opacity(0.2))
                    .frame(width: 15, height: 15)
                    .padding(5)
                Spacer()
            }
    }
}

struct ScreenView: View {
    @ObservedObject var appState = AppState.shared
    var body: some View {
        VStack{
            StatusBarView()

            Spacer()

            TimeView()

            Spacer()

            if let music = appState.status?.music {
                MediaPlayer(music: music)
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: 160, maxHeight: 390)
    }
}

struct MediaPlayer: View {
    var music: DeviceStatus.Music

    var body: some View {
        ZStack{
                GlassBoxView(width: 170, height: 70)

                VStack{
                    Label(
                        music.title,
                        systemImage: "music.note.list"
                    )
                    .font(.caption)

                    Text(music.artist)
                        .font(.footnote)

                    HStack{
                        GlassButtonView(
                            label: "",
                            systemImage: "backward.end",
                            size: .small
                        )
                        .labelStyle(.iconOnly)

                        GlassButtonView(
                            label: "",
                            systemImage: "play.fill"
                        )
                        .labelStyle(.iconOnly)

                        GlassButtonView(
                            label: "",
                            systemImage: "forward.end",
                            size: .small
                        )
                        .labelStyle(.iconOnly)
                    }
            }
        }
    }
}
