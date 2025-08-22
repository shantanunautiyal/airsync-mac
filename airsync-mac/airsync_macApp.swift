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
    @StateObject private var appState = AppState.shared
    @AppStorage("hasPairedDeviceOnce") private var hasPairedDeviceOnce: Bool = false

    init() {

        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate

        // Register base default category with generic View action; dynamic per-notification categories added later
        let viewAction = UNNotificationAction(identifier: "VIEW_ACTION", title: "View", options: [])
        let defaultCategory = UNNotificationCategory(identifier: "DEFAULT_CATEGORY", actions: [viewAction], intentIdentifiers: [], options: [])
        center.getNotificationCategories { existing in
            center.setNotificationCategories(existing.union([defaultCategory]))
        }
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
        MenuBarExtra {
            MenubarView()
                .environmentObject(appState)
        } label: {
            MenuBarLabelView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        Window("AirSync", id: "main") {
            if #available(macOS 15.0, *) {
                HomeView()
                    .containerBackground(.ultraThinMaterial, for: .window)
                    .background(WindowAccessor { window in
                        window.identifier = NSUserInterfaceItemIdentifier("main")
                        appDelegate.mainWindow = window
                        window.collectionBehavior.insert(.moveToActiveSpace)
                    })
            } else {
                HomeView()
                    .background(WindowAccessor { window in
                        window.identifier = NSUserInterfaceItemIdentifier("main")
                        appDelegate.mainWindow = window
                        window.collectionBehavior.insert(.moveToActiveSpace)
                    })
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
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .help) {
                Button(action: {
                    if let url = URL(string: "https://airsync.notion.site") {
                        NSWorkspace.shared.open(url)
                    }
                }, label: {
                    Text("Help")
                })
                .keyboardShortcut("/")
            }
            // Mirror menu: launch full device mirror or specific apps via scrcpy
            CommandMenu("Mirror") {
                // Primary full-device mirror option
                Button("Android Mirror") {
                    if let device = appState.device, appState.adbConnected {
                        ADBConnector.startScrcpy(
                            ip: device.ipAddress,
                            port: appState.adbPort,
                            deviceName: device.name,
                            package: nil
                        )
                    }
                }
                .disabled(!(appState.device != nil && appState.adbConnected))

                // Only show app list if ADB is connected
                if appState.adbConnected, let _ = appState.device {
                    Divider()
                    // Sorted list of apps by display name
                    ForEach(Array(appState.androidApps.values).sorted { $0.name.lowercased() < $1.name.lowercased() }, id: \.packageName) { app in
                        Button(app.name) {
                            if let device = appState.device {
                                ADBConnector.startScrcpy(
                                    ip: device.ipAddress,
                                    port: appState.adbPort,
                                    deviceName: device.name,
                                    package: app.packageName
                                )
                            }
                        }
                    }
                }
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
