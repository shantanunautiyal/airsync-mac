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
                    if #available(macOS 26.0, *) {
                        GlassButtonView(
                            label: "",
                            systemImage: "backward.end",
                            size: .small,
                            action: {
                                WebSocketServer.shared.skipPrevious()
                            }
                        )
                        .labelStyle(.iconOnly)
                        .buttonStyle(.glass)
                    } else {
                        GlassButtonView(
                            label: "",
                            systemImage: "backward.end",
                            size: .small,
                            action: {
                                WebSocketServer.shared.skipPrevious()
                            }
                        )
                        .labelStyle(.iconOnly)
                    }

                    if #available(macOS 26.0, *) {
                        GlassButtonView(
                            label: "",
                            systemImage: music.isPlaying ? "pause.fill" : "play.fill",
                            action: {
                                WebSocketServer.shared.togglePlayPause()
                            }
                        )
                        .labelStyle(.iconOnly)
                        .buttonStyle(.glass)
                    } else {
                        GlassButtonView(
                            label: "",
                            systemImage: music.isPlaying ? "pause.fill" : "play.fill",
                            action: {
                                WebSocketServer.shared.togglePlayPause()
                            }
                        )
                        .labelStyle(.iconOnly)
                    }

                    if #available(macOS 26.0, *) {
                        GlassButtonView(
                            label: "",
                            systemImage: "forward.end",
                            size: .small,
                            action: {
                                WebSocketServer.shared.skipNext()
                            }
                        )
                        .labelStyle(.iconOnly)
                        .buttonStyle(.glass)
                    } else {
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
        }
        .padding()
        .frame(maxWidth: 170)
    }
}


#Preview {
    MediaPlayerView(music: MockData.sampleMusic)
}
