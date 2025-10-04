//
//  airsync_macApp.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-27.
//

import SwiftUI
import UserNotifications
import AppKit
import Sparkle

@main
struct airsync_macApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let notificationDelegate = NotificationDelegate()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    @AppStorage("hasPairedDeviceOnce") private var hasPairedDeviceOnce: Bool = false
    private let updaterController: SPUStandardUpdaterController

    // Initialize NowPlayingViewModel to start sending media info to Android
    @StateObject private var macInfoSyncManager = MacInfoSyncManager()

    init() {

        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

        // Register base default category with generic View action; dynamic per-notification categories added later
        let viewAction = UNNotificationAction(identifier: "VIEW_ACTION", title: "View", options: [])
        let defaultCategory = UNNotificationCategory(identifier: "DEFAULT_CATEGORY", actions: [viewAction], intentIdentifiers: [], options: [])
        center.getNotificationCategories { existing in
            center.setNotificationCategories(existing.union([defaultCategory]))
        }
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[main-app] Notification permission error: \(error)")
            } else {
                print("[main-app] Notification permission granted: \(granted)")
            }
        }

        let devicePort = UInt16(AppState.shared.myDevice?.port ?? Int(Defaults.serverPort))
        WebSocketServer.shared.start(port: devicePort)

        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            AppState.shared.syncWithSystemNotifications()
        }

        loadCachedIcons()
        loadCachedWallpapers()

        // Load saved app icon preference and revert if needed based on license status
        let appIconManager = AppIconManager()
        appIconManager.loadCurrentIcon()

        // Set up listener for license changes to revert icon if needed
        // This will be called when license status changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LicenseStatusChanged"),
            object: nil,
            queue: .main
        ) { _ in
            appIconManager.revertToDefaultIfNeeded()
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
                    .applyMainWindowSetup(appDelegate: appDelegate, appState: appState)
                    .dropTarget(appState: appState)
            } else {
                HomeView()
                    .applyMainWindowSetup(appDelegate: appDelegate, appState: appState)
                    .dropTarget(appState: appState)
            }
        }
    .commands {
        CommandGroup(after: .appInfo) {
            CheckForUpdatesView(updater: updaterController.updater)
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

        }

    }

}

extension View {
    func applyMainWindowSetup(appDelegate: AppDelegate, appState: AppState) -> some View {
        self.background(WindowAccessor(callback: { window in
            window.identifier = NSUserInterfaceItemIdentifier("main")
            appDelegate.mainWindow = window
            window.collectionBehavior.insert(.moveToActiveSpace)
            // Make window transparent during onboarding
            if appState.isOnboardingActive {
                // Keep window visible but dimmed during onboarding to avoid fully invisible UI if sheet fails
                window.alphaValue = 0.6
                window.isOpaque = false
            } else {
                window.alphaValue = 1.0
                window.isOpaque = true
            }
        }, onOnboardingChange: { isActive in
            guard let window = appDelegate.mainWindow else { return }
            // Animate the transition
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                if isActive {
                    // Dim instead of hiding completely
                    window.animator().alphaValue = 0.6
                    window.isOpaque = false
                } else {
                    window.animator().alphaValue = 1.0
                    window.isOpaque = true
                }
            }
        }))
    }
}
