//
//  MenubarPanel.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2026-05-07.
//

import AppKit
import SwiftUI

class MenubarPanel: NSPanel {
    init(contentRect: NSRect, rootView: some View) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = self.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        self.contentView = hostingView
        self.becomesKeyOnlyIfNeeded = false
    }

    override var canBecomeKey: Bool {
        return true
    }
}
