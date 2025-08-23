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
    @State private var didTriggerFirstLaunchOpen = false
    // Avoid creating another AppDelegate instance here; use the shared one
    private var appDelegate: AppDelegate? { AppDelegate.shared }

    private func focus(window: NSWindow) {
    if window.isMiniaturized { window.deminiaturize(nil) }
    window.collectionBehavior.insert(.moveToActiveSpace)
    NSApp.unhide(nil)
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    window.orderFrontRegardless()
    }

    private func openAndFocusMainWindow() {
        // If window already exists, focus immediately + a follow-up retry
        if let existing = appDelegate?.mainWindow {
            focus(window: existing)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                self.appDelegate?.showAndActivateMainWindow()
            }
            return
        }

        // Trigger creation
        openWindow(id: "main")

        // Retry a few times until WindowAccessor supplies the reference
        for i in 0..<8 {
            let delay = Double(i) * 0.08
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if (self.appDelegate?.mainWindow) != nil {
                    self.appDelegate?.showAndActivateMainWindow()
                }
            }
        }
    }

    private func getDeviceName() -> String {
        appState.device?.name ?? "Ready"
    }

    private let minWidthTabs: CGFloat = 280
    private let toolButtonSize: CGFloat = 38

    var body: some View {
        VStack {
            VStack(spacing: 12){
                // Header
                Text("AirSync - \(getDeviceName())")
                    .font(.headline)

                HStack(spacing: 10){
                    GlassButtonView(
                        label: "Open App",
                        systemImage: "arrow.up.forward.app",
                        iconOnly: true,
                        circleSize: toolButtonSize
                    ) {
                        openAndFocusMainWindow()
                    }

                    if (appState.device != nil){
                        GlassButtonView(
                            label: "Send",
                            systemImage: "square.and.arrow.up",
                            iconOnly: true,
                            circleSize: toolButtonSize,
                            action: {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = true
                                panel.canChooseDirectories = false
                                panel.allowsMultipleSelection = false
                                panel.begin { response in
                                    if response == .OK, let url = panel.url {
                                        DispatchQueue.global(qos: .userInitiated).async {
                                            WebSocketServer.shared.sendFile(url: url)
                                        }
                                    }
                                }
                            }
                        )
                        .transition(.identity)
                        .keyboardShortcut(
                            "f",
                            modifiers: .command
                        )
                    }


                    if appState.adbConnected{
                        GlassButtonView(
                            label: "Mirror",
                            systemImage: "apps.iphone",
                            iconOnly: true,
                            circleSize: toolButtonSize,
                            action: {
                                ADBConnector
                                    .startScrcpy(
                                        ip: appState.device?.ipAddress ?? "",
                                        port: appState.adbPort,
                                        deviceName: appState.device?.name ?? "My Phone"
                                    )
                            }
                        )
                        .transition(.identity)
                        .keyboardShortcut(
                            "p",
                            modifiers: .command
                        )
                        .contextMenu {
                            Button("Desktop Mode") {
                                ADBConnector.startScrcpy(
                                    ip: appState.device?.ipAddress ?? "",
                                    port: appState.adbPort,
                                    deviceName: appState.device?.name ?? "My Phone",
                                    desktop: true
                                )
                            }
                        }
                        .keyboardShortcut(
                            "p",
                            modifiers: [.command, .shift]
                        )
                    }

                    GlassButtonView(
                        label: "Quit",
                        systemImage: "power",
                        iconOnly: true,
                        circleSize: toolButtonSize
                    ) {
                        NSApplication.shared.terminate(nil)
                    }
                }

                if (appState.status != nil){
                    DeviceStatusView()
                        .transition(.opacity.combined(with: .scale))
                }

                if let music = appState.status?.music,
                let title = appState.status?.music.title.trimmingCharacters(in: .whitespacesAndNewlines),
                !title.isEmpty {

                    MediaPlayerView(music: music)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(10)

            if appState.device != nil {
                MenuBarNotificationsListView()
            }

        }
        .onAppear {
            // On first launch (onboarding not completed), automatically open main window
            if !hasPairedDeviceOnce && !didTriggerFirstLaunchOpen {
                didTriggerFirstLaunchOpen = true
                // Slight delay to ensure menu bar extra finished mounting
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    openAndFocusMainWindow()
                }
            }
        }
    }
}

// MARK: - Menu Bar Notifications (List variant with swipe actions)
private struct MenuBarNotificationsListView: View {
    @ObservedObject private var appState = AppState.shared
    private let maxItems = 10

    var body: some View {
        Group {
            if !appState.notifications.isEmpty {
                List {
                    ForEach(appState.notifications.prefix(maxItems)) { notif in
                        NotificationCardView(
                            notification: notif,
                            deleteNotification: { appState.removeNotification(notif) },
                            hideNotification: { appState.hideNotification(notif) }
                        )
                        .applyGlassViewIfAvailable()
                        .animation(nil, value: appState.notifications.count)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: 750)
                .transaction { txn in txn.animation = nil }
            }
        }
    }
}

#Preview {
    MenubarView()
}
