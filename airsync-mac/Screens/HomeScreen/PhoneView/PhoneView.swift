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
                MediaPlayerView(music: music)
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: 175, maxHeight: 390)
    }
}

