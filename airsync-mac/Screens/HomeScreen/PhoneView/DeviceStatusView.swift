//
//  DeviceStatusView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-29.
//

import SwiftUI

struct DeviceStatusView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        ZStack {
//            GlassBoxView()

            HStack(spacing: 16) {
                // Battery
                Label(
                    "\(appState.status?.battery.level ?? 100)%",
                    systemImage: batteryIcon(for: appState.status?.battery.level ?? 100, isCharging: appState.status?.battery.isCharging ?? false)
                )

                // Volume
                Label(
                    "\(appState.status?.music.volume ?? 100)%",
                    systemImage: volumeIcon(for: appState.status?.music.volume ?? 100, isMuted: appState.status?.music.isMuted ?? false)
                )
            }
        }
    }

    // Helper for battery icon
    private func batteryIcon(for level: Int, isCharging: Bool) -> String {
        if isCharging {
            return "battery.100.bolt"
        }
        switch level {
        case 0...10:
            return "battery.0"
        case 11...25:
            return "battery.25"
        case 26...50:
            return "battery.50"
        case 51...75:
            return "battery.75"
        default:
            return "battery.100"
        }
    }

    // Helper for volume icon
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
