//
//  airsync_macApp.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI
import UserNotifications

@main
struct airsync_macApp: App {
    let notificationDelegate = NotificationDelegate()

    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }

        let devicePort = UInt16(AppState.shared.myDevice?.port ?? Int(Defaults.serverPort))
        WebSocketServer.shared.start(port: devicePort)


        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            AppState.shared.syncWithSystemNotifications()
        }

        loadCachedIcons()
        loadCachedWallpapers()
    }


    var body: some Scene {
        WindowGroup {
            if #available(macOS 15.0, *) {
                HomeView()
                    .containerBackground(
                        .ultraThinMaterial , for: .window
                    )
                    .toolbarBackgroundVisibility(
                        .hidden, for: .windowToolbar
                    )
            } else {
                HomeView()
            }
        }
    }
}
