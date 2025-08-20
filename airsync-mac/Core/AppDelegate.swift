//
//  AppDelegate.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-07.
//
import SwiftUI
import Cocoa


final class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindow: NSWindow?

    // Access the single shared AppDelegate instance
    static var shared: AppDelegate? { NSApp.delegate as? AppDelegate }

    func applicationWillTerminate() {
        AppState.shared.disconnectDevice()
        ADBConnector.disconnectADB()
        WebSocketServer.shared.stop()
    }

    func applicationDidFinishLaunching() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    // Configure and retain main window when captured
    func configureMainWindowIfNeeded(_ window: NSWindow) {
        if mainWindow == nil || mainWindow !== window {
            mainWindow = window
        }
        // Ensure window isn't released and can move to active Space on activation
        window.isReleasedWhenClosed = false
        window.collectionBehavior.insert(.moveToActiveSpace)
    }

    // Public helper to bring the main window to the current Space and focus it
    func showAndActivateMainWindow() {
        guard let window = mainWindow else { return }
        window.collectionBehavior.insert(.moveToActiveSpace)
        if window.isMiniaturized { window.deminiaturize(nil) }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        // Second pass after a slight delay to overcome Space transition latency
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak window] in
            guard let w = window else { return }
            w.collectionBehavior.insert(.moveToActiveSpace)
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

}

// Helper to grab NSWindow from SwiftUI:
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                AppDelegate.shared?.configureMainWindowIfNeeded(window)
                self.callback(window)
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
