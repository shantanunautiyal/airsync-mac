//
//  MenubarSegments.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2026-05-07.
//

import SwiftUI

struct TopSegmentView: View {
    @ObservedObject var appState = AppState.shared
    let toolButtonSize: CGFloat
    let openAndFocusMainWindow: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: toolButtonSize, height: toolButtonSize)

                Menu {
                    #if DEBUG
                    Button("Crash", systemImage: "bolt.trianglebadge.exclamationmark") {
                        fatalError("Sentry Test Crash")
                    }
                    #endif
                    
                    Button("Quit", systemImage: "power") {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    Text("AirSync")
                        .font(.title2)
                }
                .menuStyle(.borderlessButton)
                .focusable(false)

                Spacer()

                ConnectionStatusPill()
                    .focusable(false)
                
                GlassButtonView(
                    label: "Open App",
                    systemImage: "arrow.up.forward.app",
                    iconOnly: true,
                    circleSize: toolButtonSize
                ) {
                    openAndFocusMainWindow()
                }
            }

            if appState.device != nil {
                HStack(spacing: 4) {
                    GlassButtonView(
                        label: "Send Clipboard",
                        systemImage: "clipboard",
                        iconOnly: true,
                        circleSize: toolButtonSize,
                        action: {
                            sendClipboard()
                        }
                    )
                    
                    GlassButtonView(
                        label: "QuickShare",
                        systemImage: "square.and.arrow.up",
                        iconOnly: true,
                        circleSize: toolButtonSize,
                        action: {
                            openQuickShare()
                        }
                    )

                    if appState.isFileAccessEnabled && WebDAVManager.shared.isMounted {
                        GlassButtonView(
                            label: L("menu.browseFiles"),
                            systemImage: "folder",
                            iconOnly: true,
                            circleSize: toolButtonSize,
                            action: {
                                WebDAVManager.shared.openInFinder()
                            }
                        )
                    }
                    
                    if (appState.device != nil || appState.adbConnected) && (appState.isPlus || !appState.licenseCheck) {
                        GlassButtonView(
                            label: appState.isMirroring ? "Stop Mirroring" : (appState.isMirrorRequestPending ? "Starting..." : "Mirror"),
                            systemImage: appState.isMirroring ? "stop.circle" : "apps.iphone",
                            iconOnly: true,
                            primary: !appState.isMirroring,
                            circleSize: toolButtonSize,
                            isLoading: appState.isMirrorRequestPending,
                            action: {
                                if appState.isMirroring {
                                    WebSocketServer.shared.stopMirroring()
                                    print("[menubar] Requested stop mirroring")
                                } else if !appState.isMirrorRequestPending {
                                    let adbEnabled = appState.adbEnabled && appState.adbConnected
                                    let hasADB = ADBConnector.findExecutable(named: "adb", fallbackPaths: ADBConnector.possibleADBPaths) != nil
                                    let hasScrcpy = ADBConnector.findExecutable(named: "scrcpy", fallbackPaths: ADBConnector.possibleScrcpyPaths) != nil

                                    if adbEnabled && hasADB && hasScrcpy {
                                        if appState.useNativeMirroringByDefault {
                                            appState.isNativeMirroring = true
                                        } else {
                                            guard let device = appState.device else { return }
                                            ADBConnector.startScrcpy(
                                                ip: device.ipAddress,
                                                port: appState.adbPort,
                                                deviceName: device.name
                                            )
                                        }
                                    } else {
                                        // Request WebSocket mirroring
                                        WebSocketServer.shared.sendMirrorRequest(
                                            action: "start",
                                            mode: "device",
                                            package: nil,
                                            options: [
                                                "transport": "websocket",
                                                "fps": appState.mirrorFPS,
                                                "quality": appState.mirrorQuality,
                                                "maxWidth": appState.mirrorMaxWidth,
                                                "autoApprove": true
                                            ]
                                        )
                                        print("[menubar] Requested WebSocket mirroring (device mode)")
                                    }
                                }
                            }
                        )
                        .contextMenu {
                            if appState.useNativeMirroringByDefault {
                                Button("scrcpy Mirror") {
                                    ADBConnector.startScrcpy(
                                        ip: appState.device?.ipAddress ?? "",
                                        port: appState.adbPort,
                                        deviceName: appState.device?.name ?? "My Phone"
                                    )
                                }
                                .disabled(!appState.adbConnected)
                            } else {
                                Button("Android Mirror") {
                                    appState.isNativeMirroring = true
                                }
                                .disabled(!appState.adbConnected)
                            }

                            Divider()

                            if appState.useNativeDesktopMirroringByDefault {
                                Button("Native Desktop") {
                                    appState.isNativeDesktopMirroring = true
                                }
                                .disabled(!appState.adbConnected)
                                Button("scrcpy Desktop") {
                                    ADBConnector.startScrcpy(
                                        ip: appState.device?.ipAddress ?? "",
                                        port: appState.adbPort,
                                        deviceName: appState.device?.name ?? "My Phone",
                                        desktop: true
                                    )
                                }
                                .disabled(!appState.adbConnected)
                            } else {
                                Button("Desktop Mode") {
                                    ADBConnector.startScrcpy(
                                        ip: appState.device?.ipAddress ?? "",
                                        port: appState.adbPort,
                                        deviceName: appState.device?.name ?? "My Phone",
                                        desktop: true
                                    )
                                }
                                .disabled(!appState.adbConnected)
                                Button("Native Desktop") {
                                    appState.isNativeDesktopMirroring = true
                                }
                                .disabled(!appState.adbConnected)
                            }
                        }
                    }
                    
                    
                    GlassButtonView(
                        label: "DND",
                        systemImage: appState.silenceAllNotifications ? "bell.slash.fill" : "bell.badge",
                        iconOnly: true,
                        circleSize: toolButtonSize
                    ) {
                        appState.silenceAllNotifications.toggle()
                    }
                }
                
                if appState.adbConnected && !appState.recentApps.isEmpty {
                    RecentAppsGridView()
                }
            }
        }
        .padding(12)
        .segmentStyle()
    }
    
    private func sendClipboard() {
        let pasteboard = NSPasteboard.general
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let firstUrl = urls.first {
            DispatchQueue.global(qos: .userInitiated).async {
                WebSocketServer.shared.sendFile(url: firstUrl, isClipboard: true)
            }
        } else if let image = NSImage(pasteboard: pasteboard) {
            let tempDir = FileManager.default.temporaryDirectory
            let tempUrl = tempDir.appendingPathComponent("clipboard_image_\(Int(Date().timeIntervalSince1970)).png")
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                do {
                    try pngData.write(to: tempUrl)
                    DispatchQueue.global(qos: .userInitiated).async {
                        WebSocketServer.shared.sendFile(url: tempUrl, isClipboard: true)
                    }
                } catch {
                    print("[MenubarView] Failed to save clipboard image: \(error)")
                }
            }
        }
    }
    
    private func openQuickShare() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            let targetName = appState.device?.name
            QuickShareManager.shared.startDiscovery(autoTargetName: targetName)
            QuickShareManager.shared.transferURLs = panel.urls
            appState.showingQuickShareTransfer = true
        }
    }
}

struct MediaSegmentView: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        if let status = appState.status {
            DeviceStatusView(showMediaToggle: true)
                .background {
                    let artwork = status.music?.albumArt ?? ""
                    if !appState.isMusicCardHidden,
                       !artwork.isEmpty,
                       let data = Data(base64Encoded: artwork),
                       let image = NSImage(data: data) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .transition(.scale.combined(with: .opacity))
                .animation(.interpolatingSpring(stiffness: 200, damping: 30), value: appState.isMusicCardHidden)
        }
    }
}



struct DiscoverySegmentView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject private var udpDiscovery = DiscoveryManager.shared
    @ObservedObject private var bleManager = BLECentralManager.shared

    var body: some View {
        let hasUdp = !udpDiscovery.discoveredDevices.isEmpty
        let hasBle = appState.isBLEEnabled && !bleManager.discoveredBLEDevices.isEmpty
        
        if appState.device == nil && (hasUdp || hasBle) {
            MenubarDeviceDiscoveryView()
                .padding(10)
                .segmentStyle()
        }
    }
}

struct NotificationsSegmentView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var summaryViewModel = NotificationSummaryViewModel.shared
    
    var body: some View {
        let filtered = appState.includeSilentInAIOption ? appState.notifications : appState.notifications.filter { $0.priority != "silent" }
        
        if appState.device != nil && !appState.notifications.isEmpty {
            VStack(spacing: 6) {
                HStack {
                    Text("Notifications")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)

                if !appState.disableAllAIFeatures && appState.enableMenubarAISummary && filtered.count >= 3 {
                    MenubarSummaryCardView(viewModel: summaryViewModel)
                        .padding(6)
                        .segmentStyle()
                        .modifier(AIGlowModifier(isGenerating: summaryViewModel.isGeneratingSummary, cornerRadius: 20))
                        .onAppear {
                            summaryViewModel.generateSummary(notifications: appState.notifications, androidApps: appState.androidApps)
                        }
                        .onChange(of: appState.notifications) { _, newNotifications in
                            summaryViewModel.generateSummary(notifications: newNotifications, androidApps: appState.androidApps)
                        }
                }

                MenuBarNotificationsListView()
            }
        }
    }
}



