//
//  airsync_macApp.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI
import UserNotifications
import AppKit

@main
struct airsync_macApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let notificationDelegate = NotificationDelegate()
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
//        DispatchQueue.main.async {
//            NSApp.activate(ignoringOtherApps: true)
//        }

        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate

        // Register "View" button
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "DEFAULT_CATEGORY",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
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

        // Auto-check for update on launch
        UpdateChecker.shared.checkForUpdateAndDownloadIfNeeded(presentingWindow: nil) { updated in
            if updated {
                print("Update downloaded, quitting app for user to install")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }

    var body: some Scene {
        MenuBarExtra("AirSync", systemImage: "iphone.gen3") {
            MenubarView()
        }

        WindowGroup(id: "main") {
            if #available(macOS 15.0, *) {
                HomeView()
                    .containerBackground(.ultraThinMaterial, for: .window)
                    .toolbarBackgroundVisibility(
                        .automatic,
                        for: .windowToolbar
                    )
            } else {
                HomeView()
            }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    if let window = appDelegate.mainWindow {
                        checkForUpdatesManually(presentingWindow: window)
                    } else {
                        checkForUpdatesManually(presentingWindow: nil)
                    }
                }
                .keyboardShortcut("u", modifiers: [.command])
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                AppState.shared.saveAppsToDisk()
            }
        }
    }

    func checkForUpdatesManually(presentingWindow: NSWindow?) {
        UpdateChecker.shared.checkForUpdateAndDownloadIfNeeded(presentingWindow: presentingWindow) { updated in
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")

                if updated {
                    alert.messageText = "Update downloaded"
                    alert.informativeText = "A new version was downloaded to your Downloads folder. The app will quit now to let you install it."
                    alert.runModal()
                    NSApplication.shared.terminate(nil)
                } else {
                    alert.messageText = "No updates available"
                    alert.informativeText = "Your app is up to date."
                    alert.runModal()
                }
            }
        }
    }
}

