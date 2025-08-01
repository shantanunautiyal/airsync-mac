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
                                    iconOnly: true,
                                    size: .small,
                                    action: {
                                        WebSocketServer.shared.skipPrevious()
                                    }
                                )
                                .buttonStyle(.glass)
                            } else {
                                GlassButtonView(
                                    label: "",
                                    systemImage: "backward.end",
                                    iconOnly: true,
                                    size: .small,
                                    action: {
                                        WebSocketServer.shared.skipPrevious()
                                    }
                                )
                            }

                            if #available(macOS 26.0, *) {
                                GlassButtonView(
                                    label: "",
                                    systemImage: music.isPlaying ? "pause.fill" : "play.fill",
                                    iconOnly: true,
                                    action: {
                                        WebSocketServer.shared.togglePlayPause()
                                    }
                                )
                                .buttonStyle(.glass)
                            } else {
                                GlassButtonView(
                                    label: "",
                                    systemImage: music.isPlaying ? "pause.fill" : "play.fill",
                                    iconOnly: true,
                                    action: {
                                        WebSocketServer.shared.togglePlayPause()
                                    }
                                )
                            }

                            if #available(macOS 26.0, *) {
                                GlassButtonView(
                                    label: "",
                                    systemImage: "forward.end",
                                    iconOnly: true,
                                    size: .small,
                                    action: {
                                        WebSocketServer.shared.skipNext()
                                    }
                                )
                                .buttonStyle(.glass)
                            } else {
                                GlassButtonView(
                                    label: "",
                                    systemImage: "forward.end",
                                    iconOnly: true,
                                    size: .small,
                                    action: {
                                        WebSocketServer.shared.skipNext()
                                    }
                                )
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
