//
//  AppDelegate.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-08-07.
//
import SwiftUI

// Helper to grab NSWindow from SwiftUI:
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.callback(window)
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// AppDelegate to hold NSWindow reference:
class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindow: NSWindow?
}
