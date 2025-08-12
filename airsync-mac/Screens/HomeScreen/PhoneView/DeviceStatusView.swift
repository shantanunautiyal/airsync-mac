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
        ZStack {
            HStack(spacing: 16) {
                // Battery
                Label(
                    "\(appState.status?.battery.level ?? 100)%",
                    systemImage: batteryIcon(for: appState.status?.battery.level ?? 100, isCharging: appState.status?.battery.isCharging ?? false)
                )
                .contentTransition(.symbolEffect)

                // Volume Button with left/right click handling
                Label(
                    "\(appState.status?.music.volume ?? 100)%",
                    systemImage: volumeIcon(for: appState.status?.music.volume ?? 100, isMuted: appState.status?.music.isMuted ?? false)
                )
                .contentTransition(.symbolEffect)
                .onTapGesture {
                    if AppState.shared.isPlus && AppState.shared.licenseCheck {
                        if let currentVolume = appState.status?.music.volume {
                            tempVolume = Double(currentVolume)
                        }
                        showingVolumePopover.toggle()
                    } else {
                        showingPlusPopover = true
                    }
                }
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
                        .padding()
                    }
                    .frame(width: 200)
                }
                .popover(isPresented: $showingPlusPopover, arrowEdge: .bottom) {
                    PlusFeaturePopover(message: "Control volume with AirSync+")
                }
            }
            .padding()
            .applyGlassViewIfAvailable()
            .animation(.easeInOut(duration: 0.25),
                       value: "\(appState.status?.battery.level ?? 0)-\(appState.status?.music.volume ?? 0)")
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
