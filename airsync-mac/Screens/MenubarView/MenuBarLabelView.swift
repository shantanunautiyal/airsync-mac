//
//  MenuBarLabelView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-12.
//

import SwiftUI

struct MenuBarLabelView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) var openWindow
    @AppStorage("hasPairedDeviceOnce") private var hasPairedDeviceOnce: Bool = false
    @State private var didTriggerFirstLaunchOpen = false

    var deviceStatusText: String? {
        guard let device = appState.device else { return nil }

        if appState.notifications.count > 0 {
            return "\(appState.notifications.count) Unread"
        } else if let music = appState.status?.music, music.isPlaying {
            let title = music.title.isEmpty ? "Unknown Title" : music.title
            let artist = music.artist.isEmpty ? "Unknown Artist" : music.artist
            return "\(title) - \(artist)"
        } else {
            var parts: [String] = []
            if appState.showMenubarDeviceName {
                parts.append(device.name)
            }

            if let batteryLevel = appState.status?.battery.level {
                parts.append("\(batteryLevel)%")
            }
            return parts.isEmpty ? nil : parts.joined(separator: " ")
        }
    }

    var body: some View {
        HStack {
            Image(systemName: appState.device != nil
                  ? (appState.notifications.isEmpty
                     ? "iphone.gen3"
                     : "iphone.gen3.radiowaves.left.and.right")
                  : "iphone.slash")

            if appState.showMenubarText, let text = deviceStatusText {
                let maxLength = appState.menubarTextMaxLength
                let truncatedText = text.count > maxLength
                    ? String(text.prefix(maxLength - 1)) + "…"
                    : text
                Text(truncatedText)
            }
        }
        .onAppear {
            // Open main window if:
            // 1. First launch (onboarding not completed), OR
            // 2. "Always open window" setting is enabled
            // Note: didTriggerFirstLaunchOpen resets on each app launch since it's @State
            if (!hasPairedDeviceOnce || appState.alwaysOpenWindow) && !didTriggerFirstLaunchOpen {
                didTriggerFirstLaunchOpen = true
                // Slight delay to ensure everything is set up
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    openWindow(id: "main")
                }
            }
        }
    }
}



#Preview {
    MenuBarLabelView()
}
