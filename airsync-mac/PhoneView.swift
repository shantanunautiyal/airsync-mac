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

            Rectangle()
                .fill(.gray.opacity(0.2))
                .frame(width: 190, height: 410)
                .cornerRadius(25)

            Image("wallpaper")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: 400)
                .cornerRadius(20)

//            Rectangle()
//                .fill(Color.blue.gradient)
//                .frame(width: 180, height: 400)
//                .cornerRadius(20)

            ScreenView()

        }
    }
}

#Preview {
    PhoneView()
}

struct StatusBarView: View {
    var body: some View {
        ZStack{
            HStack{
                Spacer()
                Circle()
                    .fill(.gray.opacity(0.2))
                    .frame(width: 15, height: 15)
                Spacer()
            }

            HStack{
                Spacer()
                Image(systemName: "wifi")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 13, height: 13)
                Image(systemName: "battery.75percent")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 13, height: 13)
            }
        }
    }
}

struct ScreenView: View {
    var body: some View {
        VStack{
            StatusBarView()
            Spacer()
            MediaPlayer()
        }
        .frame(maxWidth: 160, maxHeight: 390)
    }
}

struct MediaPlayer: View {
    var body: some View {
        ZStack{
            Rectangle()
                .fill(.background.opacity(0))
                .frame(width: 170, height: 70)
                .glassEffect(in: .rect(cornerRadius: 16.0))

            VStack{
                Label("Emptyness Machine", systemImage: "music.note.list")
                    .font(.caption)

                Text("Linkin Park")
                    .font(.footnote)

                HStack{
                    Button{
                        //                    isShowingSafariView = true
                    } label: {
                        Label("", systemImage: "backward.end")
                    }
                    .buttonStyle(.glass)
                    .labelStyle(.iconOnly)
                    .controlSize(.small)

                    Button{
                        //                    isShowingSafariView = true
                    } label: {
                        Label("", systemImage: "play.fill")
                    }
                    .buttonStyle(.glass)
                    .labelStyle(.iconOnly)
                    .controlSize(.large)

                    Button{
                        //                    isShowingSafariView = true
                    } label: {
                        Label("", systemImage: "forward.end")
                    }
                    .buttonStyle(.glass)
                    .labelStyle(.iconOnly)
                    .controlSize(.small)
                }


            }
        }
    }
}
