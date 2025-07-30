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
        WebSocketServer.shared.start() // default port 6996
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
