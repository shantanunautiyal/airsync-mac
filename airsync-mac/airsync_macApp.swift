//
//  airsync_macApp.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

@main
struct airsync_macApp: App {
    init() {
        let devicePort = UInt16(AppState.shared.myDevice?.port ?? Int(Defaults.serverPort))
        WebSocketServer.shared.start(port: devicePort)
        loadCachedIcons()
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
