//
//  MediaPlayerView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//

import SwiftUI

struct MediaPlayerView: View {
    var music: DeviceStatus.Music

    var body: some View {
        ZStack{

            VStack{
                Label(
                    music.title,
                    systemImage: "music.note.list"
                )
                .font(.caption)

                Text(music.artist)
                    .font(.footnote)
                    .padding(.bottom, 5)

                HStack{
                    GlassButtonView(
                        label: "",
                        systemImage: "backward.end",
                        size: .small,
                        action: {
                            WebSocketServer.shared.skipPrevious()
                        }
                    )
                    .labelStyle(.iconOnly)

                    GlassButtonView(
                        label: "",
                        systemImage: music.isPlaying ? "pause.fill" : "play.fill",
                        action: {
                                WebSocketServer.shared.togglePlayPause()
                        }
                    )
                    .labelStyle(.iconOnly)

                    GlassButtonView(
                        label: "",
                        systemImage: "forward.end",
                        size: .small,
                        action: {
                            WebSocketServer.shared.skipNext()
                        }
                    )
                    .labelStyle(.iconOnly)
                }
            }
        }
        .padding()
        .frame(maxWidth: 170)
        .background(.clear)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}


#Preview {
    MediaPlayerView(music: MockData.sampleMusic)
}
