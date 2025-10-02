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
                HStack(spacing: 4) {
                    Image(systemName: "music.note.list")
                    EllipsesTextView(
                        text: music.title,
                        font: .caption
                    )
                }
                .frame(height: 14)

                EllipsesTextView(
                    text: music.artist,
                    font: .footnote,
                )



                Group {
                    if AppState.shared.isPlus || !AppState.shared.licenseCheck {
                        HStack{
                            if (AppState.shared.status?.music.likeStatus == "liked" || AppState.shared.status?.music.likeStatus == "not_liked") {
                                GlassButtonView(
                                    label: "",
                                    systemImage: {
                                        if let like = AppState.shared.status?.music.likeStatus {
                                            switch like {
                                            case "liked": return "heart.fill"
                                            case "not_liked": return "heart"
                                            default: return "heart.slash"
                                            }
                                        }
                                        return "heart.slash"
                                    }(),
                                    iconOnly: true,
                                    action: {
                                        guard let like = AppState.shared.status?.music.likeStatus else { return }
                                        if like == "liked" {
                                            WebSocketServer.shared.unlike()
                                        } else if like == "not_liked" {
                                            WebSocketServer.shared.like()
                                        } else {
                                            WebSocketServer.shared.toggleLike()
                                        }
                                    }
                                )
                                .help("Like / Unlike")
                            } else {

                                GlassButtonView(
                                    label: "",
                                    systemImage: "backward.end",
                                    iconOnly: true,
                                    action: {
                                        WebSocketServer.shared.skipPrevious()
                                    }
                                )
                                .keyboardShortcut(
                                    .leftArrow,
                                    modifiers: .control
                                )
                            }
                            
                                GlassButtonView(
                                    label: "",
                                    systemImage: music.isPlaying ? "pause.fill" : "play.fill",
                                    iconOnly: true,
                                    primary: true,
                                    action: {
                                        WebSocketServer.shared.togglePlayPause()
                                    }
                                )
                                .keyboardShortcut(
                                    .space,
                                    modifiers: .control
                                )

                                GlassButtonView(
                                    label: "",
                                    systemImage: "forward.end",
                                    iconOnly: true,
                                    action: {
                                        WebSocketServer.shared.skipNext()
                                    }
                                )
                                .keyboardShortcut(
                                    .rightArrow,
                                    modifiers: .control
                                )
                        }
                    }
                }
            }
        }
        .padding(10)
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
