//
//  MediaPlayerView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//

import SwiftUI

struct MediaPlayerView: View {
    var music: DeviceStatus.Music
    @State private var showingPlusPopover = false

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


                Group {
                    if AppState.shared.isPlus && AppState.shared.licenseCheck {
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
            }
        }
        .padding()
        .frame(maxWidth: 170)
        .onTapGesture {
            showingPlusPopover = !AppState.shared.isPlus && AppState.shared.licenseCheck
        }
        .popover(isPresented: $showingPlusPopover, arrowEdge: .bottom) {
            PlusFeaturePopover(message: "Control media with AirSync+")
        }
    }
}


#Preview {
    MediaPlayerView(music: MockData.sampleMusic)
}
