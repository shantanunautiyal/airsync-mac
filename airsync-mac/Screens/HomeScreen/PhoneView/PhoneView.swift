//
//  PhoneView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

struct PhoneView: View {
    var wallpaperPath: String? {
        AppState.shared.currentWallpaperPath
    }

    var body: some View {
        ZStack {
            GlassBoxView(
                width: 190,
                height: 410,
                radius: 25
            )
            .transition(.opacity.combined(with: .scale))

            Group {
                if let base64 = AppState.shared.currentDeviceWallpaperBase64,
                   let data = Data(base64Encoded: base64.stripBase64Prefix()),
                   let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .opacity(0.75)
                }
            }
            .aspectRatio(contentMode: .fill)
            .frame(width: 180, height: 400)
            .cornerRadius(20)




            ScreenView()
                .transition(.opacity.combined(with: .scale))
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
                    .fill(.background.opacity(0.6))
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
                .transition(.opacity.combined(with: .scale))

            Spacer()

            if let music = appState.status?.music,
               let title = appState.status?.music.title.trimmingCharacters(in: .whitespacesAndNewlines),
               !title.isEmpty {

                if #available(macOS 26.0, *) {
                    MediaPlayerView(music: music)
                        .background(.clear)
                        .glassEffect(in: .rect(cornerRadius: 20))
                        .transition(.opacity.combined(with: .scale))
                } else {
                    MediaPlayerView(music: music)
                        .transition(.opacity.combined(with: .scale))
                }
            } else {
                Spacer()
            }

        }
        .frame(maxWidth: 175, maxHeight: 390)
    }
}

