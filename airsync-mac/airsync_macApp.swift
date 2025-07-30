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
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .containerBackground(
                    .ultraThinMaterial , for: .window
                )
                .toolbarBackgroundVisibility(
                    .hidden, for: .windowToolbar
                )
        }
    }
}
