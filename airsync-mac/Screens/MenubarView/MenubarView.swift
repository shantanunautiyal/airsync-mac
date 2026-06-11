//
//  MenubarView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-08.
//

import SwiftUI

struct MenubarView: View {
    @Environment(\.openWindow) var openWindow
    @StateObject private var appState = AppState.shared
    @AppStorage("hasPairedDeviceOnce") private var hasPairedDeviceOnce: Bool = false
    private var appDelegate: AppDelegate? { AppDelegate.shared }

    private let minWidthTabs: CGFloat = 360
    private let toolButtonSize: CGFloat = 42

    @State private var isAppearing = false

    private func focus(window: NSWindow) {
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.collectionBehavior.insert(.moveToActiveSpace)
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func openAndFocusMainWindow() {
        DispatchQueue.main.async {
            if let window = self.appDelegate?.mainWindow {
                window.makeKeyAndOrderFront(nil)
            } else {
                self.openWindow(id: "main")
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func getDeviceName() -> String {
        appState.device?.name ?? "Ready"
    }

    var body: some View {
        VStack(spacing: 6) {
            TopSegmentView(
                toolButtonSize: toolButtonSize,
                openAndFocusMainWindow: openAndFocusMainWindow
            )
            .staggeredEntrance(index: 0, isVisible: appState.isMenubarWindowOpen)

            CallControlSegmentView()
                .staggeredEntrance(index: 1, isVisible: appState.isMenubarWindowOpen)

            DiscoverySegmentView()
                .staggeredEntrance(index: 2, isVisible: appState.isMenubarWindowOpen)

            MediaSegmentView()
                .staggeredEntrance(index: 3, isVisible: appState.isMenubarWindowOpen)

            NotificationsSegmentView()
                .staggeredEntrance(index: 4, isVisible: appState.isMenubarWindowOpen)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(width: minWidthTabs + 48)
        .environment(\.controlActiveState, .active)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            // Optional: close if it loses focus
        }
    }
}

#Preview {
    MenubarView()
}
