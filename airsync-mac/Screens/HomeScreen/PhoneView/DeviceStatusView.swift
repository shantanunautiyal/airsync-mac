//
//  DeviceStatusView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//

import SwiftUI

struct DeviceStatusView: View {
    @ObservedObject var appState = AppState.shared
    @State private var showingVolumePopover = false
    @State private var tempVolume: Double = 100
    @State private var isDragging = false
    @State private var showingPlusPopover = false

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                let batteryLevel = appState.status?.battery.level ?? 100
                let batteryIsCharging = appState.status?.battery.isCharging ?? false


                HStack{
                    Image(systemName: batteryIcon(for: batteryLevel, isCharging: batteryIsCharging))
                        .help("\(batteryLevel)%")
                        .contentTransition(.symbolEffect)
                    Text("\(batteryLevel)%")
                        .font(.caption2)
                }
                .padding(.leading, 4)

                let volume = appState.status?.music.volume ?? 100
                let isMuted = appState.status?.music.isMuted ?? false

                GlassButtonView(
                    label: "Music Player",
                    systemImage: volumeIcon(for: volume, isMuted: isMuted),
                    iconOnly: true,
                    primary: false,
                    action: {
                        if AppState.shared.isPlus && AppState.shared.licenseCheck {
                            if let currentVolume = appState.status?.music.volume {
                                tempVolume = Double(currentVolume)
                            }
                            showingVolumePopover.toggle()
                        } else {
                            showingPlusPopover = true
                        }
                    }
                )
                .help(isMuted ? "Muted" : "\(volume)%")
                .contentTransition(.symbolEffect)
                    .popover(isPresented: $showingVolumePopover, arrowEdge: .bottom) {
                        VStack {
                            HStack {
                                Image(systemName: "speaker.fill")

                                Slider(
                                    value: $tempVolume,
                                    in: 0...100,
                                    onEditingChanged: { editing in
                                        if !editing {
                                            WebSocketServer.shared.setVolume(Int(tempVolume))
                                        }
                                        isDragging = editing
                                    }
                                )
                                .focusable(false)

                                Image(systemName: "speaker.wave.3.fill")
                            }
                        }
                        .padding()
                        .frame(width: 200)
                    }
                    .popover(isPresented: $showingPlusPopover, arrowEdge: .bottom) {
                        PlusFeaturePopover(message: "Control volume with AirSync+")
                    }


                GlassButtonView(
                    label: "Music Player",
                    systemImage: appState.status?.music.isPlaying == true ? "play.rectangle" : "music.note",
                    iconOnly: true,
                    primary: false,
                    action: {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            appState.isMusicCardHidden.toggle()
                        }
                    }
                )
                .help("Show player")
            }
            .padding(4)
            .applyGlassViewIfAvailable()
            .animation(
                .easeInOut(duration: 0.25),
                value: "\(appState.status?.battery.level ?? 0)-\(appState.status?.music.volume ?? 0)"
            )

        }
    }

    // Battery icon helper
    private func batteryIcon(for level: Int, isCharging: Bool) -> String {
        if isCharging {
            return "battery.100.bolt"
        }
        switch level {
        case 0...10: return "battery.0"
        case 11...25: return "battery.25"
        case 26...50: return "battery.50"
        case 51...75: return "battery.75"
        default: return "battery.100"
        }
    }

    // Volume icon helper
    private func volumeIcon(for volume: Int, isMuted: Bool) -> String {
        if isMuted || volume == 0 {
            return "speaker.slash"
        } else if volume <= 25 {
            return "speaker.wave.1"
        } else if volume <= 50 {
            return "speaker.wave.2"
        } else {
            return "speaker.wave.3"
        }
    }
}

#Preview {
    DeviceStatusView()
}
