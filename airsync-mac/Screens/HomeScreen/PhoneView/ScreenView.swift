//
//  ScreenView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-20.
//

import SwiftUI

struct ScreenView: View {
    @ObservedObject var appState = AppState.shared
    var body: some View {
        VStack{

            Spacer()

            TimeView()
                .transition(.opacity.combined(with: .scale))

            Spacer()

            if appState.device != nil {

                HStack(spacing: 10){
                    GlassButtonView(
                        label: "Send",
                        systemImage: "square.and.arrow.up",
                        iconOnly: appState.adbConnected,
                        action: {
                            let panel = NSOpenPanel()
                            panel.canChooseFiles = true
                            panel.canChooseDirectories = false
                            panel.allowsMultipleSelection = false
                            panel.begin { response in
                                if response == .OK, let url = panel.url {
                                    AppState.shared.sendFile(url: url)
                                }
                            }
                        }
                    )
                    .transition(.identity)
                    .keyboardShortcut(
                        "f",
                        modifiers: .command
                    )

                    if !appState.adbConnected {
                        GlassButtonView(
                            label: "Mirror",
                            systemImage: "apps.iphone",
                            action: {
                                let res = AppState.shared.scrcpyResolution
                                let bitrate = AppState.shared.scrcpyBitrate
                                // Send a request to start mirroring (will be routed via BLE or WebSocket)
                                AppState.shared.requestStartMirroring(
                                    mode: "device",
                                    resolution: "\(res)x\(Int(Double(res) * 0.56))",
                                    bitrateMbps: bitrate,
                                     appPackage: nil
                                )
                                // Lightweight user feedback
                                AppState.shared.postNativeNotification(
                                    id: "mirror_request",
                                    appName: "AirSync",
                                    title: "Mirror request sent",
                                    body: "Waiting for Android to start mirroring"
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
                                let res = AppState.shared.scrcpyResolution
                                AppState.shared.requestStartMirroring(
                                    mode: "desktop",
                                    resolution: UserDefaults.standard.scrcpyShareRes ? UserDefaults.standard.scrcpyDesktopMode : "\(res)x\(Int(Double(res) * 0.56))",
                                     bitrateMbps: AppState.shared.scrcpyBitrate,
                                    appPackage: nil
                                )
                                AppState.shared.postNativeNotification(
                                    id: "mirror_request_desktop",
                                    appName: "AirSync",
                                    title: "Desktop mode request sent",
                                    body: "Waiting for Android to start desktop mode"
                                )
                            }
                            Button("Stop Mirroring") { 
                                AppState.shared.requestStopMirroring()
                                AppState.shared.postNativeNotification(
                                    id: "mirror_stop",
                                    appName: "AirSync",
                                    title: "Stop request sent",
                                    body: "Requested Android to stop mirroring"
                                )
                            }
                        }
                    }

                    if appState.adbConnected{
                        GlassButtonView(
                            label: "Mirror",
                            systemImage: "apps.iphone",
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
                }
            }
            if (appState.status != nil){
                DeviceStatusView()
                    .transition(.scale.combined(with: .opacity))
                    .animation(.interpolatingSpring(stiffness: 200, damping: 30), value: appState.isMusicCardHidden)
            }

        }
        .padding(8)
        .animation(
            .easeInOut(duration: 0.35),
            value: AppState.shared.adbConnected
        )
        .animation(
            .easeInOut(duration: 0.28),
            value: appState.isMusicCardHidden
        )
    }
}

#Preview {
    ScreenView()
}
