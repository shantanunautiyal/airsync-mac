//
//  airsync_macApp.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI

@main
struct airsync_macApp: App {
    let socketServer = SocketServer()

    init() {
        socketServer.start(port: 6996)
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
                .environmentObject(socketServer)
        }
    }
}
